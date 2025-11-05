"""
Routes pour les codes promo
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from extensions import db
from models.promo_code import PromoCode, PromoType

promo_bp = Blueprint('promo', __name__)


@promo_bp.route('/validate', methods=['POST'])
@jwt_required()
def validate_promo_code():
    """Valider un code promo"""
    try:
        data = request.get_json()
        code = data.get('code')
        original_price = data.get('original_price', 0)
        
        if not code:
            return jsonify({'error': 'Code requis'}), 400
        
        promo = PromoCode.query.filter_by(code=code.upper()).first()
        
        if not promo:
            return jsonify({
                'valid': False,
                'error': 'Code promo invalide',
            }), 200
        
        if not promo.is_valid():
            return jsonify({
                'valid': False,
                'error': 'Code promo expiré ou épuisé',
            }), 200
        
        discount = promo.calculate_discount(original_price)
        final_price = promo.apply_discount(original_price)
        
        return jsonify({
            'valid': True,
            'promo_code': promo.to_dict(),
            'discount_amount': discount,
            'final_price': final_price,
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@promo_bp.route('/list', methods=['GET'])
def list_promo_codes():
    """Lister les codes promo actifs (publique)"""
    try:
        promo_codes = PromoCode.query.filter_by(is_active=True).all()
        
        # Filtrer seulement les codes valides
        valid_codes = [promo.to_dict() for promo in promo_codes if promo.is_valid()]
        
        return jsonify({
            'promo_codes': valid_codes,
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

