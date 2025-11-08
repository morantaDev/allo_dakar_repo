"""
Script pour créer un utilisateur administrateur
"""
import sys
import os

# Ajouter le répertoire parent au path pour les imports
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

# Changer le répertoire de travail pour que les imports fonctionnent
os.chdir(backend_dir)

try:
    # Importer depuis le fichier app.py (pas le module app/)
    import importlib.util
    
    app_py_path = os.path.join(backend_dir, "app.py")
    if not os.path.exists(app_py_path):
        print(f"❌ Fichier app.py non trouvé dans: {backend_dir}")
        sys.exit(1)
    
    spec = importlib.util.spec_from_file_location("app_module", app_py_path)
    app_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app_module)
    
    from extensions import db
    from models.user import User
    
    def create_admin():
        """Créer un utilisateur administrateur"""
        # Utiliser create_app depuis app.py (qui prend config_name)
        app = app_module.create_app('development')
        
        with app.app_context():
            # Informations de l'admin
            admin_email = input("Email de l'administrateur (par défaut: admin@temove.sn): ").strip()
            if not admin_email:
                admin_email = "admin@temove.sn"
            
            admin_password = input("Mot de passe (laissez vide pour générer un mot de passe sécurisé): ").strip()
            if not admin_password:
                import secrets
                admin_password = secrets.token_urlsafe(16)
                print(f"\n✅ Mot de passe généré: {admin_password}")
                print("⚠️  IMPORTANT: Notez ce mot de passe dans un endroit sûr!\n")
            
            admin_name = input("Nom complet (par défaut: Administrateur): ").strip()
            if not admin_name:
                admin_name = "Administrateur"
            
            # Vérifier si l'admin existe déjà
            existing_admin = User.query.filter_by(email=admin_email).first()
            
            if existing_admin:
                # Mettre à jour l'utilisateur existant
                existing_admin.is_admin = True
                existing_admin.is_active = True
                existing_admin.is_verified = True
                if admin_password:
                    existing_admin.set_password(admin_password)
                print(f"✅ Utilisateur {admin_email} est maintenant administrateur")
            else:
                # Créer un nouvel admin
                admin = User(
                    email=admin_email,
                    full_name=admin_name,
                    name=admin_name,
                    is_admin=True,
                    is_active=True,
                    is_verified=True
                )
                admin.set_password(admin_password)
                db.session.add(admin)
                print(f"✅ Administrateur créé : {admin_email}")
            
            db.session.commit()
            print("\n✅ Opération réussie!")
            print(f"📧 Email: {admin_email}")
            print(f"👤 Nom: {admin_name}")
            print(f"🔑 Mot de passe: {'(défini ci-dessus)' if len(admin_password) > 20 else '******'}")
            print("\n🌐 Vous pouvez maintenant vous connecter avec ces identifiants sur le dashboard admin.")

    if __name__ == '__main__':
        create_admin()
        
except ModuleNotFoundError as e:
    print(f"❌ Module non trouvé: {e}")
    print("\n💡 Assurez-vous que:")
    print("   1. L'environnement virtuel est activé: .\\venv\\Scripts\\Activate.ps1")
    print("   2. Les dépendances sont installées: pip install -r requirements.txt")
    sys.exit(1)
except Exception as e:
    print(f"❌ Erreur: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

