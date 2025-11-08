# 🔍 Debug CORS - Problème "Failed to fetch"

## ❌ Problème

Les requêtes OPTIONS (preflight) fonctionnent, mais les requêtes POST ne partent pas du client Flutter Web.

## 🔍 Diagnostic

### Ce qui fonctionne ✅
- Serveur Flask actif sur `http://0.0.0.0:5000`
- Requêtes OPTIONS arrivent au serveur (logs visibles)
- Headers CORS retournés correctement
- Flask-CORS configuré

### Ce qui ne fonctionne pas ❌
- Les requêtes POST n'arrivent pas au serveur
- Erreur "Failed to fetch" dans Flutter Web
- Aucun log de requête POST dans le serveur

## 🔧 Solutions à tester

### 1. Vérifier les DevTools du navigateur

Ouvrez les DevTools (F12) dans Chrome et vérifiez :
- **Onglet Console** : Messages d'erreur CORS détaillés
- **Onglet Network** : 
  - Voir si la requête POST apparaît
  - Vérifier les headers de la requête OPTIONS
  - Vérifier les headers de la réponse OPTIONS

### 2. Vérifier la réponse OPTIONS

Dans l'onglet Network, cliquez sur la requête OPTIONS et vérifiez :
- **Response Headers** doivent contenir :
  - `Access-Control-Allow-Origin: *`
  - `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH`
  - `Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With`

### 3. Tester avec curl/Postman

Testez directement depuis la ligne de commande :

```bash
# Test OPTIONS
curl -X OPTIONS -H "Origin: http://localhost:3426" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v http://127.0.0.1:5000/api/v1/auth/login

# Test POST
curl -X POST -H "Content-Type: application/json" \
  -H "Origin: http://localhost:3426" \
  -d '{"email":"admin@temove.sn","password":"test"}' \
  -v http://127.0.0.1:5000/api/v1/auth/login
```

### 4. Vérifier la configuration Flutter Web

Dans `lib/services/api_service.dart`, vérifiez que `baseUrl` est correct :
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://127.0.0.1:5000/api/v1';  // ou 'http://localhost:5000/api/v1'
  }
  // ...
}
```

### 5. Problème connu : Flutter Web et CORS

Flutter Web peut avoir des problèmes avec CORS. Solutions possibles :

#### Option A : Utiliser un proxy CORS
Ajoutez un fichier `web/index.html` avec un proxy :
```html
<script>
  // Proxy pour contourner CORS (développement uniquement)
</script>
```

#### Option B : Désactiver la sécurité CORS du navigateur (DÉVELOPPEMENT UNIQUEMENT)
Lancez Chrome avec :
```bash
chrome.exe --user-data-dir="C:/temp/chrome_dev" --disable-web-security --disable-features=VizDisplayCompositor
```

⚠️ **ATTENTION** : Ne jamais utiliser en production !

### 6. Vérifier les logs du serveur

Après une tentative de connexion, vous devriez voir :
- `✅ [CORS_GLOBAL] OPTIONS preflight pour /api/v1/auth/login`
- `📤 [POST_REQUEST] /api/v1/auth/login depuis 127.0.0.1` ← Si cette ligne n'apparaît pas, la requête POST ne part pas

## 🎯 Solution probable

Le problème vient probablement du fait que Flutter Web bloque la requête POST après le preflight à cause d'un problème de configuration CORS ou d'un problème réseau.

**Action immédiate** : 
1. Ouvrez les DevTools (F12)
2. Allez dans l'onglet Network
3. Tentez de vous connecter
4. Regardez si la requête POST apparaît et quels sont les messages d'erreur

