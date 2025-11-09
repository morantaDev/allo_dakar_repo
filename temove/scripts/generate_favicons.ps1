# Script PowerShell pour générer les favicons PNG à partir du SVG
# Nécessite ImageMagick (https://imagemagick.org/)

$ErrorActionPreference = "Stop"

Write-Host "🎨 Génération des favicons TéMove..." -ForegroundColor Cyan

# Chemins
$svgPath = "web\favicon.svg"
$outputDir = "web"

# Vérifier si ImageMagick est installé
$magick = Get-Command magick -ErrorAction SilentlyContinue
if (-not $magick) {
    Write-Host "❌ ImageMagick n'est pas installé." -ForegroundColor Red
    Write-Host "   Installez ImageMagick depuis https://imagemagick.org/" -ForegroundColor Yellow
    Write-Host "   Ou utilisez un convertisseur en ligne pour générer les PNG" -ForegroundColor Yellow
    exit 1
}

# Vérifier si le fichier SVG existe
if (-not (Test-Path $svgPath)) {
    Write-Host "❌ Le fichier $svgPath n'existe pas." -ForegroundColor Red
    exit 1
}

# Tailles de favicon
$sizes = @(16, 32, 48, 192, 512)

Write-Host "📐 Génération des favicons aux tailles : $($sizes -join ', ')px" -ForegroundColor Green

foreach ($size in $sizes) {
    $outputFile = "$outputDir\favicon-$size.png"
    Write-Host "   Génération de $outputFile ($size x $size)..." -ForegroundColor Gray
    
    try {
        & magick convert -background none -resize "${size}x${size}" $svgPath $outputFile
        if ($LASTEXITCODE -eq 0) {
            Write-Host "   ✅ $outputFile créé" -ForegroundColor Green
        } else {
            Write-Host "   ❌ Erreur lors de la création de $outputFile" -ForegroundColor Red
        }
    } catch {
        Write-Host "   ❌ Erreur : $_" -ForegroundColor Red
    }
}

# Générer également favicon.png (32x32 par défaut)
Write-Host "   Génération de favicon.png (32x32)..." -ForegroundColor Gray
& magick convert -background none -resize "32x32" $svgPath "$outputDir\favicon.png"

Write-Host "`n✅ Génération des favicons terminée !" -ForegroundColor Green
Write-Host "   Les fichiers sont dans le répertoire : $outputDir" -ForegroundColor Cyan

