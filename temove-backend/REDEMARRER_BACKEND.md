# 🔄 Redémarrer le backend pour activer la route /register-driver

## ⚠️ Important

Le backend doit être **redémarré** pour que la nouvelle route `/auth/register-driver` soit disponible.

## 📋 Étapes

1. **Arrêter le serveur Flask** (si en cours d'exécution) :
   - Dans le terminal où le serveur tourne, appuyer sur `Ctrl+C`

2. **Redémarrer le serveur** :
   ```powershell
   cd C:\allo_dakar_repo\temove-backend
   python app.py
   ```

3. **Vérifier que le serveur démarre correctement** :
   - Vous devriez voir des messages comme :
     ```
     ✅ Toutes les tables ont été créées/vérifiées
     🔑 [JWT_CONFIG] JWT_SECRET_KEY configuré
     * Running on http://127.0.0.1:5000
     ```

4. **Vérifier que la route est disponible** :
   - Ouvrir un navigateur ou utiliser curl :
     ```
     GET http://127.0.0.1:5000/health
     ```
   - Devrait retourner : `{"status": "ok", "message": "TeMove API is running"}`

## ✅ Modification effectuée

Le fichier `app.py` a été modifié pour utiliser `app.routes.auth_routes` au lieu de `routes.auth`, ce qui permet d'utiliser la route `/auth/register-driver` que nous avons créée.

## 🧪 Test de la route

Une fois le backend redémarré, vous pouvez tester la route d'inscription :

```powershell
$body = @{
    email = "test@example.com"
    password = "password123"
    full_name = "Test User"
    phone = "+221 77 123 45 67"
    license_number = "DL-12345"
    vehicle = @{
        make = "Toyota"
        model = "Corolla"
        plate = "ABC-123"
        color = "Blanc"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/auth/register-driver" -Method POST -Body $body -ContentType "application/json"
```

Si la route fonctionne, vous devriez recevoir une réponse avec `access_token` et les informations du chauffeur créé.

