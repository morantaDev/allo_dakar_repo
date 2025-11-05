"""
Script pour visualiser les utilisateurs dans MySQL
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
from models.user import User

def view_users():
    """Afficher tous les utilisateurs"""
    app = app_module.create_app('development')
    
    with app.app_context():
        users = User.query.all()
        
        print("\n" + "="*80)
        print("👥 UTILISATEURS DANS MYSQL (temove_db)")
        print("="*80)
        
        if not users:
            print("❌ Aucun utilisateur trouvé")
            return
        
        for user in users:
            print(f"\n📧 Email: {user.email}")
            print(f"   👤 Nom: {user.name or user.full_name}")
            print(f"   📝 Full Name: {user.full_name}")
            print(f"   📱 Téléphone: {user.phone or 'Non renseigné'}")
            print(f"   🎭 Rôle: {user.role}")
            print(f"   💰 Crédit: {user.credit_balance} XOF")
            print(f"   ✅ Actif: {'Oui' if user.is_active else 'Non'}")
            print(f"   ✉️ Vérifié: {'Oui' if user.is_verified else 'Non'}")
            print(f"   📅 Créé le: {user.created_at}")
            print("-" * 80)
        
        print(f"\n📊 Total: {len(users)} utilisateur(s)")
        print("="*80 + "\n")

if __name__ == '__main__':
    view_users()

