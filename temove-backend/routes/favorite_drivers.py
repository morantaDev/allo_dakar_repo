"""
Routes pour les chauffeurs préférés
"""
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from extensions import db
from models.favorite_driver import FavoriteDriver
from models.driver import Driver

favorite_drivers_bp = Blueprint('favorite_drivers', __name__)


@favorite_drivers_bp.route('/add', methods=['POST'])
@jwt_required()
def add_favorite_driver():
    """Ajouter un chauffeur aux favoris"""
    try:
        data = request.get_json()
        user_id = get_jwt_identity()
        
        # Validation
        if not data.get('driver_id'):
            return jsonify({'error': 'driver_id requis'}), 400
        
        driver_id = data['driver_id']
        
        # Vérifier que le chauffeur existe
        driver = Driver.query.get_or_404(driver_id)
        
        # Vérifier si déjà dans les favoris
        existing = FavoriteDriver.query.filter_by(
            user_id=user_id,
            driver_id=driver_id
        ).first()
        
        if existing:
            return jsonify({'error': 'Ce chauffeur est déjà dans vos favoris'}), 400
        
        # Ajouter aux favoris
        favorite = FavoriteDriver(
            user_id=user_id,
            driver_id=driver_id,
        )
        
        db.session.add(favorite)
        db.session.commit()
        
        return jsonify({
            'message': 'Chauffeur ajouté aux favoris',
            'favorite': favorite.to_dict(),
        }), 201
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@favorite_drivers_bp.route('/remove', methods=['POST'])
@jwt_required()
def remove_favorite_driver():
    """Retirer un chauffeur des favoris"""
    try:
        data = request.get_json()
        user_id = get_jwt_identity()
        
        # Validation
        if not data.get('driver_id'):
            return jsonify({'error': 'driver_id requis'}), 400
        
        driver_id = data['driver_id']
        
        # Trouver et supprimer
        favorite = FavoriteDriver.query.filter_by(
            user_id=user_id,
            driver_id=driver_id
        ).first_or_404()
        
        db.session.delete(favorite)
        db.session.commit()
        
        return jsonify({
            'message': 'Chauffeur retiré des favoris',
        }), 200
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@favorite_drivers_bp.route('/list', methods=['GET'])
@jwt_required()
def list_favorite_drivers():
    """Lister les chauffeurs préférés de l'utilisateur"""
    try:
        user_id = get_jwt_identity()
        
        # Récupérer les favoris avec les infos des chauffeurs
        favorites = db.session.query(FavoriteDriver, Driver).join(
            Driver, FavoriteDriver.driver_id == Driver.id
        ).filter(
            FavoriteDriver.user_id == user_id
        ).all()
        
        result = []
        for favorite, driver in favorites:
            driver_dict = {
                'id': driver.id,
                'name': driver.name or driver.user.full_name if driver.user else 'Chauffeur',
                'phone': driver.user.phone if driver.user else None,
                'rating_average': driver.rating_average or 0.0,
                'rating_count': driver.rating_count or 0,
            }
            result.append({
                'favorite_id': favorite.id,
                'driver': driver_dict,
                'added_at': favorite.created_at.isoformat() if favorite.created_at else None,
            })
        
        return jsonify({
            'favorites': result,
            'count': len(result),
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@favorite_drivers_bp.route('/check/<int:driver_id>', methods=['GET'])
@jwt_required()
def check_favorite_driver(driver_id):
    """Vérifier si un chauffeur est dans les favoris"""
    try:
        user_id = get_jwt_identity()
        
        favorite = FavoriteDriver.query.filter_by(
            user_id=user_id,
            driver_id=driver_id
        ).first()
        
        return jsonify({
            'is_favorite': favorite is not None,
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

