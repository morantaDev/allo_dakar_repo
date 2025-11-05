"""
Routes pour le système de parrainage
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models.referral import ReferralCode, ReferralReward
from models.user import User

referral_bp = Blueprint('referral', __name__)


@referral_bp.route('/code', methods=['GET'])
@jwt_required()
def get_referral_code():
    """Obtenir le code de parrainage de l'utilisateur"""
    try:
        user_id = get_jwt_identity()
        referral_code = ReferralCode.query.filter_by(user_id=user_id).first()
        
        if not referral_code:
            return jsonify({'error': 'Code de parrainage non trouvé'}), 404
        
        return jsonify({
            'referral_code': referral_code.to_dict(),
            'share_message': referral_code.get_share_message(),
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@referral_bp.route('/stats', methods=['GET'])
@jwt_required()
def get_referral_stats():
    """Obtenir les statistiques de parrainage"""
    try:
        user_id = get_jwt_identity()
        referral_code = ReferralCode.query.filter_by(user_id=user_id).first()
        
        if not referral_code:
            return jsonify({'error': 'Code de parrainage non trouvé'}), 404
        
        # Compter les récompenses attribuées
        rewards = ReferralReward.query.filter_by(referrer_id=user_id).all()
        total_credit_earned = sum(reward.referrer_reward for reward in rewards)
        
        return jsonify({
            'referral_code': referral_code.to_dict(),
            'stats': {
                'total_referrals': referral_code.uses,
                'total_credit_earned': total_credit_earned,
                'rewards': [reward.to_dict() for reward in rewards],
            },
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

