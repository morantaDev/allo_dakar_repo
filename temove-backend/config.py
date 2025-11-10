"""
Configuration pour l'application TeMove Backend
"""
import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()


class Config:
    """Configuration de base"""
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'allo-dakar-secret-key-change-in-production'
    # Configuration de la base de données
    # Format MySQL: mysql+pymysql://user:password@host:port/database
    # Si DATABASE_URL n'est pas défini, utiliser MySQL par défaut
    _default_mysql_url = 'mysql+pymysql://root:1234@localhost:3306/temove_db'
    _default_db_path = os.path.join('instance', 'allo_dakar.db')
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or _default_mysql_url
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # JWT Configuration
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or SECRET_KEY
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=24)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    
    # CORS Configuration
    # Accepter toutes les origines localhost pour Flutter Web (port dynamique)
    CORS_ORIGINS = os.environ.get('CORS_ORIGINS', '*').split(',') if os.environ.get('CORS_ORIGINS') else ['*']
    
    # App Configuration
    API_PREFIX = '/api/v1'
    
    # Pricing Configuration (XOF par kilomètre)
    PRICING = {
        'eco': 300,  # 300 XOF/km
        'confort': 500,  # 500 XOF/km
        'confortPlus': 800,  # 800 XOF/km
        'partageTaxi': 200,  # 200 XOF/km
        'famille': 600,  # 600 XOF/km
        'premium': 1000,  # 1000 XOF/km
        # Modes de livraison
        'tiakTiak': 200,  # 200 XOF/km (moto)
        'voiture': 400,  # 400 XOF/km (livraison standard)
        'express': 600,  # 600 XOF/km (livraison express)
        'base_fare': 500,  # Frais de base
    }
    
    # Referral Configuration
    REFERRAL_REWARD = 1000  # XOF
    REFERRAL_CODE_LENGTH = 8
    
    # Loyalty Configuration
    POINTS_PER_100_XOF = 1  # 1 point pour 100 XOF
    LOYALTY_LEVELS = {
        1: {'name': 'Membre', 'points': 0},
        2: {'name': 'VIP Bronze', 'points': 100},
        3: {'name': 'VIP Silver', 'points': 300},
        4: {'name': 'VIP Gold', 'points': 600},
        5: {'name': 'VIP Platinum', 'points': 1000},
    }
    
    # Google Maps API (optionnel pour calculs de distance)
    GOOGLE_MAPS_API_KEY = os.environ.get('GOOGLE_MAPS_API_KEY', '')


class DevelopmentConfig(Config):
    """Configuration pour le développement"""
    DEBUG = True
    SQLALCHEMY_ECHO = True
    # Activer TOTP pour les tests locaux (codes basés sur le temps)
    USE_TOTP_LOCAL = True


class ProductionConfig(Config):
    """Configuration pour la production"""
    DEBUG = False
    SQLALCHEMY_ECHO = False


class TestingConfig(Config):
    """Configuration pour les tests"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'


config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}

