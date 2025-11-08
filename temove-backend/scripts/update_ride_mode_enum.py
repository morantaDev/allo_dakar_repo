"""
Script pour mettre à jour la colonne ride_mode ENUM dans MySQL
Ajoute les nouvelles valeurs : famille, premium, tiakTiak, voiture, express
"""
import sys
import os

# Ajouter le répertoire parent au path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app as create_app_from_app_py
from extensions import db
from sqlalchemy import text

def update_ride_mode_enum():
    """Mettre à jour la colonne ride_mode ENUM pour inclure toutes les valeurs"""
    # Utiliser app.py directement
    import sys
    import importlib.util
    spec = importlib.util.spec_from_file_location("app_module", "app.py")
    app_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app_module)
    app = app_module.create_app('development')
    
    with app.app_context():
        try:
            # Liste complète des valeurs ENUM pour ride_mode
            enum_values = [
                'eco',
                'confort',
                'confortPlus',
                'partageTaxi',
                'famille',
                'premium',
                'tiakTiak',
                'voiture',
                'express'
            ]
            
            # Créer la chaîne ENUM pour MySQL
            enum_string = "', '".join(enum_values)
            enum_string = f"'{enum_string}'"
            
            print(f"🔄 Mise à jour de la colonne ride_mode ENUM...")
            print(f"📋 Valeurs ENUM: {enum_values}")
            
            # Modifier la colonne ENUM
            sql = f"""
            ALTER TABLE rides 
            MODIFY COLUMN ride_mode ENUM({enum_string}) 
            NOT NULL DEFAULT 'confort'
            """
            
            print(f"📝 Exécution de la commande SQL...")
            db.session.execute(text(sql))
            db.session.commit()
            
            print("✅ Colonne ride_mode mise à jour avec succès!")
            print(f"✅ Toutes les valeurs sont maintenant disponibles: {enum_values}")
            
        except Exception as e:
            db.session.rollback()
            print(f"❌ Erreur lors de la mise à jour: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    return True

if __name__ == '__main__':
    print("🚀 Démarrage de la mise à jour de ride_mode ENUM...")
    success = update_ride_mode_enum()
    if success:
        print("✅ Mise à jour terminée avec succès!")
    else:
        print("❌ Échec de la mise à jour")
        sys.exit(1)

