# 🔐 Flow de Connexion OTP - TéMove Client

## 📱 Vue d'ensemble

Flow de connexion rapide et sécurisée via numéro de téléphone + code OTP (SMS ou WhatsApp), avec collecte du nom/prénom pour les nouveaux utilisateurs et affichage de la carte GPS.

## 🎯 Flow complet

```
1. WelcomeScreen
   ↓ (Bouton "Se connecter avec téléphone")
2. PhoneInputScreen
   ↓ (Saisie numéro + choix SMS/WhatsApp)
3. OtpVerificationScreen
   ↓ (Saisie code OTP à 6 chiffres)
   ├─ Utilisateur existant → MapScreen (carte GPS)
   └─ Nouvel utilisateur → UserInfoScreen
       ↓ (Saisie nom + prénom)
       MapScreen (carte GPS)
```

## 🛠️ Écrans implémentés

### 1. **WelcomeScreen** (`lib/screens/welcome_screen.dart`)
- Écran d'accueil avec logo TéMove
- Bouton principal : "Se connecter avec téléphone"
- Bouton secondaire : "Se connecter" (email/mot de passe)
- Option "Continuer en tant qu'invité"

### 2. **PhoneInputScreen** (`lib/screens/auth/phone_input_screen.dart`)
- **Fonctionnalités :**
  - Saisie du numéro de téléphone avec format automatique
  - Normalisation automatique (+221 pour numéros sénégalais)
  - Choix de la méthode : SMS ou WhatsApp
  - Validation du format du numéro
  - Envoi du code OTP via API
  - Affichage du code de debug en développement
  - Messages de succès/erreur avec SnackBar

- **Navigation :** → `OtpVerificationScreen`

### 3. **OtpVerificationScreen** (`lib/screens/auth/otp_verification_screen.dart`)
- **Fonctionnalités :**
  - 6 champs de saisie pour le code OTP
  - Auto-focus et navigation entre les champs
  - Compteur à rebours (timer 60s ou 300s)
  - Bouton de renvoi automatique si expiré
  - Vérification du code OTP via API
  - Gestion des erreurs (code invalide, expiré)
  - Messages de succès avec animation

- **Navigation :**
  - Utilisateur existant → `MapScreen`
  - Nouvel utilisateur (requires_name) → `UserInfoScreen`

### 4. **UserInfoScreen** (`lib/screens/auth/user_info_screen.dart`)
- **Fonctionnalités :**
  - Saisie du prénom
  - Saisie du nom
  - Validation des champs
  - Complétion de l'inscription avec le code OTP
  - Messages de succès/erreur

- **Navigation :** → `MapScreen`

### 5. **MapScreen** (`lib/screens/map_screen.dart`)
- **Fonctionnalités :**
  - Carte dynamique avec OpenStreetMap (via `flutter_map`)
  - Position GPS en temps réel
  - Marqueur de position avec pin personnalisé
  - Cercle de précision GPS
  - Bouton de localisation (centrer sur position actuelle)
  - Recherche de destination (bouton "Où allez-vous ?")
  - Menu drawer et profil utilisateur
  - Actualisation automatique de la position

- **Widget utilisé :** `MapPlaceholder` (lib/widgets/map_placeholder.dart)

## 🔧 Backend Flask

### Endpoints API

#### 1. **POST `/api/v1/auth/send-otp`**
```json
Request:
{
  "phone": "+221771234567",
  "method": "SMS" // ou "WHATSAPP"
}

Response (200):
{
  "success": true,
  "message": "Code OTP envoyé par SMS",
  "expires_in": 300,
  "method": "SMS",
  "debug_code": "123456" // seulement en DEBUG
}
```

#### 2. **POST `/api/v1/auth/verify-otp`**
```json
Request:
{
  "phone": "+221771234567",
  "code": "123456",
  "full_name": "John Doe" // optionnel, requis si nouveau utilisateur
}

Response (200):
{
  "success": true,
  "message": "Connexion réussie",
  "access_token": "eyJ...",
  "user": {...},
  "is_new_user": false
}

Response (400 - Nom requis):
{
  "success": false,
  "error": "Le nom est requis pour créer un compte",
  "requires_name": true
}
```

### Modèle OTP (`temove-backend/models/otp.py`)
- **Champs :**
  - `phone` : Numéro de téléphone (indexé)
  - `code` : Code OTP à 6 chiffres
  - `method` : SMS ou WHATSAPP
  - `is_used` : Empêcher la réutilisation
  - `user_id` : ID utilisateur (nullable pour nouveaux utilisateurs)
  - `expires_at` : Date d'expiration (5 minutes)
  - `created_at` : Date de création
  - `verified_at` : Date de vérification

- **Méthodes :**
  - `is_expired()` : Vérifier si le code est expiré
  - `is_valid()` : Vérifier si le code est valide (non expiré et non utilisé)
  - `mark_as_used()` : Marquer le code comme utilisé

### Sécurité
- ✅ Code OTP à 6 chiffres aléatoires
- ✅ Expiration automatique après 5 minutes
- ✅ Empêcher la réutilisation des codes
- ✅ Invalidation des anciens codes OTP non utilisés
- ✅ Token JWT valide 30 jours
- ✅ Validation du format du numéro de téléphone

## 🎨 Design & UX

### Couleurs TéMove
- **Jaune primaire :** `#FFD60A` (AppTheme.primaryColor)
- **Noir :** `#0C0C0C` (AppTheme.secondaryColor)
- **Vert :** `#00C897` (AppTheme.successColor)
- **Fond sombre :** `#0C0C0C` (AppTheme.backgroundColor)
- **Surface :** `#1A1A1A` (AppTheme.surfaceDark)

### Animations & Feedback
- ✅ Indicateurs de chargement pour chaque étape
- ✅ SnackBar avec icônes pour les messages
- ✅ Transitions fluides entre les écrans
- ✅ Messages de succès avec délai avant redirection
- ✅ Gestion des erreurs avec messages clairs
- ✅ Compteur à rebours animé pour l'OTP
- ✅ Auto-focus et navigation entre les champs OTP

### Responsive
- ✅ Design mobile-first
- ✅ Coins arrondis (16px minimum)
- ✅ Ombres douces pour la profondeur
- ✅ Typographie Inter (Google Fonts)
- ✅ Adaptation automatique pour différentes tailles d'écran

## 📍 Géolocalisation

### Service de localisation (`lib/services/location_service.dart`)
- ✅ Vérification et demande des permissions GPS
- ✅ Récupération de la position actuelle
- ✅ Géocodage inversé (coordonnées → adresse)
- ✅ Géocodage (adresse → coordonnées)
- ✅ Position par défaut (Dakar) si GPS indisponible
- ✅ Base de données locale de lieux populaires (fallback)
- ✅ Calcul de distance entre deux points
- ✅ Stream de position en temps réel

### Carte dynamique
- ✅ OpenStreetMap (gratuit, pas besoin de clé API)
- ✅ Marqueur personnalisé avec pin TéMove
- ✅ Cercle de précision GPS
- ✅ Centrage automatique sur la position
- ✅ Bouton de localisation (actualiser position)
- ✅ Affichage de l'adresse actuelle
- ✅ Zoom adaptatif selon la précision

## 🚀 Utilisation

### Démarrage de l'application
```bash
cd temove
flutter run -d chrome
```

### Flow de connexion
1. **Écran d'accueil** : Cliquer sur "Se connecter avec téléphone"
2. **Saisie du numéro** : Entrer le numéro (ex: 0771234567 ou +221771234567)
3. **Choix de la méthode** : Sélectionner SMS ou WhatsApp
4. **Envoi du code** : Le code OTP est envoyé (affiché en développement)
5. **Saisie du code** : Entrer le code à 6 chiffres
6. **Nouvel utilisateur** : Si nouveau, saisir nom et prénom
7. **Accès à la carte** : La carte s'affiche avec la position GPS

### Développement
- Le code OTP est affiché dans une SnackBar en mode DEBUG
- Les logs backend affichent le code OTP dans la console
- Timeout de 8 secondes pour la récupération GPS
- Position par défaut : Dakar (14.7167, -17.4677)

## 🔍 Dépannage

### Problèmes courants

1. **Code OTP non reçu**
   - Vérifier que le backend est démarré
   - Vérifier les logs backend pour le code de debug
   - Vérifier la configuration SMS/WhatsApp (non implémenté, en développement)

2. **GPS non disponible**
   - Vérifier les permissions de localisation
   - La position par défaut (Dakar) est utilisée
   - Vérifier que le service de localisation est activé

3. **Erreur de connexion**
   - Vérifier que le backend est accessible
   - Vérifier l'URL de base dans `ApiService.baseUrl`
   - Vérifier les logs backend pour les erreurs

## 📝 Notes importantes

- ✅ Le backend doit être démarré avant de tester le flow
- ✅ Les permissions GPS doivent être accordées pour la localisation
- ✅ Le service SMS/WhatsApp n'est pas encore implémenté (code affiché en développement)
- ✅ Le token JWT est valide 30 jours
- ✅ Les codes OTP expirent après 5 minutes
- ✅ Un code OTP ne peut être utilisé qu'une seule fois

## 🎯 Prochaines étapes

- [ ] Intégrer un service SMS/WhatsApp réel (Africa's Talking, Twilio, etc.)
- [ ] Ajouter la vérification du numéro de téléphone (format international)
- [ ] Améliorer la sécurité (rate limiting, CAPTCHA, etc.)
- [ ] Ajouter la vérification par email (optionnel)
- [ ] Améliorer la gestion des erreurs réseau
- [ ] Ajouter des animations plus fluides
- [ ] Ajouter le support multilingue
- [ ] Ajouter les tests unitaires et d'intégration

## 📚 Documentation technique

### Fichiers clés
- `lib/screens/auth/phone_input_screen.dart` : Écran de saisie du numéro
- `lib/screens/auth/otp_verification_screen.dart` : Écran de vérification OTP
- `lib/screens/auth/user_info_screen.dart` : Écran de saisie nom/prénom
- `lib/screens/map_screen.dart` : Écran principal avec carte
- `lib/services/api_service.dart` : Service API pour communiquer avec le backend
- `lib/services/location_service.dart` : Service de géolocalisation
- `lib/widgets/map_placeholder.dart` : Widget de carte avec GPS
- `temove-backend/app/routes/auth_routes.py` : Routes d'authentification
- `temove-backend/models/otp.py` : Modèle OTP

### Dépendances Flutter
- `flutter_map: ^7.0.2` : Carte OpenStreetMap
- `geolocator: ^11.0.0` : Géolocalisation
- `geocoding: ^3.0.0` : Géocodage
- `http: ^1.1.0` : Requêtes HTTP
- `shared_preferences: ^2.2.2` : Stockage local

---

**✅ Flow de connexion OTP complètement implémenté et fonctionnel !**

