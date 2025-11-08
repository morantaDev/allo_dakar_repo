# 🚗 Système d'inscription complète pour TéMove Pro

## 📋 Vue d'ensemble

Le système d'inscription permet aux nouveaux chauffeurs de créer un compte complet en une seule étape, incluant :
- Compte utilisateur (email, password, nom, téléphone)
- Profil chauffeur (numéro de permis)
- Véhicule (marque, modèle, plaque, couleur)

L'utilisateur est créé avec `role='driver'` dès le départ, ce qui lui permet de se connecter immédiatement à TéMove Pro.

---

## 🔧 Modifications Backend

### Route `/auth/register-driver` (`temove-backend/app/routes/auth_routes.py`)

**Endpoint** : `POST /api/v1/auth/register-driver`

**Body (JSON)** :
```json
{
  "email": "papa.amadou@example.com",
  "password": "motdepasse123",
  "full_name": "Papa Amadou Diop",
  "phone": "+221 77 123 45 67",
  "license_number": "DL-12345",
  "vehicle": {
    "make": "Toyota",
    "model": "Corolla",
    "plate": "ABC-123",
    "color": "Blanc"
  }
}
```

**Réponse (201)** :
```json
{
  "message": "Inscription chauffeur réussie",
  "user": {
    "id": 1,
    "email": "papa.amadou@example.com",
    "full_name": "Papa Amadou Diop",
    "role": "driver",
    ...
  },
  "driver": {
    "id": 1,
    "license_number": "DL-12345",
    "status": "offline",
    "vehicle": {
      "id": 1,
      "make": "Toyota",
      "model": "Corolla",
      "plate": "ABC-123",
      "color": "Blanc"
    }
  },
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9...",
  "refresh_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

**Fonctionnalités** :
- ✅ Crée le compte utilisateur avec `role='driver'`
- ✅ Crée le profil chauffeur
- ✅ Crée le véhicule et le lie au chauffeur
- ✅ Retourne un token JWT pour connexion automatique
- ✅ Validation complète des champs
- ✅ Gestion des erreurs avec rollback en cas d'échec
- ✅ Logs détaillés pour le debugging

---

## 🔧 Modifications Frontend

### 1. Nouveau service API (`temove-pro/lib/services/driver_api_service.dart`)

**Méthode `registerDriver()`** :
```dart
static Future<Map<String, dynamic>> registerDriver({
  required String email,
  required String password,
  required String fullName,
  String? phone,
  required String licenseNumber,
  required Map<String, dynamic> vehicle,
})
```

**Fonctionnalités** :
- ✅ Appelle l'endpoint `/auth/register-driver`
- ✅ Sauvegarde automatiquement le token JWT
- ✅ Sauvegarde les données utilisateur dans SharedPreferences
- ✅ Gestion des erreurs avec messages clairs

### 2. Nouvel écran d'inscription (`temove-pro/lib/screens/auth/driver_signup_screen.dart`)

**Fonctionnalités** :
- ✅ Formulaire complet en une seule page :
  - Informations personnelles (nom, email, téléphone, mot de passe)
  - Informations chauffeur (numéro de permis)
  - Informations véhicule (marque, modèle, plaque, couleur)
- ✅ Validation des champs
- ✅ Vérification de correspondance des mots de passe
- ✅ Affichage des erreurs
- ✅ Redirection automatique vers le dashboard après inscription réussie

### 3. Router (`temove-pro/lib/main.dart`)

**Nouvelle route** : `/signup` → `DriverSignupScreen`

**Routes disponibles** :
- `/login` → Connexion
- `/signup` → Inscription complète (nouveau)
- `/register-driver` → Inscription chauffeur pour utilisateur existant (ancien)
- `/dashboard` → Tableau de bord

### 4. Écran de connexion (`temove-pro/lib/screens/auth/driver_login_screen.dart`)

**Modification** : Ajout d'un lien "Inscrivez-vous" vers `/signup`

---

## 🔄 Flux utilisateur

### Flux d'inscription (nouveau chauffeur)

1. **Accès à l'écran d'inscription** :
   - Depuis l'écran de connexion, cliquer sur "Inscrivez-vous"
   - URL : `/signup`

2. **Remplir le formulaire** :
   - Informations personnelles (nom, email, téléphone, mot de passe)
   - Numéro de permis de conduire
   - Informations du véhicule (marque, modèle, plaque, couleur)

3. **Soumission** :
   - Validation des champs côté client
   - Envoi de la requête au backend
   - Création du compte, profil chauffeur et véhicule
   - Réception du token JWT

4. **Redirection** :
   - Token sauvegardé automatiquement
   - Redirection vers le dashboard
   - Utilisateur connecté et prêt à travailler

### Flux de connexion (chauffeur existant)

1. **Accès à l'écran de connexion** :
   - URL : `/login`

2. **Connexion** :
   - Entrer email et mot de passe
   - Vérification du rôle "driver" côté backend
   - Vérification du rôle dans le token JWT côté frontend

3. **Redirection** :
   - Si rôle "driver" : accès au dashboard
   - Si rôle "client" : erreur "Compte non autorisé"

---

## ✅ Avantages

1. **Simplicité** : Une seule étape pour créer un compte complet
2. **Sécurité** : Vérification stricte du rôle dès l'inscription
3. **Expérience utilisateur** : Pas besoin de se reconnecter après l'inscription
4. **Cohérence** : Le rôle "driver" est défini dès la création du compte
5. **Validation** : Validation complète des champs côté backend et frontend

---

## 🧪 Test du système

### Test 1 : Inscription d'un nouveau chauffeur

1. Accéder à `/signup`
2. Remplir le formulaire :
   - Email : `nouveau.chauffeur@example.com`
   - Mot de passe : `password123`
   - Nom : `Nouveau Chauffeur`
   - Téléphone : `+221 77 123 45 67`
   - Permis : `DL-12345`
   - Véhicule : Toyota Corolla ABC-123 Blanc
3. Cliquer sur "S'inscrire"
4. Vérifier : Redirection automatique vers le dashboard

### Test 2 : Connexion d'un chauffeur inscrit

1. Accéder à `/login`
2. Entrer les identifiants du chauffeur inscrit
3. Vérifier : Connexion réussie, accès au dashboard

### Test 3 : Tentative de connexion avec un compte "client"

1. Accéder à `/login`
2. Entrer les identifiants d'un compte avec `role='client'`
3. Vérifier : Erreur "Compte non autorisé"

---

## 📝 Notes importantes

1. **Double vérification** : Le backend vérifie à la fois `user.role` et l'existence du profil `Driver`
2. **Rollback automatique** : En cas d'erreur, toutes les opérations sont annulées (transaction)
3. **Logs détaillés** : Tous les logs sont ajoutés pour faciliter le debugging
4. **Token automatique** : Le token JWT est retourné et sauvegardé automatiquement

---

## 🔄 Redémarrage requis

**Backend** : Redémarrer le serveur Flask pour appliquer les modifications :
```powershell
cd C:\allo_dakar_repo\temove-backend
python app.py
```

**Frontend** : Redémarrer l'application Flutter :
```powershell
cd C:\allo_dakar_repo\temove-pro
flutter run -d chrome
```

---

## ✅ Statut

- ✅ Backend : Route `/auth/register-driver` créée
- ✅ Frontend : Écran d'inscription complet créé
- ✅ Service API : Méthode `registerDriver()` implémentée
- ✅ Router : Route `/signup` ajoutée
- ✅ Validation : Validation complète des champs
- ✅ Gestion d'erreurs : Messages d'erreur clairs
- ✅ Expérience utilisateur : Redirection automatique vers le dashboard

**Le système d'inscription est maintenant complet et fonctionnel !** 🎉

