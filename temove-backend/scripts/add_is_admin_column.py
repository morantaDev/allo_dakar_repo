"""
Script pour ajouter la colonne is_admin à la table users
"""
import sys
import os

# Ajouter le répertoire parent au path pour les imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from extensions import db
from sqlalchemy import text

def add_is_admin_column():
    """Ajouter la colonne is_admin à la table users"""
    app = create_app('development')
    
    with app.app_context():
        try:
            # Vérifier si la colonne existe déjà
            inspector = db.inspect(db.engine)
            columns = [col['name'] for col in inspector.get_columns('users')]
            
            if 'is_admin' in columns:
                print("✅ La colonne 'is_admin' existe déjà dans la table 'users'")
                return
            
            # Obtenir le type de base de données
            db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
            
            if 'mysql' in db_uri or 'mariadb' in db_uri:
                # Pour MySQL/MariaDB
                print("📊 Base de données: MySQL/MariaDB")
                db.session.execute(text("ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE"))
                print("✅ Colonne 'is_admin' ajoutée avec succès (MySQL)")
                
            elif 'postgresql' in db_uri or 'postgres' in db_uri:
                # Pour PostgreSQL
                print("📊 Base de données: PostgreSQL")
                db.session.execute(text("ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE"))
                print("✅ Colonne 'is_admin' ajoutée avec succès (PostgreSQL)")
                
            elif 'sqlite' in db_uri:
                # Pour SQLite (plus complexe car SQLite ne supporte pas ALTER TABLE ADD COLUMN facilement)
                print("📊 Base de données: SQLite")
                print("⚠️  SQLite nécessite une recréation de table...")
                
                # Créer une nouvelle table avec la colonne
                db.session.execute(text("""
                    CREATE TABLE users_new (
                        id INTEGER PRIMARY KEY AUTOINCREMENT,
                        email VARCHAR(120) NOT NULL UNIQUE,
                        password_hash VARCHAR(255) NOT NULL,
                        name VARCHAR(100),
                        full_name VARCHAR(100) NOT NULL,
                        phone VARCHAR(20) UNIQUE,
                        role VARCHAR(20) NOT NULL DEFAULT 'client',
                        is_active BOOLEAN NOT NULL DEFAULT TRUE,
                        is_verified BOOLEAN NOT NULL DEFAULT FALSE,
                        is_admin BOOLEAN NOT NULL DEFAULT FALSE,
                        credit_balance INTEGER NOT NULL DEFAULT 0,
                        created_at DATETIME NOT NULL,
                        updated_at DATETIME
                    )
                """))
                
                # Copier les données
                db.session.execute(text("""
                    INSERT INTO users_new 
                    (id, email, password_hash, name, full_name, phone, role, 
                     is_active, is_verified, credit_balance, created_at, updated_at)
                    SELECT 
                        id, email, password_hash, name, full_name, phone, role,
                        is_active, is_verified, credit_balance, created_at, updated_at
                    FROM users
                """))
                
                # Supprimer l'ancienne table
                db.session.execute(text("DROP TABLE users"))
                
                # Renommer la nouvelle table
                db.session.execute(text("ALTER TABLE users_new RENAME TO users"))
                
                # Recréer les index
                db.session.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_email ON users(email)"))
                if db.session.execute(text("SELECT COUNT(*) FROM sqlite_master WHERE type='index' AND name='ix_users_phone'")).scalar() == 0:
                    db.session.execute(text("CREATE UNIQUE INDEX IF NOT EXISTS ix_users_phone ON users(phone)"))
                
                print("✅ Colonne 'is_admin' ajoutée avec succès (SQLite)")
            else:
                print(f"❌ Type de base de données non reconnu: {db_uri}")
                print("   Tentative avec SQL générique...")
                db.session.execute(text("ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE"))
                print("✅ Colonne 'is_admin' ajoutée (générique)")
            
            db.session.commit()
            print("\n✅ Migration réussie!")
            print("   La colonne 'is_admin' a été ajoutée à la table 'users'")
            print("   Tous les utilisateurs existants ont 'is_admin = FALSE' par défaut")
            
        except Exception as e:
            db.session.rollback()
            print(f"\n❌ Erreur lors de l'ajout de la colonne: {str(e)}")
            print(f"   Type d'erreur: {type(e).__name__}")
            import traceback
            traceback.print_exc()
            return False
    
    return True

if __name__ == '__main__':
    print("🔧 Ajout de la colonne 'is_admin' à la table 'users'...")
    print("")
    success = add_is_admin_column()
    
    if success:
        print("\n🎉 Opération terminée avec succès!")
        print("   Vous pouvez maintenant créer un utilisateur admin avec:")
        print("   python scripts/create_admin.py")
    else:
        print("\n💥 L'opération a échoué. Vérifiez les erreurs ci-dessus.")

