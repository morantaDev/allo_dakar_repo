"""
Script pour rendre les colonnes email et password_hash nullable dans la table drivers
Usage: python scripts/fix_driver_table_constraints.py

Ce script modifie la table drivers pour rendre email et password_hash nullable,
car ces informations sont déjà stockées dans la table users via user_id.
"""

import sys
import os

# Ajouter le répertoire parent au path pour les imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Imports
import importlib.util
spec = importlib.util.spec_from_file_location("app_module", "app.py")
app_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app_module)

from extensions import db

def fix_driver_table_constraints():
    """Rendre les colonnes email et password_hash nullable dans la table drivers"""
    app = app_module.create_app('development')
    
    with app.app_context():
        try:
            # Obtenir le type de base de données
            db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
            
            print("🔧 Modification des contraintes de la table drivers...")
            print(f"   Type de base de données: {db_uri.split(':')[0] if ':' in db_uri else 'inconnu'}")
            print("")
            
            if db_uri.startswith('mysql'):
                # MySQL/MariaDB
                print("➕ Modification de la colonne 'email'...")
                db.session.execute(db.text("ALTER TABLE drivers MODIFY COLUMN email VARCHAR(120) NULL"))
                print("✅ Colonne 'email' rendue nullable")
                
                print("➕ Modification de la colonne 'password_hash'...")
                db.session.execute(db.text("ALTER TABLE drivers MODIFY COLUMN password_hash VARCHAR(255) NULL"))
                print("✅ Colonne 'password_hash' rendue nullable")
                
                db.session.commit()
                print("")
                print("✅ Modifications appliquées avec succès !")
                print("   Les colonnes email et password_hash sont maintenant nullable.")
                print("   Vous pouvez maintenant créer des Drivers sans dupliquer ces informations.")
                return True
                
            elif db_uri.startswith('postgresql'):
                # PostgreSQL
                print("➕ Modification de la colonne 'email'...")
                db.session.execute(db.text("ALTER TABLE drivers ALTER COLUMN email DROP NOT NULL"))
                print("✅ Colonne 'email' rendue nullable")
                
                print("➕ Modification de la colonne 'password_hash'...")
                db.session.execute(db.text("ALTER TABLE drivers ALTER COLUMN password_hash DROP NOT NULL"))
                print("✅ Colonne 'password_hash' rendue nullable")
                
                db.session.commit()
                print("")
                print("✅ Modifications appliquées avec succès !")
                print("   Les colonnes email et password_hash sont maintenant nullable.")
                return True
                
            elif db_uri.startswith('sqlite'):
                # SQLite - nécessite une recréation de table
                print("⚠️  SQLite détecté")
                print("   SQLite ne permet pas de modifier facilement les contraintes NOT NULL.")
                print("   Vous devrez recréer la table ou migrer vers MySQL/PostgreSQL.")
                print("")
                print("   Solution temporaire : Le code passe maintenant email et password_hash depuis le User.")
                return False
            else:
                print(f"❌ Type de base de données non supporté: {db_uri}")
                return False
                
        except Exception as e:
            db.session.rollback()
            print(f"❌ Erreur lors de la modification: {e}")
            import traceback
            traceback.print_exc()
            print("")
            print("💡 Note: Si la modification échoue, le code passe maintenant email et password_hash depuis le User.")
            return False

if __name__ == '__main__':
    print("🔧 Modification des contraintes de la table 'drivers'...")
    print("   Objectif: Rendre email et password_hash nullable")
    print("")
    success = fix_driver_table_constraints()
    print("")
    if success:
        print("✅ Modification réussie !")
        print("   Vous pouvez maintenant redémarrer le backend et tester l'inscription.")
        print("   Le code peut maintenant créer des Drivers sans passer email/password_hash.")
        sys.exit(0)
    else:
        print("⚠️  Modification non appliquée.")
        print("   Le code actuel passe email et password_hash depuis le User, ce qui fonctionne aussi.")
        sys.exit(0)  # Exit 0 car c'est acceptable

