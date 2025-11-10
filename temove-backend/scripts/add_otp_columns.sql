-- Script SQL pour ajouter les colonnes manquantes à la table otps
-- À exécuter directement dans MySQL si les migrations Flask ne fonctionnent pas

-- Ajouter la colonne method si elle n'existe pas
SET @dbname = DATABASE();
SET @tablename = "otps";
SET @columnname = "method";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column method already exists.'",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " VARCHAR(10) NOT NULL DEFAULT 'SMS'")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Ajouter la colonne is_used si elle n'existe pas
SET @columnname = "is_used";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column is_used already exists.'",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " BOOLEAN NOT NULL DEFAULT 0")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Ajouter la colonne verified_at si elle n'existe pas
SET @columnname = "verified_at";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column verified_at already exists.'",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " DATETIME NULL")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Rendre user_id nullable si nécessaire
ALTER TABLE otps MODIFY COLUMN user_id INT NULL;

-- Vérifier la structure de la table
DESCRIBE otps;

