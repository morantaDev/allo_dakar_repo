# Script PowerShell pour installer les dépendances de génération de rapports
# Usage: .\install_report_dependencies.ps1

Write-Host "📦 Installation des dépendances pour la génération de rapports..." -ForegroundColor Cyan

# Vérifier si l'environnement virtuel existe
if (-not (Test-Path "venv\Scripts\activate.ps1")) {
    Write-Host "❌ Environnement virtuel non trouvé dans venv\" -ForegroundColor Red
    Write-Host "   Créez un environnement virtuel avec: python -m venv venv" -ForegroundColor Yellow
    exit 1
}

# Activer l'environnement virtuel
Write-Host "🔧 Activation de l'environnement virtuel..." -ForegroundColor Cyan
. .\venv\Scripts\activate.ps1

# Vérifier que l'environnement est activé
if (-not $env:VIRTUAL_ENV) {
    Write-Host "❌ Impossible d'activer l'environnement virtuel" -ForegroundColor Red
    Write-Host "   Essayez d'exécuter: Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Environnement virtuel activé: $env:VIRTUAL_ENV" -ForegroundColor Green

# Installer les dépendances
Write-Host "📥 Installation de pandas, openpyxl et reportlab..." -ForegroundColor Cyan

try {
    pip install pandas openpyxl reportlab
    Write-Host "✅ Installation réussie!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de l'installation: $_" -ForegroundColor Red
    exit 1
}

# Vérifier l'installation
Write-Host "🔍 Vérification de l'installation..." -ForegroundColor Cyan

try {
    python -c "import pandas; import openpyxl; import reportlab; print('✅ Toutes les bibliothèques sont installées')"
    Write-Host "✅ Vérification réussie!" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de la vérification: $_" -ForegroundColor Red
    Write-Host "   Les packages peuvent ne pas être correctement installés" -ForegroundColor Yellow
    exit 1
}

Write-Host "`n🎉 Installation terminée avec succès!" -ForegroundColor Green
Write-Host "   Redémarrez le serveur Flask pour appliquer les changements" -ForegroundColor Yellow

