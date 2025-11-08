"""
Script pour créer les tables nécessaires pour l'administration
- commissions
- revenues
"""
import sys
import os

# Ajouter le répertoire parent au path pour les imports
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, backend_dir)

# Changer le répertoire de travail
os.chdir(backend_dir)

try:
    import importlib.util
    
    app_py_path = os.path.join(backend_dir, "app.py")
    spec = importlib.util.spec_from_file_location("app_module", app_py_path)
    app_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(app_module)
    
    from extensions import db
    from sqlalchemy import text, inspect
    
    def create_admin_tables():
        """Créer les tables commissions et revenues"""
        app = app_module.create_app('development')
        
        with app.app_context():
            try:
                inspector = inspect(db.engine)
                existing_tables = inspector.get_table_names()
                
                print("🔧 Création des tables admin...")
                print("")
                
                # Obtenir le type de base de données
                db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
                is_mysql = 'mysql' in db_uri or 'mariadb' in db_uri
                is_postgres = 'postgresql' in db_uri or 'postgres' in db_uri
                is_sqlite = 'sqlite' in db_uri
                
                print(f"📊 Base de données détectée: {'MySQL' if is_mysql else 'PostgreSQL' if is_postgres else 'SQLite'}")
                print("")
                
                # Créer la table commissions
                if 'commissions' not in existing_tables:
                    print("📝 Création de la table 'commissions'...")
                    if is_mysql:
                        db.session.execute(text("""
                            CREATE TABLE commissions (
                                id INTEGER AUTO_INCREMENT PRIMARY KEY,
                                ride_id INTEGER NOT NULL UNIQUE,
                                driver_id INTEGER NOT NULL,
                                ride_price INTEGER NOT NULL,
                                platform_commission INTEGER NOT NULL,
                                driver_earnings INTEGER NOT NULL,
                                service_fee INTEGER NOT NULL DEFAULT 0,
                                commission_rate FLOAT NOT NULL,
                                base_commission INTEGER NOT NULL,
                                surge_commission INTEGER NOT NULL DEFAULT 0,
                                base_price INTEGER NOT NULL,
                                surge_amount INTEGER NOT NULL DEFAULT 0,
                                status VARCHAR(50) NOT NULL DEFAULT 'pending',
                                paid_at DATETIME NULL,
                                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
                                FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE,
                                INDEX idx_commissions_driver_id (driver_id),
                                INDEX idx_commissions_ride_id (ride_id)
                            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                        """))
                    elif is_postgres:
                        db.session.execute(text("""
                            CREATE TABLE commissions (
                                id SERIAL PRIMARY KEY,
                                ride_id INTEGER NOT NULL UNIQUE,
                                driver_id INTEGER NOT NULL,
                                ride_price INTEGER NOT NULL,
                                platform_commission INTEGER NOT NULL,
                                driver_earnings INTEGER NOT NULL,
                                service_fee INTEGER NOT NULL DEFAULT 0,
                                commission_rate FLOAT NOT NULL,
                                base_commission INTEGER NOT NULL,
                                surge_commission INTEGER NOT NULL DEFAULT 0,
                                base_price INTEGER NOT NULL,
                                surge_amount INTEGER NOT NULL DEFAULT 0,
                                status VARCHAR(50) NOT NULL DEFAULT 'pending',
                                paid_at TIMESTAMP NULL,
                                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
                                FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
                            )
                        """))
                        db.session.execute(text("CREATE INDEX idx_commissions_driver_id ON commissions(driver_id)"))
                        db.session.execute(text("CREATE INDEX idx_commissions_ride_id ON commissions(ride_id)"))
                    else:  # SQLite
                        db.session.execute(text("""
                            CREATE TABLE commissions (
                                id INTEGER PRIMARY KEY AUTOINCREMENT,
                                ride_id INTEGER NOT NULL UNIQUE,
                                driver_id INTEGER NOT NULL,
                                ride_price INTEGER NOT NULL,
                                platform_commission INTEGER NOT NULL,
                                driver_earnings INTEGER NOT NULL,
                                service_fee INTEGER NOT NULL DEFAULT 0,
                                commission_rate REAL NOT NULL,
                                base_commission INTEGER NOT NULL,
                                surge_commission INTEGER NOT NULL DEFAULT 0,
                                base_price INTEGER NOT NULL,
                                surge_amount INTEGER NOT NULL DEFAULT 0,
                                status TEXT NOT NULL DEFAULT 'pending',
                                paid_at DATETIME NULL,
                                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                FOREIGN KEY (ride_id) REFERENCES rides(id) ON DELETE CASCADE,
                                FOREIGN KEY (driver_id) REFERENCES drivers(id) ON DELETE CASCADE
                            )
                        """))
                        db.session.execute(text("CREATE INDEX idx_commissions_driver_id ON commissions(driver_id)"))
                        db.session.execute(text("CREATE INDEX idx_commissions_ride_id ON commissions(ride_id)"))
                    
                    print("✅ Table 'commissions' créée")
                else:
                    print("✅ Table 'commissions' existe déjà")
                
                # Créer la table revenues
                if 'revenues' not in existing_tables:
                    print("📝 Création de la table 'revenues'...")
                    if is_mysql:
                        db.session.execute(text("""
                            CREATE TABLE revenues (
                                id INTEGER AUTO_INCREMENT PRIMARY KEY,
                                year INTEGER NOT NULL,
                                month INTEGER NOT NULL,
                                commission_revenue INTEGER NOT NULL DEFAULT 0,
                                premium_revenue INTEGER NOT NULL DEFAULT 0,
                                driver_subscription_revenue INTEGER NOT NULL DEFAULT 0,
                                service_fees_revenue INTEGER NOT NULL DEFAULT 0,
                                delivery_revenue INTEGER NOT NULL DEFAULT 0,
                                partnership_revenue INTEGER NOT NULL DEFAULT 0,
                                other_revenue INTEGER NOT NULL DEFAULT 0,
                                total_revenue INTEGER NOT NULL,
                                rides_count INTEGER NOT NULL DEFAULT 0,
                                active_users INTEGER NOT NULL DEFAULT 0,
                                active_drivers INTEGER NOT NULL DEFAULT 0,
                                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                UNIQUE KEY _year_month_uc (year, month),
                                INDEX idx_revenues_year_month (year, month)
                            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
                        """))
                    elif is_postgres:
                        db.session.execute(text("""
                            CREATE TABLE revenues (
                                id SERIAL PRIMARY KEY,
                                year INTEGER NOT NULL,
                                month INTEGER NOT NULL,
                                commission_revenue INTEGER NOT NULL DEFAULT 0,
                                premium_revenue INTEGER NOT NULL DEFAULT 0,
                                driver_subscription_revenue INTEGER NOT NULL DEFAULT 0,
                                service_fees_revenue INTEGER NOT NULL DEFAULT 0,
                                delivery_revenue INTEGER NOT NULL DEFAULT 0,
                                partnership_revenue INTEGER NOT NULL DEFAULT 0,
                                other_revenue INTEGER NOT NULL DEFAULT 0,
                                total_revenue INTEGER NOT NULL,
                                rides_count INTEGER NOT NULL DEFAULT 0,
                                active_users INTEGER NOT NULL DEFAULT 0,
                                active_drivers INTEGER NOT NULL DEFAULT 0,
                                created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                UNIQUE (year, month)
                            )
                        """))
                        db.session.execute(text("CREATE INDEX idx_revenues_year_month ON revenues(year, month)"))
                    else:  # SQLite
                        db.session.execute(text("""
                            CREATE TABLE revenues (
                                id INTEGER PRIMARY KEY AUTOINCREMENT,
                                year INTEGER NOT NULL,
                                month INTEGER NOT NULL,
                                commission_revenue INTEGER NOT NULL DEFAULT 0,
                                premium_revenue INTEGER NOT NULL DEFAULT 0,
                                driver_subscription_revenue INTEGER NOT NULL DEFAULT 0,
                                service_fees_revenue INTEGER NOT NULL DEFAULT 0,
                                delivery_revenue INTEGER NOT NULL DEFAULT 0,
                                partnership_revenue INTEGER NOT NULL DEFAULT 0,
                                other_revenue INTEGER NOT NULL DEFAULT 0,
                                total_revenue INTEGER NOT NULL,
                                rides_count INTEGER NOT NULL DEFAULT 0,
                                active_users INTEGER NOT NULL DEFAULT 0,
                                active_drivers INTEGER NOT NULL DEFAULT 0,
                                created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                UNIQUE (year, month)
                            )
                        """))
                        db.session.execute(text("CREATE INDEX idx_revenues_year_month ON revenues(year, month)"))
                    
                    print("✅ Table 'revenues' créée")
                else:
                    print("✅ Table 'revenues' existe déjà")
                
                db.session.commit()
                print("")
                print("✅ Toutes les tables admin ont été créées/vérifiées avec succès!")
                
            except Exception as e:
                db.session.rollback()
                print(f"\n❌ Erreur lors de la création des tables: {str(e)}")
                print(f"   Type d'erreur: {type(e).__name__}")
                import traceback
                traceback.print_exc()
                return False
        
        return True
    
    if __name__ == '__main__':
        print("🔧 Création des tables admin (commissions, revenues)...")
        print("")
        success = create_admin_tables()
        
        if success:
            print("\n🎉 Opération terminée avec succès!")
        else:
            print("\n💥 L'opération a échoué. Vérifiez les erreurs ci-dessus.")
            sys.exit(1)
        
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

