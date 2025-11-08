"""
Extensions Flask (initialisées ici pour éviter les imports circulaires)
"""
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate

db = SQLAlchemy()
migrate = Migrate()

