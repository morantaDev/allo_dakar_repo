-- Script SQL pour ajouter les colonnes manquantes à la table otps
-- À exécuter si la migration Alembic ne fonctionne pas

-- Ajouter la colonne method si elle n'existe pas
ALTER TABLE otps 
ADD COLUMN IF NOT EXISTS method VARCHAR(10) NOT NULL DEFAULT 'SMS' 
COMMENT 'Méthode d''envoi: SMS ou WHATSAPP';

-- Ajouter la colonne is_used si elle n'existe pas
ALTER TABLE otps 
ADD COLUMN IF NOT EXISTS is_used BOOLEAN NOT NULL DEFAULT FALSE 
COMMENT 'Empêcher la réutilisation du code';

-- Ajouter la colonne verified_at si elle n'existe pas
ALTER TABLE otps 
ADD COLUMN IF NOT EXISTS verified_at DATETIME NULL 
COMMENT 'Timestamp de vérification';

-- Rendre user_id nullable si ce n'est pas déjà le cas
ALTER TABLE otps 
MODIFY COLUMN user_id INT NULL 
COMMENT 'ID utilisateur (optionnel pour nouveaux utilisateurs)';

-- Ajouter un index sur phone si ce n'est pas déjà fait
CREATE INDEX IF NOT EXISTS idx_otps_phone ON otps(phone);

-- Ajouter un index sur expires_at si ce n'est pas déjà fait
CREATE INDEX IF NOT EXISTS idx_otps_expires_at ON otps(expires_at);

