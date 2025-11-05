"""
Application principale Flask pour Allo Dakar
"""
from flask import Flask, jsonify, request
from flask_cors import CORS
from flask_jwt_extended import JWTManager, decode_token
from werkzeug.exceptions import UnprocessableEntity
from datetime import datetime
from config import config

# Import des extensions
from extensions import db, migrate


def create_app(config_name='default'):
    """Factory pour créer l'application Flask"""
    app = Flask(__name__)
    
    # Configuration
    app.config.from_object(config[config_name])
    
    # S'assurer que le dossier instance/ existe pour SQLite
    db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
    if db_uri.startswith('sqlite:///'):
        db_path = db_uri.replace('sqlite:///', '')
        if db_path and not db_path.startswith(':memory:'):
            import os
            db_dir = os.path.dirname(db_path)
            if db_dir and not os.path.exists(db_dir):
                os.makedirs(db_dir, exist_ok=True)
    
    # Initialiser les extensions
    db.init_app(app)
    migrate.init_app(app, db)
    
    # Importer les modèles pour qu'ils soient enregistrés avec db.metadata
    # Cela permet à Flask-Migrate et Alembic de détecter automatiquement les changements
    # Les modèles peuvent être importés sans contexte d'application
    from models import (
        User, Ride, Driver, Payment, PaymentMethod, PaymentStatus,
        PromoCode, PromoType, ReferralCode, ReferralReward,
        LoyaltyPoints, UserBadge, BadgeType, Rating
    )
    
    # Créer automatiquement toutes les tables au démarrage
    with app.app_context():
        try:
            # Créer la base de données si elle n'existe pas (pour MySQL)
            db_uri = app.config.get('SQLALCHEMY_DATABASE_URI', '')
            if db_uri.startswith('mysql'):
                # Extraire le nom de la base de données
                from urllib.parse import urlparse
                import pymysql
                
                parsed_uri = urlparse(db_uri)
                database_name = parsed_uri.path.lstrip('/')
                username = parsed_uri.username
                password = parsed_uri.password
                host = parsed_uri.hostname
                port = parsed_uri.port or 3306
                
                # Se connecter à MySQL sans spécifier la base
                connection = pymysql.connect(
                    host=host,
                    port=port,
                    user=username,
                    password=password,
                    charset='utf8mb4'
                )
                
                try:
                    with connection.cursor() as cursor:
                        # Créer la base de données si elle n'existe pas
                        cursor.execute(f"CREATE DATABASE IF NOT EXISTS `{database_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci")
                        app.logger.info(f"✅ Base de données '{database_name}' vérifiée/créée")
                finally:
                    connection.close()
            
            # Créer toutes les tables
            db.create_all()
            app.logger.info("✅ Toutes les tables ont été créées/vérifiées dans MySQL")
        except Exception as e:
            app.logger.error(f"❌ Erreur lors de la création des tables: {str(e)}")
            import traceback
            app.logger.error(traceback.format_exc())
            # Ne pas bloquer le démarrage si les tables existent déjà
    
    # JWT
    jwt = JWTManager(app)
    
    # Afficher la clé secrète JWT utilisée (premiers 20 caractères pour debug)
    jwt_secret = app.config.get('JWT_SECRET_KEY', 'NON CONFIGURÉ')
    print(f"🔑 [JWT_CONFIG] JWT_SECRET_KEY configuré: {str(jwt_secret)[:20]}...")
    print(f"🔑 [JWT_CONFIG] JWT_SECRET_KEY longueur: {len(str(jwt_secret))}")
    
    # Handler d'erreur JWT personnalisé pour retourner 401 au lieu de 422
    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        print(f"❌ [JWT] Token expiré - En-tête: {jwt_header}, Données: {jwt_payload}")
        auth_header = request.headers.get('Authorization', 'NON FOURNI') if hasattr(request, 'headers') else 'Non disponible'
        print(f"❌ [JWT] En-tête Authorization: {auth_header[:50] if len(auth_header) > 50 else auth_header}")
        return jsonify({'error': 'Token expiré. Veuillez vous reconnecter.'}), 401
    
    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        import sys
        print(f"❌ [JWT] Token invalide - Erreur: {error}", flush=True)
        print(f"❌ [JWT] Type d'erreur: {type(error)}", flush=True)
        print(f"❌ [JWT] URL: {request.url if hasattr(request, 'url') else 'Non disponible'}", flush=True)
        if hasattr(request, 'headers'):
            auth_header = request.headers.get('Authorization', 'NON FOURNI')
            print(f"❌ [JWT] En-tête Authorization: {auth_header[:50] if len(auth_header) > 50 else auth_header}", flush=True)
            print(f"❌ [JWT] Tous les en-têtes: {list(request.headers.keys())}", flush=True)
            if auth_header != 'NON FOURNI':
                token = auth_header.replace('Bearer ', '').strip()
                print(f"❌ [JWT] Token (premiers 50 caractères): {token[:50]}...", flush=True)
                print(f"❌ [JWT] Longueur du token: {len(token)}", flush=True)
                # Essayer de décoder pour voir l'erreur exacte
                try:
                    from flask_jwt_extended import decode_token
                    decoded = decode_token(token)
                    print(f"❌ [JWT] Token décodé (ne devrait pas arriver ici): {decoded}", flush=True)
                except Exception as decode_error:
                    print(f"❌ [JWT] Erreur de décodage: {decode_error}", flush=True)
                    import traceback
                    traceback.print_exc()
                    sys.stdout.flush()
        sys.stdout.flush()
        return jsonify({'error': 'Token JWT invalide ou expiré. Veuillez vous reconnecter.'}), 401
    
    @jwt.unauthorized_loader
    def missing_token_callback(error):
        print(f"❌ [JWT] Token manquant - Erreur: {error}")
        if hasattr(request, 'headers'):
            auth_header = request.headers.get('Authorization', 'NON FOURNI')
            print(f"❌ [JWT] En-tête Authorization: {auth_header[:50] if len(auth_header) > 50 else auth_header}")
            print(f"❌ [JWT] Tous les en-têtes: {list(request.headers.keys())}")
        return jsonify({'error': 'Token manquant. Veuillez vous connecter.'}), 401
    
    # Handler pour les erreurs de décodage JWT
    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        return False  # On ne gère pas encore la révocation de tokens
    
    
    # Middleware pour intercepter TOUTES les erreurs Werkzeug (AVANT les handlers JWT)
    @app.errorhandler(422)
    def handle_422_error(error):
        """Intercepter les erreurs 422 et les convertir en 401 si c'est JWT"""
        import sys
        print(f"🚨 [422_HANDLER] Erreur 422 interceptée", flush=True)
        
        path = request.path if hasattr(request, 'path') else ''
        protected_routes = ['/rides/', '/users/', '/referral/', '/loyalty/', '/ratings/', '/promo/']
        is_protected_route = any(route in path for route in protected_routes)
        
        if hasattr(request, 'headers'):
            auth_header = request.headers.get('Authorization', 'NON FOURNI')
            if is_protected_route and auth_header != 'NON FOURNI':
                print(f"🚨 [422_HANDLER] Route protégée avec token - Conversion en 401", flush=True)
                sys.stdout.flush()
                return jsonify({'error': 'Token JWT invalide ou expiré. Veuillez vous reconnecter.'}), 401
        
        # Pour les autres erreurs 422, retourner l'erreur standard
        error_msg = error.description if hasattr(error, 'description') else str(error)
        return jsonify({'error': error_msg}), 422
    
    # Handler spécifique pour UnprocessableEntity
    @app.errorhandler(UnprocessableEntity)
    def handle_unprocessable_entity(error):
        """Intercepter UnprocessableEntity et les convertir en 401 si JWT"""
        import sys
        print(f"🚨 [UNPROCESSABLE] Erreur interceptée", flush=True)
        
        path = request.path if hasattr(request, 'path') else ''
        protected_routes = ['/rides/', '/users/', '/referral/', '/loyalty/', '/ratings/', '/promo/']
        is_protected_route = any(route in path for route in protected_routes)
        
        if hasattr(request, 'headers'):
            auth_header = request.headers.get('Authorization', 'NON FOURNI')
            if is_protected_route and auth_header != 'NON FOURNI':
                print(f"🚨 [UNPROCESSABLE] Route protégée avec token - Conversion en 401", flush=True)
                sys.stdout.flush()
                return jsonify({'error': 'Token JWT invalide ou expiré. Veuillez vous reconnecter.'}), 401
        
        # Pour les autres erreurs, retourner 422
        return jsonify({'error': error.description if hasattr(error, 'description') else str(error)}), 422
    
    # Middleware pour logger toutes les requêtes avant qu'elles n'atteignent les routes
    @app.before_request
    def log_request():
        """Logger toutes les requêtes avant traitement"""
        if request.method == 'POST':
            auth_header = request.headers.get('Authorization', 'NON FOURNI')
            print(f"🌐 [APP_BEFORE_REQUEST] {request.method} {request.path}", flush=True)
            print(f"🌐 [APP_BEFORE_REQUEST] Authorization: {'PRÉSENT' if auth_header != 'NON FOURNI' else 'ABSENT'}", flush=True)
            if auth_header != 'NON FOURNI':
                print(f"🌐 [APP_BEFORE_REQUEST] Token (premiers 50 caractères): {auth_header[:50]}", flush=True)
                # Essayer de décoder le token pour vérifier
                try:
                    token = auth_header.replace('Bearer ', '').strip()
                    from flask_jwt_extended import decode_token
                    from flask import current_app
                    with current_app.app_context():
                        decoded = decode_token(token)
                        print(f"✅ [APP_BEFORE_REQUEST] Token valide - Utilisateur: {decoded.get('sub', 'Non disponible')}", flush=True)
                except Exception as e:
                    print(f"❌ [APP_BEFORE_REQUEST] Token invalide: {e}", flush=True)
                    import sys
                    sys.stdout.flush()
    
    # CORS - Autoriser toutes les origines en développement (Flutter Web utilise un port dynamique)
    # Pour Flutter Web, on doit autoriser toutes les origines localhost
    CORS(app, 
         origins='*',  # Autoriser toutes les origines en développement
         methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
         allow_headers=['Content-Type', 'Authorization', 'X-Requested-With'],
         supports_credentials=False,  # False avec origins='*'
         expose_headers=['Content-Type', 'Authorization'],
         max_age=3600)  # Cache les requêtes preflight pendant 1 heure
    
    # Les headers CORS sont déjà gérés par flask_cors (configuration ci-dessus)
    # Ne pas ajouter de handler @app.after_request car cela créerait des doublons
    # flask_cors gère automatiquement tous les headers CORS nécessaires
    
    # Import des blueprints (après création de l'app pour éviter imports circulaires)
    from routes.auth import auth_bp
    from routes.rides import rides_bp
    from routes.promo_codes import promo_bp
    from routes.referral import referral_bp
    from routes.loyalty import loyalty_bp
    from routes.ratings import ratings_bp
    from routes.landmarks import landmarks_bp
    from routes.users import users_bp
    
    # Enregistrer les blueprints
    api_prefix = app.config['API_PREFIX']
    app.register_blueprint(auth_bp, url_prefix=f'{api_prefix}/auth')
    app.register_blueprint(rides_bp, url_prefix=f'{api_prefix}/rides')
    app.register_blueprint(promo_bp, url_prefix=f'{api_prefix}/promo')
    app.register_blueprint(referral_bp, url_prefix=f'{api_prefix}/referral')
    app.register_blueprint(loyalty_bp, url_prefix=f'{api_prefix}/loyalty')
    app.register_blueprint(ratings_bp, url_prefix=f'{api_prefix}/ratings')
    app.register_blueprint(landmarks_bp, url_prefix=f'{api_prefix}/landmarks')
    app.register_blueprint(users_bp, url_prefix=f'{api_prefix}/users')
    
    # Route de santé - Vérifie que le backend est accessible
    @app.route('/health')
    def health():
        """Endpoint de santé pour vérifier que l'API est en ligne"""
        return jsonify({
            'status': 'ok', 
            'message': 'Allo Dakar API is running',
            'timestamp': datetime.utcnow().isoformat()
        }), 200
    
    return app


if __name__ == '__main__':
    app = create_app('development')
    app.run(debug=True, host='0.0.0.0', port=5000)

