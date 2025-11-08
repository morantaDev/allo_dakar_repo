# app/routes/ride_routes.py
from flask import Blueprint, request, jsonify, current_app, make_response
from extensions import db
from app import socketio
from models import Ride, User, Driver
from models import Location
from flask_jwt_extended import jwt_required, get_jwt_identity
from datetime import datetime
from services.driver_availability_service import DriverAvailabilityService
from services.pricing_service import PricingService
from services.geolocation_service import GeolocationService
from models.ride import RideStatus, RideCategory, RideMode
from models.payment import Payment, PaymentMethod, PaymentStatus
from models.promo_code import PromoCode

ride_bp = Blueprint('rides', __name__)


# Handler pour les requêtes OPTIONS (CORS preflight)
@ride_bp.before_request
def handle_preflight():
    if request.method == "OPTIONS":
        response = make_response()
        response.headers.add("Access-Control-Allow-Origin", "*")
        response.headers.add('Access-Control-Allow-Headers', "Content-Type, Authorization")
        response.headers.add('Access-Control-Allow-Methods', "GET, POST, OPTIONS")
        return response


@ride_bp.route('/estimate', methods=['POST', 'OPTIONS'])
@jwt_required()
def estimate_ride():
    """Estimer le prix d'une course"""
    try:
        # Log pour debug
        current_app.logger.info(f"Estimate request - Headers: {dict(request.headers)}")
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Données JSON requises'}), 400
        
        user_id = get_jwt_identity()
        current_app.logger.info(f"User ID from JWT: {user_id}")
        
        if not user_id:
            return jsonify({'error': 'Token JWT invalide ou expiré'}), 401
        
        # Mapper les noms de champs du frontend vers les noms du backend
        pickup_lat = data.get('pickup_latitude') or data.get('departure_lat')
        pickup_lng = data.get('pickup_longitude') or data.get('departure_lng')
        dropoff_lat = data.get('dropoff_latitude') or data.get('destination_lat')
        dropoff_lng = data.get('dropoff_longitude') or data.get('destination_lng')
        ride_mode = data.get('ride_mode', 'confort')  # Valeur par défaut
        
        # Validation
        if not pickup_lat or not pickup_lng or not dropoff_lat or not dropoff_lng:
            return jsonify({'error': 'Coordonnées de départ et destination requises'}), 400
        
        # Services
        pricing = PricingService()
        geo = GeolocationService()
        
        # Calculer distance
        distance_km = geo.calculate_distance(
            pickup_lat,
            pickup_lng,
            dropoff_lat,
            dropoff_lng
        )
        
        # Calculer durée
        duration_minutes = geo.calculate_duration(
            pickup_lat,
            pickup_lng,
            dropoff_lat,
            dropoff_lng
        )
        
        # Calculer le prix
        estimate = pricing.estimate_trip(
            pickup_lat,
            pickup_lng,
            dropoff_lat,
            dropoff_lng,
            ride_mode
        )
        
        # Appliquer code promo si fourni
        discount_amount = 0
        if data.get('promo_code'):
            promo = PromoCode.query.filter_by(code=data['promo_code']).first()
            if promo and promo.is_valid():
                discount_amount = promo.calculate_discount(estimate['final_price'])
                estimate['final_price'] = promo.apply_discount(estimate['final_price'])
                estimate['discount_amount'] = discount_amount
        
        return jsonify({
            'estimate': estimate,
            'promo_applied': bool(discount_amount),
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@ride_bp.route('/book', methods=['POST', 'OPTIONS'])
@jwt_required()
def book_ride():
    """Réserver une course"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Données JSON requises'}), 400
        
        user_id = get_jwt_identity()
        if not user_id:
            return jsonify({'error': 'Token JWT invalide ou expiré'}), 401
        
        # Mapper les noms de champs du frontend vers les noms du backend
        pickup_lat = data.get('pickup_latitude') or data.get('departure_lat')
        pickup_lng = data.get('pickup_longitude') or data.get('departure_lng')
        pickup_address = data.get('pickup_address') or data.get('departure_address')
        dropoff_lat = data.get('dropoff_latitude') or data.get('destination_lat')
        dropoff_lng = data.get('dropoff_longitude') or data.get('destination_lng')
        dropoff_address = data.get('dropoff_address') or data.get('destination_address')
        ride_mode = data.get('ride_mode')
        ride_category = data.get('ride_category') or data.get('category', 'course')
        payment_method = data.get('payment_method')
        
        # Validation
        if not pickup_lat or not pickup_lng:
            return jsonify({'error': 'Coordonnées de départ requises'}), 400
        if not pickup_address:
            return jsonify({'error': 'Adresse de départ requise'}), 400
        if not ride_mode:
            return jsonify({'error': 'ride_mode requis'}), 400
        
        # Services
        pricing = PricingService()
        
        # Gérer scheduled_at si fourni
        scheduled_at = None
        if data.get('scheduled_at'):
            try:
                scheduled_str = data['scheduled_at']
                if scheduled_str.endswith('Z'):
                    scheduled_str = scheduled_str.replace('Z', '+00:00')
                scheduled_at = datetime.fromisoformat(scheduled_str)
                if scheduled_at.replace(tzinfo=None) < datetime.utcnow():
                    return jsonify({'error': 'La date de réservation ne peut pas être dans le passé'}), 400
                if scheduled_at.tzinfo:
                    scheduled_at = scheduled_at.replace(tzinfo=None)
            except (ValueError, AttributeError) as e:
                return jsonify({'error': f'Format de date invalide pour scheduled_at: {str(e)}'}), 400
        
        # Calculer prix si dropoff fourni
        base_price = 0
        surge_multiplier = 1.0
        final_price = 0
        distance_km = None
        duration_minutes = None
        
        if dropoff_lat and dropoff_lng:
            geo = GeolocationService()
            distance_km = geo.calculate_distance(
                pickup_lat,
                pickup_lng,
                dropoff_lat,
                dropoff_lng
            )
            duration_minutes = geo.calculate_duration(
                pickup_lat,
                pickup_lng,
                dropoff_lat,
                dropoff_lng
            )
            
            pricing_timestamp = scheduled_at if scheduled_at else datetime.utcnow()
            price_info = pricing.calculate_final_price(
                distance_km,
                ride_mode,
                pricing_timestamp
            )
            base_price = price_info.get('base_price', 0)
            surge_multiplier = price_info.get('surge_multiplier', 1.0)
            final_price = price_info.get('final_price', 0)
            
            # S'assurer que ce sont des types valides
            base_price = int(base_price) if base_price else 0
            surge_multiplier = float(surge_multiplier) if surge_multiplier else 1.0
            final_price = int(final_price) if final_price else 0
        else:
            # Si pas de destination, utiliser un prix minimum
            base_price = pricing.pricing['base_fare']
            surge_multiplier = pricing.calculate_surge_multiplier(scheduled_at if scheduled_at else datetime.utcnow())
            final_price = int(base_price * surge_multiplier)
        
        # Créer la course
        # Gérer les modes de livraison et les modes de course
        # Normaliser le nom du mode (confortPlus -> CONFORT_PLUS)
        ride_mode_upper = ride_mode.upper()
        # Mapper les noms possibles
        mode_mapping = {
            'CONFORTPLUS': 'CONFORT_PLUS',
            'CONFORT_PLUS': 'CONFORT_PLUS',
            'PARTAGETAXI': 'PARTAGE_TAXI',
            'PARTAGE_TAXI': 'PARTAGE_TAXI',
            'TIAKTIAK': 'TIAK_TIAK',
            'TIAK_TIAK': 'TIAK_TIAK',
        }
        ride_mode_normalized = mode_mapping.get(ride_mode_upper, ride_mode_upper)
        
        try:
            ride_mode_enum = RideMode[ride_mode_normalized]
        except KeyError:
            # Si le mode n'existe pas, utiliser confort par défaut
            current_app.logger.warning(f"Mode inconnu: {ride_mode} (normalisé: {ride_mode_normalized}), utilisation de CONFORT par défaut")
            ride_mode_enum = RideMode.CONFORT
        
        try:
            category_enum = RideCategory[ride_category.upper()]
        except KeyError:
            category_enum = RideCategory.COURSE
        
        # Vérification finale que base_price n'est pas None
        if base_price is None or base_price == 0:
            if distance_km:
                base_price = pricing.calculate_base_price(distance_km, ride_mode)
                surge_multiplier = pricing.calculate_surge_multiplier(scheduled_at if scheduled_at else datetime.utcnow())
                final_price = int(base_price * surge_multiplier)
            else:
                base_price = pricing.pricing['base_fare']
                final_price = base_price
        
        # Conversion finale
        base_price = int(base_price) if base_price else pricing.pricing['base_fare']
        surge_multiplier = float(surge_multiplier) if surge_multiplier else 1.0
        final_price = int(final_price) if final_price else int(base_price * surge_multiplier)
        
        ride = Ride(
            user_id=int(user_id) if isinstance(user_id, str) else user_id,
            category=category_enum,
            ride_mode=ride_mode_enum,
            pickup_latitude=float(pickup_lat),
            pickup_longitude=float(pickup_lng),
            pickup_address=pickup_address,
            dropoff_latitude=float(dropoff_lat) if dropoff_lat else None,
            dropoff_longitude=float(dropoff_lng) if dropoff_lng else None,
            dropoff_address=dropoff_address,
            distance_km=distance_km,
            duration_minutes=int(duration_minutes) if duration_minutes else None,
            base_price=base_price,
            surge_multiplier=surge_multiplier,
            final_price=final_price,
            payment_method=payment_method,
            scheduled_at=scheduled_at,
        )
        
        # Gérer code promo
        promo_code_id = None
        discount_amount = 0
        if data.get('promo_code'):
            promo = PromoCode.query.filter_by(code=data['promo_code']).first()
            if promo and promo.is_valid():
                discount_amount = promo.calculate_discount(final_price)
                final_price = promo.apply_discount(final_price)
                ride.promo_code_id = promo.id
                ride.discount_amount = discount_amount
                ride.final_price = final_price
                promo_code_id = promo.id
        
        db.session.add(ride)
        db.session.flush()
        
        # Créer le paiement
        payment_method_enum = PaymentMethod.CASH
        if payment_method:
            try:
                payment_method_enum = PaymentMethod[payment_method.upper()]
            except KeyError:
                pass
        
        payment = Payment(
            ride_id=ride.id,
            user_id=user_id,
            amount=final_price,
            method=payment_method_enum,
            status=PaymentStatus.PENDING,
        )
        db.session.add(payment)
        
        # Incrémenter les utilisations du code promo
        if promo_code_id:
            promo = PromoCode.query.get(promo_code_id)
            promo.increment_uses()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Course réservée avec succès',
            'ride': ride.to_dict(),
        }), 201
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500

@ride_bp.route('/history', methods=['GET'])
@jwt_required()
def get_ride_history():
    """Obtenir l'historique des courses de l'utilisateur"""
    try:
        user_id = get_jwt_identity()
        # Convertir en int car l'identité est stockée comme string dans le JWT
        user_id = int(user_id) if isinstance(user_id, str) else user_id
        
        rides = Ride.query.filter_by(user_id=user_id).order_by(Ride.requested_at.desc()).limit(50).all()
        
        current_app.logger.info(f"Récupération de l'historique pour user_id: {user_id}, {len(rides)} courses trouvées")
        
        return jsonify({
            'rides': [ride.to_dict() for ride in rides],
        }), 200
    
    except Exception as e:
        current_app.logger.error(f"Erreur lors de la récupération de l'historique: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


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
    VÃ©rifie la disponibilitÃ© en tenant compte des rÃ©servations Ã  l'avance.
    """
    user_id = get_jwt_identity()
    # find driver by user's id
    driver = Driver.query.filter_by(user_id=user_id).first()
    if not driver:
        return jsonify({"msg":"only drivers can accept rides"}), 403

    ride = Ride.query.get(ride_id)
    if not ride:
        return jsonify({"msg":"ride not found"}), 404
    
    # Vérifier le statut - peut être 'pending' (nouveau modèle) ou 'requested' (ancien modèle)
    from models.ride import RideStatus
    valid_statuses = ['pending', 'requested']
    if isinstance(ride.status, RideStatus):
        ride_status_str = ride.status.value if hasattr(ride.status, 'value') else str(ride.status)
    else:
        ride_status_str = str(ride.status).lower()
    
    if ride_status_str not in valid_statuses:
        return jsonify({"msg":f"invalid ride status: {ride_status_str}"}), 400

    # VÃ©rifier la disponibilitÃ© du chauffeur
    # Utiliser scheduled_at si disponible, sinon maintenant
    requested_time = ride.scheduled_at if ride.scheduled_at else datetime.utcnow()
    estimated_duration = ride.duration_minutes if ride.duration_minutes else 30
    
    is_available, reason = DriverAvailabilityService.is_driver_available(
        driver.id,
        requested_time,
        estimated_duration
    )
    
    if not is_available:
        return jsonify({
            "msg": "Chauffeur non disponible",
            "reason": reason
        }), 409  # Conflict

    ride.driver_id = driver.id
    ride.status = 'accepted'
    ride.started_at = None
    ride.confirmed_at = datetime.utcnow()
    db.session.commit()

    # notify passenger (namespace '/passengers') â€” send minimal driver info
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

