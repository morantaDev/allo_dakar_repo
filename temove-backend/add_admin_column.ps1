# Script PowerShell pour ajouter la colonne is_admin
# Utilisation: .\add_admin_column.ps1

Write-Host "🔧 Ajout de la colonne 'is_admin' à la table 'users'..." -ForegroundColor Cyan
Write-Host ""

# Activer l'environnement virtuel si il existe
if (Test-Path "venv\Scripts\Activate.ps1") {
    Write-Host "📦 Activation de l'environnement virtuel..." -ForegroundColor Yellow
    & "venv\Scripts\Activate.ps1"
}

# Exécuter le script Python
Write-Host "🚀 Exécution du script..." -ForegroundColor Yellow
python scripts/add_is_admin_column.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Migration réussie!" -ForegroundColor Green
    Write-Host "   Vous pouvez maintenant créer un utilisateur admin avec:" -ForegroundColor Yellow
    Write-Host "   python scripts/create_admin.py" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "❌ Erreur lors de la migration" -ForegroundColor Red
}

