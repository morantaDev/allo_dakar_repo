# app/routes/auth_routes.py
from flask import Blueprint, request, jsonify, current_app
from extensions import db
from app import bcrypt
from models import User
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


@auth_bp.route('/login', methods=['POST'])
def login():
    """Connexion avec email et mot de passe"""
    data = request.get_json() or {}
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"error": "email et password sont requis"}), 400

    # Chercher l'utilisateur
    user = User.query.filter_by(email=email).first()
    if not user:
        return jsonify({"error": "Email ou mot de passe incorrect"}), 401

    # VÃ©rifier le mot de passe
    if not user.check_password(password):
        return jsonify({"error": "Email ou mot de passe incorrect"}), 401

    # VÃ©rifier si le compte est actif
    if not user.is_active:
        return jsonify({"error": "Ce compte est dÃ©sactivÃ©"}), 403

    # CrÃ©er un token JWT
    additional_claims = {"role": user.role}
    access_token = create_access_token(identity=str(user.id), additional_claims=additional_claims)

    return jsonify({
        "message": "Connexion rÃ©ussie",
        "user": user.to_dict(),
        "access_token": access_token,
        "refresh_token": access_token,  # TODO: ImplÃ©menter refresh token sÃ©parÃ©
    }), 200

