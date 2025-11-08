"""
Script pour ajouter les colonnes manquantes à la table users
"""
import sys
import os
import importlib.util

root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, root_dir)

# Charger app.py
spec = importlib.util.spec_from_file_location("app_module", os.path.join(root_dir, "app.py"))
app_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app_module)

from extensions import db

def add_user_columns():
    """Ajouter les colonnes name et role à la table users"""
    app = app_module.create_app('development')
    
    with app.app_context():
        try:
            # Vérifier si les colonnes existent déjà
            inspector = db.inspect(db.engine)
            columns = [col['name'] for col in inspector.get_columns('users')]
            
            print("Colonnes actuelles dans users:", columns)
            
            # Ajouter les colonnes si elles n'existent pas
            if 'name' not in columns:
                print("Ajout de la colonne 'name'...")
                db.session.execute(db.text("ALTER TABLE users ADD COLUMN name VARCHAR(100) NULL"))
                db.session.commit()
                print("✅ Colonne 'name' ajoutée")
            
            if 'role' not in columns:
                print("Ajout de la colonne 'role'...")
                db.session.execute(db.text("ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'client'"))
                db.session.commit()
                print("✅ Colonne 'role' ajoutée")
            
            # Mettre à jour les valeurs existantes
            if 'name' in columns or 'name' in [col['name'] for col in inspector.get_columns('users')]:
                inspector = db.inspect(db.engine)
                columns_after = [col['name'] for col in inspector.get_columns('users')]
                if 'name' in columns_after and 'full_name' in columns_after:
                    print("Mise à jour des valeurs existantes...")
                    db.session.execute(db.text("UPDATE users SET name = full_name WHERE name IS NULL"))
                    db.session.execute(db.text("UPDATE users SET role = 'client' WHERE role IS NULL OR role = ''"))
                    db.session.commit()
                    print("✅ Valeurs mises à jour")
            
            print("\n✅ Migration terminée avec succès!")
            
        except Exception as e:
            print(f"❌ Erreur: {str(e)}")
            import traceback
            traceback.print_exc()
            db.session.rollback()

if __name__ == '__main__':
    add_user_columns()

