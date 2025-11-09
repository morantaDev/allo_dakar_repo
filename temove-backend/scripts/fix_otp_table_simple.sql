-- Script SQL simple pour ajouter les colonnes manquantes à la table otps
-- Pour MySQL/MariaDB - Exécuter directement dans la base de données

-- Ajouter la colonne method
ALTER TABLE otps ADD COLUMN method VARCHAR(10) NOT NULL DEFAULT 'SMS';

-- Ajouter la colonne is_used  
ALTER TABLE otps ADD COLUMN is_used BOOLEAN NOT NULL DEFAULT FALSE;

-- Ajouter la colonne verified_at
ALTER TABLE otps ADD COLUMN verified_at DATETIME NULL;

-- Rendre user_id nullable (important pour nouveaux utilisateurs)
ALTER TABLE otps MODIFY COLUMN user_id INT NULL;

-- Ajouter les index
CREATE INDEX idx_otps_phone ON otps(phone);
CREATE INDEX idx_otps_expires_at ON otps(expires_at);

