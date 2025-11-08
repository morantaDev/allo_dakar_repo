# ✅ Compatibilité Frontend - Colonnes Users

## Modifications effectuées

### Colonnes ajoutées à la table `users`

1. **`name`** : VARCHAR(100) NULL
   - Pour compatibilité avec `app/models.py`
   - Rempli automatiquement avec `full_name` lors de l'inscription

2. **`role`** : VARCHAR(20) NOT NULL DEFAULT 'client'
   - Pour compatibilité avec le frontend
   - Valeur par défaut : `'client'`

### Structure de la table `users` maintenant

```sql
CREATE TABLE users (
    id INT PRIMARY KEY,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NULL,              -- ✅ NOUVEAU
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20) UNIQUE NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'client',  -- ✅ NOUVEAU
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    credit_balance INT DEFAULT 0,
    created_at DATETIME,
    updated_at DATETIME
);
```

### Réponse API - Format compatible

Le `to_dict()` retourne maintenant :

```json
{
  "id": 1,
  "email": "test@example.com",
  "name": "Test User",           // ✅ Compatible frontend
  "full_name": "Test User",      // Nom principal
  "phone": "+221701234567",
  "role": "client",              // ✅ Compatible frontend
  "credit_balance": 0,
  "is_active": true,
  "is_verified": false,
  "created_at": "2025-11-04T00:17:00"
}
```

## ✅ Test

Vous pouvez maintenant vous inscrire depuis le frontend. Les colonnes `name` et `role` seront automatiquement remplies.

**Redémarrez le serveur** pour que les changements soient pris en compte :

```powershell
python app.py
```

