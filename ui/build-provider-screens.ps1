# بيولّد شاشات بروتوتايب مقدم الخدمة (ui/provider.html) من ملفات الـ Canvas (provider-canvas/project).
# الـ Canvas هو المصدر: عدّل هناك، وبعدين شغّل السكريبت ده علشان البروتوتايب يتحدّث.
# الشاشات بتتحط كـ <template> بين العلامتين @canvas:start و @canvas:end، والـ Components (dc-import) بتتفك جوه كل شاشة،
# واللينكات بين الشاشات (Pxx.dc.html) بتتحول لـ #P-xx.
param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$utf8 = New-Object Text.UTF8Encoding($false)
$proj = Join-Path $Root 'provider-canvas\project'
$index = Join-Path $PSScriptRoot 'provider.html'
$canvas = [IO.File]::ReadAllText((Join-Path $proj 'canvas.json'), $utf8) | ConvertFrom-Json

# صور الـ Canvas (/_blob/<id>) ونسختها المحلية جوه ui/assets
$blobs = @{
  'a35a0ed7034896782e8060c85e45e019' = 'assets/onboarding/ob-car.png'
  '103b56979199f2f5c79882b02f8243c3' = 'assets/onboarding/ob-parcel.png'
  '3702212b613545c022157a2417f81431' = 'assets/onboarding/ob-companion.png'
  '05c816e6a5c05ddf8636c71b0c6582a3' = 'assets/onboarding/ob-gov.png'
  '0b1131a8aec6a41446df5fd921180b57' = 'assets/map/riyadh-olaya.svg'
  '08dc33a457df0399712b1df352bbcdae' = 'assets/map/riyadh-narjis.svg'
}

# شاشات خلفيتها غامقة، فشريط الحالة فوقها يبقى أبيض
$light = @('P-01', 'P-91')

function Get-Id([string]$name) {
  if ($name -eq 'Main') { return 'P-01' }
  [regex]::Replace($name, '^P(\d+[a-z]?)-.*$', 'P-$1')
}

function Get-Markup([string]$name) {
  $t = [IO.File]::ReadAllText((Join-Path $proj "$name.dc.html"), $utf8)
  $m = [regex]::Match($t, '<x-dc>([\s\S]*)</x-dc>')
  if (-not $m.Success) { throw "مفيش <x-dc> في $name" }
  ([regex]::Replace($m.Groups[1].Value, '<helmet>[\s\S]*?</helmet>', '')).Trim()
}

# نفس الـ renderVals اللي في كل Component
function Get-Vals([string]$name, [hashtable]$a) {
  switch ($name) {
    'P-Map' {
      $m = if ($a.mode) { $a.mode } else { 'idle' }
      return @{ idle = $m -in @('idle', 'off'); dim = $m -eq 'off'; hasRoute = $m -in @('route', 'arrived', 'trip'); approach = $m -eq 'route'; arrived = $m -eq 'arrived'; trip = $m -eq 'trip' }
    }
    'P-Bottom-Nav' {
      $act = if ($a.active) { $a.active } else { 'home' }
      return @{ homeOn = $act -eq 'home'; homeOff = $act -ne 'home'; ordersOn = $act -eq 'orders'; ordersOff = $act -ne 'orders'; earnOn = $act -eq 'earnings'; earnOff = $act -ne 'earnings'; profileOn = $act -eq 'profile'; profileOff = $act -ne 'profile' }
    }
    default { return @{} }
  }
}

function Resolve-Markup([string]$html, [hashtable]$vals) {
  $html = [regex]::Replace($html, '<dc-import name="([^"]+)"([^>]*)></dc-import>', {
    param($m)
    $attrs = @{}
    foreach ($x in [regex]::Matches($m.Groups[2].Value, '([\w-]+)="([^"]*)"')) { if ($x.Groups[1].Value -ne 'hint-size') { $attrs[$x.Groups[1].Value] = $x.Groups[2].Value } }
    $n = $m.Groups[1].Value
    Resolve-Markup (Get-Markup $n) (Get-Vals $n $attrs)
  })
  $html = [regex]::Replace($html, '<sc-if value="\{\{(\w+)\}\}"[^>]*>([\s\S]*?)</sc-if>', {
    param($m) if ($vals[$m.Groups[1].Value]) { $m.Groups[2].Value.Trim() } else { '' }
  })
  [regex]::Replace($html, '\{\{(\w+)\}\}', { param($m) [string]$vals[$m.Groups[1].Value] })
}

# عنوان الـ Flow لكل صف في الـ Canvas: الملاحظة بتبقى فوق الصف بـ 300
$rows = @{}
foreach ($p in $canvas.notes.PSObject.Properties) { if ($p.Value.kind -eq 'title1') { $rows[[int]$p.Value.y + 300] = $p.Value.text } }

$out = New-Object Text.StringBuilder
$count = 0
foreach ($file in $canvas.order) {
  $name = $file -replace '\.dc\.html$', ''
  if ($name -like 'P-*') { continue }
  $b = $canvas.boards.$file
  $id = Get-Id $name
  $title = ($b.title -split ' · ', 2)[1]
  $group = $rows[[int]$b.y]
  $flags = ''
  if ([int]$b.h -gt 844) { $flags += ' data-tall' }
  if ($id -in $light) { $flags += ' data-light' }
  $html = Resolve-Markup (Get-Markup $name) @{}
  $html = [regex]::Replace($html, 'href="(?:\.\/)?([\w-]+)\.dc\.html"', { param($m) 'href="#' + (Get-Id $m.Groups[1].Value) + '"' })
  foreach ($k in $blobs.Keys) { $html = $html.Replace("/_blob/$k", $blobs[$k]) }
  [void]$out.AppendLine("<template data-id=`"$id`" data-title=`"$title`" data-group=`"$group`"$flags>$html</template>")
  $count++
}

$t = [IO.File]::ReadAllText($index, $utf8)
$start = '<!-- @canvas:start -->'; $end = '<!-- @canvas:end -->'
$i = $t.IndexOf($start); $j = $t.IndexOf($end)
if ($i -lt 0 -or $j -lt $i) { throw 'مش لاقي العلامتين @canvas:start و @canvas:end في provider.html' }
$t = $t.Substring(0, $i + $start.Length) + "`n" + $out.ToString() + $t.Substring($j)
[IO.File]::WriteAllText($index, $t, $utf8)
"اتولّدت $count شاشة في $index"
