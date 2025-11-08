# 🔧 Solution pour Ajouter la Colonne is_admin

## ❌ Problème

L'erreur `No such command 'db'` indique que Flask-Migrate n'est pas correctement configuré ou que Flask ne trouve pas l'application.

## ✅ Solution Simple (Recommandée)

### Option 1 : Script Python Direct (Plus Simple)

J'ai créé un script qui ajoute directement la colonne sans utiliser Flask-Migrate :

```powershell
# Dans PowerShell, avec le venv activé
python scripts/add_is_admin_column.py
```

Ou utilisez le script PowerShell :

```powershell
.\add_admin_column.ps1
```

### Option 2 : SQL Direct

Si vous préférez, vous pouvez exécuter directement la commande SQL :

#### Pour MySQL/MariaDB :
```sql
ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE;
```

#### Pour PostgreSQL :
```sql
ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE;
```

#### Pour SQLite :
Le script Python gère automatiquement SQLite (qui nécessite une recréation de table).

---

## 🔧 Solution Flask-Migrate (Alternative)

Si vous voulez utiliser Flask-Migrate :

### 1. Installer Flask-Migrate (si pas déjà fait)

```powershell
pip install Flask-Migrate
```

### 2. Configurer Flask pour trouver l'application

Créer un fichier `.flaskenv` à la racine du projet :

```env
FLASK_APP=app.py
FLASK_ENV=development
```

Ou définir la variable d'environnement :

```powershell
$env:FLASK_APP="app.py"
```

### 3. Initialiser Flask-Migrate (si pas déjà fait)

```powershell
flask db init
```

### 4. Créer la migration

```powershell
flask db migrate -m "Add is_admin field to users"
```

### 5. Appliquer la migration

```powershell
flask db upgrade
```

---

## 🚀 Étapes Rapides (Recommandé)

1. **Activer le venv** :
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```

2. **Exécuter le script** :
   ```powershell
   python scripts/add_is_admin_column.py
   ```

3. **Créer un utilisateur admin** :
   ```powershell
   python scripts/create_admin.py
   ```

---

## ✅ Vérification

Pour vérifier que la colonne a été ajoutée :

```python
from app import create_app
from extensions import db
from sqlalchemy import inspect

app = create_app()
with app.app_context():
    inspector = inspect(db.engine)
    columns = [col['name'] for col in inspector.get_columns('users')]
    print("Colonnes dans 'users':", columns)
    if 'is_admin' in columns:
        print("✅ Colonne 'is_admin' présente!")
    else:
        print("❌ Colonne 'is_admin' absente")
```

---

## 🐛 Dépannage

### Erreur : "ModuleNotFoundError: No module named 'flask'"

**Solution** : Activez d'abord l'environnement virtuel :
```powershell
.\venv\Scripts\Activate.ps1
```

### Erreur : "Table 'users' doesn't exist"

**Solution** : Les tables doivent être créées d'abord. Le script `app.py` les crée automatiquement au démarrage, ou vous pouvez :
```python
from app import create_app
from extensions import db

app = create_app()
with app.app_context():
    db.create_all()
```

### Erreur : "Column 'is_admin' already exists"

**Solution** : La colonne existe déjà, vous pouvez passer à l'étape suivante (créer un admin).

---

## 📝 Résumé

**Méthode la plus simple** :
1. Activer venv
2. Exécuter `python scripts/add_is_admin_column.py`
3. Créer admin avec `python scripts/create_admin.py`

C'est tout ! 🎉

