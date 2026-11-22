<#
  Resizes site photos and writes them into the pages.

  1. Put the original photo in images/src/<slug>.jpg (originals are git-ignored).
  2. Add a row to tools/photos.csv:  slug,caption,groups
       groups = ;-separated list of marker names, e.g. gallery-rack;caps
       Product photos must not show faces. Faces are allowed only in buyer
       (testimonial) groups: gallery-buyers, home-buyers.
  3. Run from the site folder:  .\tools\photos.ps1
  4. Then run .\tools\seo.ps1 so the sitemap and structured data list the photos.

  Each page has markers like <!-- photos:caps --><!-- /photos:caps -->.
  The script replaces what is between them with the photos in that group,
  in the order they appear in photos.csv.
#>
param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$utf8 = New-Object System.Text.UTF8Encoding($false)
$FULL_MAX = 1280
$THUMB_MAX = 600
$QUALITY = 74L
$srcDir = Join-Path $Root "images\src"
$outDir = Join-Path $Root "images\photos"
New-Item -ItemType Directory -Force $outDir | Out-Null
$jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }

function Repair-Orientation($img) {
  if ($img.PropertyIdList -notcontains 0x0112) { return }
  $o = [int]$img.GetPropertyItem(0x0112).Value[0]
  $map = @{ 2="RotateNoneFlipX"; 3="Rotate180FlipNone"; 4="Rotate180FlipX"; 5="Rotate90FlipX"; 6="Rotate90FlipNone"; 7="Rotate270FlipX"; 8="Rotate270FlipNone" }
  if ($map.ContainsKey($o)) { $img.RotateFlip([System.Drawing.RotateFlipType]$map[$o]) }
}

function Save-Resized($img, [int]$max, [string]$path) {
  $scale = [Math]::Min(1.0, $max / [Math]::Max($img.Width, $img.Height))
  $w = [int][Math]::Round($img.Width * $scale); $h = [int][Math]::Round($img.Height * $scale)
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = "HighQualityBicubic"; $g.PixelOffsetMode = "HighQuality"
  $g.DrawImage($img, 0, 0, $w, $h)
  $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $QUALITY)
  $bmp.Save($path, $jpegCodec, $params)
  $g.Dispose(); $bmp.Dispose()
  return @($w, $h)
}

function Build-Photo($row) {
  $src = Join-Path $srcDir "$($row.slug).jpg"
  $full = Join-Path $outDir "$($row.slug).jpg"
  $thumb = Join-Path $outDir "$($row.slug)-sm.jpg"
  if (-not (Test-Path $src)) {
    if (Test-Path $thumb) { $i = [System.Drawing.Image]::FromFile($thumb); $size = @($i.Width, $i.Height); $i.Dispose(); return $size }
    throw "Missing source photo: $src"
  }
  if ((Test-Path $thumb) -and (Get-Item $thumb).LastWriteTime -gt (Get-Item $src).LastWriteTime) {
    $i = [System.Drawing.Image]::FromFile($thumb); $size = @($i.Width, $i.Height); $i.Dispose(); return $size
  }
  $img = [System.Drawing.Image]::FromFile($src)
  try {
    Repair-Orientation $img
    [void](Save-Resized $img $FULL_MAX $full)
    return (Save-Resized $img $THUMB_MAX $thumb)
  } finally { $img.Dispose() }
}

$rows = Import-Csv (Join-Path $Root "tools\photos.csv")
$figures = @{}
foreach ($row in $rows) {
  $size = Build-Photo $row
  $alt = [System.Net.WebUtility]::HtmlEncode($row.caption)
  $fig = "<figure class=`"shot`"><a href=`"images/photos/$($row.slug).jpg`"><img src=`"images/photos/$($row.slug)-sm.jpg`" width=`"$($size[0])`" height=`"$($size[1])`" alt=`"$alt`" loading=`"lazy`" decoding=`"async`"></a><figcaption>$alt</figcaption></figure>"
  foreach ($grp in $row.groups.Split(';')) {
    if (-not $figures.ContainsKey($grp)) { $figures[$grp] = New-Object System.Collections.ArrayList }
    [void]$figures[$grp].Add($fig)
  }
}

$lightbox = '<dialog class="lightbox" aria-label="Photo viewer"><button class="lb-close" type="button" aria-label="Close photo">&times;</button><img alt=""><p class="lb-cap"></p></dialog>'
foreach ($page in Get-ChildItem $Root -Filter *.html) {
  $html = [System.IO.File]::ReadAllText($page.FullName, $utf8)
  $before = $html
  $html = [regex]::Replace($html, '<!-- photos:([\w-]+) -->.*?<!-- /photos:\1 -->', {
    param($m)
    $grp = $m.Groups[1].Value
    $inner = if ($figures.ContainsKey($grp)) { $figures[$grp] -join '' } else { '' }
    "<!-- photos:$grp -->$inner<!-- /photos:$grp -->"
  }, 'Singleline')
  if ($html.Contains('class="shot"') -and -not $html.Contains('class="lightbox"')) {
    $html = $html.Replace('<a class="fab"', "$lightbox`n<a class=`"fab`"")
  }
  if ($html -ne $before) { [System.IO.File]::WriteAllText($page.FullName, $html, $utf8); Write-Output "updated $($page.Name)" }
}
# remove resized photos that are no longer listed in photos.csv
$used = @{}; foreach ($row in $rows) { $used["$($row.slug).jpg"] = 1; $used["$($row.slug)-sm.jpg"] = 1 }
Get-ChildItem $outDir -File | Where-Object { -not $used.ContainsKey($_.Name) } | ForEach-Object { Remove-Item $_.FullName; Write-Output "removed unused images/photos/$($_.Name)" }
$groupSummary = ($figures.Keys | Sort-Object | ForEach-Object { "$_=$($figures[$_].Count)" }) -join ' '
Write-Output "photos: $($rows.Count) | $groupSummary"
