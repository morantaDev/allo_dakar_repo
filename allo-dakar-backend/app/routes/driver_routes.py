# app/routes/driver_routes.py
from flask import Blueprint, request, jsonify
from extensions import db
from models import User, Driver
from models import Vehicle
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt

driver_bp = Blueprint('drivers', __name__)

@driver_bp.route('/register', methods=['POST'])
@jwt_required()
def register_driver():
    """
    Driver registers from a user account.
    Body: { license_number, vehicle: {make, model, plate, color}, name(optional) }
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"msg":"user not found"}), 404

    data = request.get_json() or {}
    license_number = data.get('license_number')
    vehicle_data = data.get('vehicle')

    # Vérifier si l'utilisateur a déjà un profil chauffeur
    existing_driver = Driver.query.filter_by(user_id=user.id).first()
    if existing_driver:
        return jsonify({"msg":"already registered as driver"}), 400

    driver = Driver(user_id=user.id, license_number=license_number, status='pending')
    db.session.add(driver)
    db.session.flush()  # to get id

    if vehicle_data:
        vehicle = Vehicle(driver_id=driver.id,
                          make=vehicle_data.get('make'),
                          model=vehicle_data.get('model'),
                          plate=vehicle_data.get('plate'),
                          color=vehicle_data.get('color'))
        db.session.add(vehicle)
        db.session.flush()
        driver.vehicle_id = vehicle.id

    # elevate role
    user.role = 'driver'
    db.session.commit()

    return jsonify({"msg":"driver_registered", "driver_id": driver.id}), 201

@driver_bp.route('/set-status', methods=['POST'])
@jwt_required()
def set_status():
    """
    Body: { status: 'online' | 'offline' | 'in_ride' | 'unavailable' }
    """
    current_user_id = get_jwt_identity()
    # Convertir en int car l'identité est stockée comme string dans le JWT
    current_user_id = int(current_user_id) if isinstance(current_user_id, str) else current_user_id
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"msg":"user not found"}), 404

    # Vérifier si l'utilisateur a un profil chauffeur
    driver = Driver.query.filter_by(user_id=user.id).first()
    if not driver:
        return jsonify({"msg":"not a driver"}), 403

    data = request.get_json() or {}
    status = data.get('status')
    # Mapper les statuts du frontend vers les statuts du backend
    status_mapping = {
        'online': 'online',
        'offline': 'offline',
        'available': 'online',  # Alias
        'busy': 'in_ride',
        'in_ride': 'in_ride',
        'unavailable': 'unavailable',
    }
    mapped_status = status_mapping.get(status, status)
    
    if mapped_status not in ('online', 'offline', 'in_ride', 'unavailable'):
        return jsonify({"msg":"invalid status"}), 400

    driver.status = mapped_status
    db.session.commit()
    return jsonify({"msg":"status_updated","status":mapped_status}), 200

@driver_bp.route('/rides', methods=['GET'])
@jwt_required()
def get_driver_rides():
    """Obtenir les courses disponibles pour le chauffeur"""
    current_user_id = get_jwt_identity()
    # Convertir en int car l'identité est stockée comme string dans le JWT
    current_user_id = int(current_user_id) if isinstance(current_user_id, str) else current_user_id
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"msg":"user not found"}), 404

    # Vérifier si l'utilisateur a un profil chauffeur
    driver = Driver.query.filter_by(user_id=user.id).first()
    if not driver:
        return jsonify({"msg":"not a driver"}), 403

    # Récupérer les courses en attente (PENDING) qui n'ont pas encore de chauffeur assigné
    from models import Ride, RideStatus
    rides = Ride.query.filter_by(
        driver_id=None,
        status=RideStatus.PENDING
    ).order_by(Ride.requested_at.desc()).limit(20).all()
    
    return jsonify({
        "rides": [ride.to_dict() for ride in rides]
    }), 200


@driver_bp.route('/me', methods=['GET'])
@jwt_required()
def driver_me():
    current_user_id = get_jwt_identity()
    # Convertir en int car l'identité est stockée comme string dans le JWT
    current_user_id = int(current_user_id) if isinstance(current_user_id, str) else current_user_id
    user = User.query.get(current_user_id)
    if not user:
        return jsonify({"msg":"user not found"}), 404

    # Vérifier si l'utilisateur a un profil chauffeur
    driver = Driver.query.filter_by(user_id=user.id).first()
    if not driver:
        return jsonify({"msg":"not a driver"}), 403
    vehicle = None
    if driver.vehicle_id:
        vehicle = Vehicle.query.get(driver.vehicle_id)
        vehicle = {"make": vehicle.make, "model": vehicle.model, "plate": vehicle.plate, "color": vehicle.color}

    return jsonify({
        "driver": {
            "id": driver.id,
            "license_number": driver.license_number,
            "status": driver.status,
            "rating": driver.rating,
            "vehicle": vehicle
        }
    })
