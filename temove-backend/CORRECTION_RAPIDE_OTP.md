# 🚀 Correction Rapide - Table OTP

## Problème

L'erreur suivante apparaît :
```
Unknown column 'otps.method' in 'field list'
```

La table `otps` n'a pas les colonnes nécessaires : `method`, `is_used`, `verified_at`.

## Solution Rapide (RECOMMANDÉ)

### Option 1 : Script Python (Le plus simple)

```bash
cd temove-backend
python scripts/fix_otp_table.py
```

Ce script va :
- Vérifier les colonnes existantes
- Ajouter les colonnes manquantes
- Modifier `user_id` pour le rendre nullable
- Ajouter les index nécessaires

### Option 2 : SQL Direct

Connectez-vous à MySQL et exécutez :

```sql
-- Ajouter les colonnes manquantes
ALTER TABLE otps ADD COLUMN method VARCHAR(10) NOT NULL DEFAULT 'SMS';
ALTER TABLE otps ADD COLUMN is_used BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE otps ADD COLUMN verified_at DATETIME NULL;
ALTER TABLE otps MODIFY COLUMN user_id INT NULL;

-- Ajouter les index
CREATE INDEX idx_otps_phone ON otps(phone);
CREATE INDEX idx_otps_expires_at ON otps(expires_at);
```

### Option 3 : Flask-Migrate

```bash
cd temove-backend

# Appliquer la migration
python -m flask db upgrade head
```

## Vérification

Après avoir exécuté le script, vérifiez que tout fonctionne :

```bash
# Redémarrer le serveur Flask
python app.py
```

Puis testez l'envoi d'un OTP depuis l'application Flutter.

## Structure attendue de la table

La table `otps` doit avoir les colonnes suivantes :

- `id` : INT (primary key)
- `phone` : VARCHAR(20) (indexé)
- `code` : VARCHAR(6)
- `method` : VARCHAR(10) (DEFAULT 'SMS')
- `is_used` : BOOLEAN (DEFAULT FALSE)
- `user_id` : INT (nullable, foreign key vers users.id)
- `expires_at` : DATETIME (indexé)
- `created_at` : DATETIME
- `verified_at` : DATETIME (nullable)

## Après correction

Le flow OTP devrait fonctionner correctement ! 🎉

