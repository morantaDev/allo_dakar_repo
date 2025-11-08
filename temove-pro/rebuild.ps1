# Script PowerShell pour reconstruire complètement l'application Flutter
# Utilisation: .\rebuild.ps1

Write-Host "🧹 Nettoyage du cache Flutter..." -ForegroundColor Yellow
flutter clean

Write-Host "📦 Téléchargement des dépendances..." -ForegroundColor Yellow
flutter pub get

Write-Host "🏗️  Reconstruction de l'application pour le web..." -ForegroundColor Yellow
flutter build web --release

Write-Host "✅ Reconstruction terminée!" -ForegroundColor Green
Write-Host "Pour lancer l'application: flutter run -d chrome" -ForegroundColor Cyan

