"""
Application principale Flask pour TeMove
"""
from flask import Flask, jsonify, request, make_response
from flask_cors import CORS
from flask_jwt_extended import JWTManager, decode_token
from werkzeug.exceptions import UnprocessableEntity
from datetime import datetime
import os
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
        LoyaltyPoints, UserBadge, BadgeType, Rating, Commission, Revenue, OTP
    )
    from models.favorite_driver import FavoriteDriver
    
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
    
    # ============================================
    # Configuration CORS optimisée pour Flutter
    # ============================================
    # Autoriser toutes les origines en développement (Flutter Web, Android, iOS)
    # En production, configurer CORS_ORIGINS dans les variables d'environnement
    cors_origins = app.config.get('CORS_ORIGINS', ['*'])
    
    # Configuration CORS globale pour toutes les routes
    # Cette configuration permet à Flutter Web, Android et iOS de communiquer avec le backend
    CORS(app, 
         resources={
             r"/*": {  # Appliquer à toutes les routes
                 "origins": cors_origins,
                 "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
                 "allow_headers": [
                     "Content-Type", 
                     "Authorization", 
                     "X-Requested-With",
                     "Accept",
                     "Origin",
                     "Access-Control-Request-Method",
                     "Access-Control-Request-Headers",
                     "X-CSRF-Token"
                 ],
                 "expose_headers": [
                     "Content-Type", 
                     "Authorization",
                     "X-Total-Count",
                     "Access-Control-Allow-Origin"
                 ],
                 "supports_credentials": False,  # False car on utilise "*" pour les origines
                 "max_age": 3600  # Cache des requêtes preflight pendant 1 heure
             }
         },
         # Options globales pour Flask-CORS
         automatic_options=True,  # Répondre automatiquement aux requêtes OPTIONS
         send_wildcard=False  # Ne pas envoyer "*" mais l'origine exacte
         )
    
    
    # Handler CORS explicite pour toutes les réponses (backup)
    # IMPORTANT: Ce handler ne doit ajouter les headers QUE si Flask-CORS ne les a pas déjà ajoutés
    # pour éviter les doublons qui causent l'erreur "multiple values"
    @app.after_request
    def after_request(response):
        """
        Ajouter les headers CORS à toutes les réponses (seulement si Flask-CORS ne l'a pas fait)
        
        Cette fonction sert de backup si Flask-CORS ne fonctionne pas correctement.
        Elle vérifie d'abord si les headers CORS existent déjà avant de les ajouter
        pour éviter les doublons qui causent l'erreur "multiple values".
        """
        # Vérifier si Flask-CORS a déjà ajouté les headers
        # Si oui, ne rien faire pour éviter les doublons
        if 'Access-Control-Allow-Origin' in response.headers:
            # Flask-CORS a déjà géré les headers, on ne fait rien
            return response
        
        # Flask-CORS n'a pas ajouté les headers, on les ajoute manuellement
        origin = request.headers.get('Origin')
        
        # Si une origine spécifique est demandée et autorisée, l'utiliser
        if origin:
            # Vérifier si l'origine est autorisée
            if cors_origins == ['*'] or origin in cors_origins:
                response.headers['Access-Control-Allow-Origin'] = origin
        elif cors_origins == ['*']:
            # En développement, autoriser toutes les origines
            response.headers['Access-Control-Allow-Origin'] = '*'
        
        # Ajouter les autres headers seulement s'ils n'existent pas déjà
        if 'Access-Control-Allow-Headers' not in response.headers:
            response.headers['Access-Control-Allow-Headers'] = (
                'Content-Type, Authorization, X-Requested-With, Accept, Origin, '
                'Access-Control-Request-Method, Access-Control-Request-Headers'
            )
        
        if 'Access-Control-Allow-Methods' not in response.headers:
            response.headers['Access-Control-Allow-Methods'] = (
                'GET, POST, PUT, DELETE, OPTIONS, PATCH'
            )
        
        if 'Access-Control-Max-Age' not in response.headers:
            response.headers['Access-Control-Max-Age'] = '3600'
        
        if 'Access-Control-Expose-Headers' not in response.headers:
            response.headers['Access-Control-Expose-Headers'] = (
                'Content-Type, Authorization, X-Total-Count'
            )
        
        return response
    
    # Import des blueprints (après création de l'app pour éviter imports circulaires)
    # IMPORTANT: Utiliser app/routes/auth_routes.py qui contient la route /register-driver
    from app.routes.auth_routes import auth_bp
    from routes.rides import rides_bp
    from routes.promo_codes import promo_bp
    from routes.referral import referral_bp
    from routes.loyalty import loyalty_bp
    from routes.ratings import ratings_bp
    from routes.landmarks import landmarks_bp
    from routes.users import users_bp
    from routes.favorite_drivers import favorite_drivers_bp
    from routes.upload import upload_bp
    from routes.admin_routes import admin_bp
    
    # Import des blueprints depuis app/routes (nouveau système)
    # Ces routes sont utilisées par l'application TéMove Pro (chauffeurs)
    from app.routes.driver_routes import driver_bp
    
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
    app.register_blueprint(favorite_drivers_bp, url_prefix=f'{api_prefix}/favorite-drivers')
    app.register_blueprint(upload_bp, url_prefix=f'{api_prefix}/upload')
    app.register_blueprint(admin_bp, url_prefix=f'{api_prefix}/admin')
    
    # Enregistrer le blueprint des routes drivers (pour TéMove Pro)
    app.register_blueprint(driver_bp, url_prefix=f'{api_prefix}/drivers')
    
    # IMPORTANT: Ne pas ajouter de handler before_request pour OPTIONS car Flask-CORS
    # gère déjà cela automatiquement avec automatic_options=True.
    # Ajouter un handler ici causerait des conflits et des doublons de headers.
    # Flask-CORS répond automatiquement aux requêtes OPTIONS avec les bons headers.
    
    # Route pour servir les fichiers uploadés (audio, images, etc.)
    @app.route('/uploads/audio/<filename>')
    def uploaded_audio(filename):
        """Servir les fichiers audio uploadés"""
        from flask import send_from_directory
        upload_folder = os.path.join(app.instance_path, 'uploads', 'audio')
        # Créer le dossier s'il n'existe pas
        os.makedirs(upload_folder, exist_ok=True)
        return send_from_directory(upload_folder, filename)
    
    # Route de santé - Vérifie que le backend est accessible
    @app.route('/health')
    def health():
        """Endpoint de santé pour vérifier que l'API est en ligne"""
        return jsonify({
            'status': 'ok', 
            'message': 'TeMove API is running',
            'timestamp': datetime.utcnow().isoformat()
        }), 200
    
    return app


if __name__ == '__main__':
    app = create_app('development')
    app.run(debug=True, host='0.0.0.0', port=5000)

