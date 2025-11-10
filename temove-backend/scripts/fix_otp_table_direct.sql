-- Script SQL direct pour corriger la table otps
-- Exécuter ce script dans MySQL pour ajouter les colonnes manquantes

USE temove_db;

-- Ajouter la colonne method si elle n'existe pas
ALTER TABLE otps ADD COLUMN method VARCHAR(10) NOT NULL DEFAULT 'SMS';

-- Ajouter la colonne is_used si elle n'existe pas  
ALTER TABLE otps ADD COLUMN is_used BOOLEAN NOT NULL DEFAULT 0;

-- Ajouter la colonne verified_at si elle n'existe pas
ALTER TABLE otps ADD COLUMN verified_at DATETIME NULL;

-- Rendre user_id nullable
ALTER TABLE otps MODIFY COLUMN user_id INT NULL;

-- Vérifier la structure de la table
DESCRIBE otps;

