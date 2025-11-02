from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app import create_app, db
from dotenv import load_dotenv
import os

# Charger .env
load_dotenv()

# Config Alembic
config = context.config
fileConfig(config.config_file_name)

# Créer l'app Flask
app = create_app()

# Metadata pour autogenerate
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
