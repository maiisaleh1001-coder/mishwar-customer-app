# بيولّد شاشات Flow 3 وما بعده في ui/index.html من ملفات الـ Design Canvas (design-canvas/project).
# الـ Canvas هو المصدر: عدّل هناك، وبعدين شغّل السكريبت ده علشان البروتوتايب يتحدّث.
# الشاشات بتتحط كـ <template> بين العلامتين @canvas:start و @canvas:end، والـ Components (dc-import) بتتفك جوه كل شاشة.
param([string]$Root = (Split-Path $PSScriptRoot -Parent))

$utf8 = New-Object Text.UTF8Encoding($false)
$proj = Join-Path $Root 'design-canvas\project'
$index = Join-Path $PSScriptRoot 'index.html'
$canvas = [IO.File]::ReadAllText((Join-Path $proj 'canvas.json'), $utf8) | ConvertFrom-Json

# M1 و M2 متعمولين في البروتوتايب بإيد (فيهم Logic)، فبناخد من C-21 وطالع، و X-xx
$pick = '^(C([2-9]\d|1\d\d)[a-z]?|X\d+)-'

# صور الـ Canvas (/_blob/<id>) ونسختها المحلية جوه ui/assets
$blobs = @{
  'f2c8c0eebdc23155c7b793f03309d34d' = 'assets/map/riyadh-olaya.svg'
  '3c4dd54157ba99fa4a8bf5e4349761f4' = 'assets/map/riyadh-narjis.svg'
  '683e65e84fbe83744f6ac53dcd7de224' = 'assets/map/riyadh-malqa.svg'
}

function Get-Markup([string]$name) {
  $t = [IO.File]::ReadAllText((Join-Path $proj "$name.dc.html"), $utf8)
  $m = [regex]::Match($t, '<x-dc>([\s\S]*)</x-dc>')
  if (-not $m.Success) { throw "مفيش <x-dc> في $name" }
  ([regex]::Replace($m.Groups[1].Value, '<helmet>[\s\S]*?</helmet>', '')).Trim()
}

# نفس الـ renderVals اللي في كل Component
function Get-Vals([string]$name, [hashtable]$a) {
  $no = { param($v) $v -in @('{{no}}', 'false', 'False') }
  switch ($name) {
    'Bottom-Nav' {
      $act = if ($a.active) { $a.active } else { 'home' }
      return @{ homeOn = $act -eq 'home'; homeOff = $act -ne 'home'; ordersOn = $act -eq 'orders'; ordersOff = $act -ne 'orders'; profileOn = $act -eq 'profile'; profileOff = $act -ne 'profile' }
    }
    'Map-Route' { return @{ showCar = -not (& $no $a['show-car']) } }
    'Provider-Card' {
      $d = @{ person = 'عبدالله القحطاني'; rating = '4.9'; detail = 'تويوتا كامري · بيضاء'; plate = '1234 ر س ع' }
      foreach ($k in @($d.Keys)) { if ($a.ContainsKey($k)) { $d[$k] = $a[$k] } }
      $d.hasPlate = $d.plate -ne ''
      return $d
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
  if ($name -notmatch $pick) { continue }
  $b = $canvas.boards.$file
  $id = [regex]::Replace($name, '^([A-Z])(\d+[a-z]?)-.*$', '$1-$2')
  $title = ($b.title -split ' · ', 2)[1]
  $group = $rows[[int]$b.y]
  $tall = if ([int]$b.h -gt 844) { ' data-tall' } else { '' }
  $html = Resolve-Markup (Get-Markup $name) @{ no = $false }
  foreach ($k in $blobs.Keys) { $html = $html.Replace("/_blob/$k", $blobs[$k]) }
  [void]$out.AppendLine("<template data-id=`"$id`" data-title=`"$title`" data-group=`"$group`"$tall>$html</template>")
  $count++
}

$t = [IO.File]::ReadAllText($index, $utf8)
$start = '<!-- @canvas:start -->'; $end = '<!-- @canvas:end -->'
$i = $t.IndexOf($start); $j = $t.IndexOf($end)
if ($i -lt 0 -or $j -lt $i) { throw 'مش لاقي العلامتين @canvas:start و @canvas:end في index.html' }
$t = $t.Substring(0, $i + $start.Length) + "`n" + $out.ToString() + $t.Substring($j)
[IO.File]::WriteAllText($index, $t, $utf8)
"اتولّدت $count شاشة في $index"
