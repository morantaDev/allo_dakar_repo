# 🧪 Guide de Test - Synchronisation Frontend-Backend

## ✅ Checklist de Synchronisation

### 1. Vérifier que le Backend est démarré

**Dans le terminal backend :**
```powershell
# Le backend doit être lancé et afficher :
# * Running on http://0.0.0.0:5000
```

**Test rapide :**
- Ouvrir dans Chrome : http://localhost:5000/health
- Devrait afficher : `{"status": "ok", "message": "Allo Dakar API is running"}`

---

### 2. Vérifier l'URL de l'API dans Flutter

**Pour Chrome (Web) :**
```dart
const String API_BASE_URL = 'http://localhost:5000/api/v1';
```

**Vérifier dans votre code Flutter :**
- Chercher le fichier qui contient `API_BASE_URL` ou `baseUrl`
- S'assurer qu'il pointe vers `http://localhost:5000/api/v1`

---

### 3. Test depuis l'Interface Flutter

#### A. Test d'Inscription

1. **Ouvrir l'écran d'inscription** dans votre app Flutter
2. **Remplir le formulaire :**
   - Email : `test@example.com`
   - Mot de passe : `test123`
   - Nom complet : `Test User`
   - Téléphone : `+221701234567` (optionnel)
3. **Cliquer sur "S'inscrire"**

**✅ Ce qui devrait se passer :**
- Un message de succès s'affiche : "Inscription réussie"
- Vous êtes redirigé vers l'écran principal
- Un token est sauvegardé (dans le storage)

**❌ Si ça ne marche pas :**
- Ouvrir la console du navigateur (F12)
- Vérifier l'onglet **Network** pour voir les requêtes
- Vérifier l'onglet **Console** pour voir les erreurs

#### B. Test de Connexion

1. **Ouvrir l'écran de connexion**
2. **Entrer les identifiants :**
   - Email : `test@example.com`
   - Mot de passe : `test123`
3. **Cliquer sur "Se connecter"**

**✅ Ce qui devrait se passer :**
- Message de succès : "Connexion réussie"
- Redirection vers l'écran principal
- Token sauvegardé

#### C. Test de Réservation de Course

1. **Se connecter à l'app**
2. **Ouvrir l'écran de réservation**
3. **Sélectionner un point de départ et destination**
4. **Choisir le mode de transport**
5. **Cliquer sur "Réserver"**

**✅ Ce qui devrait se passer :**
- La course est créée
- Un message de confirmation s'affiche
- La course apparaît dans l'historique

**Pour une réservation en avance :**
- Sélectionner une date/heure future
- Le message devrait être : "Réservation programmée pour [heure]"
- **PAS** "Le chauffeur sera là dans 5 min"

---

### 4. Vérifier les Messages dans l'Interface

#### Messages de Succès
- ✅ "Inscription réussie"
- ✅ "Connexion réussie"
- ✅ "Course réservée avec succès"
- ✅ "Réservation programmée pour [heure]"

#### Messages d'Erreur
- ❌ "Email déjà utilisé"
- ❌ "Email ou mot de passe incorrect"
- ❌ "Erreur lors de la réservation"

**Si vous ne voyez pas les messages :**
- Vérifier que votre code Flutter affiche les `SnackBar` ou `AlertDialog`
- Vérifier la console du navigateur (F12) pour voir les réponses API

---

### 5. Debug dans la Console du Navigateur

**Ouvrir Chrome DevTools (F12) :**

1. **Onglet Network :**
   - Voir toutes les requêtes HTTP
   - Vérifier que les requêtes vont vers `localhost:5000/api/v1`
   - Vérifier les codes de statut (200 = OK, 400 = Erreur client, 500 = Erreur serveur)

2. **Onglet Console :**
   - Voir les erreurs JavaScript/Dart
   - Voir les logs de debug

3. **Exemple de requête réussie :**
   ```
   POST http://localhost:5000/api/v1/auth/register
   Status: 201 Created
   Response: {
     "message": "Inscription réussie",
     "access_token": "...",
     "user": {...}
   }
   ```

---

### 6. Vérifier la Synchronisation des Réservations en Avance

**Test spécifique :**

1. **Créer une réservation programmée :**
   - Date/heure : Dans 2 heures par exemple
   - Point de départ et destination
   - Mode de transport

2. **Vérifier la réponse API :**
   - Ouvrir DevTools > Network
   - Trouver la requête `POST /api/v1/rides/book`
   - Vérifier la réponse :

```json
{
  "ride": {
    "scheduled_at": "2024-11-04T14:30:00",
    "is_scheduled": true,
    "estimated_arrival": {
      "message": "Réservation programmée pour 14:30",
      "is_scheduled": true,
      "arrival_in_minutes": 120
    }
  }
}
```

3. **Vérifier dans l'interface :**
   - Le message affiché doit être : "Réservation programmée pour 14:30"
   - **PAS** "Le chauffeur sera là dans 5 min"

---

### 7. Problèmes Courants et Solutions

#### ❌ "Network Error" ou "Connection refused"
- **Cause :** Backend non démarré ou mauvaise URL
- **Solution :** Vérifier que le backend tourne sur le port 5000
- **Solution :** Vérifier l'URL dans Flutter : `http://localhost:5000/api/v1`

#### ❌ "CORS Error"
- **Cause :** Problème de CORS entre frontend et backend
- **Solution :** Le backend devrait déjà gérer CORS, vérifier la config dans `app.py`

#### ❌ Les messages ne s'affichent pas
- **Cause :** Code Flutter ne gère pas les messages de réponse
- **Solution :** Ajouter `SnackBar` ou `AlertDialog` pour afficher les messages

#### ❌ "401 Unauthorized"
- **Cause :** Token manquant ou expiré
- **Solution :** Vérifier que le token est bien sauvegardé après connexion
- **Solution :** Vérifier que le token est envoyé dans les headers : `Authorization: Bearer <token>`

#### ❌ Réservation en avance affiche "dans 5 min"
- **Cause :** Frontend n'utilise pas `estimated_arrival.message`
- **Solution :** Utiliser `ride.estimated_arrival.message` au lieu d'un message fixe

---

## 📋 Checklist Rapide

- [ ] Backend démarré sur http://localhost:5000
- [ ] URL API dans Flutter : `http://localhost:5000/api/v1`
- [ ] Test d'inscription fonctionne
- [ ] Test de connexion fonctionne
- [ ] Messages de succès/erreur s'affichent
- [ ] Réservation immédiate fonctionne
- [ ] Réservation en avance affiche le bon message ("Réservation programmée pour...")
- [ ] Console du navigateur ne montre pas d'erreurs

---

## 🔍 Commandes Utiles pour Debug

**Dans Chrome DevTools (F12) :**

```javascript
// Voir les tokens stockés
localStorage.getItem('access_token')
localStorage.getItem('refresh_token')

// Voir toutes les requêtes
// Aller dans Network > Filtrer par "XHR" ou "Fetch"
```

---

## 📞 Support

Si vous avez des problèmes :
1. Vérifier la console du navigateur (F12)
2. Vérifier les logs du backend dans le terminal
3. Vérifier que l'URL de l'API est correcte
4. Tester l'API directement avec le script `test_api.ps1`

