"""
Script pour créer un profil chauffeur pour un utilisateur existant
Usage: python scripts/create_driver_profile.py <email> <license_number>
"""

import sys
import os

# Ajouter le dossier parent au path pour importer les modules
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Imports selon la structure du projet
# Utiliser app.py qui a create_app(config_name)
import importlib.util
spec = importlib.util.spec_from_file_location("app_module", "app.py")
app_module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app_module)

from extensions import db
from models import User, Driver, Vehicle

def create_driver_profile(email, license_number, car_make="Toyota", car_model="Corolla", car_plate="ABC-123", car_color="Blanc"):
    """
    Créer un profil chauffeur pour un utilisateur existant
    
    Args:
        email: Email de l'utilisateur
        license_number: Numéro de permis de conduire
        car_make: Marque du véhicule (par défaut: Toyota)
        car_model: Modèle du véhicule (par défaut: Corolla)
        car_plate: Plaque d'immatriculation (par défaut: ABC-123)
        car_color: Couleur du véhicule (par défaut: Blanc)
    """
    app = app_module.create_app('development')
    
    with app.app_context():
        # Trouver l'utilisateur
        user = User.query.filter_by(email=email).first()
        
        if not user:
            print(f"❌ Utilisateur avec l'email '{email}' non trouvé!")
            return False
        
        # Vérifier si l'utilisateur a déjà un profil chauffeur
        existing_driver = Driver.query.filter_by(user_id=user.id).first()
        if existing_driver:
            print(f"⚠️  L'utilisateur '{email}' a déjà un profil chauffeur (ID: {existing_driver.id})")
            return False
        
        try:
            # Créer le profil chauffeur
            driver = Driver(
                user_id=user.id,
                license_number=license_number,
                status='offline'
            )
            db.session.add(driver)
            db.session.flush()  # Pour obtenir l'ID
            
            # Créer le véhicule
            vehicle = Vehicle(
                driver_id=driver.id,
                make=car_make,
                model=car_model,
                plate=car_plate,
                color=car_color
            )
            db.session.add(vehicle)
            db.session.flush()
            
            # Lier le véhicule au chauffeur
            driver.vehicle_id = vehicle.id
            
            # Mettre à jour le rôle de l'utilisateur
            user.role = 'driver'
            
            # Commit les changements
            db.session.commit()
            
            print(f"✅ Profil chauffeur créé avec succès!")
            print(f"   - Utilisateur: {user.full_name} ({user.email})")
            print(f"   - Chauffeur ID: {driver.id}")
            print(f"   - Véhicule: {car_make} {car_model} ({car_plate})")
            print(f"   - Permis: {license_number}")
            
            return True
            
        except Exception as e:
            db.session.rollback()
            print(f"❌ Erreur lors de la création du profil chauffeur: {e}")
            import traceback
            traceback.print_exc()
            return False

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python scripts/create_driver_profile.py <email> <license_number> [car_make] [car_model] [car_plate] [car_color]")
        print("\nExemple:")
        print("  python scripts/create_driver_profile.py morantadev@gmail.com DL-12345")
        print("  python scripts/create_driver_profile.py morantadev@gmail.com DL-12345 Toyota Corolla ABC-123 Blanc")
        sys.exit(1)
    
    email = sys.argv[1]
    license_number = sys.argv[2]
    car_make = sys.argv[3] if len(sys.argv) > 3 else "Toyota"
    car_model = sys.argv[4] if len(sys.argv) > 4 else "Corolla"
    car_plate = sys.argv[5] if len(sys.argv) > 5 else "ABC-123"
    car_color = sys.argv[6] if len(sys.argv) > 6 else "Blanc"
    
    success = create_driver_profile(email, license_number, car_make, car_model, car_plate, car_color)
    sys.exit(0 if success else 1)

