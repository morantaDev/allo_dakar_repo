# Script PowerShell pour generer les favicons et icones depuis le logo TeMove
# Ce script copie le logo SVG/PNG depuis les assets et genere tous les fichiers necessaires

$ErrorActionPreference = "Stop"

Write-Host "Generation des favicons et icones TeMove depuis les assets..." -ForegroundColor Cyan

# Chemins des assets
$logoPath = "assets\logos\temove_logo.svg"
$logoPngPath = "assets\icons\app_logo.png"
$webDir = "web"
$iconsDir = "$webDir\icons"

# Verifier si les repertoires existent
if (-not (Test-Path $webDir)) {
    Write-Host "Le repertoire $webDir n'existe pas." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $iconsDir)) {
    New-Item -ItemType Directory -Path $iconsDir -Force | Out-Null
    Write-Host "Repertoire $iconsDir cree" -ForegroundColor Green
}

# 1. Copier le logo SVG vers favicon.svg
if (Test-Path $logoPath) {
    Copy-Item $logoPath "$webDir\favicon.svg" -Force
    Write-Host "favicon.svg copie depuis $logoPath" -ForegroundColor Green
} else {
    Write-Host "Le fichier $logoPath n'existe pas. Ignore." -ForegroundColor Yellow
}

# 2. Verifier si ImageMagick est disponible pour generer les PNG
$magick = Get-Command magick -ErrorAction SilentlyContinue

if ($magick) {
    Write-Host "`nImageMagick detecte - Generation des icones PNG..." -ForegroundColor Green
    
    # Source SVG ou PNG
    $sourceFile = if (Test-Path $logoPath) { $logoPath } elseif (Test-Path $logoPngPath) { $logoPngPath } else { $null }
    
    if ($sourceFile) {
        # Generer favicon.png (32x32)
        Write-Host "   Generation de favicon.png (32x32)..." -ForegroundColor Gray
        & magick convert -background none -resize "32x32" $sourceFile "$webDir\favicon.png"
        
        # Generer les icones PWA
        Write-Host "   Generation de Icon-192.png (192x192)..." -ForegroundColor Gray
        & magick convert -background none -resize "192x192" $sourceFile "$iconsDir\Icon-192.png"
        
        Write-Host "   Generation de Icon-512.png (512x512)..." -ForegroundColor Gray
        & magick convert -background none -resize "512x512" $sourceFile "$iconsDir\Icon-512.png"
        
        # Generer les icones maskable (avec padding pour maskable)
        Write-Host "   Generation de Icon-maskable-192.png (192x192 avec padding)..." -ForegroundColor Gray
        & magick convert -background none -resize "144x144" $sourceFile -gravity center -extent "192x192" "$iconsDir\Icon-maskable-192.png"
        
        Write-Host "   Generation de Icon-maskable-512.png (512x512 avec padding)..." -ForegroundColor Gray
        & magick convert -background none -resize "384x384" $sourceFile -gravity center -extent "512x512" "$iconsDir\Icon-maskable-512.png"
        
        Write-Host "`nToutes les icones ont ete generees avec succes !" -ForegroundColor Green
    } else {
        Write-Host "Aucun fichier source (SVG ou PNG) trouve dans les assets." -ForegroundColor Red
        Write-Host "   Verifiez que $logoPath ou $logoPngPath existe." -ForegroundColor Yellow
    }
} else {
    Write-Host "`nImageMagick n'est pas installe." -ForegroundColor Yellow
    Write-Host "   Pour generer les icones PNG automatiquement :" -ForegroundColor Yellow
    Write-Host "   1. Installez ImageMagick depuis https://imagemagick.org/" -ForegroundColor Yellow
    Write-Host "   2. Relancez ce script" -ForegroundColor Yellow
    Write-Host "`n   Ou manuellement :" -ForegroundColor Yellow
    Write-Host "   1. Copiez $logoPngPath vers $webDir\favicon.png" -ForegroundColor Yellow
    Write-Host "   2. Redimensionnez aux tailles necessaires (192x192, 512x512)" -ForegroundColor Yellow
    Write-Host "   3. Placez-les dans $iconsDir\" -ForegroundColor Yellow
    
    # Tentative de copie directe du PNG si disponible
    if (Test-Path $logoPngPath) {
        Copy-Item $logoPngPath "$webDir\favicon.png" -Force
        Write-Host "`nfavicon.png copie depuis $logoPngPath (taille originale)" -ForegroundColor Green
        Write-Host "   Pensez a redimensionner manuellement aux tailles requises" -ForegroundColor Yellow
    }
}

Write-Host "`nFichiers generes :" -ForegroundColor Cyan
Write-Host "   - $webDir\favicon.svg" -ForegroundColor Gray
Write-Host "   - $webDir\favicon.png" -ForegroundColor Gray
Write-Host "   - $iconsDir\Icon-192.png" -ForegroundColor Gray
Write-Host "   - $iconsDir\Icon-512.png" -ForegroundColor Gray
Write-Host "   - $iconsDir\Icon-maskable-192.png" -ForegroundColor Gray
Write-Host "   - $iconsDir\Icon-maskable-512.png" -ForegroundColor Gray

Write-Host "`nGeneration terminee !" -ForegroundColor Green
Write-Host "   Videz le cache de votre navigateur pour voir les nouveaux favicons." -ForegroundColor Cyan
