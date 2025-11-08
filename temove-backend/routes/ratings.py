"""
Routes pour les évaluations
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models.rating import Rating
from models.ride import Ride, RideStatus

ratings_bp = Blueprint('ratings', __name__)


@ratings_bp.route('/create', methods=['POST'])
@jwt_required()
def create_rating():
    """Créer une évaluation"""
    try:
        data = request.get_json()
        user_id = get_jwt_identity()
        # Convertir en int car l'identité est stockée comme string dans le JWT
        user_id = int(user_id) if isinstance(user_id, str) else user_id
        
        # Validation
        if not data.get('ride_id'):
            return jsonify({'error': 'ride_id requis'}), 400
        if not data.get('rating') or not (1 <= data['rating'] <= 5):
            return jsonify({'error': 'Rating doit être entre 1 et 5'}), 400
        
        # Vérifier que la course existe et appartient à l'utilisateur
        ride = Ride.query.get_or_404(data['ride_id'])
        
        if ride.user_id != user_id:
            return jsonify({
                'error': 'Accès non autorisé',
                'details': f'Ride user_id: {ride.user_id} (type: {type(ride.user_id).__name__}), JWT user_id: {user_id} (type: {type(user_id).__name__})'
            }), 403
        
        if ride.status != RideStatus.COMPLETED:
            return jsonify({'error': 'La course doit être terminée pour être évaluée'}), 400
        
        # Vérifier si déjà évaluée
        if Rating.query.filter_by(ride_id=ride.id).first():
            return jsonify({'error': 'Cette course a déjà été évaluée'}), 400
        
        # Créer l'évaluation
        rating = Rating(
            ride_id=ride.id,
            user_id=user_id,
            driver_id=ride.driver_id,
            rating=data['rating'],
            comment=data.get('comment'),
            audio_url=data.get('audio_url'),  # URL de l'avis vocal
        )
        
        db.session.add(rating)
        db.session.flush()
        
        # Mettre à jour la note du conducteur
        rating.update_driver_rating()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Évaluation enregistrée',
            'rating': rating.to_dict(),
        }), 201
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

