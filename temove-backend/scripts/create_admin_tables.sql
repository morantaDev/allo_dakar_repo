-- Script SQL pour créer les tables admin (commissions et revenues)
-- Pour MySQL/MariaDB

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

