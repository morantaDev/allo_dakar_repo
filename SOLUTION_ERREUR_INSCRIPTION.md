# 🔧 Solution : Erreur "Failed to fetch" lors de l'inscription

## 📋 Problème

L'erreur `❌ [DRIVER_REGISTER] Exception: ClientException: Failed to fetch, uri=http://127.0.0.1:5000/api/v1/auth/register-driver` indique que :

1. **Le backend n'est pas démarré** OU
2. **La route `/auth/register-driver` n'est pas disponible** (backend non redémarré après les modifications)

## ✅ Solution

### Étape 1 : Vérifier que le backend est démarré

Ouvrir un terminal et vérifier si le backend tourne :

```powershell
# Vérifier si le port 5000 est utilisé
netstat -ano | findstr :5000
```

Si aucun processus n'utilise le port 5000, le backend n'est pas démarré.

### Étape 2 : Redémarrer le backend

**IMPORTANT** : Le backend doit être redémarré pour que la nouvelle route soit disponible.

1. **Arrêter le serveur** (si en cours) :
   - Dans le terminal où le serveur tourne, appuyer sur `Ctrl+C`

2. **Démarrer le serveur** :
   ```powershell
   cd C:\allo_dakar_repo\temove-backend
   python app.py
   ```

3. **Vérifier que le serveur démarre correctement** :
   Vous devriez voir :
   ```
   ✅ Toutes les tables ont été créées/vérifiées
   🔑 [JWT_CONFIG] JWT_SECRET_KEY configuré
   * Running on http://0.0.0.0:5000
   ```

### Étape 3 : Vérifier que la route est disponible

Ouvrir un navigateur ou utiliser PowerShell :

```powershell
# Test de santé
Invoke-RestMethod -Uri "http://127.0.0.1:5000/health"
```

Devrait retourner : `{"status": "ok", "message": "TeMove API is running"}`

### Étape 4 : Tester la route d'inscription

```powershell
$body = @{
    email = "test.driver@example.com"
    password = "password123"
    full_name = "Test Driver"
    phone = "+221 77 123 45 67"
    license_number = "DL-12345"
    vehicle = @{
        make = "Toyota"
        model = "Corolla"
        plate = "ABC-123"
        color = "Blanc"
    }
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/auth/register-driver" -Method POST -Body $body -ContentType "application/json"
    Write-Host "✅ Inscription réussie!" -ForegroundColor Green
    Write-Host "Token: $($response.access_token.Substring(0, 50))..." -ForegroundColor Cyan
} catch {
    Write-Host "❌ Erreur: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "Détails: $($_.ErrorDetails.Message)" -ForegroundColor Yellow
    }
}
```

### Étape 5 : Tester depuis Flutter

Une fois le backend redémarré et la route testée, essayer à nouveau l'inscription depuis TéMove Pro.

---

## 🔍 Vérifications supplémentaires

### Vérifier que la route est bien enregistrée

Dans `temove-backend/app.py`, vérifier que l'import est correct :

```python
# Ligne 308 doit être :
from app.routes.auth_routes import auth_bp

# Et non :
from routes.auth import auth_bp
```

### Vérifier les logs du backend

Si le backend est démarré, vous devriez voir dans les logs :

```
[REGISTER_DRIVER] Création du compte utilisateur pour: email@example.com
[REGISTER_DRIVER] Création du profil chauffeur pour user_id: X
[REGISTER_DRIVER] Création du véhicule pour driver_id: Y
[REGISTER_DRIVER] Inscription réussie pour: email@example.com
```

### Vérifier CORS

Si le backend est démarré mais que vous avez toujours l'erreur "Failed to fetch", vérifier la configuration CORS dans `app.py`. Elle devrait autoriser toutes les origines en développement.

---

## ✅ Après correction

Une fois le backend redémarré, l'inscription devrait fonctionner :
1. Remplir le formulaire dans TéMove Pro
2. Cliquer sur "S'inscrire"
3. Voir le message "Inscription réussie ! Bienvenue sur TéMove Pro."
4. Être redirigé automatiquement vers le dashboard

---

## 📝 Note

**Le backend DOIT être redémarré** après chaque modification de routes pour que les changements prennent effet. C'est une limitation de Flask en mode développement (même avec `debug=True`, les nouvelles routes nécessitent un redémarrage).

