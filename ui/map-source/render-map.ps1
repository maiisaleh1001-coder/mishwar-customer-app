# Renders a clean SVG map (390x844) from Overpass JSON, in Mishwar colors.
# -Lat/-Lon: النقطة اللي بتيجي في نص الصورة (195,422). -NoRoute: من غير مسار (شاشات اختيار الموقع).
param([string]$Osm, [string]$Labels, [string]$Out, [double]$Lat = 24.7080, [double]$Lon = 46.6760, [switch]$NoRoute, [int]$Y0 = 60, [int]$Y1 = 824, [int]$MinorY0 = 100, [int]$MinorY1 = 420)
$inv = [Globalization.CultureInfo]::InvariantCulture
$N = [math]::Pow(2,16)*256; $W = 390; $H = 844
$rl = $Lat * [math]::PI / 180
$left = [math]::Floor(($Lon + 180) / 360 * $N - 195)
$top = [math]::Floor((1 - [math]::Log([math]::Tan($rl) + 1/[math]::Cos($rl)) / [math]::PI) / 2 * $N - 422)
function P($pt) {
  $x = ($pt.lon + 180) / 360 * $N - $left
  $r = $pt.lat * [math]::PI / 180
  $y = (1 - [math]::Log([math]::Tan($r) + 1/[math]::Cos($r)) / [math]::PI) / 2 * $N - $top
  ,@($x, $y)
}
function F($v) { $v.ToString('0.#', $inv) }
function D($pts, [switch]$Close) { $s = 'M' + (($pts | % { (F $_[0]) + ' ' + (F $_[1]) }) -join 'L'); if ($Close) { $s += 'Z' }; $s }

$j = [IO.File]::ReadAllText($Osm, [Text.Encoding]::UTF8) | ConvertFrom-Json
$cfg = [IO.File]::ReadAllText($Labels, [Text.Encoding]::UTF8) | ConvertFrom-Json

$cls = @{ motorway='mw'; trunk='mw'; motorway_link='lk'; trunk_link='lk'; primary='pr'; primary_link='lk'; secondary='se'; secondary_link='lk'
          tertiary='se'; tertiary_link='lk'; residential='re'; unclassified='re'; living_street='re'; service='sv' }
$roads = @{ mw=@(); pr=@(); se=@(); lk=@(); re=@(); sv=@() }
$bld = New-Object Text.StringBuilder; $green = New-Object Text.StringBuilder; $water = New-Object Text.StringBuilder
$named = @{}; $geom = @{}
foreach ($e in $j.elements) {
  if (-not $e.geometry -or $e.geometry.Count -lt 2) { continue }
  $pts = @($e.geometry | % { P $_ })
  $geom[[string]$e.id] = $pts
  $t = $e.tags
  if ($t.highway) {
    $c = $cls[$t.highway]; if (-not $c) { continue }
    $roads[$c] += (D $pts)
    if ($t.name) { if (-not $named[$t.name]) { $named[$t.name] = @() }; $named[$t.name] += ,$pts }
  } elseif ($t.building) { [void]$bld.Append((D $pts -Close)) }
  elseif ($t.natural -eq 'water') { [void]$water.Append((D $pts -Close)) }
  else { [void]$green.Append((D $pts -Close)) }
}

# casing ثم fill لكل الطرق، علشان التقاطعات تبان متصلة
$spec = [ordered]@{ sv=@(3.5,2.5,'#FFFFFF','#E3E7E5'); re=@(6,4.5,'#FFFFFF','#DCE1DF'); lk=@(6.5,5,'#FFFFFF','#D6DCDA')
                    se=@(9,7.5,'#FFFFFF','#D3DAD8'); pr=@(11.5,10,'#FFFFFF','#CBD3D1'); mw=@(15,13,'#F6E8CB','#E5D2AA') }
$sb = New-Object Text.StringBuilder
[void]$sb.Append("<svg xmlns=`"http://www.w3.org/2000/svg`" width=`"$W`" height=`"$H`" viewBox=`"0 0 $W $H`">")
[void]$sb.Append("<rect width=`"$W`" height=`"$H`" fill=`"#F1F3F1`"/>")
[void]$sb.Append("<path d=`"$($green.ToString())`" fill=`"#DCEBE1`"/>")
[void]$sb.Append("<path d=`"$($water.ToString())`" fill=`"#CFE4EA`"/>")
[void]$sb.Append("<path d=`"$($bld.ToString())`" fill=`"#E3E7E5`" stroke=`"#D8DDDB`" stroke-width=`".5`"/>")
[void]$sb.Append('<g fill="none" stroke-linecap="round" stroke-linejoin="round">')
foreach ($k in $spec.Keys) { if ($roads[$k].Count) { [void]$sb.Append("<path d=`"$($roads[$k] -join '')`" stroke=`"$($spec[$k][3])`" stroke-width=`"$($spec[$k][0])`"/>") } }
foreach ($k in $spec.Keys) { if ($roads[$k].Count) { [void]$sb.Append("<path d=`"$($roads[$k] -join '')`" stroke=`"$($spec[$k][2])`" stroke-width=`"$($spec[$k][1])`"/>") } }
[void]$sb.Append('</g>')

# أسامي الشوارع: أطول جزء ظاهر من كل شارع، واتجاهه من الشمال لليمين علشان الكلام مايتقلبش
$route = if ($NoRoute) { @() } else { @(@(276,399),@(238,315),@(222,280),@(193,215),@(176,179),@(162,149),@(150,139),@(121,152),@(79,173),@(64,180)) }
function NearRoute($pt) { for ($i=1; $i -lt $route.Count; $i++) { $a=$route[$i-1]; $b=$route[$i]; $dx=$b[0]-$a[0]; $dy=$b[1]-$a[1]
  $u=[math]::Max(0,[math]::Min(1,(($pt[0]-$a[0])*$dx+($pt[1]-$a[1])*$dy)/($dx*$dx+$dy*$dy))); $d=[math]::Sqrt([math]::Pow($a[0]+$u*$dx-$pt[0],2)+[math]::Pow($a[1]+$u*$dy-$pt[1],2)); if ($d -lt 22) { return $true } }; $false }
function Clip($pts) { $l = New-Object Collections.ArrayList; foreach ($p in $pts) { if ($p[0] -gt 8 -and $p[0] -lt ($W-8) -and $p[1] -gt $Y0 -and $p[1] -lt $Y1) { [void]$l.Add($p) } }; ,$l.ToArray() }
function Len($pts) { $l=0; for($i=1;$i -lt $pts.Count;$i++){ $l += [math]::Sqrt([math]::Pow($pts[$i][0]-$pts[$i-1][0],2)+[math]::Pow($pts[$i][1]-$pts[$i-1][1],2)) }; $l }
$font = "font-family=`"'IBM Plex Sans Arabic','Segoe UI',Tahoma,sans-serif`""
$defs = New-Object Text.StringBuilder; $txt = New-Object Text.StringBuilder; $n = 0; $used = @()
foreach ($r in $cfg.roads) {
  $cands = @($named[$r.name] | % { ,(Clip $_) } | ? { $_.Count -ge 2 } | Sort-Object { -(Len $_) })
  $label = if ($r.text) { $r.text } else { $r.name }
  $need = $label.Length * 6 + 40; $placed = 0
  foreach ($c in $cands) {
    if ($placed -ge $r.count) { break }
    if ((Len $c) -lt $need) { continue }
    $mid = $c[[int]($c.Count/2)]
    if (NearRoute $mid) { continue }
    if ($used | ? { [math]::Abs($_[0]-$mid[0]) -lt 40 -and [math]::Abs($_[1]-$mid[1]) -lt 120 }) { continue }
    if ($c[-1][0] -lt $c[0][0]) { [array]::Reverse($c) }
    $n++; $used += ,$mid; $placed++
    [void]$defs.Append("<path id=`"rl$n`" d=`"$(D $c)`"/>")
    [void]$txt.Append("<text $font font-size=`"10.5`" font-weight=`"600`" fill=`"#4F5D5B`" stroke=`"#FFFFFF`" stroke-width=`"3`" paint-order=`"stroke`" stroke-linejoin=`"round`" dy=`"3.5`"><textPath href=`"#rl$n`" startOffset=`"50%`" text-anchor=`"middle`">$label</textPath></text>")
  }
}
# أسامي شوارع صغيرة في الجزء اللي فوق (اللي مش متغطي بالـ Bottom Sheet)، بعيد عن المسار
$minor = 0
$resNames = $j.elements | ? { $_.tags.highway -in 'residential','tertiary','living_street' -and $_.tags.name -and $_.geometry.Count -ge 2 } | % { $_.tags.name } | Sort-Object -Unique
foreach ($nm in ($resNames | ? { $_ -match '[\u0600-\u06FF]' })) {
  if ($minor -ge 6) { break }
  foreach ($seg in $named[$nm]) {
    $l = New-Object Collections.ArrayList; foreach ($p in $seg) { if ($p[0] -gt 10 -and $p[0] -lt ($W-10) -and $p[1] -gt $MinorY0 -and $p[1] -lt $MinorY1) { [void]$l.Add($p) } }
    $c = $l.ToArray(); if ($c.Count -lt 2) { continue }
    if ((Len $c) -lt ($nm.Length * 5.2 + 30)) { continue }
    $mid = $c[[int]($c.Count/2)]
    if (NearRoute $mid) { continue }
    if ($used | ? { [math]::Abs($_[0]-$mid[0]) -lt 60 -and [math]::Abs($_[1]-$mid[1]) -lt 45 }) { continue }
    if ($c[-1][0] -lt $c[0][0]) { [array]::Reverse($c) }
    $n++; $used += ,$mid; $minor++
    [void]$defs.Append("<path id=`"rl$n`" d=`"$(D $c)`"/>")
    [void]$txt.Append("<text $font font-size=`"10.5`" fill=`"#5B6766`" stroke=`"#FFFFFF`" stroke-width=`"2.5`" paint-order=`"stroke`" stroke-linejoin=`"round`" dy=`"3`"><textPath href=`"#rl$n`" startOffset=`"50%`" text-anchor=`"middle`">$nm</textPath></text>")
    break
  }
}
foreach ($p in $cfg.pois) {
  $g = $geom[[string]$p.id]; if (-not $g) { continue }
  $cx = ($g | % { $_[0] } | Measure-Object -Average).Average; $cy = ($g | % { $_[1] } | Measure-Object -Average).Average
  [void]$txt.Append("<text $font x=`"$(F $cx)`" y=`"$(F $cy)`" font-size=`"11`" font-weight=`"600`" fill=`"#5B6766`" stroke=`"#F1F3F1`" stroke-width=`"3`" paint-order=`"stroke`" text-anchor=`"middle`">$($p.text)</text>")
}
[void]$sb.Append("<defs>$($defs.ToString())</defs>$($txt.ToString())</svg>")
[IO.File]::WriteAllText($Out, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
"written $Out $([math]::Round((Get-Item $Out).Length/1KB)) KB, $n road labels"
