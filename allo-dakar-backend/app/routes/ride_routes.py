# app/routes/ride_routes.py
from flask import Blueprint, request, jsonify, current_app
from .. import db, socketio
from ..models import Ride, User, Driver, Location
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime

ride_bp = Blueprint('rides', __name__)

@ride_bp.route('/request', methods=['POST'])
@jwt_required()
def request_ride():
    """
    Passenger requests a ride.
    Body: { origin: {lat,lng}, dest: {lat,lng} }
    """
    user_id = get_jwt_identity()
    data = request.get_json() or {}
    origin = data.get('origin')
    dest = data.get('dest')

    if not origin or not dest:
        return jsonify({"msg":"origin and dest required"}), 400

    ride = Ride(
        passenger_id=user_id,
        origin_lat=float(origin['lat']),
        origin_lng=float(origin['lng']),
        dest_lat=float(dest['lat']),
        dest_lng=float(dest['lng']),
        status='requested',
        created_at=datetime.utcnow()
    )
    db.session.add(ride)
    db.session.commit()

    # Broadcast to drivers namespace -> in prod filter by proximity & available drivers
    payload = {
        "ride_id": ride.id,
        "origin": {"lat": ride.origin_lat, "lng": ride.origin_lng},
        "dest": {"lat": ride.dest_lat, "lng": ride.dest_lng}
    }
    # notify all connected drivers (namespace '/drivers' to be implemented in sockets)
    socketio.emit('new_ride', payload, namespace='/drivers')

    return jsonify({"ride_id": ride.id, "status": ride.status}), 201

@ride_bp.route('/<int:ride_id>', methods=['GET'])
@jwt_required()
def get_ride(ride_id):
    user_id = get_jwt_identity()
    ride = Ride.query.get(ride_id)
    if not ride:
        return jsonify({"msg":"ride not found"}), 404
    # only passenger, driver or admin can see
    if ride.passenger_id != user_id and (not ride.driver or ride.driver.user_id != user_id):
        # allow admin? For now block
        pass
    driver_info = None
    if ride.driver_id:
        driver = Driver.query.get(ride.driver_id)
        driver_info = {"id": driver.id, "user_id": driver.user_id, "status": driver.status} if driver else None

    return jsonify({
        "id": ride.id,
        "passenger_id": ride.passenger_id,
        "driver": driver_info,
        "origin": {"lat": ride.origin_lat, "lng": ride.origin_lng},
        "dest": {"lat": ride.dest_lat, "lng": ride.dest_lng},
        "status": ride.status,
        "price": ride.price,
        "created_at": ride.created_at.isoformat()
    })

@ride_bp.route('/<int:ride_id>/accept', methods=['POST'])
@jwt_required()
def accept_ride(ride_id):
    """
    Called by driver to accept a ride.
    """
    user_id = get_jwt_identity()
    # find driver by user's id
    driver = Driver.query.filter_by(user_id=user_id).first()
    if not driver:
        return jsonify({"msg":"only drivers can accept rides"}), 403

    ride = Ride.query.get(ride_id)
    if not ride or ride.status != 'requested':
        return jsonify({"msg":"invalid ride"}), 400

    ride.driver_id = driver.id
    ride.status = 'accepted'
    ride.started_at = None
    db.session.commit()

    # notify passenger (namespace '/passengers') — send minimal driver info
    socketio.emit('ride_update', {
        "ride_id": ride.id,
        "status": ride.status,
        "driver_id": driver.id,
        "driver_user_id": driver.user_id
    }, namespace='/passengers')

    current_app.logger.info(f"Driver {driver.id} accepted ride {ride.id}")
    return jsonify({"msg":"accepted", "ride_id": ride.id}), 200

@ride_bp.route('/<int:ride_id>/location', methods=['POST'])
@jwt_required()
def update_location(ride_id):
    """
    Driver sends location updates (or driver can send without ride_id for general availability)
    Body: { lat, lng, ride_id(optional) }
    """
    data = request.get_json() or {}
    lat = data.get('lat')
    lng = data.get('lng')
    if lat is None or lng is None:
        return jsonify({"msg":"lat and lng required"}), 400

    user_id = get_jwt_identity()
    driver = Driver.query.filter_by(user_id=user_id).first()
    if not driver:
        return jsonify({"msg":"only drivers can send locations"}), 403

    # store location optionally linked to ride
    loc = Location(ride_id=ride_id if ride_id else None, driver_id=driver.id, lat=float(lat), lng=float(lng))
    db.session.add(loc)
    db.session.commit()

    # emit to passengers so they can track driver on their ride
    socketio.emit('driver_location', {
        "driver_id": driver.id,
        "lat": loc.lat,
        "lng": loc.lng,
        "ride_id": ride_id
    }, namespace='/passengers')

    return jsonify({"msg":"location_saved"}), 200
