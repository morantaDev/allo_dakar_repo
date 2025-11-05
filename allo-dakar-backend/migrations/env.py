from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from dotenv import load_dotenv
import os
import sys

# Charger .env
load_dotenv()

# Config Alembic
config = context.config
fileConfig(config.config_file_name)

# Importer app.py (pas app/__init__.py) pour utiliser la bonne factory
# Note: On doit importer app.py directement, pas le package app
import app as app_module
from extensions import db

# Créer l'app Flask avec la configuration de développement
app = app_module.create_app('development')

# Les modèles sont déjà importés dans app.py lors de la création de l'app
# Mais on les importe aussi ici pour s'assurer qu'ils sont bien chargés
# Metadata pour autogenerate - doit être défini après que les modèles soient importés
target_metadata = db.metadata

def run_migrations_online():
    # ⚠️ Créer un contexte d'application pour que db.engine soit disponible
    with app.app_context():
        connectable = db.engine
        with connectable.connect() as connection:
            context.configure(
                connection=connection,
                target_metadata=target_metadata
            )
            with context.begin_transaction():
                context.run_migrations()

run_migrations_online()
