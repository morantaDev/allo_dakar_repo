# Script PowerShell pour démarrer le backend Flask TéMove
# Utilisation: .\start_backend.ps1

Write-Host "🚀 Démarrage du Backend Flask TéMove..." -ForegroundColor Cyan

# Aller dans le dossier backend
$backendPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $backendPath

# Vérifier si l'environnement virtuel existe
if (-not (Test-Path "venv\Scripts\activate")) {
    Write-Host "❌ Environnement virtuel non trouvé!" -ForegroundColor Red
    Write-Host "💡 Créez un environnement virtuel avec: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# Activer l'environnement virtuel
Write-Host "📦 Activation de l'environnement virtuel..." -ForegroundColor Yellow
& "venv\Scripts\activate"

# Vérifier si les dépendances sont installées
Write-Host "🔍 Vérification des dépendances..." -ForegroundColor Yellow
$flaskInstalled = python -c "import flask" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️  Flask n'est pas installé. Installation des dépendances..." -ForegroundColor Yellow
    pip install -r requirements.txt
}

# Vérifier si le port 5000 est disponible
Write-Host "🔍 Vérification du port 5000..." -ForegroundColor Yellow
$portInUse = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "⚠️  Le port 5000 est déjà utilisé!" -ForegroundColor Yellow
    Write-Host "💡 Arrêtez le processus ou utilisez un autre port" -ForegroundColor Yellow
    $response = Read-Host "Voulez-vous continuer quand même? (o/n)"
    if ($response -ne "o") {
        exit 1
    }
}

# Démarrer le serveur
Write-Host "🚀 Démarrage du serveur Flask..." -ForegroundColor Green
Write-Host "📍 URL: http://127.0.0.1:5000" -ForegroundColor Cyan
Write-Host "💚 Health: http://127.0.0.1:5000/health" -ForegroundColor Cyan
Write-Host "🔗 API: http://127.0.0.1:5000/api/v1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur" -ForegroundColor Gray
Write-Host ""

python app.py

