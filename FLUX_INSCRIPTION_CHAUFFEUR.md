# 🚗 Flux d'inscription chauffeur pour TéMove Pro

## 📋 Vue d'ensemble

L'application TéMove Pro est **exclusivement réservée aux chauffeurs**. Un utilisateur doit :
1. **Avoir un compte utilisateur** (créé via l'app client ou l'API)
2. **S'inscrire en tant que chauffeur** avant de pouvoir se connecter

---

## 🔄 Flux complet

### Étape 1 : Connexion
- L'utilisateur entre son email et mot de passe
- Le backend vérifie les identifiants
- **Si l'utilisateur n'est pas chauffeur** : 
  - Le backend retourne un **token JWT** (pour permettre l'inscription)
  - Mais retourne une **erreur 403** avec le flag `requires_driver_registration: true`
  - L'app Flutter sauvegarde le token et redirige vers `/register-driver`

### Étape 2 : Inscription chauffeur
- L'utilisateur remplit le formulaire :
  - Numéro de permis de conduire
  - Informations du véhicule (marque, modèle, plaque, couleur)
- L'app envoie la requête avec le token JWT sauvegardé
- Le backend crée le profil chauffeur
- L'utilisateur est redirigé vers la page de connexion

### Étape 3 : Reconnexion
- L'utilisateur se reconnecte avec les mêmes identifiants
- Cette fois, le backend détecte qu'il est chauffeur
- La connexion réussit et l'utilisateur accède au dashboard

---

## 🔧 Modifications apportées

### Backend (`temove-backend/app/routes/auth_routes.py`)

1. **Vérification du profil chauffeur** :
   - Si `driver_app: true` dans la requête de login
   - Vérifier si l'utilisateur a un profil `Driver`
   - Si non, retourner le token mais avec erreur 403

2. **Route `/drivers/register`** :
   - Déjà existante, crée le profil chauffeur
   - Nécessite un token JWT valide

### Frontend Flutter (`temove-pro`)

1. **Écran de connexion** (`driver_login_screen.dart`) :
   - Envoie `driver_app: true` dans la requête
   - Gère le cas `requires_driver_registration`
   - Sauvegarde le token et redirige vers `/register-driver`

2. **Écran d'inscription** (`driver_register_screen.dart`) :
   - Nouvel écran créé
   - Formulaire pour numéro de permis et véhicule
   - Utilise le token sauvegardé pour créer le profil chauffeur

3. **Router** (`main.dart`) :
   - Ajout de la route `/register-driver`

4. **Service API** (`driver_api_service.dart`) :
   - Méthode `register()` simplifiée (ne nécessite que licenseNumber et vehicle)
   - Gestion du token lors de l'erreur 403

---

## ✅ Résultat

- ✅ **Sécurité** : Seuls les chauffeurs peuvent accéder à TéMove Pro
- ✅ **UX** : Flux d'inscription simple et intuitif
- ✅ **Cohérence** : L'utilisateur doit d'abord avoir un compte, puis devenir chauffeur

---

## 🧪 Test du flux

1. **Créer un compte utilisateur** (via l'app client ou l'API)
2. **Tenter de se connecter à TéMove Pro** :
   - Entrer email/password
   - Vous devriez être redirigé vers `/register-driver`
3. **Remplir le formulaire d'inscription** :
   - Numéro de permis : `DL-12345`
   - Véhicule : Toyota Corolla ABC-123 Blanc
4. **Se reconnecter** :
   - Entrer les mêmes identifiants
   - Vous devriez accéder au dashboard

---

## 📝 Notes importantes

- Le token JWT est sauvegardé même si la connexion échoue (pour permettre l'inscription)
- L'inscription nécessite que l'utilisateur soit déjà authentifié (token présent)
- Après l'inscription, l'utilisateur doit se reconnecter pour accéder au dashboard
- Le backend vérifie automatiquement le profil chauffeur lors de chaque connexion depuis TéMove Pro

