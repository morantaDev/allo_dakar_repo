# 🔧 Correction : Colonne 'email' cannot be null dans la table drivers

## ❌ Problème

L'erreur `Column 'email' cannot be null` indique que la colonne `email` dans la table `drivers` est définie comme NOT NULL dans la base de données, mais le code tentait d'insérer NULL.

## ✅ Solution

Le code a été modifié pour toujours passer l'email du User lors de la création d'un Driver :

```python
driver = Driver(
    user_id=user.id,
    email=user.email,  # Email du User (requis par la base de données)
    full_name=full_name,
    phone=phone,  # Téléphone du User (si fourni)
    car_make=vehicle_make,
    car_model=vehicle_model,
    car_color=vehicle_color,
    license_plate=vehicle_plate,
    license_number=license_number,
    status=DriverStatus.OFFLINE,
    is_active=True,
    is_verified=False,
)
```

## 📋 Explication

Le modèle `Driver` dans `models/driver.py` définit `email` comme nullable :
```python
email = db.Column(db.String(120), unique=True, nullable=True, index=True)
```

Cependant, la base de données MySQL a probablement été créée avec une contrainte NOT NULL sur cette colonne, ou la migration a ajouté cette contrainte.

## 🔍 Vérification

Pour vérifier la structure de la table `drivers` dans MySQL :

```sql
DESCRIBE drivers;
```

Ou pour voir les contraintes :

```sql
SHOW CREATE TABLE drivers;
```

Si la colonne `email` est définie comme NOT NULL, vous avez deux options :

### Option 1 : Modifier la base de données pour rendre email nullable

```sql
ALTER TABLE drivers MODIFY COLUMN email VARCHAR(120) NULL;
```

### Option 2 : Toujours passer l'email (recommandé - déjà fait)

Le code passe maintenant toujours l'email du User au Driver, ce qui évite le problème.

## ✅ Résultat

Après cette correction, l'inscription devrait fonctionner correctement :
- Le User est créé avec un email
- Le Driver est créé avec le même email (copié depuis le User)
- Toutes les contraintes de la base de données sont respectées

## 🧪 Test

Pour tester :

1. Redémarrer le backend :
   ```powershell
   python app.py
   ```

2. Tester l'inscription depuis TéMove Pro avec un nouvel email

3. Vérifier que l'inscription réussit sans erreur

