#!/usr/bin/env python3
"""
Script pour ajouter les colonnes manquantes à la table otps
À exécuter si les migrations Flask ne fonctionnent pas
"""
import sys
import os

# Ajouter le répertoire parent au path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

from extensions import db
from sqlalchemy import text
import config as project_config

def fix_otp_table():
    """Ajouter les colonnes manquantes à la table otps"""
    # Créer l'app Flask avec la configuration de développement
    # Utiliser la même approche que init_db.py
    from flask import Flask
    
    app = Flask(__name__)
    app.config.from_object(project_config.config['development'])
    
    # S'assurer que le dossier instance/ existe pour SQLite
    db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    if db_uri.startswith('sqlite:///'):
        db_path = db_uri.replace('sqlite:///', '')
        if db_path and not db_path.startswith(':memory:'):
            db_dir = os.path.dirname(db_path)
            if db_dir and not os.path.exists(db_dir):
                os.makedirs(db_dir, exist_ok=True)
    
    # Initialiser db avec l'app
    db.init_app(app)
    
    # Importer les modèles pour qu'ils soient enregistrés
    from models import OTP
    
    with app.app_context():
        try:
            # Vérifier si la colonne method existe
            result = db.session.execute(text("""
                SELECT COUNT(*) as count 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'otps' 
                AND COLUMN_NAME = 'method'
            """))
            method_exists = result.fetchone()[0] > 0
            
            if not method_exists:
                print("➕ Ajout de la colonne 'method'...")
                db.session.execute(text("ALTER TABLE otps ADD COLUMN method VARCHAR(10) NOT NULL DEFAULT 'SMS'"))
                db.session.commit()
                print("✅ Colonne 'method' ajoutée")
            else:
                print("ℹ️  Colonne 'method' existe déjà")
            
            # Vérifier si la colonne is_used existe
            result = db.session.execute(text("""
                SELECT COUNT(*) as count 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'otps' 
                AND COLUMN_NAME = 'is_used'
            """))
            is_used_exists = result.fetchone()[0] > 0
            
            if not is_used_exists:
                print("➕ Ajout de la colonne 'is_used'...")
                db.session.execute(text("ALTER TABLE otps ADD COLUMN is_used BOOLEAN NOT NULL DEFAULT 0"))
                db.session.commit()
                print("✅ Colonne 'is_used' ajoutée")
            else:
                print("ℹ️  Colonne 'is_used' existe déjà")
            
            # Vérifier si la colonne verified_at existe
            result = db.session.execute(text("""
                SELECT COUNT(*) as count 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'otps' 
                AND COLUMN_NAME = 'verified_at'
            """))
            verified_at_exists = result.fetchone()[0] > 0
            
            if not verified_at_exists:
                print("➕ Ajout de la colonne 'verified_at'...")
                db.session.execute(text("ALTER TABLE otps ADD COLUMN verified_at DATETIME NULL"))
                db.session.commit()
                print("✅ Colonne 'verified_at' ajoutée")
            else:
                print("ℹ️  Colonne 'verified_at' existe déjà")
            
            # Rendre user_id nullable (seulement si la colonne existe)
            result = db.session.execute(text("""
                SELECT COUNT(*) as count 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'otps' 
                AND COLUMN_NAME = 'user_id'
            """))
            user_id_exists = result.fetchone()[0] > 0
            
            if user_id_exists:
                print("🔄 Modification de la colonne 'user_id' pour la rendre nullable...")
                try:
                    db.session.execute(text("ALTER TABLE otps MODIFY COLUMN user_id INT NULL"))
                    db.session.commit()
                    print("✅ Colonne 'user_id' modifiée")
                except Exception as e:
                    print(f"⚠️  Impossible de modifier 'user_id' (peut-être déjà nullable): {e}")
                    db.session.rollback()
            else:
                print("ℹ️  Colonne 'user_id' n'existe pas, création...")
                try:
                    db.session.execute(text("ALTER TABLE otps ADD COLUMN user_id INT NULL"))
                    db.session.commit()
                    print("✅ Colonne 'user_id' créée")
                except Exception as e:
                    print(f"⚠️  Impossible de créer 'user_id': {e}")
                    db.session.rollback()
            
            # Afficher la structure de la table
            print("\n📊 Structure de la table otps:")
            result = db.session.execute(text("DESCRIBE otps"))
            for row in result:
                print(f"  - {row[0]}: {row[1]} ({'NULL' if row[2] == 'YES' else 'NOT NULL'})")
            
            print("\n✅ Table otps mise à jour avec succès!")
            
        except Exception as e:
            db.session.rollback()
            print(f"❌ Erreur: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    return True

if __name__ == '__main__':
    print("🔧 Correction de la table otps...\n")
    success = fix_otp_table()
    sys.exit(0 if success else 1)
