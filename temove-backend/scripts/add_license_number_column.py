"""
Script pour ajouter la colonne license_number à la table drivers
Usage: python scripts/add_license_number_column.py
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

def add_license_number_column():
    """Ajouter la colonne license_number à la table drivers"""
    app = app_module.create_app('development')
    
    with app.app_context():
        try:
            # Vérifier si la colonne existe déjà
            inspector = db.inspect(db.engine)
            columns = [col['name'] for col in inspector.get_columns('drivers')]
            
            print("📋 Colonnes actuelles dans drivers:", columns)
            
            # Ajouter la colonne si elle n'existe pas
            if 'license_number' not in columns:
                print("➕ Ajout de la colonne 'license_number'...")
                
                # Obtenir le type de base de données
                db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
                
                if db_uri.startswith('mysql'):
                    # MySQL/MariaDB
                    db.session.execute(db.text("ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50) NULL"))
                    print("✅ Colonne 'license_number' ajoutée (MySQL)")
                elif db_uri.startswith('postgresql'):
                    # PostgreSQL
                    db.session.execute(db.text("ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50) NULL"))
                    print("✅ Colonne 'license_number' ajoutée (PostgreSQL)")
                elif db_uri.startswith('sqlite'):
                    # SQLite - nécessite une recréation de table
                    print("⚠️  SQLite détecté - recréation de la table nécessaire")
                    print("   Cette opération est plus complexe pour SQLite.")
                    print("   Recommandation : Utilisez MySQL ou PostgreSQL pour la production.")
                    print("   Pour SQLite, vous pouvez recréer la base de données ou utiliser une migration manuelle.")
                    
                    # Tentative simple pour SQLite (peut échouer selon la version)
                    try:
                        db.session.execute(db.text("ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50)"))
                        db.session.commit()
                        print("✅ Colonne 'license_number' ajoutée (SQLite)")
                    except Exception as e:
                        print(f"❌ Erreur SQLite: {e}")
                        print("   Solution: Recréez la base de données ou migrez vers MySQL/PostgreSQL")
                        return False
                else:
                    # Par défaut, essayer ALTER TABLE
                    db.session.execute(db.text("ALTER TABLE drivers ADD COLUMN license_number VARCHAR(50) NULL"))
                    print("✅ Colonne 'license_number' ajoutée (défaut)")
                
                db.session.commit()
            else:
                print("✅ Colonne 'license_number' existe déjà")
            
            # Vérifier que la colonne a été ajoutée
            inspector = db.inspect(db.engine)
            columns_after = [col['name'] for col in inspector.get_columns('drivers')]
            
            if 'license_number' in columns_after:
                print("✅ Vérification: La colonne 'license_number' est présente dans la table drivers")
                print("📋 Colonnes après modification:", columns_after)
                return True
            else:
                print("❌ Erreur: La colonne n'a pas été ajoutée")
                return False
                
        except Exception as e:
            db.session.rollback()
            print(f"❌ Erreur lors de l'ajout de la colonne: {e}")
            import traceback
            traceback.print_exc()
            return False

if __name__ == '__main__':
    print("🔧 Ajout de la colonne 'license_number' à la table 'drivers'...")
    print("")
    success = add_license_number_column()
    print("")
    if success:
        print("✅ Migration réussie !")
        print("   Vous pouvez maintenant redémarrer le backend et tester l'inscription.")
        sys.exit(0)
    else:
        print("❌ Migration échouée. Vérifiez les erreurs ci-dessus.")
        sys.exit(1)

