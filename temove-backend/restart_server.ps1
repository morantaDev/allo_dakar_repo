# Script PowerShell pour redémarrer le serveur Flask

Write-Host "🔄 Redémarrage du serveur Flask TeMove..." -ForegroundColor Cyan
Write-Host ""

# Trouver et arrêter le processus Flask existant sur le port 5000
$processes = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique

if ($processes) {
    foreach ($pid in $processes) {
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -eq "python") {
            Write-Host "⏹️  Arrêt du processus Flask (PID: $pid)..." -ForegroundColor Yellow
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
    }
} else {
    Write-Host "ℹ️  Aucun serveur Flask trouvé sur le port 5000" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🚀 Démarrage du serveur Flask..." -ForegroundColor Green
Write-Host ""

# Activer l'environnement virtuel si nécessaire
if (Test-Path "venv\Scripts\Activate.ps1") {
    Write-Host "📦 Activation de l'environnement virtuel..." -ForegroundColor Cyan
    & .\venv\Scripts\Activate.ps1
}

# Démarrer le serveur
Write-Host "🔌 Démarrage du serveur sur http://0.0.0.0:5000" -ForegroundColor Green
Write-Host "📝 Appuyez sur Ctrl+C pour arrêter le serveur" -ForegroundColor Gray
Write-Host ""

python run.py

