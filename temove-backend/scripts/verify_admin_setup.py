"""
Script pour vérifier que la colonne is_admin est bien présente
"""
import sys
import os

# Ajouter le répertoire parent au path pour les imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app
from extensions import db
from sqlalchemy import inspect

def verify_admin_setup():
    """Vérifier que la colonne is_admin existe"""
    app = create_app('development')
    
    with app.app_context():
        try:
            # Vérifier si la colonne existe
            inspector = inspect(db.engine)
            columns = [col['name'] for col in inspector.get_columns('users')]
            
            print("🔍 Vérification de la configuration admin...")
            print("")
            
            if 'is_admin' in columns:
                print("✅ Colonne 'is_admin' présente dans la table 'users'")
            else:
                print("❌ Colonne 'is_admin' ABSENTE de la table 'users'")
                print("   Vous devez l'ajouter avec:")
                print("   ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE;")
                return False
            
            # Vérifier le modèle User
            from models.user import User
            if hasattr(User, 'is_admin'):
                print("✅ Modèle User a l'attribut 'is_admin'")
            else:
                print("❌ Modèle User n'a PAS l'attribut 'is_admin'")
                return False
            
            # Vérifier les routes admin
            from routes import admin_routes
            print("✅ Routes admin importées avec succès")
            
            # Vérifier s'il y a déjà des admins
            admins = User.query.filter_by(is_admin=True).all()
            admin_count = len(admins)
            
            print("")
            print(f"👥 Nombre d'administrateurs dans la base: {admin_count}")
            
            if admin_count == 0:
                print("⚠️  Aucun administrateur trouvé")
                print("   Créez un admin avec: python scripts/create_admin.py")
            else:
                print("✅ Administrateurs existants:")
                for admin in admins:
                    print(f"   - {admin.email} (ID: {admin.id})")
            
            print("")
            print("✅ Configuration admin complète!")
            return True
            
        except Exception as e:
            print(f"❌ Erreur lors de la vérification: {str(e)}")
            import traceback
            traceback.print_exc()
            return False

if __name__ == '__main__':
    success = verify_admin_setup()
    if success:
        print("\n🎉 Tout est prêt! Vous pouvez créer un administrateur.")
    else:
        print("\n💥 Il y a un problème. Vérifiez les erreurs ci-dessus.")

