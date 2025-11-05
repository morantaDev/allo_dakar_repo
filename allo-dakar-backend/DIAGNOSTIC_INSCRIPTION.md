# 🔍 Diagnostic Inscription Frontend → Backend

## ❌ Problème

Aucune requête d'inscription n'apparaît dans les logs du serveur, ce qui signifie que la requête depuis Flutter n'atteint pas le backend.

## 🔍 Vérifications à faire

### 1. Dans Chrome DevTools (F12) dans Flutter

**Onglet Network :**
1. Cliquez sur "S'inscrire" dans l'interface Flutter
2. Cherchez une requête vers `/register`, `/auth/register`, ou `/api/`
3. Si **aucune requête n'apparaît** → Le frontend n'envoie pas la requête
4. Si une requête apparaît → Regardez :
   - **URL complète** : Doit être `http://localhost:5000/api/v1/auth/register`
   - **Status Code** : 201 = succès, 400/500 = erreur
   - **Response** : Contenu de la réponse

**Onglet Console :**
- Cherchez les erreurs JavaScript/Dart
- Erreurs CORS typiques : `Access to XMLHttpRequest... blocked by CORS policy`
- Autres erreurs de connexion

### 2. Vérifier l'URL de l'API dans Flutter

Le code Flutter doit utiliser :
```dart
const String API_BASE_URL = 'http://localhost:5000/api/v1';
```

**Où chercher :**
- Fichier de configuration API (ex: `lib/api/api.dart`, `lib/services/api_service.dart`)
- Fichier de constantes (ex: `lib/constants/api_constants.dart`)
- Fichier d'environnement (ex: `lib/config/env.dart`)

### 3. Test direct depuis Chrome Console

Dans Chrome DevTools > Console (dans la fenêtre Flutter), exécutez :

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
.then(data => {
  console.log('✅ Succès:', data);
})
.catch(err => {
  console.error('❌ Erreur:', err);
});
```

Si ça fonctionne, le problème vient du code Flutter.
Si ça ne fonctionne pas, le problème vient de la configuration réseau/CORS.

## 📋 Checklist

- [ ] Backend accessible : http://localhost:5000/health
- [ ] URL dans Flutter : `http://localhost:5000/api/v1`
- [ ] Requête visible dans Network (Chrome DevTools)
- [ ] Pas d'erreurs CORS dans la Console
- [ ] Status Code 201 dans la réponse

## 🆘 Si aucune requête n'apparaît

Le problème vient du code Flutter qui n'envoie pas la requête. Vérifiez :
1. Le bouton "S'inscrire" appelle bien la fonction d'inscription
2. La fonction d'inscription fait bien l'appel API
3. Il n'y a pas d'erreur avant l'envoi de la requête

## 📞 Informations à partager

Si ça ne fonctionne toujours pas, partagez :
1. **L'URL exacte** utilisée dans le code Flutter
2. **Les erreurs** dans Chrome DevTools > Console
3. **Les requêtes** dans Chrome DevTools > Network (si elles existent)
4. **Le fichier Flutter** où l'API est configurée

