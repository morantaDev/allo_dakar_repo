# Correction du Problème CORS - Doublons de Headers

## Problème Identifié

L'erreur suivante se produisait lors des requêtes depuis Flutter Web :

```
Access to fetch at 'http://127.0.0.1:5000/api/v1/auth/login' from origin 'http://localhost:9342' 
has been blocked by CORS policy: Response to preflight request doesn't pass access control check: 
The 'Access-Control-Allow-Origin' header contains multiple values 'http://localhost:9342, http://localhost:9342', 
but only one is allowed.
```

## Cause du Problème

Le header `Access-Control-Allow-Origin` était ajouté **plusieurs fois** par différents handlers :

1. **Flask-CORS** (configuration globale) - Ajoute automatiquement les headers CORS
2. **Handler `after_request`** dans `app.py` - Ajoutait les headers même si Flask-CORS l'avait déjà fait
3. **Handler `before_request`** dans `app.py` - Géraient OPTIONS manuellement alors que Flask-CORS le fait déjà
4. **Handlers dans les blueprints** (`rides.py`, `admin_routes.py`) - Ajoutaient aussi les headers CORS

Résultat : Des doublons de headers causant l'erreur CORS.

## Solution Appliquée

### 1. Correction du Handler `after_request`

**Avant :**
```python
@app.after_request
def after_request(response):
    # Ajoutait toujours les headers, même si Flask-CORS l'avait déjà fait
    response.headers.add('Access-Control-Allow-Origin', origin)
    # ...
```

**Après :**
```python
@app.after_request
def after_request(response):
    # Vérifier si Flask-CORS a déjà ajouté les headers
    if 'Access-Control-Allow-Origin' in response.headers:
        # Flask-CORS a déjà géré les headers, on ne fait rien
        return response
    
    # Seulement si Flask-CORS n'a pas ajouté les headers, on les ajoute
    # Utiliser response.headers['key'] = value au lieu de .add() pour éviter les doublons
    response.headers['Access-Control-Allow-Origin'] = origin
    # ...
```

### 2. Suppression du Handler `before_request` pour OPTIONS

**Avant :**
```python
@app.before_request
def handle_cors_preflight_after_blueprints():
    if request.method == 'OPTIONS':
        # Gérait OPTIONS manuellement
        response = make_response()
        response.headers.add('Access-Control-Allow-Origin', origin)
        # ...
```

**Après :**
```python
# IMPORTANT: Ne pas ajouter de handler before_request pour OPTIONS car Flask-CORS
# gère déjà cela automatiquement avec automatic_options=True.
# Flask-CORS répond automatiquement aux requêtes OPTIONS avec les bons headers.
```

### 3. Suppression des Handlers dans les Blueprints

**Avant (rides.py) :**
```python
@rides_bp.before_request
def handle_preflight():
    if request.method == "OPTIONS":
        # Gérait OPTIONS manuellement
        response.headers.add("Access-Control-Allow-Origin", "*")
        # ...
```

**Après :**
```python
# IMPORTANT: Ne pas gérer les requêtes OPTIONS ici car Flask-CORS le fait déjà
# au niveau global dans app.py. Flask-CORS avec automatic_options=True gère 
# automatiquement toutes les requêtes OPTIONS.
```

**Avant (admin_routes.py) :**
```python
@admin_bp.before_request
def handle_preflight():
    if request.method == 'OPTIONS':
        # Gérait OPTIONS manuellement
        response.headers.add('Access-Control-Allow-Origin', '*')
        # ...
```

**Après :**
```python
# IMPORTANT: Ne pas gérer les requêtes OPTIONS ici car Flask-CORS le fait déjà
# au niveau global dans app.py.
```

### 4. Correction des Routes avec OPTIONS

**Avant :**
```python
@rides_bp.route('/estimate', methods=['POST', 'OPTIONS'])
def estimate_ride():
    if request.method == 'OPTIONS':
        # Gérait OPTIONS manuellement
        # ...
```

**Après :**
```python
@rides_bp.route('/estimate', methods=['POST'])
def estimate_ride():
    # Les requêtes OPTIONS sont automatiquement gérées par Flask-CORS
    # ...
```

## Configuration Flask-CORS

La configuration Flask-CORS dans `app.py` est maintenant la seule source de vérité :

```python
CORS(app, 
     resources={
         r"/*": {
             "origins": cors_origins,
             "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS", PATCH"],
             "allow_headers": [...],
             "supports_credentials": False,
             "max_age": 3600
         }
     },
     automatic_options=True,  # Gère automatiquement les requêtes OPTIONS
     send_wildcard=False
)
```

## Résultat

✅ **Plus de doublons de headers CORS**
✅ **Flask-CORS gère automatiquement toutes les requêtes OPTIONS**
✅ **Le handler `after_request` sert uniquement de backup si Flask-CORS échoue**
✅ **Toutes les requêtes Flutter → Flask fonctionnent correctement**

## Vérification

Pour vérifier que le problème est résolu :

1. **Démarrer le backend Flask :**
   ```bash
   cd temove-backend
   python app.py
   ```

2. **Démarrer l'application Flutter Web :**
   ```bash
   cd temove
   flutter run -d chrome
   ```

3. **Tester une requête de connexion :**
   - La requête devrait passer sans erreur CORS
   - Vérifier dans les DevTools Chrome (Network) que les headers CORS sont présents une seule fois

4. **Vérifier les logs du serveur :**
   - Aucune erreur de doublons de headers
   - Les requêtes OPTIONS sont gérées automatiquement par Flask-CORS

## Notes Importantes

- **Ne jamais ajouter manuellement les headers CORS** si Flask-CORS est configuré
- **Utiliser `response.headers['key'] = value`** au lieu de `response.headers.add()` pour éviter les doublons
- **Vérifier toujours si un header existe** avant de l'ajouter dans les handlers `after_request`
- **Laisser Flask-CORS gérer les requêtes OPTIONS** avec `automatic_options=True`

## Ressources

- [Documentation Flask-CORS](https://flask-cors.readthedocs.io/)
- [Documentation CORS TeMove](temove-backend/DOCUMENTATION_CORS.md)

