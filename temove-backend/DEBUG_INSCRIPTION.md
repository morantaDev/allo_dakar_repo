# 🔍 Debug - Inscription Frontend

## ❌ Problème identifié

L'inscription depuis le frontend ne crée pas d'utilisateur dans MySQL. Les logs du serveur ne montrent **aucune requête** vers `/api/v1/auth/register`, ce qui signifie que la requête n'atteint pas le backend.

## 🔍 Causes possibles

### 1. **URL incorrecte dans le frontend**

Le frontend Flutter doit utiliser :
```dart
const String API_BASE_URL = 'http://localhost:5000/api/v1';
```

**Vérifiez dans votre code Flutter :**
- Cherchez le fichier qui contient la configuration de l'API
- Cherchez `API_BASE_URL`, `baseUrl`, ou `BASE_URL`
- Vérifiez qu'il pointe vers `http://localhost:5000/api/v1`

### 2. **Problème CORS**

Le backend doit autoriser les requêtes depuis `localhost` (Chrome).

**Vérifiez dans Chrome DevTools (F12) :**
- Onglet **Console** : Cherchez les erreurs CORS
- Message typique : `Access to XMLHttpRequest at 'http://localhost:5000/...' from origin 'http://localhost:xxxxx' has been blocked by CORS policy`

### 3. **Requête non envoyée**

Le frontend n'envoie peut-être pas la requête.

**Vérifiez dans Chrome DevTools (F12) :**
- Onglet **Network**
- Cherchez une requête vers `/register` ou `/auth/register`
- Si aucune requête n'apparaît, le code Flutter ne l'envoie pas

### 4. **Erreur silencieuse**

Le frontend peut avoir une erreur qui n'est pas affichée.

**Vérifiez dans Chrome DevTools (F12) :**
- Onglet **Console** : Cherchez les erreurs JavaScript/Dart
- Onglet **Network** : Regardez s'il y a des requêtes en rouge (échec)

## 🧪 Test rapide

### Test 1 : Vérifier que le backend répond

Ouvrez dans Chrome : http://localhost:5000/health

### Test 2 : Tester l'inscription directement

Dans Chrome DevTools > Console, exécutez :

```javascript
fetch('http://localhost:5000/api/v1/auth/register', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    email: 'test@example.com',
    password: 'test123',
    full_name: 'Test User'
  })
})
.then(r => r.json())
.then(console.log)
.catch(console.error);
```

### Test 3 : Vérifier l'URL dans Flutter

Dans votre code Flutter, cherchez où l'URL de l'API est définie et vérifiez qu'elle est correcte.

## ✅ Checklist de vérification

- [ ] Backend lancé sur http://localhost:5000
- [ ] URL dans Flutter : `http://localhost:5000/api/v1`
- [ ] Pas d'erreurs CORS dans la console
- [ ] Requête visible dans Network (Chrome DevTools)
- [ ] Status Code 201 dans la réponse

## 📞 Informations à partager

Si ça ne fonctionne toujours pas, partagez :

1. **L'URL exacte** utilisée dans le code Flutter
2. **Les erreurs** dans Chrome DevTools > Console
3. **Les requêtes** dans Chrome DevTools > Network
4. **Le fichier Flutter** où l'API est configurée

