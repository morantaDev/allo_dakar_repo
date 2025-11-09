# 🚗 TéMove - Plateforme de Transport au Sénégal

<div align="center">

![TéMove Logo](temove/assets/icons/app_logo.png)

**Votre trajet, notre hospitalité**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Flask](https://img.shields.io/badge/Flask-3.0-000000?logo=flask)](https://flask.palletsprojects.com)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?logo=python)](https://www.python.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?logo=mysql)](https://www.mysql.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Fonctionnalités](#-fonctionnalités)
- [Installation](#-installation)
- [Configuration](#-configuration)
- [Utilisation](#-utilisation)
- [API Documentation](#-api-documentation)
- [Structure du projet](#-structure-du-projet)
- [Technologies utilisées](#-technologies-utilisées)
- [Contribution](#-contribution)
- [License](#-license)

---

## 🎯 Vue d'ensemble

**TéMove** est une plateforme complète de transport au Sénégal, similaire à Yango ou Heetch, comprenant trois modules principaux :

1. **TéMove (Client App)** 📱 - Application mobile pour les clients/passagers
2. **TéMove Pro (Driver App)** 🚖 - Application mobile pour les chauffeurs
3. **TéMove Backend (Admin Dashboard)** 🎛️ - Interface d'administration et API REST

### Caractéristiques principales

- ✅ **Connexion OTP par téléphone** - Authentification rapide et sécurisée via SMS/WhatsApp
- ✅ **Géolocalisation en temps réel** - Suivi des trajets avec OpenStreetMap
- ✅ **Gestion complète des courses** - Réservation, acceptation, suivi en temps réel
- ✅ **Système de paiement** - Paiement en espèces, mobile money, carte bancaire
- ✅ **Dashboard administrateur** - Statistiques, gestion des utilisateurs, rapports
- ✅ **Design moderne et responsive** - Interface utilisateur intuitive et élégante

---

## 🏗️ Architecture

```
TéMove Ecosystem
├── temove/                    # Application Client (Flutter)
│   ├── lib/
│   │   ├── screens/          # Écrans de l'application
│   │   ├── services/         # Services API
│   │   ├── widgets/          # Widgets réutilisables
│   │   └── theme/            # Thème et styles
│   └── assets/               # Images et icônes
│
├── temove-pro/               # Application Chauffeur (Flutter)
│   ├── lib/
│   │   ├── screens/          # Écrans de l'application
│   │   ├── services/         # Services API
│   │   └── widgets/          # Widgets réutilisables
│   └── assets/               # Images et icônes
│
└── temove-backend/           # Backend Flask + Admin Dashboard
    ├── app/
    │   ├── routes/           # Routes API
    │   └── models/           # Modèles de données
    ├── services/             # Services métier
    ├── scripts/              # Scripts utilitaires
    └── reports/              # Rapports générés
```

### Flux de données

```
Client App (Flutter)  ──┐
                        ├──> Backend Flask (REST API) ──> MySQL Database
Driver App (Flutter)  ──┘                │
                                         └──> Admin Dashboard (Flutter Web)
```

---

## ✨ Fonctionnalités

### 📱 TéMove (Client App)

#### Authentification
- 🔐 **Connexion OTP par téléphone** - SMS ou WhatsApp
- 📝 **Inscription rapide** - Création de compte en quelques étapes
- 🔒 **Sécurité JWT** - Tokens d'authentification sécurisés

#### Réservation de courses
- 🗺️ **Carte interactive** - OpenStreetMap avec géolocalisation GPS
- 📍 **Sélection de destination** - Recherche d'adresses, géolocalisation
- 💰 **Estimation de prix** - Calcul automatique du prix du trajet
- 📊 **Suivi en temps réel** - Visualisation des chauffeurs disponibles avec ETA
- 🔔 **Notifications** - Alertes pour l'arrivée du chauffeur

#### Gestion du compte
- 👤 **Profil utilisateur** - Gestion des informations personnelles
- 📜 **Historique des courses** - Consultation des trajets passés
- ⭐ **Système de notation** - Évaluation des chauffeurs
- 💳 **Méthodes de paiement** - Espèces, mobile money, carte bancaire
- 🎁 **Codes promo et parrainage** - Système de fidélité

### 🚖 TéMove Pro (Driver App)

#### Authentification
- 🔐 **Connexion sécurisée** - Vérification du rôle chauffeur
- 📝 **Inscription complète** - Création de profil chauffeur + véhicule

#### Gestion des courses
- 📋 **Liste des courses disponibles** - Affichage en temps réel
- ✅ **Acceptation de courses** - Acceptation/rejet des demandes
- 🗺️ **Navigation vers le client** - Itinéraire optimisé
- 🚦 **Gestion du statut** - Disponible, en course, hors ligne
- 💰 **Suivi des revenus** - Statistiques détaillées (jour/semaine/mois)

#### Profil chauffeur
- 👤 **Gestion du profil** - Informations personnelles et véhicule
- 📊 **Statistiques** - Nombre de courses, note moyenne, revenus
- 🚗 **Informations véhicule** - Marque, modèle, plaque, couleur

### 🎛️ TéMove Backend (Admin Dashboard)

#### Tableau de bord
- 📊 **Statistiques globales** - Revenus, courses, utilisateurs, chauffeurs
- 📈 **Graphiques dynamiques** - Évolution des métriques (jour/semaine/mois)
- 🔄 **Suivi en temps réel** - Activité de la plateforme

#### Gestion des utilisateurs
- 👥 **Liste des clients** - Filtres, recherche, pagination
- 👤 **Détails utilisateur** - Historique, statistiques, gestion
- 🚫 **Gestion des comptes** - Activation/désactivation

#### Gestion des chauffeurs
- 🚖 **Liste des chauffeurs** - Filtres par ville, statut, note
- ✅ **Validation des chauffeurs** - Approbation/rejet des inscriptions
- 📊 **Statistiques chauffeurs** - Courses, revenus, évaluations
- 🚦 **Gestion du statut** - Activation/désactivation

#### Gestion des courses
- 📋 **Liste des courses** - Filtres par statut, date, ville
- 📍 **Suivi en temps réel** - Carte avec courses actives
- 💰 **Gestion des paiements** - Suivi des transactions

#### Rapports et exports
- 📄 **Génération de rapports** - Excel et PDF
- 💰 **Gestion des commissions** - Calcul et suivi (10% par défaut)
- 📊 **Rapports financiers** - Revenus, paiements, commissions

---

## 🚀 Installation

### Prérequis

- **Flutter** >= 3.0.0 ([Installation](https://flutter.dev/docs/get-started/install))
- **Python** >= 3.8 ([Installation](https://www.python.org/downloads/))
- **MySQL** >= 8.0 ([Installation](https://www.mysql.com/downloads/))
- **Node.js** (optionnel, pour certaines dépendances)

### Installation du Backend

```bash
# Cloner le repository
git clone https://github.com/votre-username/temove.git
cd temove/temove-backend

# Créer un environnement virtuel
python -m venv venv

# Activer l'environnement virtuel
# Sur Windows:
venv\Scripts\activate
# Sur Linux/Mac:
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt

# Configurer la base de données
# Créer la base de données MySQL
mysql -u root -p
CREATE DATABASE temove_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Configurer les variables d'environnement
# Créer un fichier .env dans temove-backend/
# Voir la section Configuration ci-dessous

# Initialiser la base de données
python init_db.py

# Démarrer le serveur
python app.py
# ou
flask run
```

Le backend sera accessible sur `http://127.0.0.1:5000`

### Installation de l'Application Client (TéMove)

```bash
cd temove

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
# ou pour le web
flutter run -d chrome
```

### Installation de l'Application Chauffeur (TéMove Pro)

```bash
cd temove-pro

# Installer les dépendances
flutter pub get

# Lancer l'application
flutter run
# ou pour le web
flutter run -d chrome
```

---

## ⚙️ Configuration

### Configuration Backend

Créer un fichier `.env` dans `temove-backend/` :

```env
# Base de données
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=votre_mot_de_passe
DB_NAME=temove_db

# JWT
JWT_SECRET_KEY=votre_clé_secrète_jwt_très_longue_et_aléatoire
JWT_ACCESS_TOKEN_EXPIRES=30

# Flask
FLASK_ENV=development
FLASK_DEBUG=True
FLASK_APP=app.py

# CORS (pour le développement)
CORS_ORIGINS=*

# SMS/WhatsApp (optionnel)
SMS_API_KEY=votre_clé_api_sms
WHATSAPP_API_KEY=votre_clé_api_whatsapp
```

### Configuration Flutter

Les URLs du backend sont configurées dans :
- `temove/lib/services/api_service.dart` (Client App)
- `temove-pro/lib/services/driver_api_service.dart` (Driver App)

Par défaut :
- **Web** : `http://127.0.0.1:5000/api/v1`
- **Android émulateur** : `http://10.0.2.2:5000/api/v1`
- **Android/iOS physique** : `http://<VOTRE_IP_LOCALE>:5000/api/v1`

---

## 📱 Utilisation

### Flow de connexion OTP (Client)

1. **Saisie du numéro de téléphone**
   - Ouvrir l'application TéMove
   - Entrer le numéro de téléphone (format international : +221771234567)
   - Choisir la méthode d'envoi : SMS ou WhatsApp

2. **Vérification du code OTP**
   - Entrer le code à 6 chiffres reçu
   - Le code expire après 5 minutes
   - Possibilité de renvoyer un nouveau code

3. **Complétion du profil** (nouveaux utilisateurs)
   - Entrer le prénom et le nom
   - Le compte est créé automatiquement

4. **Accès à l'application**
   - La carte s'affiche avec la position GPS
   - Possibilité de réserver une course

### Réservation d'une course

1. Ouvrir l'application et se connecter
2. La carte affiche automatiquement votre position
3. Sélectionner la destination (recherche ou géolocalisation)
4. Choisir le type de course (Confort, Économique, etc.)
5. Voir l'estimation du prix
6. Confirmer la réservation
7. Attendre qu'un chauffeur accepte la course
8. Suivre le trajet en temps réel

### Acceptation d'une course (Chauffeur)

1. Se connecter à TéMove Pro
2. Activer le statut "Disponible"
3. Voir la liste des courses disponibles
4. Accepter une course
5. Naviguer vers le client
6. Démarrer la course
7. Terminer la course

---

## 📚 API Documentation

### Authentification

#### Envoi d'un code OTP
```http
POST /api/v1/auth/send-otp
Content-Type: application/json

{
  "phone": "+221771234567",
  "method": "SMS"
}
```

**Réponse :**
```json
{
  "success": true,
  "message": "Code OTP envoyé par SMS",
  "expires_in": 300,
  "method": "SMS",
  "debug_code": "123456"
}
```

#### Vérification du code OTP
```http
POST /api/v1/auth/verify-otp
Content-Type: application/json

{
  "phone": "+221771234567",
  "code": "123456",
  "full_name": "John Doe"
}
```

**Réponse :**
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
    "role": "client"
  },
  "is_new_user": true
}
```

### Courses

#### Estimation d'une course
```http
POST /api/v1/rides/estimate
Authorization: Bearer <token>
Content-Type: application/json

{
  "pickup_latitude": 14.7167,
  "pickup_longitude": -17.4677,
  "dropoff_latitude": 14.75,
  "dropoff_longitude": -17.45,
  "ride_mode": "confort"
}
```

#### Réservation d'une course
```http
POST /api/v1/rides/book
Authorization: Bearer <token>
Content-Type: application/json

{
  "pickup_latitude": 14.7167,
  "pickup_longitude": -17.4677,
  "dropoff_latitude": 14.75,
  "dropoff_longitude": -17.45,
  "pickup_address": "Point de départ",
  "dropoff_address": "Point d'arrivée",
  "ride_mode": "confort",
  "payment_method": "cash"
}
```

### Documentation complète

Voir la documentation détaillée dans :
- `temove-backend/EXEMPLE_REQUETE_API.md`
- `FLOW_OTP_COMPLET.md`

---

## 📁 Structure du projet

### Backend (`temove-backend/`)

```
temove-backend/
├── app/
│   ├── routes/           # Routes API
│   │   ├── auth_routes.py      # Authentification (OTP, login, register)
│   │   ├── driver_routes.py    # Routes chauffeurs
│   │   ├── ride_routes.py      # Routes courses
│   │   └── admin_routes.py     # Routes administrateur
│   └── models/           # Modèles de données
│       ├── user.py             # Modèle utilisateur
│       ├── driver.py           # Modèle chauffeur
│       ├── ride.py             # Modèle course
│       └── otp.py              # Modèle OTP
├── services/             # Services métier
│   ├── report_service.py       # Génération de rapports
│   └── driver_proximity_service.py  # Proximité des chauffeurs
├── scripts/              # Scripts utilitaires
│   └── create_admin.py         # Création d'administrateur
├── app.py                # Point d'entrée Flask
├── requirements.txt      # Dépendances Python
└── config.py            # Configuration
```

### Client App (`temove/`)

```
temove/
├── lib/
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── phone_input_screen.dart      # Saisie numéro téléphone
│   │   │   ├── otp_verification_screen.dart # Vérification OTP
│   │   │   └── user_info_screen.dart        # Saisie nom/prénom
│   │   ├── map_screen.dart                  # Carte principale
│   │   ├── booking_screen.dart              # Réservation
│   │   └── ride_tracking_screen.dart        # Suivi de course
│   ├── services/
│   │   ├── api_service.dart                 # Service API client
│   │   └── location_service.dart            # Service géolocalisation
│   ├── widgets/
│   │   ├── map_placeholder.dart             # Widget carte
│   │   └── temove_logo.dart                 # Logo TéMove
│   └── theme/
│       └── app_theme.dart                   # Thème de l'application
└── pubspec.yaml
```

### Driver App (`temove-pro/`)

```
temove-pro/
├── lib/
│   ├── screens/
│   │   ├── auth/
│   │   │   ├── driver_login_screen.dart     # Connexion chauffeur
│   │   │   └── driver_signup_screen.dart    # Inscription chauffeur
│   │   ├── dashboard/
│   │   │   └── driver_dashboard_screen.dart # Tableau de bord
│   │   ├── rides/
│   │   │   └── rides_list_screen.dart       # Liste des courses
│   │   └── profile/
│   │       └── driver_profile_screen.dart   # Profil chauffeur
│   ├── services/
│   │   └── driver_api_service.dart          # Service API chauffeur
│   └── theme/
│       └── app_theme.dart                   # Thème de l'application
└── pubspec.yaml
```

---

## 🛠️ Technologies utilisées

### Frontend
- **Flutter** 3.0+ - Framework cross-platform
- **Dart** 3.0+ - Langage de programmation
- **flutter_map** - Cartes OpenStreetMap
- **geolocator** - Géolocalisation GPS
- **shared_preferences** - Stockage local
- **http** - Requêtes HTTP
- **go_router** - Navigation

### Backend
- **Flask** 3.0 - Framework web Python
- **Flask-SQLAlchemy** - ORM pour MySQL
- **Flask-JWT-Extended** - Authentification JWT
- **Flask-CORS** - Gestion CORS
- **Flask-Bcrypt** - Hashage de mots de passe
- **PyMySQL** - Driver MySQL
- **pandas** - Manipulation de données (rapports)
- **reportlab** - Génération PDF
- **openpyxl** - Génération Excel

### Base de données
- **MySQL** 8.0 - Base de données relationnelle

### Services externes (optionnels)
- **SMS API** - Envoi de SMS (Africa's Talking, Twilio, etc.)
- **WhatsApp API** - Envoi de messages WhatsApp
- **OpenStreetMap** - Cartes (gratuit, open source)

---

## 🎨 Design System

### Couleurs principales

- **Jaune primaire** : `#FFD60A` / `#FFC800`
- **Noir secondaire** : `#0C0C0C`
- **Vert accent** : `#00C897`
- **Blanc** : `#FFFFFF`
- **Gris** : `#F5F5F5`

### Typographie

- **Police principale** : Inter (Google Fonts)
- **Police secondaire** : Poppins (Google Fonts)

### Composants

- **Coins arrondis** : 16px (boutons, inputs), 20px (cartes)
- **Ombres** : Ombres douces pour la profondeur
- **Animations** : Transitions fluides et naturelles

---

## 🔒 Sécurité

- ✅ **Authentification JWT** - Tokens sécurisés avec expiration
- ✅ **Hashage des mots de passe** - Bcrypt pour le hashage
- ✅ **Validation des entrées** - Validation côté serveur
- ✅ **CORS configuré** - Protection contre les requêtes non autorisées
- ✅ **Codes OTP sécurisés** - Expiration automatique, non réutilisables
- ✅ **Gestion des rôles** - Séparation client/chauffeur/admin

---

## 📊 Base de données

### Tables principales

- **users** - Utilisateurs (clients et chauffeurs)
- **drivers** - Profils chauffeurs
- **rides** - Courses
- **payments** - Paiements
- **otps** - Codes OTP temporaires
- **vehicles** - Véhicules
- **commissions** - Commissions
- **revenues** - Revenus

Voir `temove-backend/models/` pour les modèles complets.

---

## 🧪 Tests

### Tests Backend

```bash
cd temove-backend
python -m pytest tests/
```

### Tests Flutter

```bash
cd temove
flutter test
```

---

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

### Guidelines

- Suivre les conventions de code Flutter/Dart et Python
- Ajouter des commentaires pour le code complexe
- Tester vos modifications
- Mettre à jour la documentation si nécessaire

---

## 📝 License

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus d'informations.

---

## 👥 Équipe

**TéMove Development Team**

- Développement Frontend (Flutter)
- Développement Backend (Flask)
- Design UI/UX
- Gestion de projet

---

## 📞 Support

Pour toute question ou problème :

- 📧 Email : support@temove.sn
- 💬 Issues GitHub : [Créer une issue](https://github.com/votre-username/temove/issues)
- 📚 Documentation : Voir les fichiers `.md` dans le projet

---

## 🗺️ Roadmap

### Version 1.1 (À venir)
- [ ] Intégration SMS/WhatsApp réelle
- [ ] Notifications push
- [ ] Paiement en ligne (Stripe, PayPal)
- [ ] Système de chat en temps réel
- [ ] Multi-langues (Wolof, Français, Anglais)

### Version 1.2 (Planifié)
- [ ] Application iOS native
- [ ] Application Android native
- [ ] Optimisation des performances
- [ ] Tests automatisés complets
- [ ] CI/CD pipeline

---

## 🙏 Remerciements

- **OpenStreetMap** - Pour les cartes gratuites et open source
- **Flutter Team** - Pour le framework exceptionnel
- **Flask Team** - Pour le framework backend robuste
- **Communauté open source** - Pour les nombreuses contributions

---

<div align="center">

**Made with ❤️ in Senegal**

![Senegal Flag](https://img.shields.io/badge/Senegal-🇸🇳-green)

[⬆ Retour en haut](#-témove---plateforme-de-transport-au-sénégal)

</div>
