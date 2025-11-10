-- Script SQL pour MySQL/MariaDB pour ajouter les colonnes manquantes à la table otps
-- Utilise la syntaxe MySQL (sans IF NOT EXISTS pour ALTER TABLE)

-- Vérifier et ajouter la colonne method
SET @dbname = DATABASE();
SET @tablename = "otps";
SET @columnname = "method";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 1",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " VARCHAR(10) NOT NULL DEFAULT 'SMS' COMMENT 'Méthode d''envoi: SMS ou WHATSAPP'")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Vérifier et ajouter la colonne is_used
SET @columnname = "is_used";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 1",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Empêcher la réutilisation du code'")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Vérifier et ajouter la colonne verified_at
SET @columnname = "verified_at";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (TABLE_SCHEMA = @dbname)
      AND (TABLE_NAME = @tablename)
      AND (COLUMN_NAME = @columnname)
  ) > 0,
  "SELECT 1",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " DATETIME NULL COMMENT 'Timestamp de vérification'")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Rendre user_id nullable
ALTER TABLE otps MODIFY COLUMN user_id INT NULL COMMENT 'ID utilisateur (optionnel pour nouveaux utilisateurs)';

-- Ajouter les index si nécessaire (MySQL ignore si l'index existe déjà)
CREATE INDEX idx_otps_phone ON otps(phone);
CREATE INDEX idx_otps_expires_at ON otps(expires_at);

