# 🔧 Solution : Ajouter la colonne `license_number` à la table `drivers`

## ❌ Problème

L'erreur `No such command 'db'` indique que Flask-Migrate n'est pas correctement configuré. Plutôt que de configurer Flask-Migrate, nous utilisons un script Python simple qui ajoute directement la colonne.

## ✅ Solution Simple (Recommandée)

### Option 1 : Script Python Direct

Exécutez le script Python qui ajoute directement la colonne :

```powershell
# Dans PowerShell, depuis le dossier temove-backend
python scripts/add_license_number_column.py
```

### Option 2 : Script PowerShell (Plus simple)

```powershell
# Depuis le dossier temove-backend
.\add_license_number.ps1
```

### Option 3 : SQL Direct

Si vous préférez, vous pouvez exécuter directement la commande SQL :

#### Pour MySQL/MariaDB :
```sql
ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50) NULL;
```

#### Pour PostgreSQL :
```sql
ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50) NULL;
```

#### Pour SQLite :
Le script Python gère automatiquement SQLite (qui nécessite une recréation de table dans certains cas).

## 🚀 Étapes Rapides

1. **Assurez-vous d'être dans le bon dossier** :
   ```powershell
   cd C:\allo_dakar_repo\temove-backend
   ```

2. **Activer le venv** (si pas déjà fait) :
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```

3. **Exécuter le script** :
   ```powershell
   python scripts/add_license_number_column.py
   ```

4. **Redémarrer le backend** :
   ```powershell
   python app.py
   ```

5. **Tester l'inscription** depuis TéMove Pro

## ✅ Vérification

Après avoir exécuté le script, vous devriez voir :

```
✅ Colonne 'license_number' ajoutée
✅ Vérification: La colonne 'license_number' est présente dans la table drivers
✅ Migration réussie !
```

## 🧪 Test

Une fois la colonne ajoutée et le backend redémarré, testez l'inscription :

1. Ouvrir TéMove Pro
2. Cliquer sur "Inscrivez-vous" depuis l'écran de connexion
3. Remplir le formulaire d'inscription complète
4. L'inscription devrait maintenant fonctionner sans erreur

## 📋 Ce que fait le script

Le script :
1. Se connecte à la base de données
2. Vérifie si la colonne `license_number` existe déjà
3. Si elle n'existe pas, l'ajoute avec le type `VARCHAR(50) NULL`
4. Vérifie que la colonne a été ajoutée avec succès

## 🔍 Résolution de problèmes

### Erreur : "Table 'drivers' doesn't exist"

Cela signifie que la table `drivers` n'existe pas encore. Dans ce cas :
1. Démarrez le backend une fois : `python app.py`
2. Le backend créera automatiquement toutes les tables
3. Puis exécutez le script de migration

### Erreur : "Column 'license_number' already exists"

Cela signifie que la colonne existe déjà. C'est bon, vous pouvez ignorer cette erreur et continuer.

### Erreur : "No module named 'app_module'"

Assurez-vous d'exécuter le script depuis le dossier `temove-backend` :
```powershell
cd C:\allo_dakar_repo\temove-backend
python scripts/add_license_number_column.py
```

---

## 📝 Note

Le script gère automatiquement :
- MySQL/MariaDB
- PostgreSQL
- SQLite (avec certaines limitations)

Pour SQLite, si la migration échoue, vous pouvez recréer la base de données en supprimant le fichier `.db` et en redémarrant le backend (qui créera toutes les tables avec les nouveaux champs).

