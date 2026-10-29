param([string]$pdf, [string]$mode = 'raw', [int]$page = 1)
$b = [IO.File]::ReadAllBytes($pdf)
$L1 = [Text.Encoding]::GetEncoding(28591)
$s = $L1.GetString($b)

function Inflate([byte[]]$data) {
  $ms = New-Object IO.MemoryStream($data, 2, $data.Length - 2)
  $ds = New-Object IO.Compression.DeflateStream($ms, [IO.Compression.CompressionMode]::Decompress)
  $o = New-Object IO.MemoryStream
  try { $ds.CopyTo($o) } catch {}
  return ,$o.ToArray()
}

$objs = @{}; $streams = @{}
foreach ($m in [regex]::Matches($s, '(?s)(\d+) 0 obj(.*?)endobj')) {
  $num = [int]$m.Groups[1].Value
  $body = $m.Groups[2].Value
  $si = $body.IndexOf('stream')
  if ($si -ge 0) {
    $dict = $body.Substring(0, $si)
    $objs[$num] = $dict
    if ($dict -match '/Subtype\s*/Image') { continue }
    $start = $m.Groups[2].Index + $si + 6
    if ($s[$start] -eq "`r") { $start++ }
    if ($s[$start] -eq "`n") { $start++ }
    $end = $m.Groups[2].Index + $body.LastIndexOf('endstream')
    $len = $end - $start
    $raw = New-Object byte[] $len
    [Array]::Copy($b, $start, $raw, 0, $len)
    if ($dict -match 'FlateDecode') { $raw = Inflate $raw }
    $streams[$num] = $L1.GetString($raw)
  } else { $objs[$num] = $body }
}

function HexToStr([string]$h) {
  $h = $h -replace '\s', ''
  $bytes = New-Object byte[] ($h.Length / 2)
  for ($i = 0; $i -lt $bytes.Length; $i++) { $bytes[$i] = [Convert]::ToByte($h.Substring($i * 2, 2), 16) }
  return [Text.Encoding]::BigEndianUnicode.GetString($bytes)
}

function ParseCMap([string]$c) {
  $map = @{}
  foreach ($blk in [regex]::Matches($c, '(?s)beginbfchar(.*?)endbfchar')) {
    foreach ($p in [regex]::Matches($blk.Groups[1].Value, '<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]*)>')) {
      $map[[Convert]::ToInt32($p.Groups[1].Value, 16)] = HexToStr $p.Groups[2].Value
    }
  }
  foreach ($blk in [regex]::Matches($c, '(?s)beginbfrange(.*?)endbfrange')) {
    foreach ($p in [regex]::Matches($blk.Groups[1].Value, '<([0-9A-Fa-f]+)>\s*<([0-9A-Fa-f]+)>\s*(<[0-9A-Fa-f]*>|\[[^\]]*\])')) {
      $lo = [Convert]::ToInt32($p.Groups[1].Value, 16); $hi = [Convert]::ToInt32($p.Groups[2].Value, 16)
      $d = $p.Groups[3].Value
      if ($d.StartsWith('[')) {
        $arr = [regex]::Matches($d, '<([0-9A-Fa-f]*)>')
        for ($k = 0; $k -le ($hi - $lo) -and $k -lt $arr.Count; $k++) { $map[$lo + $k] = HexToStr $arr[$k].Groups[1].Value }
      } else {
        $h = $d.Trim('<', '>'); $base = [Convert]::ToInt32($h, 16)
        for ($k = 0; $k -le ($hi - $lo); $k++) { $map[$lo + $k] = [string][char]($base + $k) }
      }
    }
  }
  return $map
}

# font object -> cmap
$fontMaps = @{}
foreach ($n in @($objs.Keys)) {
  $mm = [regex]::Match($objs[$n], '/ToUnicode\s+(\d+)\s+0\s+R')
  if ($mm.Success) { $fontMaps[$n] = ParseCMap $streams[[int]$mm.Groups[1].Value] }
}

# page order
$root = $objs.Keys | Where-Object { $objs[$_] -match '/Type\s*/Pages' -and $objs[$_] -notmatch '/Parent' } | Select-Object -First 1
$pages = New-Object System.Collections.ArrayList
function Walk($n) {
  $o = $objs[$n]
  if ($o -match '/Type\s*/Pages') {
    $kids = [regex]::Match($o, '/Kids\s*\[([^\]]*)\]').Groups[1].Value
    foreach ($k in [regex]::Matches($kids, '(\d+)\s+0\s+R')) { Walk ([int]$k.Groups[1].Value) }
  } else { [void]$pages.Add($n) }
}
Walk $root

function PageFonts($pn) {
  $o = $objs[$pn]
  $rm = [regex]::Match($o, '/Resources\s+(\d+)\s+0\s+R')
  $res = if ($rm.Success) { $objs[[int]$rm.Groups[1].Value] } else { $o }
  $fm = [regex]::Match($res, '/Font\s+(\d+)\s+0\s+R')
  $fd = if ($fm.Success) { $objs[[int]$fm.Groups[1].Value] } else { [regex]::Match($res, '(?s)/Font\s*<<(.*?)>>').Groups[1].Value }
  $h = @{}
  foreach ($f in [regex]::Matches($fd, '/([^\s/]+)\s+(\d+)\s+0\s+R')) { $h[$f.Groups[1].Value] = [int]$f.Groups[2].Value }
  return $h
}

function PageContent($pn) {
  $o = $objs[$pn]
  $cm = [regex]::Match($o, '/Contents\s*(\[[^\]]*\]|\d+\s+0\s+R)')
  $sb = New-Object Text.StringBuilder
  foreach ($r in [regex]::Matches($cm.Groups[1].Value, '(\d+)\s+0\s+R')) { [void]$sb.Append($streams[[int]$r.Groups[1].Value]); [void]$sb.Append("`n") }
  return $sb.ToString()
}

function IsLtr([string]$t) { return $t -match '[A-Za-z0-9٠-٩]' }

function ExtractPage($pn) {
  $fonts = PageFonts $pn
  $c = PageContent $pn
  $runs = New-Object System.Collections.ArrayList
  $curMap = $null; $x = 0.0; $y = 0.0; $stack = New-Object System.Collections.ArrayList
  $tok = '<[0-9A-Fa-f\s]*>|\((?:\\.|[^\\)])*\)|\[|\]|/[^\s/\[\]<>()]+|-?\d*\.?\d+|[A-Za-z''"*]+'
  $inArr = $false; $arrUnits = $null
  foreach ($t in [regex]::Matches($c, $tok)) {
    $v = $t.Value
    if ($v -eq '[') { $inArr = $true; $arrUnits = New-Object System.Collections.ArrayList; continue }
    if ($v -eq ']') { $inArr = $false; continue }
    if ($v.StartsWith('<')) {
      $h = $v.Trim('<', '>') -replace '\s', ''
      $units = New-Object System.Collections.ArrayList
      for ($i = 0; $i + 4 -le $h.Length; $i += 4) {
        $g = [Convert]::ToInt32($h.Substring($i, 4), 16)
        if ($curMap -and $curMap.ContainsKey($g)) { [void]$units.Add($curMap[$g]) }
      }
      if ($inArr) { [void]$arrUnits.AddRange($units) } else { [void]$stack.Add($units) }
      continue
    }
    if ($v -match '^-?\d*\.?\d+$' -or $v.StartsWith('/') -or $v.StartsWith('(')) { [void]$stack.Add($v); continue }
    switch -CaseSensitive ($v) {
      'Tf' { $fn = $stack[$stack.Count - 2].TrimStart('/'); $curMap = if ($fonts.ContainsKey($fn)) { $fontMaps[$fonts[$fn]] } else { $null } }
      'Tm' { $x = [double]$stack[$stack.Count - 2]; $y = [double]$stack[$stack.Count - 1] }
      'Td' { $x += [double]$stack[$stack.Count - 2]; $y += [double]$stack[$stack.Count - 1] }
      'TD' { $x += [double]$stack[$stack.Count - 2]; $y += [double]$stack[$stack.Count - 1] }
      'Tj' { [void]$runs.Add([pscustomobject]@{ x = $x; y = $y; u = $stack[$stack.Count - 1] }) }
      'TJ' { [void]$runs.Add([pscustomobject]@{ x = $x; y = $y; u = $arrUnits }) }
    }
    $stack.Clear()
  }
  $lines = $runs | Group-Object { [math]::Round($_.y / 3) } | Sort-Object { [double]$_.Group[0].y }
  $out = New-Object Text.StringBuilder
  foreach ($ln in $lines) {
    $vis = New-Object System.Collections.ArrayList
    foreach ($r in ($ln.Group | Sort-Object x)) { if ($vis.Count) { [void]$vis.Add(' ') }; foreach ($u in $r.u) { [void]$vis.Add($u) } }
    # visual -> logical: reverse units, then restore order within LTR runs
    $rev = @($vis); [Array]::Reverse($rev)
    $res = New-Object System.Collections.ArrayList; $buf = New-Object System.Collections.ArrayList
    foreach ($u in $rev) {
      if ((IsLtr $u) -or ($buf.Count -and $u -match '^[\s\.\-:/,%]$')) { [void]$buf.Add($u) }
      else { if ($buf.Count) { $a = @($buf); [Array]::Reverse($a); [void]$res.AddRange($a); $buf.Clear() }; [void]$res.Add($u) }
    }
    if ($buf.Count) { $a = @($buf); [Array]::Reverse($a); [void]$res.AddRange($a) }
    $line = (-join $res) -replace '\s+', ' '
    if ($line.Trim()) { [void]$out.AppendLine($line.Trim()) }
  }
  return $out.ToString()
}

if ($mode -eq 'raw') { (PageContent $pages[$page - 1]).Substring(0, 2500) }
elseif ($mode -eq 'text') {
  $sb = New-Object Text.StringBuilder
  for ($p = 0; $p -lt $pages.Count; $p++) { [void]$sb.AppendLine("===== Page $($p + 1) ====="); [void]$sb.Append((ExtractPage $pages[$p])) }
  [IO.File]::WriteAllText($page, '') | Out-Null
  $sb.ToString()
}
