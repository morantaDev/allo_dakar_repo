# app/routes/driver_routes.py
from flask import Blueprint, request, jsonify
from .. import db
from ..models import User, Driver, Vehicle
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

    # create driver row
    if user.driver:
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
    Body: { status: 'available' | 'offline' | 'busy' }
    """
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user or not user.driver:
        return jsonify({"msg":"not a driver"}), 403

    data = request.get_json() or {}
    status = data.get('status')
    if status not in ('available','offline','busy'):
        return jsonify({"msg":"invalid status"}), 400

    user.driver.status = status
    db.session.commit()
    return jsonify({"msg":"status_updated","status":status}), 200

@driver_bp.route('/me', methods=['GET'])
@jwt_required()
def driver_me():
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    if not user or not user.driver:
        return jsonify({"msg":"not a driver"}), 403

    driver = user.driver
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
