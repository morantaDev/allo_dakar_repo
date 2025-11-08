# 🚗 Solution : Créer un profil chauffeur

## 🔴 Problème actuel

L'utilisateur `morantadev@gmail.com` peut se connecter mais n'a pas encore de profil chauffeur, ce qui cause l'erreur **403 "not a driver"** lors de l'accès aux endpoints `/drivers/me` et `/drivers/rides`.

---

## ✅ Solution : Utiliser le script PowerShell

### Méthode 1 : Script PowerShell (RECOMMANDÉ)

1. **Ouvrez un terminal PowerShell** dans le dossier `temove-backend`

2. **Exécutez le script** :

```powershell
cd C:\allo_dakar_repo\temove-backend
.\create_driver.ps1 -Email "morantadev@gmail.com" -Password "VOTRE_MOT_DE_PASSE" -LicenseNumber "DL-12345"
```

Le script va :
- ✅ Se connecter avec vos identifiants
- ✅ Créer le profil chauffeur
- ✅ Vérifier que le profil a été créé

---

### Méthode 2 : Utiliser PowerShell manuellement

Si vous préférez le faire manuellement :

```powershell
# 1. Se connecter
$body = @{
    email = "morantadev@gmail.com"
    password = "VOTRE_MOT_DE_PASSE"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/auth/login" -Method POST -Body $body -ContentType "application/json"
$token = $response.access_token

# 2. Créer le profil chauffeur
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

Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/drivers/register" -Method POST -Headers $headers -Body $driverData
```

---

## ✅ Après avoir créé le profil

1. **Redémarrez l'application Flutter** (hot restart avec `R`)
2. **Reconnectez-vous** si nécessaire
3. **Vérifiez** que les écrans fonctionnent :
   - ✅ Profil chauffeur affiché
   - ✅ Courses disponibles affichées
   - ✅ Plus d'erreur "not a driver"

---

## 🆘 Si le script ne fonctionne pas

### Vérifier que le backend est démarré :

```powershell
# Tester l'endpoint de santé
Invoke-WebRequest -Uri "http://127.0.0.1:5000/health"
```

### Vérifier les logs du backend

Le backend doit être démarré et accessible. Si ce n'est pas le cas :

```powershell
cd C:\allo_dakar_repo\temove-backend
.\venv\Scripts\activate
python app.py
```

---

## 📝 Notes

- Le script utilise l'API REST, donc le backend doit être démarré
- Les valeurs par défaut du véhicule sont : Toyota Corolla ABC-123 Blanc
- Vous pouvez personnaliser les valeurs du véhicule dans le script
- Le numéro de permis est requis (ex: "DL-12345")

