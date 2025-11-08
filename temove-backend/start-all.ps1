# Script PowerShell pour démarrer Backend et Frontend
# Utilisation : .\start-all.ps1

Write-Host "🚀 Démarrage de Backend + Frontend Allo Dakar" -ForegroundColor Cyan
Write-Host ""

# Chemins des projets (ajustez selon votre configuration)
# Backend : chemin actuel (dossier où se trouve ce script)
$backendPath = $PSScriptRoot
# Frontend : ajustez le chemin selon votre configuration
$frontendPath = "C:\allo-dakar\allo-dakar-frontend"
# Si le frontend est dans le même répertoire parent :
# $frontendPath = Join-Path (Split-Path $PSScriptRoot -Parent) "allo-dakar-frontend"

# Vérifier que les dossiers existent
if (-not (Test-Path $backendPath)) {
    Write-Host "❌ Erreur : Dossier backend introuvable : $backendPath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $frontendPath)) {
    Write-Host "❌ Erreur : Dossier frontend introuvable : $frontendPath" -ForegroundColor Red
    exit 1
}

# Démarrer le Backend
Write-Host "📦 Démarrage du Backend Flask..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$backendPath'; .\venv\Scripts\activate; Write-Host '🚀 Backend Flask démarré sur http://0.0.0.0:5000 (toutes les interfaces)' -ForegroundColor Green; python run.py"

# Attendre 3 secondes pour que le backend démarre
Write-Host "⏳ Attente du démarrage du backend..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# Démarrer le Frontend
Write-Host "📱 Démarrage du Frontend Flutter..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$frontendPath'; Write-Host '🚀 Frontend Flutter en cours de démarrage...' -ForegroundColor Green; flutter run"

Write-Host ""
Write-Host "✅ Backend et Frontend lancés dans des fenêtres séparées!" -ForegroundColor Green
Write-Host ""
Write-Host "📍 URLs importantes :" -ForegroundColor Cyan
Write-Host "   - Backend API : http://0.0.0.0:5000/api/v1 (toutes les interfaces)" -ForegroundColor White
Write-Host "   - Backend Health : http://0.0.0.0:5000/health" -ForegroundColor White
Write-Host "   - Accès local : http://localhost:5000/api/v1" -ForegroundColor White
Write-Host ""
Write-Host "🛑 Pour arrêter : Fermez les fenêtres PowerShell ou appuyez sur Ctrl+C" -ForegroundColor Gray
Write-Host ""

# Garder la fenêtre ouverte
Read-Host "Appuyez sur Entrée pour fermer cette fenêtre"




