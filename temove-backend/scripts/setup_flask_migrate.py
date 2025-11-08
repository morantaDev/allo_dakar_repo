"""
Script pour configurer Flask-Migrate si nécessaire
Alternative: utilisez add_is_admin_column.py qui ne nécessite pas Flask-Migrate
"""
import sys
import os

# Ajouter le répertoire parent au path pour les imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def setup_flask_migrate():
    """Configurer Flask-Migrate"""
    print("🔧 Configuration de Flask-Migrate...")
    print("")
    
    # Vérifier si le dossier migrations existe
    migrations_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'migrations')
    
    if not os.path.exists(migrations_dir):
        print("📁 Création du dossier 'migrations'...")
        os.makedirs(migrations_dir, exist_ok=True)
        print("✅ Dossier créé")
    
    # Créer un fichier .flaskenv si il n'existe pas
    flaskenv_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.flaskenv')
    
    if not os.path.exists(flaskenv_path):
        print("📝 Création du fichier '.flaskenv'...")
        with open(flaskenv_path, 'w') as f:
            f.write("FLASK_APP=app.py\n")
            f.write("FLASK_ENV=development\n")
        print("✅ Fichier '.flaskenv' créé")
        print("   FLASK_APP=app.py")
        print("   FLASK_ENV=development")
    else:
        print("✅ Fichier '.flaskenv' existe déjà")
    
    print("")
    print("📋 Prochaines étapes:")
    print("   1. Assurez-vous que Flask-Migrate est installé:")
    print("      pip install Flask-Migrate")
    print("")
    print("   2. Initialisez Flask-Migrate (si pas déjà fait):")
    print("      flask db init")
    print("")
    print("   3. Créez une migration:")
    print("      flask db migrate -m 'Add is_admin field to users'")
    print("")
    print("   4. Appliquez la migration:")
    print("      flask db upgrade")
    print("")
    print("💡 Alternative: Utilisez le script add_is_admin_column.py")
    print("   qui ajoute directement la colonne sans Flask-Migrate:")
    print("   python scripts/add_is_admin_column.py")

if __name__ == '__main__':
    setup_flask_migrate()

