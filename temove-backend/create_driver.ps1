# Script PowerShell pour créer un profil chauffeur via l'API REST
param(
    [Parameter(Mandatory=$true)]
    [string]$Email,
    
    [Parameter(Mandatory=$true)]
    [string]$Password,
    
    [Parameter(Mandatory=$true)]
    [string]$LicenseNumber,
    
    [string]$CarMake = "Toyota",
    [string]$CarModel = "Corolla",
    [string]$CarPlate = "ABC-123",
    [string]$CarColor = "Blanc"
)

$baseUrl = "http://127.0.0.1:5000/api/v1"

# 1. Se connecter
Write-Host "🔐 Connexion pour: $Email" -ForegroundColor Yellow
$loginBody = @{
    email = $Email
    password = $Password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.access_token
    Write-Host "✅ Connexion réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur de connexion: $_" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "   Détails: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
    exit 1
}

# 2. Créer le profil chauffeur
Write-Host "🚗 Création du profil chauffeur..." -ForegroundColor Yellow
$headers = @{
    Authorization = "Bearer $token"
    Content-Type = "application/json"
}

$driverData = @{
    license_number = $LicenseNumber
    vehicle = @{
        make = $CarMake
        model = $CarModel
        plate = $CarPlate
        color = $CarColor
    }
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$baseUrl/drivers/register" -Method POST -Headers $headers -Body $driverData
    Write-Host "✅ Profil chauffeur créé avec succès!" -ForegroundColor Green
    Write-Host "   Driver ID: $($registerResponse.driver_id)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Erreur lors de la création: $_" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   Message: $($errorDetails.msg)" -ForegroundColor Yellow
    }
    exit 1
}

# 3. Vérifier le profil
Write-Host "🔍 Vérification du profil..." -ForegroundColor Yellow
try {
    $profileResponse = Invoke-RestMethod -Uri "$baseUrl/drivers/me" -Method GET -Headers $headers
    Write-Host "✅ Profil vérifié:" -ForegroundColor Green
    Write-Host "   - ID: $($profileResponse.driver.id)" -ForegroundColor Cyan
    Write-Host "   - Permis: $($profileResponse.driver.license_number)" -ForegroundColor Cyan
    Write-Host "   - Statut: $($profileResponse.driver.status)" -ForegroundColor Cyan
    if ($profileResponse.driver.vehicle) {
        Write-Host "   - Véhicule: $($profileResponse.driver.vehicle.make) $($profileResponse.driver.vehicle.model) ($($profileResponse.driver.vehicle.plate))" -ForegroundColor Cyan
    }
} catch {
    Write-Host "⚠️  Erreur lors de la vérification: $_" -ForegroundColor Yellow
}

