# 🚗 Créer un profil chauffeur pour un utilisateur

Ce guide explique comment créer un profil chauffeur pour un utilisateur existant dans la base de données.

## 📋 Prérequis

- Backend Flask démarré et accessible
- Utilisateur existant dans la base de données
- Environnement virtuel activé

---

## 🎯 Méthode 1 : Utiliser le script Python (RECOMMANDÉ)

### Étape 1 : Vérifier que l'utilisateur existe

```powershell
cd C:\allo_dakar_repo\temove-backend
.\venv\Scripts\activate
python -c "from app import create_app; from extensions import db; from models import User; app = create_app(); ctx = app.app_context(); ctx.push(); users = User.query.all(); print('\n'.join([f'{u.id}: {u.email} ({u.full_name})' for u in users]))"
```

### Étape 2 : Créer le profil chauffeur

```powershell
python scripts/create_driver_profile.py <email> <license_number> [car_make] [car_model] [car_plate] [car_color]
```

**Exemple :**
```powershell
# Avec valeurs par défaut
python scripts/create_driver_profile.py morantadev@gmail.com DL-12345

# Avec valeurs personnalisées
python scripts/create_driver_profile.py morantadev@gmail.com DL-12345 Toyota Corolla ABC-123 Blanc
```

### Paramètres :

- `email` : Email de l'utilisateur (requis)
- `license_number` : Numéro de permis de conduire (requis)
- `car_make` : Marque du véhicule (optionnel, défaut: Toyota)
- `car_model` : Modèle du véhicule (optionnel, défaut: Corolla)
- `car_plate` : Plaque d'immatriculation (optionnel, défaut: ABC-123)
- `car_color` : Couleur du véhicule (optionnel, défaut: Blanc)

---

## 🎯 Méthode 2 : Utiliser l'API REST

### Étape 1 : Se connecter pour obtenir un token JWT

```powershell
# POST http://127.0.0.1:5000/api/v1/auth/login
$body = @{
    email = "morantadev@gmail.com"
    password = "votre_mot_de_passe"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/auth/login" -Method POST -Body $body -ContentType "application/json"
$token = $response.access_token
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
```

---

## 🎯 Méthode 3 : Utiliser Python directement

```python
from app import create_app
from extensions import db
from models import User, Driver, Vehicle

app = create_app()

with app.app_context():
    # Trouver l'utilisateur
    user = User.query.filter_by(email="morantadev@gmail.com").first()
    
    if not user:
        print("Utilisateur non trouvé!")
        exit(1)
    
    # Vérifier si déjà chauffeur
    existing_driver = Driver.query.filter_by(user_id=user.id).first()
    if existing_driver:
        print(f"Déjà chauffeur! ID: {existing_driver.id}")
        exit(0)
    
    # Créer le profil chauffeur
    driver = Driver(
        user_id=user.id,
        license_number="DL-12345",
        status='offline'
    )
    db.session.add(driver)
    db.session.flush()
    
    # Créer le véhicule
    vehicle = Vehicle(
        driver_id=driver.id,
        make="Toyota",
        model="Corolla",
        plate="ABC-123",
        color="Blanc"
    )
    db.session.add(vehicle)
    db.session.flush()
    
    driver.vehicle_id = vehicle.id
    user.role = 'driver'
    
    db.session.commit()
    print(f"✅ Profil chauffeur créé! ID: {driver.id}")
```

---

## ✅ Vérification

### Vérifier que le profil a été créé :

```powershell
# Dans PowerShell
$headers = @{
    Authorization = "Bearer $token"
}
$response = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/v1/drivers/me" -Method GET -Headers $headers
$response | ConvertTo-Json
```

### Ou via Python :

```python
from app import create_app
from extensions import db
from models import User, Driver

app = create_app()

with app.app_context():
    user = User.query.filter_by(email="morantadev@gmail.com").first()
    driver = Driver.query.filter_by(user_id=user.id).first()
    
    if driver:
        print(f"✅ Chauffeur trouvé:")
        print(f"   - ID: {driver.id}")
        print(f"   - Permis: {driver.license_number}")
        print(f"   - Statut: {driver.status}")
        print(f"   - Véhicule ID: {driver.vehicle_id}")
    else:
        print("❌ Aucun profil chauffeur trouvé")
```

---

## 🆘 Problèmes courants

### "Utilisateur non trouvé"
- Vérifiez que l'email est correct
- Vérifiez que l'utilisateur existe dans la base de données

### "Déjà enregistré comme chauffeur"
- L'utilisateur a déjà un profil chauffeur
- Utilisez l'endpoint `/drivers/me` pour voir les détails

### "Erreur lors de la création"
- Vérifiez les logs du backend
- Vérifiez que la base de données est accessible
- Vérifiez que tous les champs requis sont fournis

---

## 📝 Notes

- Le script crée automatiquement un véhicule avec les valeurs par défaut si non spécifiées
- Le rôle de l'utilisateur est automatiquement mis à jour à 'driver'
- Le statut initial du chauffeur est 'offline'
- Le véhicule est automatiquement lié au chauffeur

