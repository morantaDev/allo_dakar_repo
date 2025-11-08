# Exemple de Requête API - TeMove

## Vue d'ensemble

Ce document fournit des exemples concrets de requêtes API entre Flutter et Flask pour le projet TeMove.

## Configuration de base

### URL du backend

```dart
// Dans api_service.dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:5000/api/v1';
  } else {
    // Pour Android émulateur : 'http://10.0.2.2:5000/api/v1'
    // Pour appareil physique : utiliser votre IP locale
    return 'http://192.168.18.10:5000/api/v1';
  }
}
```

## Exemples de requêtes

### 1. Inscription (Register)

**Endpoint :** `POST /api/v1/auth/register`

**Requête Flutter :**
```dart
final response = await ApiService.register(
  email: 'nouveau@example.com',
  password: 'motdepasse123',
  fullName: 'Jean Dupont',
  phone: '+221771234567',
);
```

**Requête HTTP :**
```http
POST /api/v1/auth/register HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Origin: http://localhost:3000

{
  "email": "nouveau@example.com",
  "password": "motdepasse123",
  "full_name": "Jean Dupont",
  "phone": "+221771234567"
}
```

**Réponse (201 Created) :**
```json
{
  "message": "Inscription réussie",
  "user": {
    "id": 1,
    "email": "nouveau@example.com",
    "full_name": "Jean Dupont",
    "phone": "+221771234567",
    "role": "client",
    "is_active": true
  },
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "referral_credit": 0
}
```

### 2. Connexion (Login)

**Endpoint :** `POST /api/v1/auth/login`

**Requête Flutter :**
```dart
final response = await ApiService.login(
  email: 'nouveau@example.com',
  password: 'motdepasse123',
);
```

**Requête HTTP :**
```http
POST /api/v1/auth/login HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Origin: http://localhost:3000

{
  "email": "nouveau@example.com",
  "password": "motdepasse123"
}
```

**Réponse (200 OK) :**
```json
{
  "message": "Connexion réussie",
  "user": {
    "id": 1,
    "email": "nouveau@example.com",
    "full_name": "Jean Dupont",
    "is_admin": false
  },
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

### 3. Estimation de trajet (Trip Estimate)

**Endpoint :** `POST /api/v1/rides/estimate`

**Requête Flutter :**
```dart
final response = await ApiService.getTripEstimate(
  departureLat: 14.7167,      // Latitude Dakar
  departureLng: -17.4677,      // Longitude Dakar
  destinationLat: 14.7500,     // Latitude destination
  destinationLng: -17.4833,    // Longitude destination
  rideMode: 'eco',             // Mode: eco, confort, confortPlus, etc.
);
```

**Requête HTTP (avec preflight OPTIONS) :**
```http
# Requête preflight (OPTIONS)
OPTIONS /api/v1/rides/estimate HTTP/1.1
Host: 127.0.0.1:5000
Origin: http://localhost:3000
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization

# Réponse preflight
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin
Access-Control-Max-Age: 3600

# Requête réelle (POST)
POST /api/v1/rides/estimate HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Origin: http://localhost:3000

{
  "pickup_latitude": 14.7167,
  "pickup_longitude": -17.4677,
  "dropoff_latitude": 14.7500,
  "dropoff_longitude": -17.4833,
  "ride_mode": "eco"
}
```

**Réponse (200 OK) :**
```json
{
  "estimate": {
    "distance_km": 5.2,
    "duration_minutes": 15,
    "price_xof": 1560,
    "ride_mode": "eco",
    "base_fare": 500,
    "distance_fare": 1060
  },
  "promo_applied": false
}
```

### 4. Réservation de course (Book Ride)

**Endpoint :** `POST /api/v1/rides/book`

**Requête Flutter :**
```dart
final response = await ApiService.bookRide(
  departureLat: 14.7167,
  departureLng: -17.4677,
  departureAddress: 'Plateau, Dakar',
  destinationLat: 14.7500,
  destinationLng: -17.4833,
  destinationAddress: 'Almadies, Dakar',
  rideMode: 'eco',
  rideCategory: 'standard',
  paymentMethod: 'cash',
  promoCode: 'WELCOME10',  // Optionnel
);
```

**Requête HTTP :**
```http
POST /api/v1/rides/book HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Origin: http://localhost:3000

{
  "pickup_latitude": 14.7167,
  "pickup_longitude": -17.4677,
  "pickup_address": "Plateau, Dakar",
  "dropoff_latitude": 14.7500,
  "dropoff_longitude": -17.4833,
  "dropoff_address": "Almadies, Dakar",
  "ride_mode": "eco",
  "ride_category": "standard",
  "payment_method": "cash",
  "promo_code": "WELCOME10"
}
```

**Réponse (201 Created) :**
```json
{
  "message": "Réservation créée avec succès",
  "ride": {
    "id": 123,
    "user_id": 1,
    "pickup_latitude": 14.7167,
    "pickup_longitude": -17.4677,
    "pickup_address": "Plateau, Dakar",
    "dropoff_latitude": 14.7500,
    "dropoff_longitude": -17.4833,
    "dropoff_address": "Almadies, Dakar",
    "status": "pending",
    "price_xof": 1560,
    "ride_mode": "eco",
    "created_at": "2024-01-15T10:30:00Z"
  }
}
```

### 5. Historique des courses (Ride History)

**Endpoint :** `GET /api/v1/rides/history`

**Requête Flutter :**
```dart
final response = await ApiService.getRideHistory();
```

**Requête HTTP :**
```http
GET /api/v1/rides/history HTTP/1.1
Host: 127.0.0.1:5000
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Origin: http://localhost:3000
```

**Réponse (200 OK) :**
```json
{
  "rides": [
    {
      "id": 123,
      "pickup_address": "Plateau, Dakar",
      "dropoff_address": "Almadies, Dakar",
      "status": "completed",
      "price_xof": 1560,
      "ride_mode": "eco",
      "created_at": "2024-01-15T10:30:00Z",
      "completed_at": "2024-01-15T10:45:00Z"
    },
    {
      "id": 122,
      "pickup_address": "Mermoz, Dakar",
      "dropoff_address": "Ouakam, Dakar",
      "status": "completed",
      "price_xof": 1200,
      "ride_mode": "eco",
      "created_at": "2024-01-14T15:20:00Z",
      "completed_at": "2024-01-14T15:35:00Z"
    }
  ],
  "total": 2
}
```

### 6. Dashboard Admin (Admin Dashboard Stats)

**Endpoint :** `GET /api/v1/admin/dashboard/stats`

**Requête Flutter :**
```dart
final response = await ApiService.getAdminDashboardStats();
```

**Requête HTTP :**
```http
GET /api/v1/admin/dashboard/stats HTTP/1.1
Host: 127.0.0.1:5000
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...
Origin: http://localhost:3000
```

**Réponse (200 OK) :**
```json
{
  "revenue": {
    "current_month": 1500000,
    "last_month": 1200000,
    "growth": 25.0,
    "commissions": 150000
  },
  "rides": {
    "today": 45,
    "completed_today": 40,
    "in_progress": 5,
    "current_month": 1200,
    "last_month": 1000,
    "growth": 20.0
  },
  "users": {
    "total": 500,
    "active_30d": 350
  },
  "drivers": {
    "active": 80
  },
  "period": {
    "year": 2024,
    "month": 1,
    "day": 15
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Gestion des erreurs

### Erreur d'authentification (401)

```json
{
  "error": "Token JWT invalide ou expiré. Veuillez vous reconnecter."
}
```

### Erreur de validation (400)

```json
{
  "error": "Email requis"
}
```

### Erreur serveur (500)

```json
{
  "error": "Erreur interne du serveur"
}
```

## Notes importantes

1. **Token JWT :** Toutes les requêtes authentifiées nécessitent un token JWT dans l'en-tête `Authorization: Bearer <token>`
2. **CORS :** Les requêtes depuis Flutter Web nécessitent une configuration CORS correcte
3. **Preflight :** Les requêtes avec headers personnalisés déclenchent automatiquement une requête OPTIONS préalable
4. **Format des dates :** Utiliser le format ISO 8601 pour les dates (`YYYY-MM-DDTHH:MM:SSZ`)
5. **Coordonnées GPS :** Utiliser le format décimal (latitude, longitude) avec 4-6 décimales de précision

## Test avec curl

```bash
# Test de connexion
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'

# Test d'estimation (avec token)
curl -X POST http://localhost:5000/api/v1/rides/estimate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{
    "pickup_latitude": 14.7167,
    "pickup_longitude": -17.4677,
    "dropoff_latitude": 14.7500,
    "dropoff_longitude": -17.4833,
    "ride_mode": "eco"
  }'
```

## Support

Pour plus d'informations, consultez la documentation CORS (`DOCUMENTATION_CORS.md`) ou les logs du serveur.

