-- Script SQL sécurisé pour corriger la table otps
-- Ce script vérifie l'existence des colonnes avant de les ajouter
-- Exécuter ce script dans MySQL

USE temove_db;

-- Fonction pour vérifier si une colonne existe (MySQL 5.7+)
-- Si vous obtenez une erreur, exécutez simplement les commandes ALTER TABLE ci-dessous
-- et ignorez les erreurs si les colonnes existent déjà

-- Ajouter la colonne method
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
  "SELECT 'Column method already exists.' AS result",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " VARCHAR(10) NOT NULL DEFAULT 'SMS'")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Ajouter la colonne is_used
SET @columnname = "is_used";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column is_used already exists.' AS result",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " BOOLEAN NOT NULL DEFAULT 0")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Ajouter la colonne verified_at
SET @columnname = "verified_at";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 'Column verified_at already exists.' AS result",
  CONCAT("ALTER TABLE ", @tablename, " ADD COLUMN ", @columnname, " DATETIME NULL")
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Rendre user_id nullable (ignorer l'erreur si elle est déjà nullable)
ALTER TABLE otps MODIFY COLUMN user_id INT NULL;

-- Vérifier la structure de la table
DESCRIBE otps;

