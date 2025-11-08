"""
Script d'initialisation de la base de données avec des données de test
"""
from datetime import datetime, timedelta, timezone
from flask import Flask
from extensions import db
import config as project_config


def init_db():
    """Initialiser la base de données sans importer le package `app`.

    The repository contains two different model sets: `app.models` and the
    top-level `models` package. Importing the `app` package (its factory)
    pulls in `app.models` which defines tables with the same names as the
    top-level `models` package, causing duplicate table definitions.

    To avoid that, create a minimal Flask app here and configure it from
    the project's `config` module so we only import the top-level models.
    """
    # Create a minimal Flask app and load the development config
    app = Flask(__name__)
    app.config.from_object(project_config.config['development'])

    # S'assurer que le dossier instance/ existe pour SQLite
    db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    if db_uri.startswith('sqlite:///'):
        db_path = db_uri.replace('sqlite:///', '')
        if db_path and not db_path.startswith(':memory:'):
            import os
            db_dir = os.path.dirname(db_path)
            if db_dir and not os.path.exists(db_dir):
                os.makedirs(db_dir, exist_ok=True)
                print(f"✓ Dossier créé: {db_dir}")

    # Initialize the shared extensions with this app
    db.init_app(app)

    # Import models and create tables inside the app context
    with app.app_context():
        # Import all top-level models so they're registered with `extensions.db`
        from models import (
            User, Ride, Driver, Payment, PaymentMethod, PaymentStatus,
            PromoCode, PromoType, ReferralCode, ReferralReward,
            LoyaltyPoints, UserBadge, BadgeType, Rating
        )

        # Créer les tables
        db.create_all()
        
        print("✓ Tables créées")
        
        # Créer des codes promo de test
        if PromoCode.query.count() == 0:
            promo_codes = [
                PromoCode(
                    code='BIENVENUE10',
                    description='10% de réduction sur votre première course',
                    promo_type=PromoType.PERCENTAGE,
                    value=10,
                    expiry_date=datetime.now(timezone.utc) + timedelta(days=30),
                    is_active=True,
                ),
                PromoCode(
                    code='DAKAR500',
                    description='500 XOF de réduction',
                    promo_type=PromoType.FIXED_AMOUNT,
                    value=500,
                    expiry_date=datetime.now(timezone.utc) + timedelta(days=7),
                    max_uses=1000,
                    is_active=True,
                ),
                PromoCode(
                    code='WEEKEND20',
                    description='20% de réduction ce week-end',
                    promo_type=PromoType.PERCENTAGE,
                    value=20,
                    expiry_date=datetime.now(timezone.utc) + timedelta(days=2),
                    is_active=True,
                ),
            ]
            
            for promo in promo_codes:
                db.session.add(promo)
            
            db.session.commit()
            print("✓ Codes promo créés")
        
        print("\n✅ Base de données initialisée avec succès!")
        print("\nVous pouvez maintenant lancer l'API avec: python app.py")

if __name__ == '__main__':
    init_db()

