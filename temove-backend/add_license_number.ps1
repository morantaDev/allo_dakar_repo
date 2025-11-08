# Script PowerShell pour ajouter la colonne license_number à la table drivers
# Usage: .\add_license_number.ps1

Write-Host "🔧 Ajout de la colonne 'license_number' à la table 'drivers'..." -ForegroundColor Yellow
Write-Host ""

# Vérifier que le venv est activé
if (-not (Test-Path "venv\Scripts\Activate.ps1")) {
    Write-Host "❌ Le venv n'existe pas. Créez-le d'abord avec: python -m venv venv" -ForegroundColor Red
    exit 1
}

# Activer le venv
Write-Host "🔌 Activation du venv..." -ForegroundColor Cyan
& "venv\Scripts\Activate.ps1"

# Exécuter le script Python
Write-Host "🚀 Exécution du script de migration..." -ForegroundColor Cyan
python scripts/add_license_number_column.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Migration réussie !" -ForegroundColor Green
    Write-Host "   Vous pouvez maintenant redémarrer le backend et tester l'inscription." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ Migration échouée. Vérifiez les erreurs ci-dessus." -ForegroundColor Red
    exit 1
}

