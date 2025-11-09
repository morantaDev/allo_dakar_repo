# 🔧 Correction de la table OTP

## Problème
La table `otps` n'a pas les colonnes nécessaires (`method`, `is_used`, `verified_at`), ce qui cause une erreur lors de l'envoi d'OTP.

## Solution rapide : Script Python

### Étape 1 : Activer l'environnement virtuel

```powershell
cd C:\allo_dakar_repo\temove-backend
.\venv\Scripts\activate
```

### Étape 2 : Exécuter le script de correction

```powershell
python scripts/fix_otp_table.py
```

Le script va :
- ✅ Vérifier si les colonnes existent
- ✅ Ajouter les colonnes manquantes (`method`, `is_used`, `verified_at`)
- ✅ Modifier `user_id` pour le rendre nullable
- ✅ Afficher la structure finale de la table

## Solution alternative : Script SQL direct

Si le script Python ne fonctionne pas, vous pouvez exécuter directement le SQL dans MySQL :

### Étape 1 : Se connecter à MySQL

```powershell
mysql -u root -p
```

### Étape 2 : Sélectionner la base de données

```sql
USE temove_db;
```

### Étape 3 : Exécuter les commandes SQL

```sql
-- Ajouter la colonne method
ALTER TABLE otps ADD COLUMN method VARCHAR(10) NOT NULL DEFAULT 'SMS';

-- Ajouter la colonne is_used
ALTER TABLE otps ADD COLUMN is_used BOOLEAN NOT NULL DEFAULT 0;

-- Ajouter la colonne verified_at
ALTER TABLE otps ADD COLUMN verified_at DATETIME NULL;

-- Rendre user_id nullable
ALTER TABLE otps MODIFY COLUMN user_id INT NULL;

-- Vérifier la structure
DESCRIBE otps;
```

## Solution avec migrations Flask

### Étape 1 : Activer l'environnement virtuel

```powershell
cd C:\allo_dakar_repo\temove-backend
.\venv\Scripts\activate
```

### Étape 2 : Vérifier l'état des migrations

```powershell
python -m flask db current
```

### Étape 3 : Appliquer la migration

```powershell
python -m flask db upgrade
```

## Vérification

Après avoir exécuté une des solutions, vérifiez que la table a bien toutes les colonnes :

```sql
DESCRIBE otps;
```

Vous devriez voir :
- `id` (INT, PRIMARY KEY)
- `phone` (VARCHAR(20))
- `code` (VARCHAR(6))
- `method` (VARCHAR(10)) ✅
- `is_used` (BOOLEAN) ✅
- `user_id` (INT, NULL) ✅
- `expires_at` (DATETIME)
- `created_at` (DATETIME)
- `verified_at` (DATETIME, NULL) ✅

## Après la correction

Une fois les colonnes ajoutées, redémarrez le serveur Flask et testez à nouveau l'envoi d'OTP.
