"""
Routes pour les courses
"""
from flask import Blueprint, request, jsonify, make_response
from flask_jwt_extended import jwt_required, get_jwt_identity, decode_token
from datetime import datetime
from extensions import db
from models.ride import Ride, RideStatus, RideCategory, RideMode
from models.payment import Payment, PaymentMethod, PaymentStatus
from models.promo_code import PromoCode
from services.pricing_service import PricingService
from services.geolocation_service import GeolocationService

rides_bp = Blueprint('rides', __name__)




@rides_bp.route('/test', methods=['GET'])
def test_rides():
    return jsonify({'message': 'Rides blueprint fonctionne!'}), 200


# Handler pour les requêtes OPTIONS (CORS preflight)
@rides_bp.before_request
def handle_preflight():
    """Gérer les requêtes OPTIONS et logger les requêtes POST"""
    if request.method == "OPTIONS":
        response = make_response()
        response.headers.add("Access-Control-Allow-Origin", "*")
        response.headers.add('Access-Control-Allow-Headers', "Content-Type, Authorization, X-Requested-With")
        response.headers.add('Access-Control-Allow-Methods', "GET, POST, PUT, DELETE, OPTIONS, PATCH")
        response.headers.add('Access-Control-Max-Age', "3600")
        # Ne pas utiliser Access-Control-Allow-Credentials avec "*" (incompatible CORS)
        print(f"✅ [CORS] OPTIONS preflight pour {request.path} - Headers retournés", flush=True)
        return response
    
    # Log pour toutes les requêtes POST (avant validation JWT)
    if request.method == 'POST':
        auth_header = request.headers.get('Authorization', 'NON FOURNI')
        print(f"🚀 [BEFORE_REQUEST] {request.path} - Méthode: {request.method}")
        print(f"🚀 [BEFORE_REQUEST] En-tête Authorization présent: {'OUI' if auth_header != 'NON FOURNI' else 'NON'}")
        if auth_header != 'NON FOURNI':
            print(f"🚀 [BEFORE_REQUEST] Authorization (premiers 50 caractères): {auth_header[:50]}")
            # Essayer de décoder le token manuellement pour voir s'il est valide
            try:
                token = auth_header.replace('Bearer ', '').strip()
                from flask_jwt_extended import decode_token
                from flask import current_app
                with current_app.app_context():
                    decoded = decode_token(token)
                    print(f"✅ [BEFORE_REQUEST] Token décodé avec succès - ID Utilisateur: {decoded.get('sub', 'NON TROUVÉ')}", flush=True)
            except Exception as e:
                print(f"❌ [BEFORE_REQUEST] Erreur lors du décodage du token: {e}", flush=True)
                import traceback
                traceback.print_exc()
                import sys
                sys.stdout.flush()


# Ne pas ajouter de headers CORS ici - déjà géré par flask_cors et le handler global
# Les headers CORS sont déjà gérés par :
# 1. flask_cors (configuration globale)
# 2. @app.after_request dans app.py
# Ajouter ici créerait des doublons et causerait l'erreur "multiple values"


@rides_bp.route('/estimate', methods=['POST', 'OPTIONS'])
def estimate_ride():
    """Estimer le prix d'une course"""
    
    # 🚨 IMPORTANT : Gérer OPTIONS (CORS preflight) AVANT jwt_required
    if request.method == 'OPTIONS':
        response = make_response()
        response.headers.add("Access-Control-Allow-Origin", "*")
        response.headers.add('Access-Control-Allow-Headers', "Content-Type, Authorization, X-Requested-With")
        response.headers.add('Access-Control-Allow-Methods', "GET, POST, PUT, DELETE, OPTIONS, PATCH")
        response.headers.add('Access-Control-Max-Age', "3600")
        return response
    
    # Maintenant on peut vérifier le JWT pour les requêtes POST
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
        
        # Commit final
        try:
            db.session.commit()
            print(f"✅ Course et paiement sauvegardés avec succès - Ride ID: {ride.id}, Utilisateur: {user_id}")
        except Exception as db_error:
            db.session.rollback()
            print(f"❌ Erreur base de données: {db_error}")
            import traceback
            traceback.print_exc()
            print("="*60 + "\n")
            return jsonify({'error': f'Erreur base de données: {str(db_error)}'}), 500
        
        result = {
            'message': 'Réservation créée avec succès',
            'ride': ride.to_dict(),
        }
        
        print(f"\n✅ SUCCÈS - Réponse envoyée")
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
