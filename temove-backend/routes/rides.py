"""
Routes pour les courses
"""
from flask import Blueprint, request, jsonify, make_response, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity, decode_token
from datetime import datetime
from extensions import db
from models.ride import Ride, RideStatus, RideCategory, RideMode
from models.payment import Payment, PaymentMethod, PaymentStatus
from models.promo_code import PromoCode
from models import Driver
from services.pricing_service import PricingService
from services.geolocation_service import GeolocationService

rides_bp = Blueprint('rides', __name__)




@rides_bp.route('/test', methods=['GET'])
def test_rides():
    return jsonify({'message': 'Rides blueprint fonctionne!'}), 200


# IMPORTANT: Ne pas gérer les requêtes OPTIONS ici car Flask-CORS le fait déjà
# au niveau global dans app.py. Gérer OPTIONS ici causerait des doublons de headers.
# Flask-CORS avec automatic_options=True gère automatiquement toutes les requêtes OPTIONS.

# Logger les requêtes POST pour debug (uniquement en mode développement)
@rides_bp.before_request
def log_request():
    """Logger les requêtes POST pour debug"""
    # Ne pas gérer OPTIONS ici - Flask-CORS s'en charge
    if request.method == 'OPTIONS':
        return None  # Laisser Flask-CORS gérer
    
    # Log pour toutes les requêtes POST (avant validation JWT)
    if request.method == 'POST':
        auth_header = request.headers.get('Authorization', 'NON FOURNI')
        print(f"🚀 [RIDES_BEFORE_REQUEST] {request.path} - Méthode: {request.method}")
        print(f"🚀 [RIDES_BEFORE_REQUEST] En-tête Authorization présent: {'OUI' if auth_header != 'NON FOURNI' else 'NON'}")
        if auth_header != 'NON FOURNI':
            print(f"🚀 [RIDES_BEFORE_REQUEST] Authorization (premiers 50 caractères): {auth_header[:50]}")
            # Essayer de décoder le token manuellement pour voir s'il est valide
            try:
                token = auth_header.replace('Bearer ', '').strip()
                from flask_jwt_extended import decode_token
                from flask import current_app
                with current_app.app_context():
                    decoded = decode_token(token)
                    print(f"✅ [RIDES_BEFORE_REQUEST] Token décodé avec succès - ID Utilisateur: {decoded.get('sub', 'NON TROUVÉ')}", flush=True)
            except Exception as e:
                print(f"❌ [RIDES_BEFORE_REQUEST] Erreur lors du décodage du token: {e}", flush=True)
                import traceback
                traceback.print_exc()
                import sys
                sys.stdout.flush()


# Ne pas ajouter de headers CORS ici - déjà géré par flask_cors et le handler global
# Les headers CORS sont déjà gérés par :
# 1. flask_cors (configuration globale)
# 2. @app.after_request dans app.py
# Ajouter ici créerait des doublons et causerait l'erreur "multiple values"


@rides_bp.route('/estimate', methods=['POST'])
def estimate_ride():
    """
    Estimer le prix d'une course
    
    Note: Les requêtes OPTIONS (preflight) sont automatiquement gérées par Flask-CORS
    grâce à la configuration automatic_options=True dans app.py.
    Aucune gestion manuelle d'OPTIONS n'est nécessaire ici.
    """
    # Vérifier le JWT pour les requêtes POST
    try:
        # Vérifier manuellement le JWT pour POST uniquement
        from flask_jwt_extended import verify_jwt_in_request
        verify_jwt_in_request()
        
        user_id = get_jwt_identity()
        # Convertir en int car l'identité est stockée comme string dans le JWT
        user_id = int(user_id) if isinstance(user_id, str) else user_id
        print(f"✅ [ESTIMATE] JWT valide - ID Utilisateur: {user_id} (type: {type(user_id).__name__})")
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'Données JSON requises'}), 400
        
        print(f"📋 [ESTIMATE] Données reçues: {data}")
        
        # Mapper les noms de champs du frontend vers les noms du backend
        pickup_lat = data.get('pickup_latitude') or data.get('departure_lat')
        pickup_lng = data.get('pickup_longitude') or data.get('departure_lng')
        dropoff_lat = data.get('dropoff_latitude') or data.get('destination_lat')
        dropoff_lng = data.get('dropoff_longitude') or data.get('destination_lng')
        ride_mode = data.get('ride_mode', 'confort')  # Valeur par défaut
        
        print(f"🔍 [ESTIMATE] Coordonnées:")
        print(f"  Départ: {pickup_lat}, {pickup_lng}")
        print(f"  Arrivée: {dropoff_lat}, {dropoff_lng}")
        print(f"  Mode: {ride_mode}")
        
        # Validation
        if not all([pickup_lat, pickup_lng, dropoff_lat, dropoff_lng]):
            return jsonify({'error': 'Coordonnées de départ et destination requises'}), 400
        
        # Convertir en float si nécessaire
        try:
            pickup_lat = float(pickup_lat)
            pickup_lng = float(pickup_lng)
            dropoff_lat = float(dropoff_lat)
            dropoff_lng = float(dropoff_lng)
        except (ValueError, TypeError) as e:
            return jsonify({'error': f'Coordonnées invalides: {str(e)}'}), 400
        
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
        
        print(f"📏 [ESTIMATE] Distance calculée: {distance_km} km")
        
        # Calculer durée
        duration_minutes = geo.calculate_duration(
            pickup_lat,
            pickup_lng,
            dropoff_lat,
            dropoff_lng
        )
        
        print(f"⏱️ [ESTIMATE] Durée estimée: {duration_minutes} minutes")
        
        # Calculer le prix
        estimate = pricing.estimate_trip(
            pickup_lat,
            pickup_lng,
            dropoff_lat,
            dropoff_lng,
            ride_mode
        )
        
        print(f"💰 [ESTIMATE] Prix estimé: {estimate}")
        
        # Appliquer code promo si fourni
        discount_amount = 0
        if data.get('promo_code'):
            promo = PromoCode.query.filter_by(code=data['promo_code']).first()
            if promo and promo.is_valid():
                discount_amount = promo.calculate_discount(estimate['final_price'])
                estimate['final_price'] = promo.apply_discount(estimate['final_price'])
                estimate['discount_amount'] = discount_amount
                print(f"🎟️ [ESTIMATE] Code promo appliqué - Réduction: {discount_amount}")
        
        result = {
            'estimate': estimate,
            'promo_applied': bool(discount_amount),
        }
        
        print(f"✅ [ESTIMATE] Réponse envoyée: {result}")
        return jsonify(result), 200
    
    except Exception as e:
        print(f"❌ [ESTIMATE] Erreur: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@rides_bp.route('/book', methods=['POST', 'OPTIONS'])
def book_ride():
    """Réserver une course"""
    
    print("\n" + "="*60)
    print("📞 ENDPOINT /rides/book APPELÉ")
    print(f"   Méthode: {request.method}")
    print("="*60)
    
    # 🚨 CRITIQUE : Gérer OPTIONS AVANT jwt_required
    if request.method == 'OPTIONS':
        print("✅ Requête OPTIONS - Réponse OK")
        print("="*60 + "\n")
        response = make_response()
        response.headers.add("Access-Control-Allow-Origin", "*")
        response.headers.add('Access-Control-Allow-Headers', "Content-Type, Authorization, X-Requested-With")
        response.headers.add('Access-Control-Allow-Methods', "GET, POST, PUT, DELETE, OPTIONS, PATCH")
        response.headers.add('Access-Control-Max-Age', "3600")
        return response
    
    # Maintenant vérifier le JWT pour POST uniquement
    try:
        print("🔐 Vérification du JWT...")
        from flask_jwt_extended import verify_jwt_in_request
        
        try:
            verify_jwt_in_request()
            user_id = get_jwt_identity()
            # Convertir en int car l'identité est stockée comme string dans le JWT
            user_id = int(user_id) if isinstance(user_id, str) else user_id
            print(f"✅ JWT valide - ID Utilisateur: {user_id} (type: {type(user_id).__name__})")
        except Exception as jwt_error:
            print(f"❌ Erreur JWT: {jwt_error}")
            import traceback
            traceback.print_exc()
            print("="*60 + "\n")
            return jsonify({'error': 'Token JWT invalide', 'details': str(jwt_error)}), 422
        
        # Récupérer les données
        raw_data = request.get_data(as_text=True)
        print(f"\n📦 Données brutes reçues ({len(raw_data)} caractères):")
        print(raw_data)
        
        data = request.get_json()
        if not data:
            print("❌ Aucune donnée JSON reçue")
            print("="*60 + "\n")
            return jsonify({'error': 'Données JSON requises'}), 400
        
        print(f"\n📋 JSON parsé - Clés reçues: {list(data.keys())}")
        import json
        print("📋 Données complètes:")
        print(json.dumps(data, indent=2, ensure_ascii=False))
        
        # Mapper les noms de champs du frontend vers les noms du backend
        print("\n🔍 Extraction des données...")
        pickup_lat = data.get('pickup_latitude') or data.get('departure_lat')
        pickup_lng = data.get('pickup_longitude') or data.get('departure_lng')
        pickup_address = data.get('pickup_address') or data.get('departure_address') or 'Adresse de départ'
        dropoff_lat = data.get('dropoff_latitude') or data.get('destination_lat')
        dropoff_lng = data.get('dropoff_longitude') or data.get('destination_lng')
        dropoff_address = data.get('dropoff_address') or data.get('destination_address') or 'Adresse d\'arrivée'
        ride_mode = data.get('ride_mode', 'confort')
        ride_category = data.get('ride_category') or data.get('category', 'course')
        payment_method = data.get('payment_method', 'cash')
        
        print(f"  pickup_latitude: {pickup_lat} ({type(pickup_lat).__name__})")
        print(f"  pickup_longitude: {pickup_lng} ({type(pickup_lng).__name__})")
        print(f"  pickup_address: {pickup_address}")
        print(f"  dropoff_latitude: {dropoff_lat} ({type(dropoff_lat).__name__})")
        print(f"  dropoff_longitude: {dropoff_lng} ({type(dropoff_lng).__name__})")
        print(f"  dropoff_address: {dropoff_address}")
        print(f"  ride_mode: {ride_mode}")
        print(f"  ride_category: {ride_category}")
        print(f"  payment_method: {payment_method}")
        
        # Validation
        if not pickup_lat or not pickup_lng:
            error_msg = 'Coordonnées de départ requises'
            print(f"❌ {error_msg}")
            print("="*60 + "\n")
            return jsonify({'error': error_msg}), 400
        
        # Convertir en float
        print("\n🔄 Conversion des coordonnées...")
        try:
            pickup_lat = float(pickup_lat)
            pickup_lng = float(pickup_lng)
            if dropoff_lat and dropoff_lng:
                dropoff_lat = float(dropoff_lat)
                dropoff_lng = float(dropoff_lng)
            print("✅ Conversion réussie")
        except (ValueError, TypeError) as e:
            error_msg = f'Coordonnées invalides: {str(e)}'
            print(f"❌ {error_msg}")
            print("="*60 + "\n")
            return jsonify({'error': error_msg}), 400
        
        # Services
        pricing = PricingService()
        
        # Gérer scheduled_at si fourni
        scheduled_at = None
        if data.get('scheduled_at'):
            try:
                scheduled_str = data['scheduled_at']
                if isinstance(scheduled_str, str):
                    scheduled_at = datetime.fromisoformat(scheduled_str.replace('Z', '+00:00'))
                else:
                    scheduled_at = scheduled_str
                print(f"📅 Réservation programmée: {scheduled_at}")
            except Exception as e:
                print(f"⚠️ Erreur parsing scheduled_at: {e}")
        
        # Calculer distance et prix
        distance_km = None
        duration_minutes = None
        base_price = 0
        surge_multiplier = 1.0
        final_price = 0
        
        if dropoff_lat and dropoff_lng:
            print("\n💰 Calcul du prix...")
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
            
            print(f"📏 Distance: {distance_km} km")
            print(f"⏱️ Durée: {duration_minutes} minutes")
            
            pricing_timestamp = scheduled_at if scheduled_at else datetime.utcnow()
            price_info = pricing.calculate_final_price(
                distance_km,
                ride_mode,
                pricing_timestamp
            )
            print(f"🔍 [DEBUG] price_info reçu: {price_info}")
            base_price = price_info.get('base_price')
            surge_multiplier = price_info.get('surge_multiplier', 1.0)
            final_price = price_info.get('final_price')
            
            # Vérifier que base_price n'est pas None
            if base_price is None:
                print(f"❌ [ERROR] base_price est None! Calcul direct...")
                base_price = pricing.calculate_base_price(distance_km, ride_mode)
                surge_multiplier = pricing.calculate_surge_multiplier(pricing_timestamp)
                final_price = int(base_price * surge_multiplier)
            
            # S'assurer que ce sont des entiers/floats valides
            base_price = int(base_price) if base_price is not None else 0
            surge_multiplier = float(surge_multiplier) if surge_multiplier is not None else 1.0
            final_price = int(final_price) if final_price is not None else 0
            
            print(f"💵 Prix de base: {base_price} XOF (type: {type(base_price).__name__})")
            print(f"💵 Multiplicateur: {surge_multiplier} (type: {type(surge_multiplier).__name__})")
            print(f"💵 Prix final: {final_price} XOF (type: {type(final_price).__name__})")
        else:
            # Si pas de destination, utiliser un prix minimum
            print("⚠️ Pas de destination fournie, utilisation du prix minimum")
            base_price = pricing.pricing['base_fare']
            surge_multiplier = pricing.calculate_surge_multiplier(scheduled_at if scheduled_at else datetime.utcnow())
            final_price = int(base_price * surge_multiplier)
        
        # Créer la course
        print("\n💾 Création de la course...")
        
        # Vérification finale avant création
        print(f"🔍 [FINAL CHECK] Avant création de Ride:")
        print(f"  base_price: {base_price} (type: {type(base_price).__name__})")
        print(f"  surge_multiplier: {surge_multiplier} (type: {type(surge_multiplier).__name__})")
        print(f"  final_price: {final_price} (type: {type(final_price).__name__})")
        
        # S'assurer que base_price n'est jamais None
        if base_price is None or base_price == 0:
            print(f"⚠️ [WARNING] base_price est None ou 0, calcul d'urgence...")
            if distance_km:
                base_price = pricing.calculate_base_price(distance_km, ride_mode)
                surge_multiplier = pricing.calculate_surge_multiplier(scheduled_at if scheduled_at else datetime.utcnow())
                final_price = int(base_price * surge_multiplier)
            else:
                base_price = pricing.pricing['base_fare']
                final_price = base_price
            print(f"✅ [WARNING] Nouveau base_price: {base_price}")
        
        # Conversion finale en types corrects
        base_price = int(base_price) if base_price else 0
        surge_multiplier = float(surge_multiplier) if surge_multiplier else 1.0
        final_price = int(final_price) if final_price else int(base_price * surge_multiplier)
        
        # Gérer les modes de livraison et les modes de course
        # Convertir la valeur du frontend (minuscule) vers le nom de l'enum (majuscule)
        try:
            # Le frontend envoie 'famille', 'confort', etc. (valeurs)
            # On doit trouver l'enum correspondant
            ride_mode_enum = None
            for mode in RideMode:
                if mode.value == ride_mode.lower():
                    ride_mode_enum = mode
                    break
            
            # Si pas trouvé par valeur, essayer par nom
            if ride_mode_enum is None:
                ride_mode_enum = RideMode[ride_mode.upper()]
        except KeyError:
            print(f"⚠️ Mode inconnu: {ride_mode}, utilisation de CONFORT par défaut")
            ride_mode_enum = RideMode.CONFORT
        
        print(f"🔍 [BOOK] ride_mode reçu: '{ride_mode}' -> Enum: {ride_mode_enum.name}")
        
        try:
            category_enum = RideCategory[ride_category.upper()]
        except KeyError:
            category_enum = RideCategory.COURSE
        
        print(f"🔍 [FINAL CHECK] Après conversions:")
        print(f"  base_price: {base_price} (type: {type(base_price).__name__})")
        print(f"  surge_multiplier: {surge_multiplier} (type: {type(surge_multiplier).__name__})")
        print(f"  final_price: {final_price} (type: {type(final_price).__name__})")
        
        # IMPORTANT: S'assurer que le statut est PENDING et driver_id est None
        # pour que la course soit visible dans /api/v1/drivers/rides
        ride = Ride(
            user_id=user_id,
            category=category_enum,
            ride_mode=ride_mode_enum,
            pickup_latitude=pickup_lat,
            pickup_longitude=pickup_lng,
            pickup_address=pickup_address,
            dropoff_latitude=dropoff_lat,
            dropoff_longitude=dropoff_lng,
            dropoff_address=dropoff_address,
            distance_km=distance_km,
            duration_minutes=duration_minutes,
            base_price=base_price,
            surge_multiplier=surge_multiplier,
            final_price=final_price,
            payment_method=payment_method,
            scheduled_at=scheduled_at,
            status=RideStatus.PENDING,  # FORCER le statut PENDING pour synchronisation
            driver_id=None,  # FORCER driver_id à None pour synchronisation
        )
        
        # Gérer code promo
        promo_code_id = None
        discount_amount = 0
        if data.get('promo_code'):
            print(f"🎟️ Vérification du code promo: {data['promo_code']}")
            promo = PromoCode.query.filter_by(code=data['promo_code']).first()
            if promo and promo.is_valid():
                discount_amount = promo.calculate_discount(final_price)
                final_price = promo.apply_discount(final_price)
                ride.promo_code_id = promo.id
                ride.discount_amount = discount_amount
                ride.final_price = final_price
                print(f"✅ Code promo appliqué - Réduction: {discount_amount} XOF")
        
        # Sauvegarder la ride d'abord pour obtenir son ID
        print("\n💾 Sauvegarde de la course dans la base de données...")
        try:
            db.session.add(ride)
            db.session.flush()  # Flush pour obtenir ride.id sans commit
            print(f"✅ Course créée (flush) - ID: {ride.id}, Utilisateur: {user_id}")
        except Exception as db_error:
            db.session.rollback()
            print(f"❌ Erreur base de données lors de la création de la course: {db_error}")
            import traceback
            traceback.print_exc()
            print("="*60 + "\n")
            return jsonify({'error': f'Erreur base de données: {str(db_error)}'}), 500
        
        # Créer le paiement si méthode fournie (après avoir obtenu ride.id)
        payment = None
        if payment_method:
            print(f"💳 Création du paiement - Méthode: {payment_method}")
            try:
                payment_method_enum = PaymentMethod[payment_method.upper()]
            except KeyError:
                payment_method_enum = PaymentMethod.CASH
            
            payment = Payment(
                ride_id=ride.id,  # ✅ Maintenant ride.id est disponible
                user_id=user_id,  # ✅ Ajouter explicitement user_id
                amount=final_price,
                method=payment_method_enum,
                status=PaymentStatus.PENDING,
            )
            db.session.add(payment)
            print(f"✅ Paiement créé - Ride ID: {ride.id}, User ID: {user_id}, Montant: {final_price}")
        
        # IMPORTANT: Vérifier et forcer le statut PENDING avant le commit final
        # pour garantir que la course sera visible par les chauffeurs via /api/v1/drivers/rides
        if isinstance(ride.status, RideStatus):
            if ride.status != RideStatus.PENDING:
                print(f"⚠️ [BOOK_RIDE] Correction du statut: {ride.status} -> PENDING")
                ride.status = RideStatus.PENDING
        else:
            if str(ride.status).lower() != 'pending':
                print(f"⚠️ [BOOK_RIDE] Correction du statut: {ride.status} -> pending")
                try:
                    ride.status = RideStatus.PENDING
                except:
                    ride.status = 'pending'
        
        # S'assurer que driver_id est None (pas encore assigné)
        if ride.driver_id is not None:
            print(f"⚠️ [BOOK_RIDE] Correction de driver_id: {ride.driver_id} -> None")
            ride.driver_id = None
        
        # Commit final
        try:
            db.session.commit()
            print(f"✅ [BOOK_RIDE] Course et paiement sauvegardés avec succès")
            print(f"   Ride ID: {ride.id}")
            print(f"   Utilisateur: {user_id}")
            print(f"   Statut: {ride.status} (PENDING = visible par les chauffeurs)")
            print(f"   Driver ID: {ride.driver_id} (None = pas encore assigné)")
            print(f"   Prix: {ride.final_price} XOF")
            print(f"   📍 La course est maintenant disponible dans /api/v1/drivers/rides")
        except Exception as db_error:
            db.session.rollback()
            print(f"❌ Erreur base de données: {db_error}")
            import traceback
            traceback.print_exc()
            print("="*60 + "\n")
            return jsonify({'error': f'Erreur base de données: {str(db_error)}'}), 500
        
        # ============================================
        # RÉCUPÉRER LES CHAUFFEURS DISPONIBLES AVEC ETA
        # ============================================
        # Obtenir les chauffeurs disponibles proches du point de prise en charge
        # avec leur distance et temps d'arrivée estimé (ETA)
        available_drivers = []
        try:
            from services.driver_proximity_service import DriverProximityService
            driver_proximity = DriverProximityService()
            available_drivers = driver_proximity.get_available_drivers_with_eta(
                pickup_lat=pickup_lat,
                pickup_lng=pickup_lng,
                max_distance_km=10,  # 10 km de rayon maximum
                max_drivers=10  # Maximum 10 chauffeurs à retourner
            )
            print(f"🚗 [BOOK_RIDE] {len(available_drivers)} chauffeur(s) disponible(s) trouvé(s)")
        except Exception as e:
            print(f"⚠️ [BOOK_RIDE] Erreur lors de la récupération des chauffeurs disponibles: {e}")
            import traceback
            traceback.print_exc()
            # Continuer même si l'erreur survient, la course est créée
        
        result = {
            'message': 'Réservation créée avec succès. En attente d\'un chauffeur...',
            'ride': ride.to_dict(),
            'status': 'pending',  # Informer explicitement le statut
            'driver_id': None,  # Informer qu'aucun chauffeur n'est assigné
            'available_for_drivers': True,  # La course est disponible pour les chauffeurs
            'available_drivers': available_drivers,  # Liste des chauffeurs disponibles avec ETA
            'available_drivers_count': len(available_drivers),  # Nombre de chauffeurs disponibles
        }
        
        print(f"\n✅ SUCCÈS - Réponse envoyée")
        print(f"   Chauffeurs disponibles: {len(available_drivers)}")
        print("="*60 + "\n")
        
        return jsonify(result), 201
    
    except Exception as e:
        db.session.rollback()
        print(f"\n❌ ERREUR INATTENDUE: {str(e)}")
        import traceback
        traceback.print_exc()
        print("="*60 + "\n")
        return jsonify({'error': f'Erreur: {str(e)}'}), 500



@rides_bp.route('/history', methods=['GET'])
@jwt_required()
def get_ride_history():
    """Obtenir l'historique des courses de l'utilisateur"""
    try:
        user_id = get_jwt_identity()
        # Convertir en int car l'identité est stockée comme string dans le JWT
        user_id = int(user_id) if isinstance(user_id, str) else user_id
        
        rides = Ride.query.filter_by(user_id=user_id).order_by(Ride.requested_at.desc()).limit(50).all()
        
        print(f"📚 [HISTORY] Récupération de l'historique pour user_id: {user_id}")
        print(f"📚 [HISTORY] Nombre de courses trouvées: {len(rides)}")
        
        return jsonify({
            'rides': [ride.to_dict() for ride in rides],
        }), 200
    
    except Exception as e:
        print(f"❌ [HISTORY] Erreur: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@rides_bp.route('/<int:ride_id>/available-drivers', methods=['GET'])
@jwt_required()
def get_available_drivers_for_ride(ride_id):
    """
    Obtenir les chauffeurs disponibles pour une course avec leur ETA
    
    Cette route permet au client de voir les chauffeurs disponibles
    proches du point de prise en charge avec leur temps d'arrivée estimé.
    
    Returns:
        200: Liste des chauffeurs disponibles avec ETA
        404: Course non trouvée
        403: Accès non autorisé (seul le client peut voir les chauffeurs pour sa course)
    """
    try:
        current_user_id = get_jwt_identity()
        current_user_id = int(current_user_id) if isinstance(current_user_id, str) else current_user_id
        
        # Récupérer la course
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"error": "Course non trouvée"}), 404
        
        # Vérifier que l'utilisateur est le propriétaire de la course
        if ride.user_id != current_user_id:
            return jsonify({"error": "Accès non autorisé"}), 403
        
        # Vérifier que la course est toujours en attente (PENDING)
        if isinstance(ride.status, RideStatus):
            ride_status = ride.status.value if hasattr(ride.status, 'value') else str(ride.status)
        else:
            ride_status = str(ride.status).lower()
        
        if ride_status != 'pending':
            return jsonify({
                "error": "La course a déjà un chauffeur assigné",
                "status": ride_status,
                "driver_id": ride.driver_id
            }), 400
        
        # Récupérer les chauffeurs disponibles avec ETA
        from services.driver_proximity_service import DriverProximityService
        driver_proximity = DriverProximityService()
        
        available_drivers = driver_proximity.get_available_drivers_with_eta(
            pickup_lat=ride.pickup_latitude,
            pickup_lng=ride.pickup_longitude,
            max_distance_km=10,  # 10 km de rayon maximum
            max_drivers=10  # Maximum 10 chauffeurs
        )
        
        return jsonify({
            "ride_id": ride.id,
            "status": ride_status,
            "available_drivers": available_drivers,
            "available_drivers_count": len(available_drivers),
            "pickup_location": {
                "latitude": ride.pickup_latitude,
                "longitude": ride.pickup_longitude,
                "address": ride.pickup_address
            }
        }), 200
        
    except Exception as e:
        current_app.logger.error(f"[GET_AVAILABLE_DRIVERS] Erreur: {e}")
        import traceback
        current_app.logger.error(traceback.format_exc())
        return jsonify({"error": f"Erreur: {str(e)}"}), 500


@rides_bp.route('/<int:ride_id>/accept', methods=['POST'])
@jwt_required()
def accept_ride(ride_id):
    """
    Accepter une course (appelé par le chauffeur)
    
    Body: {} (vide)
    
    Returns:
        200: Course acceptée avec succès
        400: Course invalide ou statut incorrect
        403: Utilisateur n'est pas un chauffeur
        404: Course non trouvée
    
    Note: Les requêtes OPTIONS (preflight CORS) sont gérées automatiquement par Flask-CORS
    grâce à la configuration automatic_options=True dans app.py
    """
    try:
        current_user_id = get_jwt_identity()
        # Convertir en int car l'identité est stockée comme string dans le JWT
        current_user_id = int(current_user_id) if isinstance(current_user_id, str) else current_user_id
        
        # Vérifier si l'utilisateur est un chauffeur
        from models import User, Driver
        user = User.query.get(current_user_id)
        if not user:
            return jsonify({"msg": "user not found"}), 404
        
        driver = Driver.query.filter_by(user_id=user.id).first()
        if not driver:
            return jsonify({"msg": "only drivers can accept rides"}), 403
        
        # Récupérer la course
        ride = Ride.query.get(ride_id)
        if not ride:
            return jsonify({"msg": "ride not found"}), 404
        
        # Vérifier le statut de la course
        # Le statut peut être 'pending' (nouveau modèle) ou 'requested' (ancien modèle)
        valid_statuses = ['pending', 'requested']
        if isinstance(ride.status, RideStatus):
            ride_status_str = ride.status.value if hasattr(ride.status, 'value') else str(ride.status)
        else:
            ride_status_str = str(ride.status).lower()
        
        if ride_status_str not in valid_statuses:
            return jsonify({"msg": f"invalid ride status: {ride_status_str}. Ride must be pending or requested."}), 400
        
        # Vérifier si la course a déjà un chauffeur
        if ride.driver_id is not None:
            # Récupérer les informations du chauffeur déjà assigné pour information
            assigned_driver = Driver.query.get(ride.driver_id)
            driver_info = None
            if assigned_driver:
                driver_info = {
                    "id": assigned_driver.id,
                    "full_name": assigned_driver.full_name,
                    "phone": assigned_driver.phone,
                }
            return jsonify({
                "msg": "ride already has a driver assigned",
                "assigned_driver": driver_info,
                "ride_id": ride.id
            }), 400
        
        # Assigner le chauffeur à la course
        ride.driver_id = driver.id
        
        # Mettre à jour le statut
        try:
            # Utiliser le nouveau modèle avec Enum
            ride.status = RideStatus.DRIVER_ASSIGNED
        except:
            # Fallback pour l'ancien modèle
            ride.status = 'accepted'
        
        # Mettre à jour les timestamps
        ride.confirmed_at = datetime.utcnow()
        
        # Commit les changements
        db.session.commit()
        
        # Récupérer les informations complètes de la course pour la réponse
        ride_dict = ride.to_dict()
        
        # Log pour le débogage
        print(f"✅ [ACCEPT_RIDE] Course {ride.id} acceptée par le chauffeur {driver.id} (user_id: {user.id})")
        print(f"   Statut: {ride.status}")
        print(f"   Chauffeur: {driver.full_name}")
        print(f"   Client: {ride.user_id}")
        
        return jsonify({
            "msg": "accepted",
            "ride_id": ride.id,
            "status": ride.status.value if isinstance(ride.status, RideStatus) else str(ride.status),
            "driver": {
                "id": driver.id,
                "user_id": driver.user_id,
                "full_name": driver.full_name,
                "phone": driver.phone,
                "car_make": driver.car_make if hasattr(driver, 'car_make') else None,
                "car_model": driver.car_model if hasattr(driver, 'car_model') else None,
                "car_color": driver.car_color if hasattr(driver, 'car_color') else None,
                "license_plate": driver.license_plate if hasattr(driver, 'license_plate') else None,
                "rating_average": driver.rating_average if hasattr(driver, 'rating_average') else 0.0,
            },
            "ride": ride_dict
        }), 200
    
    except Exception as e:
        db.session.rollback()
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'Erreur lors de l\'acceptation de la course: {str(e)}'}), 500


@rides_bp.route('/<int:ride_id>', methods=['GET'])
@jwt_required()
def get_ride(ride_id):
    """Obtenir les détails d'une course"""
    try:
        user_id = get_jwt_identity()
        # Convertir en int car l'identité est stockée comme string dans le JWT
        user_id = int(user_id) if isinstance(user_id, str) else user_id
        ride = Ride.query.filter_by(id=ride_id, user_id=user_id).first()
        
        if not ride:
            return jsonify({'error': 'Course non trouvée'}), 404
        
        return jsonify({
            'ride': ride.to_dict(),
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@rides_bp.route('/<int:ride_id>/cancel', methods=['POST'])
@jwt_required()
def cancel_ride(ride_id):
    """Annuler une course"""
    try:
        user_id = get_jwt_identity()
        # Convertir en int car l'identité est stockée comme string dans le JWT
        user_id = int(user_id) if isinstance(user_id, str) else user_id
        ride = Ride.query.filter_by(id=ride_id, user_id=user_id).first()
        
        if not ride:
            return jsonify({'error': 'Course non trouvée'}), 404
        
        if ride.status in [RideStatus.COMPLETED, RideStatus.CANCELLED]:
            return jsonify({'error': 'Cette course ne peut pas être annulée'}), 400
        
        ride.status = RideStatus.CANCELLED
        ride.cancelled_at = datetime.utcnow()
        
        db.session.commit()
        
        return jsonify({
            'message': 'Course annulée avec succès',
            'ride': ride.to_dict(),
        }), 200
    
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500
