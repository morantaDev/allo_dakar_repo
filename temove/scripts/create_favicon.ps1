# Script PowerShell pour créer les favicons à partir du logo TeMove
# Nécessite ImageMagick ou utilise des outils Windows intégrés

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$logoPath = Join-Path $projectRoot "assets\icons\app_logo.png"
$webDir = Join-Path $projectRoot "web"
$faviconPngPath = Join-Path $webDir "favicon.png"
$faviconSvgPath = Join-Path $webDir "favicon.svg"

Write-Host "🎨 Création des favicons TeMove..." -ForegroundColor Cyan

# Vérifier que le logo existe
if (-not (Test-Path $logoPath)) {
    Write-Host "❌ Logo non trouvé : $logoPath" -ForegroundColor Red
    exit 1
}

# Vérifier si ImageMagick est disponible
$magickAvailable = $false
try {
    $magickVersion = & magick -version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $magickAvailable = $true
        Write-Host "✅ ImageMagick trouvé" -ForegroundColor Green
    }
} catch {
    $magickAvailable = $false
}

if ($magickAvailable) {
    # Utiliser ImageMagick pour redimensionner
    Write-Host "🔄 Redimensionnement du logo en favicon 32x32..." -ForegroundColor Yellow
    & magick $logoPath -resize 32x32 $faviconPngPath
    Write-Host "✅ Favicon PNG créé : $faviconPngPath" -ForegroundColor Green
} else {
    # Copier le logo directement (les navigateurs le redimensionneront)
    Write-Host "⚠️  ImageMagick non trouvé. Copie du logo original..." -ForegroundColor Yellow
    Write-Host "💡 Pour un meilleur résultat, installez ImageMagick ou redimensionnez manuellement l'image à 32x32 pixels" -ForegroundColor Yellow
    Copy-Item -Path $logoPath -Destination $faviconPngPath -Force
    Write-Host "✅ Logo copié vers : $faviconPngPath" -ForegroundColor Green
}

# Créer le favicon SVG
Write-Host "🔄 Création du favicon.svg..." -ForegroundColor Yellow
$svgContent = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
  <title>TeMove</title>
  <desc>TeMove - Votre trajet, notre hospitalité</desc>
  <image href="favicon.png" width="32" height="32" preserveAspectRatio="xMidYMid meet"/>
</svg>
"@
$svgContent | Out-File -FilePath $faviconSvgPath -Encoding UTF8 -NoNewline
Write-Host "✅ Favicon SVG créé : $faviconSvgPath" -ForegroundColor Green

Write-Host "`n✅ Favicons créés avec succès!" -ForegroundColor Green
Write-Host "   - PNG: $faviconPngPath" -ForegroundColor Gray
Write-Host "   - SVG: $faviconSvgPath" -ForegroundColor Gray
Write-Host "`n💡 Pour appliquer les changements, reconstruisez l'application Flutter web" -ForegroundColor Cyan

