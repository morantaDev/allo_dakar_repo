# 🚗 Créer un profil chauffeur via l'API REST

## 📋 Prérequis

- Backend Flask démarré et accessible sur `http://127.0.0.1:5000`
- Utilisateur existant et connecté (token JWT)

---

## 🎯 Méthode : Utiliser l'API REST `/drivers/register`

### Étape 1 : Se connecter pour obtenir le token

```powershell
# POST http://127.0.0.1:5000/api/v1/auth/login
$body = @{
    email = "morantadev@gmail.com"
    password = "votre_mot_de_passe"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/auth/login" -Method POST -Body $body -ContentType "application/json"
$token = $response.access_token
Write-Host "Token: $token"
```

### Étape 2 : Créer le profil chauffeur

```powershell
# POST http://127.0.0.1:5000/api/v1/drivers/register
$headers = @{
    Authorization = "Bearer $token"
    Content-Type = "application/json"
}

$driverData = @{
    license_number = "DL-12345"
    vehicle = @{
        make = "Toyota"
        model = "Corolla"
        plate = "ABC-123"
        color = "Blanc"
    }
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/drivers/register" -Method POST -Headers $headers -Body $driverData
$response | ConvertTo-Json
```

---

## 🔧 Utilisation avec curl (si disponible)

### Étape 1 : Se connecter

```bash
curl -X POST http://127.0.0.1:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"morantadev@gmail.com","password":"votre_mot_de_passe"}' \
  | jq -r '.access_token'
```

### Étape 2 : Créer le profil chauffeur

```bash
TOKEN="votre_token_ici"

curl -X POST http://127.0.0.1:5000/api/v1/drivers/register \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "license_number": "DL-12345",
    "vehicle": {
      "make": "Toyota",
      "model": "Corolla",
      "plate": "ABC-123",
      "color": "Blanc"
    }
  }'
```

---

## ✅ Vérification

### Vérifier que le profil a été créé :

```powershell
# GET http://127.0.0.1:5000/api/v1/drivers/me
$headers = @{
    Authorization = "Bearer $token"
}
$response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/drivers/me" -Method GET -Headers $headers
$response | ConvertTo-Json
```

---

## 📝 Script PowerShell complet

Créez un fichier `create_driver.ps1` :

```powershell
# Script pour créer un profil chauffeur
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

# 1. Se connecter
Write-Host "🔐 Connexion..." -ForegroundColor Yellow
$loginBody = @{
    email = $Email
    password = $Password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/auth/login" -Method POST -Body $loginBody -ContentType "application/json"
    $token = $loginResponse.access_token
    Write-Host "✅ Connexion réussie" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur de connexion: $_" -ForegroundColor Red
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
    $registerResponse = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/drivers/register" -Method POST -Headers $headers -Body $driverData
    Write-Host "✅ Profil chauffeur créé avec succès!" -ForegroundColor Green
    Write-Host "   Driver ID: $($registerResponse.driver_id)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ Erreur lors de la création: $_" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "   Détails: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
    exit 1
}

# 3. Vérifier le profil
Write-Host "🔍 Vérification du profil..." -ForegroundColor Yellow
try {
    $profileResponse = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/drivers/me" -Method GET -Headers $headers
    Write-Host "✅ Profil vérifié:" -ForegroundColor Green
    Write-Host "   - ID: $($profileResponse.driver.id)" -ForegroundColor Cyan
    Write-Host "   - Permis: $($profileResponse.driver.license_number)" -ForegroundColor Cyan
    Write-Host "   - Statut: $($profileResponse.driver.status)" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️  Erreur lors de la vérification: $_" -ForegroundColor Yellow
}
```

**Utilisation :**
```powershell
.\create_driver.ps1 -Email "morantadev@gmail.com" -Password "votre_mot_de_passe" -LicenseNumber "DL-12345"
```

---

## 🆘 Problèmes courants

### "already registered as driver"
L'utilisateur a déjà un profil chauffeur. Vérifiez avec `/drivers/me`.

### "user not found"
L'utilisateur n'existe pas. Créez d'abord un compte avec `/auth/register`.

### "Token JWT invalide"
Le token a expiré. Reconnectez-vous pour obtenir un nouveau token.

