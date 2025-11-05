"""
Script pour corriger la colonne ride_mode ENUM dans MySQL
Utilise les NOMS des enums Python (majuscules) au lieu des valeurs
"""
import sys
import os

# Ajouter le répertoire parent au path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def fix_ride_mode_enum():
    """Corriger la colonne ride_mode ENUM pour utiliser les noms d'enums"""
    import sys
    import importlib.util
    spec = importlib.util.spec_from_file_location("app_module", "app.py")
    app_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app_module)
    app = app_module.create_app('development')
    
    with app.app_context():
        from extensions import db
        from sqlalchemy import text
        from models.ride import RideMode
        
        try:
            # Utiliser les NOMS des enums Python (majuscules) pour MySQL ENUM
            enum_names = [mode.name for mode in RideMode]  # ['ECO', 'CONFORT', etc.]
            
            print(f"🔄 Correction de la colonne ride_mode ENUM...")
            print(f"📋 Noms ENUM: {enum_names}")
            
            # Créer la chaîne ENUM pour MySQL avec les noms
            enum_string = "', '".join(enum_names)
            enum_string = f"'{enum_string}'"
            
            # Modifier la colonne ENUM pour utiliser les noms
            sql = f"""
            ALTER TABLE rides 
            MODIFY COLUMN ride_mode ENUM({enum_string}) 
            NOT NULL DEFAULT 'CONFORT'
            """
            
            print(f"📝 Exécution de la commande SQL...")
            db.session.execute(text(sql))
            db.session.commit()
            
            print("✅ Colonne ride_mode corrigée avec succès!")
            print(f"✅ Utilisation des noms d'enums: {enum_names}")
            
            # Mettre à jour les données existantes pour utiliser les noms
            print("\n🔄 Mise à jour des données existantes...")
            update_mapping = {
                'eco': 'ECO',
                'confort': 'CONFORT',
                'confortPlus': 'CONFORT_PLUS',
                'partageTaxi': 'PARTAGE_TAXI',
                'famille': 'FAMILLE',
                'premium': 'PREMIUM',
                'tiakTiak': 'TIAK_TIAK',
                'voiture': 'VOITURE',
                'express': 'EXPRESS'
            }
            
            for old_value, new_value in update_mapping.items():
                update_sql = f"UPDATE rides SET ride_mode = '{new_value}' WHERE ride_mode = '{old_value}'"
                try:
                    result = db.session.execute(text(update_sql))
                    if result.rowcount > 0:
                        print(f"  ✅ {result.rowcount} ligne(s) mise(s) à jour: {old_value} -> {new_value}")
                    db.session.commit()
                except Exception as e:
                    db.session.rollback()
                    print(f"  ⚠️ Erreur lors de la mise à jour {old_value}: {e}")
            
            print("\n✅ Correction terminée avec succès!")
            
        except Exception as e:
            db.session.rollback()
            print(f"❌ Erreur lors de la correction: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    return True

if __name__ == '__main__':
    print("🚀 Démarrage de la correction de ride_mode ENUM...")
    success = fix_ride_mode_enum()
    if success:
        print("✅ Correction terminée avec succès!")
    else:
        print("❌ Échec de la correction")
        sys.exit(1)

