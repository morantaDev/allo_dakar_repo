"""
Script pour visualiser les utilisateurs dans la base de données
"""
import sys
import os
import importlib.util

# Ajouter le répertoire parent au path
root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, root_dir)

# Charger app.py directement
spec = importlib.util.spec_from_file_location("app_module", os.path.join(root_dir, "app.py"))
app_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app_module)

from extensions import db
from models.user import User
from models.referral import ReferralCode
from models.loyalty import LoyaltyPoints

def view_users():
    """Afficher tous les utilisateurs"""
    app = app_module.create_app('development')
    
    with app.app_context():
        users = User.query.all()
        
        print("\n" + "="*80)
        print("👥 UTILISATEURS DANS LA BASE DE DONNÉES")
        print("="*80)
        
        if not users:
            print("❌ Aucun utilisateur trouvé")
            return
        
        for user in users:
            print(f"\n📧 Email: {user.email}")
            print(f"   👤 Nom: {user.full_name}")
            print(f"   📱 Téléphone: {user.phone or 'Non renseigné'}")
            print(f"   💰 Crédit: {user.credit_balance} XOF")
            print(f"   ✅ Actif: {'Oui' if user.is_active else 'Non'}")
            print(f"   ✉️ Vérifié: {'Oui' if user.is_verified else 'Non'}")
            print(f"   📅 Créé le: {user.created_at}")
            
            # Code de parrainage
            referral = ReferralCode.query.filter_by(user_id=user.id).first()
            if referral:
                print(f"   🎁 Code de parrainage: {referral.code}")
            
            # Points de fidélité
            loyalty = LoyaltyPoints.query.filter_by(user_id=user.id).first()
            if loyalty:
                print(f"   ⭐ Points: {loyalty.points} (Niveau {loyalty.level})")
            
            print("-" * 80)
        
        print(f"\n📊 Total: {len(users)} utilisateur(s)")
        print("="*80 + "\n")

if __name__ == '__main__':
    view_users()

