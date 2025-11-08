# app/routes/auth_routes.py
from flask import Blueprint, request, jsonify, current_app
from extensions import db
from models import User, Driver
from models import Vehicle
from models import OTP
from datetime import datetime, timedelta
import random

from flask_jwt_extended import create_access_token

auth_bp = Blueprint('auth', __name__)

def _generate_otp():
    return "{:06d}".format(random.randint(0, 999999))

# @auth_bp.route('/request-otp', methods=['POST'])
# def request_otp():
#     """
#     Body: { "phone": "+22177xxxxxxx" }
#     TODO: intÃ©grer un provider SMS (Africa's Talking / Orange / Twilio)
#     """
#     data = request.get_json() or {}
#     phone = data.get('phone')
#     if not phone:
#         return jsonify({"msg": "phone required"}), 400

#     code = _generate_otp()
#     expires = datetime.utcnow() + timedelta(minutes=5)

#     otp = OTP(phone=phone, code=code, expires_at=expires)
#     db.session.add(otp)
#     db.session.commit()

#     # For now we print the OTP in logs; replace by SMS send.
#     current_app.logger.info(f"OTP for {phone} -> {code}")
#     return jsonify({"msg": "otp_sent"}), 200

@auth_bp.route('/request-otp', methods=['POST'])
def request_otp():
    data = request.get_json()
    phone = data.get("phone")

    if not phone:
        return jsonify({"msg": "phone required"}), 400

    # Chercher l'utilisateur existant
    user = User.query.filter_by(phone=phone).first()
    if not user:
        return jsonify({"msg": "user not found"}), 404

    code = _generate_otp()
    expires = datetime.utcnow() + timedelta(minutes=5)

    # ðŸŸ¢ utiliser user_id au lieu de phone
    otp = OTP(user_id=user.id, code=code, expires_at=expires)
    db.session.add(otp)
    db.session.commit()

    current_app.logger.info(f"OTP for {phone} -> {code}")

    return jsonify({"msg": "OTP sent"})


@auth_bp.route('/verify-otp', methods=['POST'])
def verify_otp():
    """
    Body: { "phone": "...", "code": "123456", "name": "Optional Name" }
    Returns: { access_token, user }
    """
    data = request.get_json() or {}
    phone = data.get('phone')
    code = data.get('code')
    name = data.get('name')

    if not phone or not code:
        return jsonify({"msg": "phone and code required"}), 400

    otp = OTP.query.filter_by(phone=phone, code=code).order_by(OTP.created_at.desc()).first()
    if not otp:
        return jsonify({"msg": "invalid code"}), 400
    if otp.expires_at < datetime.utcnow():
        return jsonify({"msg": "expired code"}), 400

    user = User.query.filter_by(phone=phone).first()
    if not user:
        user = User(phone=phone, name=name or None, role='passenger')
        db.session.add(user)
        db.session.commit()

    additional_claims = {"role": user.role}
    token = create_access_token(identity=str(user.id), additional_claims=additional_claims)

    return jsonify({
        "access_token": token,
        "user": {"id": user.id, "phone": user.phone, "name": user.name, "role": user.role}
    }), 200


@auth_bp.route('/register', methods=['POST'])
def register():
    """Inscription avec email et mot de passe"""
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')
    full_name = data.get('full_name')
    phone = data.get('phone')

    if not email or not password or not full_name:
        return jsonify({"error": "email, password et full_name sont requis"}), 400

    # VÃ©rifier si l'utilisateur existe dÃ©jÃ 
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        return jsonify({"error": "Cet email est dÃ©jÃ  utilisÃ©"}), 400

    # CrÃ©er un nouvel utilisateur
    user = User(
        email=email,
        full_name=full_name,
        name=full_name,  # Pour compatibilitÃ©
        phone=phone,
        role='client',
        is_active=True,
        is_verified=False,
    )
    user.set_password(password)
    
    try:
        db.session.add(user)
        db.session.commit()
        
        # CrÃ©er un token JWT
        additional_claims = {"role": user.role}
        access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
        
        return jsonify({
            "message": "Inscription rÃ©ussie",
            "user": user.to_dict(),
            "access_token": access_token,
            "refresh_token": access_token,  # TODO: ImplÃ©menter refresh token sÃ©parÃ©
        }), 201
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"Erreur lors de l'inscription: {e}")
        return jsonify({"error": "Erreur lors de l'inscription"}), 500


@auth_bp.route('/register-driver', methods=['POST'])
def register_driver():
    """
    Inscription complète d'un chauffeur TéMove Pro
    
    Cette route permet à un nouveau chauffeur de s'inscrire directement avec :
    - Compte utilisateur (email, password, nom, téléphone)
    - Profil chauffeur (numéro de permis)
    - Véhicule (marque, modèle, plaque, couleur)
    
    L'utilisateur est créé avec role='driver' dès le départ.
    
    Body (JSON):
    {
        "email": "string (requis)",
        "password": "string (requis)",
        "full_name": "string (requis)",
        "phone": "string (optionnel)",
        "license_number": "string (requis)",
        "vehicle": {
            "make": "string (requis)",
            "model": "string (requis)",
            "plate": "string (requis)",
            "color": "string (requis)"
        }
    }
    
    Returns:
        201: Inscription réussie avec token JWT
        400: Erreur de validation
        500: Erreur serveur
    """
    data = request.get_json() or {}
    
    # Validation des champs requis
    email = data.get('email')
    password = data.get('password')
    full_name = data.get('full_name')
    phone = data.get('phone')
    license_number = data.get('license_number')
    vehicle_data = data.get('vehicle')
    
    # Vérifier les champs requis
    if not email or not password or not full_name:
        return jsonify({"error": "email, password et full_name sont requis"}), 400
    
    if not license_number:
        return jsonify({"error": "license_number est requis"}), 400
    
    if not vehicle_data:
        return jsonify({"error": "vehicle est requis"}), 400
    
    # Vérifier les champs du véhicule
    vehicle_make = vehicle_data.get('make')
    vehicle_model = vehicle_data.get('model')
    vehicle_plate = vehicle_data.get('plate')
    vehicle_color = vehicle_data.get('color')
    
    if not vehicle_make or not vehicle_model or not vehicle_plate or not vehicle_color:
        return jsonify({"error": "Les champs make, model, plate et color du véhicule sont requis"}), 400
    
    # NOTE: Dans le modèle Driver actuel (models/driver.py), le numéro de permis
    # est stocké dans license_plate. Le champ license_number du formulaire sera
    # utilisé comme license_plate dans le modèle Driver.
    
    # Vérifier si l'utilisateur existe déjà
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        current_app.logger.warning(f"[REGISTER_DRIVER] Tentative d'inscription avec email existant: {email}")
        return jsonify({"error": "Cet email est déjà utilisé"}), 400
    
    try:
        # ============================================
        # CRÉATION DU COMPTE UTILISATEUR
        # ============================================
        current_app.logger.info(f"[REGISTER_DRIVER] Création du compte utilisateur pour: {email}")
        
        user = User(
            email=email,
            full_name=full_name,
            name=full_name,  # Pour compatibilité
            phone=phone,
            role='driver',  # IMPORTANT: Rôle driver dès la création
            is_active=True,
            is_verified=False,
        )
        user.set_password(password)
        db.session.add(user)
        db.session.flush()  # Pour obtenir l'ID
        
        # ============================================
        # CRÉATION DU PROFIL CHAUFFEUR
        # ============================================
        # IMPORTANT: Le modèle Driver dans models/driver.py a les informations
        # du véhicule intégrées directement (car_make, car_model, car_color, license_plate)
        # Il n'y a pas de champ license_number ni de relation avec Vehicle séparé.
        # 
        # Note: license_number est stocké dans license_plate pour ce modèle
        current_app.logger.info(f"[REGISTER_DRIVER] Création du profil chauffeur pour user_id: {user.id}")
        
        # Importer DriverStatus pour le statut
        from models.driver import DriverStatus
        
        # IMPORTANT: Le modèle Driver dans la base de données a des colonnes email et password_hash
        # qui sont NOT NULL. Même si le Driver est lié à un User, nous devons passer ces valeurs
        # pour satisfaire les contraintes de la base de données.
        # 
        # Note: C'est une redondance car ces informations sont déjà dans la table users,
        # mais c'est nécessaire pour la structure actuelle de la base de données.
        driver = Driver(
            user_id=user.id,
            email=user.email,  # Email du User (requis par la base de données)
            password_hash=user.password_hash,  # Password hash du User (requis par la base de données)
            full_name=full_name,  # Nécessaire pour le modèle Driver
            phone=phone or user.phone,  # Téléphone du User (utiliser celui fourni ou celui du User)
            car_make=vehicle_make,
            car_model=vehicle_model,
            car_color=vehicle_color,
            license_plate=vehicle_plate,  # Plaque d'immatriculation du véhicule
            license_number=license_number,  # Numéro de permis de conduire
            status=DriverStatus.OFFLINE,  # Statut initial : offline
            is_active=True,
            is_verified=False,
        )
        db.session.add(driver)
        db.session.flush()  # Pour obtenir l'ID
        
        # ============================================
        # CRÉATION DU VÉHICULE (optionnel - pour compatibilité)
        # ============================================
        # Créer aussi un Vehicle séparé pour compatibilité avec d'autres parties du système
        # qui pourraient utiliser la table vehicles
        current_app.logger.info(f"[REGISTER_DRIVER] Création du véhicule pour driver_id: {driver.id}")
        
        try:
            vehicle = Vehicle(
                driver_id=driver.id,
                make=vehicle_make,
                model=vehicle_model,
                plate_number=vehicle_plate,  # Utiliser plate_number (pas plate)
                color=vehicle_color,
            )
            db.session.add(vehicle)
            db.session.flush()  # Pour obtenir l'ID
        except Exception as e:
            # Si la création du Vehicle échoue (table peut ne pas exister ou erreur de contrainte),
            # continuer quand même car les informations sont dans Driver
            current_app.logger.warning(f"[REGISTER_DRIVER] Erreur lors de la création du Vehicle (non bloquant): {e}")
            vehicle = None
        
        # ============================================
        # COMMIT DES CHANGEMENTS
        # ============================================
        db.session.commit()
        
        current_app.logger.info(f"[REGISTER_DRIVER] Inscription réussie pour: {email} (User ID: {user.id}, Driver ID: {driver.id})")
        
        # Créer un token JWT avec le rôle driver
        additional_claims = {"role": user.role}
        access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)
        
        # Construire la réponse complète avec toutes les données du driver
        # Utiliser la méthode to_dict() du modèle Driver pour obtenir toutes les informations
        driver_dict = driver.to_dict()
        
        # Construire l'objet véhicule depuis les données du Driver
        # Note: license_plate contient la plaque d'immatriculation du véhicule (pas le permis)
        vehicle_dict = {
            "make": driver.car_make,
            "model": driver.car_model,
            "plate": driver.license_plate,  # Plaque d'immatriculation du véhicule
            "color": driver.car_color,
        }
        
        # Si un Vehicle séparé a été créé, ajouter son ID et utiliser sa plaque
        if vehicle:
            vehicle_dict["id"] = vehicle.id
            vehicle_dict["plate"] = vehicle.plate_number
        
        # Construire la réponse complète avec toutes les données du driver
        # Format similaire à /drivers/me pour cohérence
        return jsonify({
            "message": "Inscription chauffeur réussie",
            "user": user.to_dict(),
            "driver": {
                # Informations de base du driver
                "id": driver.id,
                "user_id": driver.user_id,
                "full_name": driver.full_name,
                "email": driver.email,
                "phone": driver.phone,
                # Informations du permis et statut
                "license_number": driver.license_number,  # Numéro de permis de conduire
                "status": driver.status.value if hasattr(driver.status, 'value') else str(driver.status),
                "is_active": driver.is_active,
                "is_verified": driver.is_verified,
                # Informations du véhicule
                "vehicle": vehicle_dict,
                "car_make": driver.car_make,
                "car_model": driver.car_model,
                "car_color": driver.car_color,
                "license_plate": driver.license_plate,  # Plaque d'immatriculation du véhicule
                # Statistiques
                "rating_average": driver.rating_average,
                "rating_count": driver.rating_count,
                "total_rides": driver.total_rides,
                # Localisation (si disponible)
                "current_location": driver_dict.get('current_location'),
            },
            "access_token": access_token,
            "refresh_token": access_token,
        }), 201
        
    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f"[REGISTER_DRIVER] Erreur lors de l'inscription: {e}")
        import traceback
        current_app.logger.error(traceback.format_exc())
        return jsonify({"error": f"Erreur lors de l'inscription: {str(e)}"}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    """
    Connexion avec email et mot de passe
    
    IMPORTANT: Pour TéMove Pro, cette route vérifie que l'utilisateur a un profil chauffeur.
    Si l'utilisateur n'a pas de profil chauffeur, la connexion est refusée avec un code
    spécial pour rediriger vers l'inscription chauffeur.
    """
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')
    
    # Flag pour indiquer si c'est une tentative de connexion depuis TéMove Pro
    is_driver_app = data.get('driver_app', False)

    if not email or not password:
        return jsonify({"error": "email et password sont requis"}), 400

    # Chercher l'utilisateur
    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({"error": "Email ou mot de passe incorrect"}), 401

    # Vérifier le mot de passe
    if not user.check_password(password):
        return jsonify({"error": "Email ou mot de passe incorrect"}), 401

    # Vérifier si le compte est actif
    if not user.is_active:
        return jsonify({"error": "Ce compte est désactivé"}), 403

    # ============================================
    # VÉRIFICATION STRICTE DU RÔLE POUR TÉMOVE PRO
    # ============================================
    # Si c'est une connexion depuis l'app chauffeur (TéMove Pro),
    # vérifier que l'utilisateur a le rôle "driver"
    # 
    # IMPORTANT: Seuls les utilisateurs avec role="driver" peuvent se connecter à TéMove Pro
    # Cette vérification se fait AVANT la création du token pour éviter toute connexion non autorisée
    if is_driver_app:
        current_app.logger.info(f"[LOGIN] Tentative de connexion TéMove Pro pour: {email}, rôle actuel: {user.role}")
        
        # Vérifier le rôle utilisateur
        if user.role != 'driver':
            current_app.logger.warning(f"[LOGIN] Accès refusé - Utilisateur {email} n'a pas le rôle 'driver' (rôle actuel: {user.role})")
            return jsonify({
                "error": "not a driver",
                "message": "Compte non autorisé. Cette application est réservée aux chauffeurs TéMove.",
                "code": "NOT_A_DRIVER",
                "user_role": user.role  # Pour debug
            }), 403
        
        # Vérifier également que l'utilisateur a un profil Driver (double vérification)
        driver = Driver.query.filter_by(user_id=user.id).first()
        if not driver:
            current_app.logger.warning(f"[LOGIN] Accès refusé - Utilisateur {email} a role='driver' mais pas de profil Driver")
            return jsonify({
                "error": "not a driver",
                "message": "Profil chauffeur incomplet. Veuillez compléter votre inscription.",
                "code": "MISSING_DRIVER_PROFILE",
                "user_role": user.role
            }), 403
        
        current_app.logger.info(f"[LOGIN] Connexion TéMove Pro autorisée pour: {email} (rôle: {user.role}, Driver ID: {driver.id})")

    # Créer un token JWT (si c'est un driver ou si ce n'est pas l'app chauffeur)
    additional_claims = {"role": user.role}
    access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)

    return jsonify({
        "message": "Connexion réussie",
        "user": user.to_dict(),
        "access_token": access_token,
        "refresh_token": access_token,  # TODO: Implémenter refresh token séparé
    }), 200

