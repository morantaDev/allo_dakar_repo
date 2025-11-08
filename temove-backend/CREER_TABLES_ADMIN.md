# 🔧 Créer les Tables Admin

## ❌ Erreur

L'erreur `Table 'temove_db.revenues' doesn't exist` indique que les tables `commissions` et `revenues` n'ont pas encore été créées.

## ✅ Solution Rapide

### Option 1 : Utiliser le Script Python (Recommandé)

**Avec l'environnement virtuel activé** :

```powershell
.\venv\Scripts\Activate.ps1
python scripts/create_admin_tables.py
```

### Option 2 : Utiliser SQL Direct

Exécutez ce script SQL dans votre base de données MySQL :

```sql
-- Table commissions
CREATE TABLE IF NOT EXISTS commissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ride_id INT NOT NULL UNIQUE,
    driver_id INT NOT NULL,
    ride_price INT NOT NULL,
    platform_commission INT NOT NULL,
    driver_earnings INT NOT NULL,
    service_fee INT NOT NULL DEFAULT 0,
    commission_rate FLOAT NOT NULL,
    base_commission INT NOT NULL,
    surge_commission INT NOT NULL DEFAULT 0,
    base_price INT NOT NULL,
    surge_amount INT NOT NULL DEFAULT 0,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    paid_at DATETIME NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
    FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
    INDEX idx_commissions_driver_id (driver_id),
    INDEX idx_commissions_ride_id (ride_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Table revenues
CREATE TABLE IF NOT EXISTS revenues (
    id INT AUTO_INCREMENT PRIMARY KEY,
    year INT NOT NULL,
    month INT NOT NULL,
    commission_revenue INT NOT NULL DEFAULT 0,
    premium_revenue INT NOT NULL DEFAULT 0,
    driver_subscription_revenue INT NOT NULL DEFAULT 0,
    service_fees_revenue INT NOT NULL DEFAULT 0,
    delivery_revenue INT NOT NULL DEFAULT 0,
    partnership_revenue INT NOT NULL DEFAULT 0,
    other_revenue INT NOT NULL DEFAULT 0,
    total_revenue INT NOT NULL,
    rides_count INT NOT NULL DEFAULT 0,
    active_users INT NOT NULL DEFAULT 0,
    active_drivers INT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY _year_month_uc (year, month),
    INDEX idx_revenues_year_month (year, month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Option 3 : Redémarrer le Serveur Flask

Le serveur Flask devrait créer automatiquement les tables avec `db.create_all()` si les modèles sont bien importés.

**Redémarrez simplement le serveur** :

```powershell
python app.py
```

ou

```powershell
python run.py
```

Les tables seront créées automatiquement au démarrage.

---

## 🧪 Vérification

Pour vérifier que les tables ont été créées :

```sql
SHOW TABLES LIKE 'commissions';
SHOW TABLES LIKE 'revenues';
```

Ou pour voir la structure :

```sql
DESCRIBE commissions;
DESCRIBE revenues;
```

---

## 📝 Note

Les routes admin ont été modifiées pour gérer gracieusement l'absence de ces tables (affichent 0 si les tables n'existent pas encore).

Une fois les tables créées, le dashboard admin fonctionnera normalement.

