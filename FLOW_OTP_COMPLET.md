# Flow de Connexion OTP - TéMove Client

## 📱 Vue d'ensemble

Le système de connexion OTP (One-Time Password) permet aux utilisateurs de se connecter ou de s'inscrire en utilisant uniquement leur numéro de téléphone, sans mot de passe.

## 🔄 Flow complet

### 1. Saisie du numéro de téléphone
- **Écran**: `PhoneInputScreen`
- **Actions**:
  - L'utilisateur entre son numéro de téléphone
  - Choix de la méthode d'envoi : SMS ou WhatsApp
  - Normalisation automatique du numéro (format international +221)
  - Validation du format

### 2. Envoi du code OTP
- **Endpoint Backend**: `POST /api/v1/auth/send-otp`
- **Actions**:
  - Génération d'un code OTP à 6 chiffres
  - Expiration dans 5 minutes
  - Invalidation des anciens codes OTP non utilisés
  - Envoi par SMS/WhatsApp (simulé en développement, logs console)
  - Retour du code de debug en mode développement

### 3. Vérification du code OTP
- **Écran**: `OtpVerificationScreen`
- **Endpoint Backend**: `POST /api/v1/auth/verify-otp`
- **Actions**:
  - Saisie du code OTP à 6 chiffres (6 champs individuels)
  - Timer de compte à rebours (5 minutes)
  - Vérification du code côté backend
  - Si nouveau utilisateur et nom requis → Dialogue pour demander le nom
  - Si utilisateur existant → Connexion directe

### 4. Saisie du nom (nouveaux utilisateurs uniquement)
- **Dialogue**: Dans `OtpVerificationScreen`
- **Actions**:
  - Saisie du prénom et du nom
  - Réutilisation du même code OTP avec le nom
  - Création du compte utilisateur
  - Génération du token JWT
  - Connexion automatique

### 5. Accès à l'application
- **Écran**: `MapScreen`
- **Actions**:
  - Redirection vers la carte principale
  - Token JWT sauvegardé dans SharedPreferences
  - Données utilisateur sauvegardées

## 🔧 Modifications Backend

### Modèle OTP (`models/otp.py`)
- Ajout du champ `method` (SMS/WHATSAPP)
- Ajout du champ `is_used` pour empêcher la réutilisation
- Ajout du champ `verified_at` pour le timestamp de vérification
- Méthode `mark_as_used()` pour marquer le code comme utilisé
- Méthode `is_valid()` pour vérifier la validité (non expiré et non utilisé)

### Modèle User (`models/user.py`)
- `password_hash` rendu nullable pour permettre la connexion OTP sans mot de passe

### Endpoints (`app/routes/auth_routes.py`)

#### `POST /api/v1/auth/send-otp`
- Normalisation du numéro de téléphone
- Génération d'un code OTP à 6 chiffres
- Invalidation des anciens codes
- Retour du code de debug en mode développement
- Support SMS et WhatsApp

#### `POST /api/v1/auth/verify-otp`
- Vérification du code OTP (non expiré et non utilisé)
- Si nouveau utilisateur et nom requis : retourne `requires_name: true` sans marquer le code comme utilisé
- Si nouveau utilisateur avec nom : création du compte et marquage du code comme utilisé
- Si utilisateur existant : connexion directe et marquage du code comme utilisé
- Génération du token JWT (valide 30 jours)
- Retour des données utilisateur

## 📱 Modifications Frontend

### Services (`lib/services/api_service.dart`)
- `sendOtp(phone, method)`: Envoie un code OTP
- `verifyOtp(phone, code, fullName)`: Vérifie un code OTP et connecte l'utilisateur

### Écrans (`lib/screens/auth/`)

#### `PhoneInputScreen`
- Saisie du numéro de téléphone
- Choix de la méthode (SMS/WhatsApp)
- Normalisation automatique du numéro
- Validation du format
- Navigation vers `OtpVerificationScreen`

#### `OtpVerificationScreen`
- Saisie du code OTP (6 champs)
- Timer de compte à rebours
- Bouton de renvoi de code
- Dialogue pour saisie du nom si requis
- Réutilisation du code OTP avec le nom
- Navigation vers `MapScreen` après connexion réussie

#### `UserInfoScreen`
- Écran de saisie du nom (prénom + nom)
- Utilisé dans le dialogue si nécessaire
- Validation des champs

### Intégration (`lib/screens/welcome_screen.dart`)
- Bouton "Se connecter avec téléphone" → `PhoneInputScreen`
- Bouton "Se connecter par email" → `AuthScreen` (ancien système)

## 🗄️ Migration de la base de données

### Script de migration nécessaire

```sql
-- Mettre à jour la table OTP
ALTER TABLE otps 
ADD COLUMN method VARCHAR(10) DEFAULT 'SMS' NOT NULL,
ADD COLUMN is_used BOOLEAN DEFAULT FALSE NOT NULL,
ADD COLUMN verified_at DATETIME NULL,
MODIFY COLUMN user_id INT NULL,
MODIFY COLUMN phone VARCHAR(20) NOT NULL,
ADD INDEX idx_otps_phone (phone),
ADD INDEX idx_otps_expires_at (expires_at);

-- Mettre à jour la table users
ALTER TABLE users 
MODIFY COLUMN password_hash VARCHAR(255) NULL;
```

### Script Python de migration

Un script `temove-backend/scripts/migrate_otp.py` devrait être créé pour :
1. Ajouter les colonnes manquantes dans `otps`
2. Rendre `password_hash` nullable dans `users`
3. Mettre à jour les index

## 🧪 Tests

### Tests backend
1. Envoi OTP avec numéro valide
2. Vérification OTP avec code valide
3. Vérification OTP avec code expiré
4. Vérification OTP avec code invalide
5. Création de compte avec nom
6. Connexion utilisateur existant

### Tests frontend
1. Saisie et validation du numéro de téléphone
2. Envoi et réception du code OTP
3. Saisie du code OTP
4. Timer de compte à rebours
5. Renvoi de code
6. Saisie du nom pour nouveau utilisateur
7. Navigation vers la carte après connexion

## 🔐 Sécurité

- Codes OTP à 6 chiffres aléatoires
- Expiration automatique après 5 minutes
- Empêchement de la réutilisation des codes
- Validation stricte du format du numéro
- Normalisation du numéro de téléphone
- Tokens JWT avec expiration (30 jours)
- Vérification du statut `is_active` de l'utilisateur

## 📝 TODO / Améliorations futures

- [ ] Intégration d'un service SMS réel (Africa's Talking, Twilio, etc.)
- [ ] Intégration d'un service WhatsApp réel
- [ ] Rate limiting pour l'envoi d'OTP (max 3 par numéro par heure)
- [ ] Logs d'audit pour les tentatives de connexion
- [ ] Support de la vérification par appel vocal
- [ ] Support du format international pour tous les pays
- [ ] Amélioration de l'UX avec animations
- [ ] Support du dark mode
- [ ] Tests unitaires et d'intégration complets

## 🚀 Déploiement

1. **Backend**:
   - Exécuter le script de migration de la base de données
   - Redémarrer le serveur Flask
   - Vérifier que les endpoints OTP fonctionnent

2. **Frontend**:
   - Vérifier que les écrans OTP sont accessibles
   - Tester le flow complet
   - Vérifier la navigation

3. **Production**:
   - Configurer un service SMS/WhatsApp réel
   - Désactiver le retour du code de debug
   - Configurer le rate limiting
   - Mettre en place la surveillance et les logs

## 📚 Documentation API

### POST /api/v1/auth/send-otp
**Request:**
```json
{
  "phone": "+221771234567",
  "method": "SMS"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Code OTP envoyé par SMS",
  "expires_in": 300,
  "method": "SMS",
  "debug_code": "123456"  // Seulement en mode développement
}
```

### POST /api/v1/auth/verify-otp
**Request:**
```json
{
  "phone": "+221771234567",
  "code": "123456",
  "full_name": "John Doe"  // Optionnel, requis pour nouveaux utilisateurs
}
```

**Response:**
```json
{
  "success": true,
  "message": "Connexion réussie",
  "access_token": "eyJhbGci...",
  "user": {
    "id": 1,
    "email": "user_221771234567@temove.sn",
    "full_name": "John Doe",
    "phone": "+221771234567",
    "role": "client",
    "is_verified": true
  },
  "is_new_user": true
}
```

**Erreur (nom requis):**
```json
{
  "success": false,
  "error": "Le nom est requis pour créer un compte",
  "requires_name": true
}
```

## 🎨 Design

- Design moderne avec coins arrondis (16px)
- Couleurs TéMove : Jaune (#FFD60A), Noir (#0C0C0C), Vert (#00C897)
- Animations fluides
- Feedback visuel pour chaque action
- Messages d'erreur clairs
- Timer visuel pour l'expiration du code
- Boutons de renvoi de code

## 📞 Support

Pour toute question ou problème :
1. Vérifier les logs backend (console Flask)
2. Vérifier les logs frontend (console Flutter)
3. Vérifier la base de données (table `otps`)
4. Vérifier la configuration CORS
5. Vérifier la connexion réseau

---

**Date de création**: 2025-11-08
**Version**: 1.0.0
**Auteur**: TéMove Development Team

