# Script de test pour l'API Allo Dakar
# Usage: .\test_api.ps1

$API_BASE = "http://localhost:5000/api/v1"

Write-Host "🧪 Test de l'API Allo Dakar" -ForegroundColor Cyan
Write-Host ""

# Test 1: Health Check
Write-Host "1️⃣ Test Health Check..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
    Write-Host "✅ Backend OK: $($health.message)" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend non accessible" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Inscription
Write-Host "2️⃣ Test Inscription..." -ForegroundColor Yellow
$email = "test_$(Get-Random)@example.com"
$password = "Test123!"
$fullName = "Test User"

$registerBody = @{
    email = $email
    password = $password
    full_name = $fullName
    phone = "+221701234567"
} | ConvertTo-Json

try {
    $registerResponse = Invoke-RestMethod -Uri "$API_BASE/auth/register" -Method Post -Body $registerBody -ContentType "application/json"
    Write-Host "✅ $($registerResponse.message)" -ForegroundColor Green
    Write-Host "   Email: $email" -ForegroundColor Gray
    Write-Host "   User ID: $($registerResponse.user.id)" -ForegroundColor Gray
    Write-Host "   Token reçu: $($registerResponse.access_token.Substring(0, 20))..." -ForegroundColor Gray
    
    $accessToken = $registerResponse.access_token
    $userId = $registerResponse.user.id
} catch {
    Write-Host "❌ Erreur d'inscription:" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   $($errorObj.error)" -ForegroundColor Red
    } else {
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""

# Test 3: Connexion
Write-Host "3️⃣ Test Connexion..." -ForegroundColor Yellow
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$API_BASE/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "✅ $($loginResponse.message)" -ForegroundColor Green
    Write-Host "   User: $($loginResponse.user.full_name)" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur de connexion:" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   $($errorObj.error)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 4: Obtenir les infos utilisateur (avec token)
Write-Host "4️⃣ Test Get Current User..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
    }
    $userResponse = Invoke-RestMethod -Uri "$API_BASE/auth/me" -Method Get -Headers $headers
    Write-Host "✅ Utilisateur récupéré:" -ForegroundColor Green
    Write-Host "   Nom: $($userResponse.user.full_name)" -ForegroundColor Gray
    Write-Host "   Email: $($userResponse.user.email)" -ForegroundColor Gray
    Write-Host "   Crédit: $($userResponse.user.credit_balance) XOF" -ForegroundColor Gray
} catch {
    Write-Host "❌ Erreur:" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "   $($errorObj.error)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ Tous les tests sont terminés!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Informations de connexion:" -ForegroundColor Cyan
Write-Host "   Email: $email" -ForegroundColor White
Write-Host "   Password: $password" -ForegroundColor White
Write-Host "   Token: $($accessToken.Substring(0, 30))..." -ForegroundColor White

