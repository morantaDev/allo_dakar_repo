# Documentation CORS - TeMove Backend

## Vue d'ensemble

Cette documentation explique la configuration CORS (Cross-Origin Resource Sharing) du backend TeMove pour permettre la communication entre les applications Flutter (Client, Pro) et l'API Flask.

## Configuration CORS

### Architecture

Le backend TeMove utilise une configuration CORS multicouche pour garantir une compatibilité maximale :

1. **Flask-CORS** (configuration globale) - Gère automatiquement les requêtes CORS
2. **Handler `after_request`** - Backup pour ajouter les headers CORS à toutes les réponses
3. **Handler `before_request`** - Gère les requêtes OPTIONS (preflight) après l'enregistrement des blueprints

### Configuration dans `app.py`

```python
# Configuration CORS globale
CORS(app, 
     resources={
         r"/*": {
             "origins": cors_origins,  # '*' en développement, liste spécifique en production
             "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
             "allow_headers": [
                 "Content-Type", 
                 "Authorization", 
                 "X-Requested-With",
                 "Accept",
                 "Origin",
                 ...
             ],
             "supports_credentials": False,
             "max_age": 3600
         }
     },
     automatic_options=True,
     send_wildcard=False
)
```

### Variables d'environnement

Configurez les origines autorisées via la variable d'environnement `CORS_ORIGINS` :

```bash
# .env
CORS_ORIGINS=http://localhost:3000,http://localhost:5000,https://temove.com
```

En développement, si `CORS_ORIGINS` n'est pas défini, toutes les origines (`*`) sont autorisées.

## Requêtes CORS

### Requêtes simples (Simple Requests)

Les requêtes GET, HEAD et certaines requêtes POST ne nécessitent pas de requête preflight.

**Exemple :**
```http
GET /api/v1/health HTTP/1.1
Host: localhost:5000
Origin: http://localhost:3000
```

### Requêtes preflight (Preflight Requests)

Les requêtes avec headers personnalisés (comme `Authorization`) nécessitent une requête OPTIONS préalable.

**Exemple de requête preflight :**
```http
OPTIONS /api/v1/rides/estimate HTTP/1.1
Host: localhost:5000
Origin: http://localhost:3000
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization
```

**Réponse preflight :**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin
Access-Control-Max-Age: 3600
```

## Exemple de requête API complète (Flutter → Flask)

### 1. Connexion (Login)

**Requête Flutter :**
```dart
final response = await http.post(
  Uri.parse('http://127.0.0.1:5000/api/v1/auth/login'),
  headers: {
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'email': 'user@example.com',
    'password': 'password123',
  }),
);
```

**Requête HTTP envoyée :**
```http
POST /api/v1/auth/login HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Origin: http://localhost:3000

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Réponse Flask :**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:3000
Content-Type: application/json

{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "full_name": "John Doe"
  }
}
```

### 2. Requête authentifiée (avec JWT)

**Requête Flutter :**
```dart
final response = await http.post(
  Uri.parse('http://127.0.0.1:5000/api/v1/rides/estimate'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer eyJ0eXAiOiJKV1QiLCJhbGc...',
  },
  body: jsonEncode({
    'pickup_latitude': 14.7167,
    'pickup_longitude': -17.4677,
    'dropoff_latitude': 14.7500,
    'dropoff_longitude': -17.4833,
    'ride_mode': 'eco',
  }),
);
```

**Requête preflight (OPTIONS) :**
```http
OPTIONS /api/v1/rides/estimate HTTP/1.1
Host: 127.0.0.1:5000
Origin: http://localhost:3000
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization
```

**Réponse preflight :**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH
Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin
Access-Control-Max-Age: 3600
```

**Requête réelle (POST) :**
```http
POST /api/v1/rides/estimate HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
Origin: http://localhost:3000

{
  "pickup_latitude": 14.7167,
  "pickup_longitude": -17.4677,
  "dropoff_latitude": 14.7500,
  "dropoff_longitude": -17.4833,
  "ride_mode": "eco"
}
```

**Réponse Flask :**
```http
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:3000
Content-Type: application/json

{
  "estimate": {
    "distance_km": 5.2,
    "duration_minutes": 15,
    "price_xof": 1560,
    "ride_mode": "eco"
  }
}
```

## Dépannage CORS

### Erreur : "Access to XMLHttpRequest blocked by CORS policy"

**Cause :** L'origine de la requête n'est pas autorisée ou les headers CORS ne sont pas correctement configurés.

**Solution :**
1. Vérifier que `CORS_ORIGINS` inclut l'origine de la requête
2. Vérifier que les headers `Authorization` et `Content-Type` sont dans `allow_headers`
3. Vérifier que la méthode HTTP est dans `allow_methods`

### Erreur : "Preflight response is not successful"

**Cause :** La requête OPTIONS (preflight) ne retourne pas un status 200.

**Solution :**
1. Vérifier que le handler `before_request` gère correctement les requêtes OPTIONS
2. Vérifier que `automatic_options=True` est défini dans la configuration CORS
3. Vérifier les logs du serveur pour voir la réponse à la requête OPTIONS

### Erreur : "Multiple values for 'Access-Control-Allow-Origin'"

**Cause :** Les headers CORS sont ajoutés plusieurs fois (par Flask-CORS et par le handler `after_request`).

**Solution :**
1. S'assurer que le handler `after_request` ne duplique pas les headers déjà ajoutés par Flask-CORS
2. Utiliser `response.headers.get()` avant d'ajouter un header pour éviter les doublons

## Configuration pour la production

### 1. Définir les origines autorisées

```bash
# .env (production)
CORS_ORIGINS=https://app.temove.com,https://pro.temove.com,https://admin.temove.com
```

### 2. Désactiver le mode debug

```python
# config.py
class ProductionConfig(Config):
    DEBUG = False
    CORS_ORIGINS = os.environ.get('CORS_ORIGINS', '').split(',')
```

### 3. Activer HTTPS

En production, utilisez HTTPS pour toutes les communications. Les navigateurs bloquent les requêtes CORS mixtes (HTTP/HTTPS).

## Test de la configuration CORS

### Test avec curl

```bash
# Test de requête preflight
curl -X OPTIONS http://localhost:5000/api/v1/rides/estimate \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type, Authorization" \
  -v

# Test de requête réelle
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Origin: http://localhost:3000" \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}' \
  -v
```

### Test avec Postman

1. Créer une nouvelle requête
2. Ajouter l'en-tête `Origin: http://localhost:3000`
3. Envoyer la requête
4. Vérifier que la réponse contient les headers CORS

## Ressources

- [Documentation Flask-CORS](https://flask-cors.readthedocs.io/)
- [MDN - CORS](https://developer.mozilla.org/fr/docs/Web/HTTP/CORS)
- [CORS Headers Explained](https://www.stackhawk.com/blog/flask-cors-guide/)

## Support

Pour toute question sur la configuration CORS, consultez les logs du serveur ou contactez l'équipe de développement.
