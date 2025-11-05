# Endpoints Backend Requis

Ce document liste les endpoints que vous devez créer sur votre backend Flask pour que l'application fonctionne complètement.

## Endpoints Requis

### 1. POST `/api/v1/rides/estimate`

Calcule une estimation de trajet (distance, durée, prix).

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <token> (optionnel)
```

**Body:**
```json
{
  "departure_lat": 14.7167,
  "departure_lng": -17.4677,
  "destination_lat": 14.6928,
  "destination_lng": -17.4467,
  "ride_mode": "confort" (optionnel)
}
```

**Response 200:**
```json
{
  "distance_km": 5.2,
  "duration_minutes": 15,
  "base_price": 2500,
  "estimated_price": 3750,
  "final_price": 3750,
  "surge_multiplier": 1.5,
  "formatted_distance": "5.2 km",
  "formatted_duration": "15 min"
}
```

**Exemple d'implémentation Flask:**
```python
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
import math

rides_bp = Blueprint('rides', __name__)

@rides_bp.route('/estimate', methods=['POST'])
def estimate_ride():
    data = request.get_json()
    
    departure_lat = data.get('departure_lat')
    departure_lng = data.get('departure_lng')
    destination_lat = data.get('destination_lat')
    destination_lng = data.get('destination_lng')
    ride_mode = data.get('ride_mode', 'confort')
    
    # Calculer la distance (formule de Haversine)
    def calculate_distance(lat1, lon1, lat2, lon2):
        R = 6371  # Rayon de la Terre en km
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = (math.sin(dlat/2)**2 + 
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * 
             math.sin(dlon/2)**2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c
    
    distance_km = calculate_distance(departure_lat, departure_lng, 
                                     destination_lat, destination_lng)
    
    # Estimation durée (moyenne 30 km/h à Dakar)
    duration_minutes = int((distance_km / 0.5))  # 0.5 km/min = 30 km/h
    
    # Prix de base selon le mode
    base_prices = {
        'eco': 1500,
        'confort': 2500,
        'confortPlus': 4000,
        'partageTaxi': 1200,
        'famille': 4500,
        'premium': 6000
    }
    
    price_per_km = base_prices.get(ride_mode, 2500) / 5  # Prix par km
    base_price = int(distance_km * price_per_km)
    
    # Surge pricing (heures de pointe)
    from datetime import datetime
    hour = datetime.now().hour
    if (hour >= 7 and hour < 9) or (hour >= 17 and hour < 19):
        surge_multiplier = 1.5
    elif hour >= 22 or hour < 6:
        surge_multiplier = 1.2
    else:
        surge_multiplier = 1.0
    
    final_price = int(base_price * surge_multiplier)
    
    return jsonify({
        'distance_km': round(distance_km, 2),
        'duration_minutes': duration_minutes,
        'base_price': base_price,
        'estimated_price': final_price,
        'final_price': final_price,
        'surge_multiplier': surge_multiplier if surge_multiplier > 1.0 else None,
        'formatted_distance': f'{distance_km:.1f} km' if distance_km >= 1 else f'{int(distance_km * 1000)} m',
        'formatted_duration': f'{duration_minutes} min' if duration_minutes < 60 else f'{duration_minutes // 60}h {duration_minutes % 60}'
    }), 200
```

---

### 2. POST `/api/v1/rides/book`

Crée une réservation de course.

**Headers:**
```
Content-Type: application/json
Authorization: Bearer <token> (requis)
```

**Body:**
```json
{
  "departure_lat": 14.7167,
  "departure_lng": -17.4677,
  "departure_address": "Almadies, Dakar",
  "destination_lat": 14.6928,
  "destination_lng": -17.4467,
  "destination_address": "Plateau, Dakar",
  "ride_mode": "confort",
  "ride_category": "course",
  "payment_method": "om",
  "promo_code": "WELCOME10" (optionnel),
  "scheduled_at": "2024-01-15T10:30:00Z" (optionnel)
}
```

**Response 201:**
```json
{
  "message": "Réservation créée avec succès",
  "ride": {
    "id": 123,
    "status": "pending",
    "estimated_price": 3750,
    "departure_address": "Almadies, Dakar",
    "destination_address": "Plateau, Dakar",
    "scheduled_at": null,
    "created_at": "2024-01-14T10:30:00Z"
  }
}
```

**Exemple d'implémentation Flask:**
```python
@rides_bp.route('/book', methods=['POST'])
@jwt_required()
def book_ride():
    from datetime import datetime, timedelta
    from models.ride import Ride, RideStatus
    from models.user import User
    
    current_user_id = get_jwt_identity()
    data = request.get_json()
    
    # Validation des données
    required_fields = ['departure_lat', 'departure_lng', 'departure_address',
                      'destination_lat', 'destination_lng', 'destination_address',
                      'ride_mode', 'ride_category', 'payment_method']
    
    for field in required_fields:
        if field not in data:
            return jsonify({'error': f'Champ requis manquant: {field}'}), 400
    
    # Vérifier la réservation à l'avance
    scheduled_at = None
    if data.get('scheduled_at'):
        try:
            scheduled_at = datetime.fromisoformat(data['scheduled_at'].replace('Z', '+00:00'))
            # Vérifier que c'est dans les 48h
            min_time = datetime.utcnow() + timedelta(minutes=5)  # Au moins 5 min
            max_time = datetime.utcnow() + timedelta(hours=48)
            
            if scheduled_at < min_time:
                return jsonify({'error': 'Réservation doit être au moins 5 minutes à l\'avance'}), 400
            if scheduled_at > max_time:
                return jsonify({'error': 'Réservation max 48h à l\'avance'}), 400
        except ValueError:
            return jsonify({'error': 'Format de date invalide'}), 400
    
    # Calculer le prix (ou utiliser l'estimation)
    # Vous pouvez réutiliser la logique de /estimate ici
    
    # Créer la réservation
    ride = Ride(
        user_id=current_user_id,
        departure_lat=data['departure_lat'],
        departure_lng=data['departure_lng'],
        departure_address=data['departure_address'],
        destination_lat=data['destination_lat'],
        destination_lng=data['destination_lng'],
        destination_address=data['destination_address'],
        ride_mode=data['ride_mode'],
        ride_category=data['ride_category'],
        payment_method=data['payment_method'],
        promo_code=data.get('promo_code'),
        scheduled_at=scheduled_at,
        status=RideStatus.SCHEDULED if scheduled_at else RideStatus.PENDING,
        estimated_price=final_price  # Calculé précédemment
    )
    
    db.session.add(ride)
    db.session.commit()
    
    return jsonify({
        'message': 'Réservation créée avec succès',
        'ride': {
            'id': ride.id,
            'status': ride.status.value,
            'estimated_price': ride.estimated_price,
            'departure_address': ride.departure_address,
            'destination_address': ride.destination_address,
            'scheduled_at': ride.scheduled_at.isoformat() if ride.scheduled_at else None,
            'created_at': ride.created_at.isoformat()
        }
    }), 201
```

---

## Enregistrement des Blueprints

Dans votre `app.py` ou `__init__.py`:

```python
from routes.rides import rides_bp

app.register_blueprint(rides_bp, url_prefix='/api/v1/rides')
```

---

## Notes Importantes

1. **Authentification**: L'endpoint `/book` nécessite une authentification JWT. L'endpoint `/estimate` peut être optionnel.

2. **Validation**: Validez toujours les données entrantes.

3. **Gestion d'erreurs**: Retournez des codes HTTP appropriés (400 pour erreurs client, 500 pour erreurs serveur).

4. **CORS**: Assurez-vous que CORS est configuré pour permettre les requêtes depuis votre application Flutter.

5. **Base de données**: Adaptez les modèles selon votre structure de base de données.

