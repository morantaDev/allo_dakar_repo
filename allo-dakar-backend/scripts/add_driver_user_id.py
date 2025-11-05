"""
Script pour ajouter la colonne user_id à la table drivers
"""
import os
import sys
from dotenv import load_dotenv

# Ensure repo root is on sys.path
ROOT = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, ROOT)

load_dotenv()

from app import create_app
from extensions import db
from sqlalchemy import text

def add_user_id_column():
    """Ajouter la colonne user_id à la table drivers"""
    app = create_app()
    
    with app.app_context():
        try:
            # Vérifier si la colonne existe déjà (MySQL)
            try:
                result = db.session.execute(text("""
                    SELECT COUNT(*) as count 
                    FROM information_schema.COLUMNS 
                    WHERE TABLE_SCHEMA = DATABASE() 
                    AND TABLE_NAME = 'drivers' 
                    AND COLUMN_NAME = 'user_id'
                """))
                exists = result.fetchone()[0] > 0
            except:
                # Si ce n'est pas MySQL, essayer SQLite
                try:
                    result = db.session.execute(text("""
                        SELECT COUNT(*) FROM sqlite_master 
                        WHERE type='table' AND name='drivers'
                    """))
                    # Vérifier les colonnes dans SQLite
                    result = db.session.execute(text("PRAGMA table_info(drivers)"))
                    columns = [row[1] for row in result.fetchall()]
                    exists = 'user_id' in columns
                except:
                    exists = False
            
            if exists:
                print("✅ La colonne user_id existe déjà dans la table drivers")
                return
            
            # Ajouter la colonne user_id
            print("🔧 Ajout de la colonne user_id à la table drivers...")
            try:
                # MySQL
                db.session.execute(text("""
                    ALTER TABLE drivers 
                    ADD COLUMN user_id INT NULL,
                    ADD INDEX idx_drivers_user_id (user_id),
                    ADD CONSTRAINT fk_drivers_user_id 
                        FOREIGN KEY (user_id) REFERENCES users(id) 
                        ON DELETE SET NULL
                """))
            except:
                # SQLite ou autre
                db.session.execute(text("""
                    ALTER TABLE drivers 
                    ADD COLUMN user_id INTEGER NULL
                """))
                # Créer l'index séparément
                try:
                    db.session.execute(text("CREATE INDEX idx_drivers_user_id ON drivers(user_id)"))
                except:
                    pass  # L'index existe peut-être déjà
            
            db.session.commit()
            print("✅ Colonne user_id ajoutée avec succès")
            
        except Exception as e:
            db.session.rollback()
            print(f"❌ Erreur lors de l'ajout de la colonne: {e}")
            import traceback
            traceback.print_exc()

if __name__ == '__main__':
    add_user_id_column()

