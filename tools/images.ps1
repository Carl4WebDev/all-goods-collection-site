param([string]$Root)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$ink  = [System.Drawing.ColorTranslator]::FromHtml("#0c0b0a")
$gold = [System.Drawing.ColorTranslator]::FromHtml("#e9b730")
$bone = [System.Drawing.ColorTranslator]::FromHtml("#f2ede3")
$PESO = [string][char]0x20B1; $DOT = " " + [char]0x00B7 + " "

function New-Canvas([int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = "AntiAlias"; $g.TextRenderingHint = "AntiAliasGridFit"
  return @($bmp, $g)
}
function Draw-Centered($g, [string]$text, [string]$font, [float]$size, $color, [float]$cx, [float]$cy) {
  $f = New-Object System.Drawing.Font($font, $size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $sf = New-Object System.Drawing.StringFormat; $sf.Alignment = "Center"; $sf.LineAlignment = "Center"
  $g.DrawString($text, $f, (New-Object System.Drawing.SolidBrush($color)), $cx, $cy, $sf)
}
function Draw-Logo($g, [float]$x, [float]$y, [float]$d) {
  $g.FillEllipse((New-Object System.Drawing.SolidBrush($ink)), $x, $y, $d, $d)
  $pen = New-Object System.Drawing.Pen($gold, [float]($d * 0.025))
  $in = $d * 0.06
  $g.DrawEllipse($pen, $x + $in, $y + $in, $d - 2 * $in, $d - 2 * $in)
  $cx = $x + $d / 2; $cy = $y + $d / 2
  $state = $g.Save()
  $g.TranslateTransform($cx, $cy); $g.RotateTransform(-8)
  Draw-Centered $g "ALL" "Impact" ($d * 0.27) ([System.Drawing.Color]::White) 0 (-$d * 0.13)
  Draw-Centered $g "GOOD$" "Impact" ($d * 0.27) $gold 0 ($d * 0.15)
  $g.Restore($state)
}
function Save-Icon([int]$size, [string]$name, [bool]$square) {
  $c = New-Canvas $size $size; $bmp = $c[0]; $g = $c[1]
  if ($square) { $g.Clear($ink) } else { $g.Clear([System.Drawing.Color]::Transparent) }
  Draw-Logo $g 0 0 $size
  $bmp.Save((Join-Path $Root $name), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}

Save-Icon 32 "favicon-32.png" $false
Save-Icon 180 "apple-touch-icon.png" $true
Save-Icon 192 "icon-192.png" $true
Save-Icon 512 "icon-512.png" $true

# Open Graph share image 1200x630
$c = New-Canvas 1200 630; $bmp = $c[0]; $g = $c[1]
$g.Clear($ink)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($gold)), 0, 600, 1200, 30)
Draw-Logo $g 70 115 400
$left = New-Object System.Drawing.StringFormat
function Draw-Left($text, $font, $size, $color, $x, $y) {
  $f = New-Object System.Drawing.Font($font, [float]$size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $g.DrawString($text, $f, (New-Object System.Drawing.SolidBrush($color)), [float]$x, [float]$y)
}
Draw-Left "ALL GOODS COLLECTION" "Impact" 64 ([System.Drawing.Color]::White) 520 120
Draw-Left "Streetwear finds in Davao City" "Arial" 38 $bone 524 205
Draw-Left ("Caps","Tees","Outerwear","Bags" -join $DOT) "Arial" 34 $bone 524 260
Draw-Left "ANY 3 FOR ${PESO}999" "Impact" 92 $gold 520 330
Draw-Left ("Order on Messenger" + $DOT + "GCash accepted") "Arial" 30 $bone 524 470
$bmp.Save((Join-Path $Root "og-image.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
Write-Output "images written"
