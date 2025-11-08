# 🔄 Migration : Ajout du champ `license_number` au modèle Driver

## 📋 Problème

Le modèle `Driver` avait seulement `license_plate` (plaque d'immatriculation du véhicule), mais il manquait `license_number` (numéro de permis de conduire). Ces deux informations sont différentes :
- **`license_number`** : Numéro de permis de conduire (ex: DL-12345)
- **`license_plate`** : Plaque d'immatriculation du véhicule (ex: ABC-123)

## ✅ Solution

Un champ `license_number` a été ajouté au modèle `Driver` dans `models/driver.py`.

## 🔧 Modification effectuée

### Modèle Driver (`temove-backend/models/driver.py`)

**Ajout du champ** :
```python
# Informations permis de conduire
license_number = db.Column(db.String(50), nullable=True)  # Numéro de permis de conduire (DL-12345)
```

**Mise à jour de `to_dict()`** :
```python
'license_number': self.license_number,  # Numéro de permis de conduire
```

### Route d'inscription (`temove-backend/app/routes/auth_routes.py`)

**Utilisation correcte des champs** :
```python
driver = Driver(
    user_id=user.id,
    full_name=full_name,
    car_make=vehicle_make,
    car_model=vehicle_model,
    car_color=vehicle_color,
    license_plate=vehicle_plate,  # Plaque d'immatriculation du véhicule
    license_number=license_number,  # Numéro de permis de conduire
    status=DriverStatus.OFFLINE,
    is_active=True,
    is_verified=False,
)
```

## 🔄 Migration de la base de données

**IMPORTANT** : Si vous avez déjà une base de données existante, vous devez ajouter la colonne `license_number` à la table `drivers`.

### Option 1 : Migration automatique (Flask-Migrate)

```powershell
cd C:\allo_dakar_repo\temove-backend
python -m flask db migrate -m "Add license_number to Driver"
python -m flask db upgrade
```

### Option 2 : Migration manuelle (SQL)

Si vous utilisez MySQL :

```sql
ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50) NULL;
```

Si vous utilisez SQLite :

```sql
ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50);
```

## ✅ Après la migration

Une fois la colonne ajoutée, l'inscription devrait fonctionner correctement :
- Le numéro de permis de conduire sera stocké dans `license_number`
- La plaque d'immatriculation sera stockée dans `license_plate`
- Les deux informations seront disponibles dans la réponse API

## 🧪 Test

Pour tester que tout fonctionne :

```powershell
# Tester l'inscription
$body = @{
    email = "test.driver@example.com"
    password = "password123"
    full_name = "Test Driver"
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

La réponse devrait contenir :
```json
{
  "driver": {
    "license_number": "DL-12345",
    "vehicle": {
      "plate": "ABC-123"
    }
  }
}
```

