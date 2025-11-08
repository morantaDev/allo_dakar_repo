"""
Routes d'authentification pour TeMove Backend

Ce module gère toutes les routes liées à l'authentification :
- Inscription (register)
- Connexion (login)
- Récupération du profil utilisateur (me)
- Rafraîchissement du token (refresh)

Toutes les routes utilisent JWT (JSON Web Tokens) pour l'authentification.
Les tokens sont valides pendant 24 heures (access_token) ou 30 jours (refresh_token).
"""
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import create_access_token, create_refresh_token, jwt_required, get_jwt_identity
from extensions import db
from models.user import User
from models.referral import ReferralCode
from models.loyalty import LoyaltyPoints

# Création du blueprint pour les routes d'authentification
# Le préfixe '/auth' sera ajouté lors de l'enregistrement dans app.py
auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
def register():
    """
    Inscription d'un nouvel utilisateur
    
    Cette route permet à un nouvel utilisateur de s'inscrire sur la plateforme.
    Elle crée automatiquement :
    - Un compte utilisateur avec hash du mot de passe
    - Un code de parrainage unique
    - Un compte de fidélité
    
    Méthode: POST
    Endpoint: /api/v1/auth/register
    
    Body (JSON):
    {
        "email": "string (requis)",
        "password": "string (requis)",
        "full_name": "string (requis)",
        "phone": "string (optionnel)",
        "referral_code": "string (optionnel)"
    }
    
    Returns:
        201: Inscription réussie avec tokens JWT
        400: Erreur de validation (email déjà utilisé, champs manquants)
        500: Erreur serveur
    """
    try:
        # Log pour debug
        from flask import current_app
        current_app.logger.info(f"🔵 Requête d'inscription reçue depuis {request.remote_addr}")
        current_app.logger.info(f"🔵 Headers: {dict(request.headers)}")
        
        data = request.get_json()
        current_app.logger.info(f"🔵 Données reçues: {data}")
        
        # Validation
        if not data.get('email'):
            return jsonify({'error': 'Email requis'}), 400
        if not data.get('password'):
            return jsonify({'error': 'Mot de passe requis'}), 400
        if not data.get('full_name'):
            return jsonify({'error': 'Nom complet requis'}), 400
        
        # Vérifier si l'email existe déjà
        if User.query.filter_by(email=data['email']).first():
            return jsonify({'error': 'Email déjà utilisé'}), 400
        
        # Créer l'utilisateur
        full_name = data.get('full_name') or data.get('name', '')
        user = User(
            email=data['email'],
            full_name=full_name,
            name=full_name,  # Pour compatibilité avec app/models.py
            phone=data.get('phone'),
            role=data.get('role', 'client'),  # Par défaut 'client'
        )
        user.set_password(data['password'])
        
        db.session.add(user)
        db.session.flush()  # Pour obtenir l'ID
        
        # Créer le code de parrainage
        referral_code = ReferralCode(
            user_id=user.id,
            code=ReferralCode.generate_code(),
        )
        db.session.add(referral_code)
        
        # Créer le système de fidélité
        loyalty = LoyaltyPoints(user_id=user.id)
        db.session.add(loyalty)
        
        # Gérer le code de parrainage si fourni
        referral_credit = 0
        if data.get('referral_code'):
            referral_code_used = ReferralCode.query.filter_by(code=data['referral_code']).first()
            if referral_code_used and referral_code_used.is_valid():
                # Créditer le parrainé
                user.add_credit(referral_code_used.credit_amount, 'referral_new_user')
                referral_credit = referral_code_used.credit_amount
                
                # Marquer le code comme utilisé (s'il y a une limite)
                referral_code_used.increment_uses()
        
        db.session.commit()
        
        # Tokens JWT - L'identité doit être une string
        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        
        return jsonify({
            'message': 'Inscription réussie',
            'user': user.to_dict(),
            'access_token': access_token,
            'refresh_token': refresh_token,
            'referral_credit': referral_credit,
        }), 201
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Connexion d'un utilisateur existant
    
    Cette route authentifie un utilisateur et retourne des tokens JWT
    pour les requêtes ultérieures.
    
    Méthode: POST
    Endpoint: /api/v1/auth/login
    
    Body (JSON):
    {
        "email": "string (requis)",
        "password": "string (requis)"
    }
    
    Returns:
        200: Connexion réussie avec tokens JWT et données utilisateur
        401: Email ou mot de passe incorrect
        400: Champs manquants
        500: Erreur serveur
    
    Note: Le token doit être inclus dans l'en-tête Authorization
    pour toutes les requêtes authentifiées :
    Authorization: Bearer <access_token>
    """
    try:
        data = request.get_json()
        
        if not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email et mot de passe requis'}), 400
        
        user = User.query.filter_by(email=data['email']).first()
        
        if not user or not user.check_password(data['password']):
            return jsonify({'error': 'Email ou mot de passe incorrect'}), 401
        
        if not user.is_active:
            return jsonify({'error': 'Compte désactivé'}), 403
        
        # Tokens JWT - L'identité doit être une string
        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        
        print(f"✅ [LOGIN] Token créé pour ID Utilisateur: {user.id} (type: {type(user.id).__name__})")
        print(f"✅ [LOGIN] Token (premiers 50 caractères): {access_token[:50]}...")
        print(f"✅ [LOGIN] Token longueur: {len(access_token)}")
        
        return jsonify({
            'message': 'Connexion réussie',
            'user': user.to_dict(),
            'access_token': access_token,
            'refresh_token': refresh_token,
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh():
    """Rafraîchir le token d'accès"""
    try:
        current_user_id = get_jwt_identity()
        # S'assurer que l'identité est une string
        access_token = create_access_token(identity=str(current_user_id))
        
        return jsonify({
            'access_token': access_token,
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/me', methods=['GET'])
@jwt_required()
def get_current_user():
    """Obtenir les informations de l'utilisateur connecté"""
    try:
        user_id = get_jwt_identity()
        user = User.query.get(user_id)
        
        if not user:
            return jsonify({'error': 'Utilisateur non trouvé'}), 404
        
        return jsonify({
            'user': user.to_dict(include_sensitive=True),
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

