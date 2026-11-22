<#
  Builds the logo, icons and social share image from images/src/logo.jpg.
  Run from the site folder:  .\tools\images.ps1
#>
param([string]$Root = (Get-Location).Path)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$ink  = [System.Drawing.ColorTranslator]::FromHtml("#0c0b0a")
$gold = [System.Drawing.ColorTranslator]::FromHtml("#e9b730")
$bone = [System.Drawing.ColorTranslator]::FromHtml("#f2ede3")
$PESO = [string][char]0x20B1; $DOT = " " + [char]0x00B7 + " "
# badge circle inside Logo.jpg (1254x1254): centre and radius in source pixels
$CX = 634; $CY = 617; $R = 446

$logo = [System.Drawing.Image]::FromFile((Join-Path $Root "images\src\logo.jpg"))

function New-Canvas([int]$w, [int]$h) {
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = "AntiAlias"; $g.InterpolationMode = "HighQualityBicubic"; $g.PixelOffsetMode = "HighQuality"; $g.TextRenderingHint = "AntiAliasGridFit"
  return @($bmp, $g)
}
# draws the round badge (dark disc + logo clipped to a circle) at x,y with diameter d
function Draw-Badge($g, [float]$x, [float]$y, [float]$d) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $path.AddEllipse($x, $y, $d, $d)
  $state = $g.Save()
  $g.SetClip($path)
  $srcRect = New-Object System.Drawing.RectangleF(($CX - $R), ($CY - $R), (2 * $R), (2 * $R))
  $dstRect = New-Object System.Drawing.RectangleF($x, $y, $d, $d)
  $g.DrawImage($logo, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
  $g.Restore($state)
}
function Save-Icon([int]$size, [string]$name, [bool]$square) {
  $c = New-Canvas $size $size; $bmp = $c[0]; $g = $c[1]
  if ($square) { $g.Clear([System.Drawing.Color]::FromArgb(255, 1, 4, 9)) } else { $g.Clear([System.Drawing.Color]::Transparent) }
  Draw-Badge $g 0 0 $size
  $bmp.Save((Join-Path $Root $name), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
}

New-Item -ItemType Directory -Force (Join-Path $Root "images") | Out-Null
Save-Icon 240 "images\logo.png" $false
Save-Icon 32 "favicon-32.png" $false
Save-Icon 48 "favicon-48.png" $false
Save-Icon 180 "apple-touch-icon.png" $true
Save-Icon 192 "icon-192.png" $true
Save-Icon 512 "icon-512.png" $true

# Open Graph share image 1200x630
$c = New-Canvas 1200 630; $bmp = $c[0]; $g = $c[1]
$g.Clear($ink)
$g.FillRectangle((New-Object System.Drawing.SolidBrush($gold)), 0, 600, 1200, 30)
Draw-Badge $g 60 105 400
function Draw-Left($text, $font, $size, $color, $x, $y) {
  $f = New-Object System.Drawing.Font($font, [float]$size, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $g.DrawString($text, $f, (New-Object System.Drawing.SolidBrush($color)), [float]$x, [float]$y)
}
Draw-Left "ALL GOODS COLLECTION" "Impact" 64 ([System.Drawing.Color]::White) 520 120
Draw-Left "Streetwear finds in Davao City" "Arial" 38 $bone 524 205
Draw-Left ("Caps", "Tees", "Outerwear", "Bags" -join $DOT) "Arial" 34 $bone 524 260
Draw-Left "ANY 3 FOR ${PESO}999" "Impact" 92 $gold 520 330
Draw-Left ("Order on Messenger" + $DOT + "GCash accepted") "Arial" 30 $bone 524 470
$bmp.Save((Join-Path $Root "og-image.png"), [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
$logo.Dispose()
Write-Output "logo, icons and og-image written"
