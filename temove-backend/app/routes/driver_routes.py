# app/routes/driver_routes.py
from flask import Blueprint, request, jsonify, current_app
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
    try:
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
        from sqlalchemy import or_, cast, String
        
        # IMPORTANT: RideStatus.PENDING.value = 'pending' (minuscules)
        # Le statut peut être stocké comme Enum ou comme string selon la base de données
        # Pour MySQL, on doit parfois utiliser cast() pour comparer correctement
        
        # D'abord, vérifier s'il y a des courses dans la base
        total_rides = Ride.query.count()
        pending_rides_count = Ride.query.filter(Ride.driver_id.is_(None)).count()
        current_app.logger.info(f"[GET_DRIVER_RIDES] Total courses: {total_rides}, Sans chauffeur: {pending_rides_count}")
        
        # Essayer plusieurs méthodes pour récupérer les courses PENDING
        rides = []
        
        # Méthode 1: Utiliser l'Enum directement (recommandé pour PostgreSQL)
        try:
            rides = Ride.query.filter(
                Ride.driver_id.is_(None),
                Ride.status == RideStatus.PENDING
            ).order_by(Ride.requested_at.desc()).limit(20).all()
            if rides:
                current_app.logger.info(f"[GET_DRIVER_RIDES] ✅ Méthode Enum - {len(rides)} courses trouvées")
        except Exception as e:
            current_app.logger.warning(f"[GET_DRIVER_RIDES] ⚠️ Méthode Enum échouée: {e}")
        
        # Méthode 2: Utiliser la valeur string 'pending' (minuscules) si Enum n'a pas fonctionné
        if not rides:
            try:
                rides = Ride.query.filter(
                    Ride.driver_id.is_(None),
                    cast(Ride.status, String) == 'pending'  # Cast explicite pour MySQL
                ).order_by(Ride.requested_at.desc()).limit(20).all()
                if rides:
                    current_app.logger.info(f"[GET_DRIVER_RIDES] ✅ Méthode cast(String) - {len(rides)} courses trouvées")
            except Exception as e:
                current_app.logger.warning(f"[GET_DRIVER_RIDES] ⚠️ Méthode cast(String) échouée: {e}")
        
        # Méthode 3: Comparaison directe avec string (fallback)
        if not rides:
            try:
                rides = Ride.query.filter(
                    Ride.driver_id.is_(None),
                    Ride.status == 'pending'
                ).order_by(Ride.requested_at.desc()).limit(20).all()
                if rides:
                    current_app.logger.info(f"[GET_DRIVER_RIDES] ✅ Méthode string directe - {len(rides)} courses trouvées")
            except Exception as e:
                current_app.logger.warning(f"[GET_DRIVER_RIDES] ⚠️ Méthode string directe échouée: {e}")
        
        # Méthode 4: Comparaison insensible à la casse (dernier recours)
        if not rides:
            try:
                from sqlalchemy import func
                rides = Ride.query.filter(
                    Ride.driver_id.is_(None),
                    func.lower(cast(Ride.status, String)) == 'pending'
                ).order_by(Ride.requested_at.desc()).limit(20).all()
                if rides:
                    current_app.logger.info(f"[GET_DRIVER_RIDES] ✅ Méthode func.lower - {len(rides)} courses trouvées")
            except Exception as e:
                current_app.logger.error(f"[GET_DRIVER_RIDES] ❌ Toutes les méthodes ont échoué: {e}")
        
        # Log final
        if not rides:
            # Afficher quelques exemples de statuts dans la base pour déboguer
            sample_rides = Ride.query.filter(Ride.driver_id.is_(None)).limit(5).all()
            if sample_rides:
                current_app.logger.warning(f"[GET_DRIVER_RIDES] Exemples de statuts trouvés:")
                for r in sample_rides:
                    status_str = str(r.status)
                    status_type = type(r.status).__name__
                    current_app.logger.warning(f"  - Ride {r.id}: status={status_str} (type={status_type})")
            else:
                current_app.logger.info(f"[GET_DRIVER_RIDES] Aucune course sans chauffeur dans la base")
        
        # Convertir les courses en dictionnaires pour JSON
        rides_data = []
        for ride in rides:
            try:
                ride_dict = ride.to_dict()
                # S'assurer que les adresses sont présentes
                if 'pickup_address' not in ride_dict and hasattr(ride, 'pickup_address') and ride.pickup_address:
                    ride_dict['pickup_address'] = ride.pickup_address
                if 'dropoff_address' not in ride_dict and hasattr(ride, 'dropoff_address') and ride.dropoff_address:
                    ride_dict['dropoff_address'] = ride.dropoff_address
                rides_data.append(ride_dict)
            except Exception as e:
                current_app.logger.error(f"[GET_DRIVER_RIDES] Erreur lors de la conversion d'une course: {e}")
                continue
        
        return jsonify({
            "rides": rides_data
        }), 200
    
    except Exception as e:
        current_app.logger.error(f"[GET_DRIVER_RIDES] Erreur: {e}")
        import traceback
        current_app.logger.error(traceback.format_exc())
        return jsonify({"error": f"Erreur lors de la récupération des courses: {str(e)}"}), 500


@driver_bp.route('/me', methods=['GET'])
@jwt_required()
def driver_me():
    """
    Obtenir les informations du chauffeur connecté
    
    Retourne les informations du profil chauffeur (statut, véhicule, note, etc.)
    ainsi que les informations utilisateur associées.
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
    
    # Récupérer les informations du véhicule
    # Le modèle Driver a les informations du véhicule intégrées (car_make, car_model, etc.)
    # On peut aussi chercher un Vehicle séparé via la relation vehicles
    vehicle = None
    
    # Option 1: Utiliser les informations intégrées du Driver
    if driver.car_make and driver.car_model:
        vehicle = {
            "make": driver.car_make,
            "model": driver.car_model,
            "plate": driver.license_plate,  # Plaque d'immatriculation
            "color": driver.car_color
        }
    
    # Option 2: Vérifier s'il existe un Vehicle séparé (relation)
    # Le modèle Driver a une relation backref 'vehicles' depuis Vehicle
    if hasattr(driver, 'vehicles') and driver.vehicles:
        # Prendre le premier véhicule de la liste
        vehicle_obj = driver.vehicles[0]
        vehicle = {
            "id": vehicle_obj.id,
            "make": vehicle_obj.make,
            "model": vehicle_obj.model,
            "plate": vehicle_obj.plate_number,
            "color": vehicle_obj.color
        }

    # Obtenir le statut du driver
    driver_status = driver.status.value if hasattr(driver.status, 'value') else str(driver.status)
    
    # Retourner les informations complètes (utilisateur + chauffeur)
    return jsonify({
        "driver": {
            "id": driver.id,
            "user_id": driver.user_id,
            "full_name": driver.full_name,
            "license_number": driver.license_number if hasattr(driver, 'license_number') else None,
            "status": driver_status,
            "is_active": driver.is_active,
            "is_verified": driver.is_verified,
            "rating": driver.rating_average if hasattr(driver, 'rating_average') else (driver.rating if hasattr(driver, 'rating') else 0.0),
            "rating_average": driver.rating_average if hasattr(driver, 'rating_average') else 0.0,
            "rating_count": driver.rating_count if hasattr(driver, 'rating_count') else 0,
            "total_rides": driver.total_rides if hasattr(driver, 'total_rides') else 0,
            "vehicle": vehicle,
            # Informations du véhicule intégrées
            "car_make": driver.car_make if hasattr(driver, 'car_make') else None,
            "car_model": driver.car_model if hasattr(driver, 'car_model') else None,
            "car_color": driver.car_color if hasattr(driver, 'car_color') else None,
            "license_plate": driver.license_plate if hasattr(driver, 'license_plate') else None,
            # Informations utilisateur
            "user": {
                "id": user.id,
                "email": user.email,
                "full_name": user.full_name,
                "phone": user.phone,
            }
        }
    }), 200

@driver_bp.route('/completed-rides', methods=['GET'])
@jwt_required()
def get_completed_rides():
    """
    Obtenir les courses complétées du chauffeur avec leurs commissions
    
    Retourne les courses complétées (status='completed') avec les détails
    de commission (montant final, commission, revenus net).
    """
    try:
        current_user_id = get_jwt_identity()
        current_user_id = int(current_user_id) if isinstance(current_user_id, str) else current_user_id
        user = User.query.get(current_user_id)
        if not user:
            return jsonify({"msg":"user not found"}), 404

        # Vérifier si l'utilisateur a un profil chauffeur
        driver = Driver.query.filter_by(user_id=user.id).first()
        if not driver:
            return jsonify({"msg":"not a driver"}), 403
        
        # Récupérer les paramètres de période
        from datetime import datetime, timedelta
        period = request.args.get('period', 'all')  # all, today, week, month
        
        # Calculer les dates selon la période
        now = datetime.utcnow()
        if period == 'today':
            start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
        elif period == 'week':
            start_date = now - timedelta(days=7)
        elif period == 'month':
            start_date = now - timedelta(days=30)
        else:
            start_date = None
        
        # Récupérer les courses complétées
        from models import Ride, RideStatus
        from models.commission import Commission
        
        query = Ride.query.filter(
            Ride.driver_id == driver.id,
            Ride.status == RideStatus.COMPLETED
        )
        
        if start_date:
            query = query.filter(Ride.completed_at >= start_date)
        
        rides = query.order_by(Ride.completed_at.desc()).all()
        
        # Récupérer les commissions associées
        ride_ids = [ride.id for ride in rides]
        commissions = {}
        if ride_ids:
            commission_list = Commission.query.filter(
                Commission.ride_id.in_(ride_ids),
                Commission.driver_id == driver.id
            ).all()
            commissions = {comm.ride_id: comm for comm in commission_list}
        
        # Construire la réponse
        rides_data = []
        total_earnings = 0
        total_commission = 0
        total_rides = len(rides)
        
        for ride in rides:
            commission = commissions.get(ride.id)
            ride_dict = ride.to_dict() if hasattr(ride, 'to_dict') else {}
            
            # Extraire les adresses depuis le format imbriqué
            pickup_address = ''
            dropoff_address = ''
            if 'pickup' in ride_dict and isinstance(ride_dict['pickup'], dict):
                pickup_address = ride_dict['pickup'].get('address', '')
            elif hasattr(ride, 'pickup_address'):
                pickup_address = ride.pickup_address or ''
            
            if 'dropoff' in ride_dict and isinstance(ride_dict['dropoff'], dict):
                dropoff_address = ride_dict['dropoff'].get('address', '')
            elif hasattr(ride, 'dropoff_address'):
                dropoff_address = ride.dropoff_address or ''
            
            # Ajouter les adresses au format plat pour faciliter l'affichage
            ride_dict['pickup_address'] = pickup_address
            ride_dict['dropoff_address'] = dropoff_address
            
            # Ajouter les informations de commission
            if commission:
                ride_dict['commission'] = commission.to_dict()
                ride_dict['ride_price'] = commission.ride_price
                ride_dict['platform_commission'] = commission.platform_commission
                ride_dict['driver_earnings'] = commission.driver_earnings
                ride_dict['service_fee'] = commission.service_fee
                ride_dict['commission_rate'] = commission.commission_rate
                total_earnings += commission.driver_earnings
                total_commission += commission.platform_commission
            else:
                # Si pas de commission, utiliser les données de la course
                ride_price = ride_dict.get('final_price', 0) or getattr(ride, 'final_price', 0)
                ride_dict['ride_price'] = ride_price
                ride_dict['platform_commission'] = 0
                ride_dict['driver_earnings'] = ride_price
                ride_dict['service_fee'] = 0
                ride_dict['commission_rate'] = 0.0
                total_earnings += ride_price
            
            rides_data.append(ride_dict)
        
        return jsonify({
            "success": True,
            "data": {
                "rides": rides_data,
                "summary": {
                    "total_rides": total_rides,
                    "total_earnings": total_earnings,
                    "total_commission": total_commission,
                    "period": period
                }
            }
        }), 200
    
    except Exception as e:
        current_app.logger.error(f"[GET_COMPLETED_RIDES] Erreur: {e}")
        import traceback
        current_app.logger.error(traceback.format_exc())
        return jsonify({"error": f"Erreur lors de la récupération des courses: {str(e)}"}), 500