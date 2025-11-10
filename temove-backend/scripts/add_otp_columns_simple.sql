-- Script SQL simple pour ajouter les colonnes manquantes à la table otps
-- À exécuter directement dans MySQL

-- Ajouter la colonne method
ALTER TABLE otps ADD COLUMN IF NOT EXISTS method VARCHAR(10) NOT NULL DEFAULT 'SMS';

-- Ajouter la colonne is_used
ALTER TABLE otps ADD COLUMN IF NOT EXISTS is_used BOOLEAN NOT NULL DEFAULT 0;

-- Ajouter la colonne verified_at
ALTER TABLE otps ADD COLUMN IF NOT EXISTS verified_at DATETIME NULL;

-- Rendre user_id nullable
ALTER TABLE otps MODIFY COLUMN user_id INT NULL;

-- Vérifier la structure de la table
DESCRIBE otps;

