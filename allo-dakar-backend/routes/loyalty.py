"""
Routes pour le système de fidélité
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models.loyalty import LoyaltyPoints

loyalty_bp = Blueprint('loyalty', __name__)


@loyalty_bp.route('/points', methods=['GET'])
@jwt_required()
def get_loyalty_points():
    """Obtenir les points de fidélité de l'utilisateur"""
    try:
        user_id = get_jwt_identity()
        loyalty = LoyaltyPoints.query.filter_by(user_id=user_id).first()
        
        if not loyalty:
            # Créer si n'existe pas
            loyalty = LoyaltyPoints(user_id=user_id)
            db.session.add(loyalty)
            db.session.commit()
        
        return jsonify({
            'loyalty': loyalty.to_dict(),
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

