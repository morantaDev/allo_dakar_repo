# Architecture - Applications Témove

## Vue d'ensemble

Les deux applications Témove sont **complètement indépendantes** mais partagent la même base de données backend.

## Applications

### 1. Allo Dakar (Client) - `allo-dakar-stitch-cursor`
- **Rôle** : Application pour les clients/passagers
- **Service API** : `lib/services/api_service.dart`
- **Base URL** : `http://127.0.0.1:5000/api/v1`
- **Endpoints utilisés** :
  - `/api/v1/auth/*` - Authentification
  - `/api/v1/rides/*` - Réservation de courses
  - `/api/v1/promo/*` - Codes promo
  - `/api/v1/referral/*` - Parrainage
  - `/api/v1/loyalty/*` - Fidélité

### 2. Témove Pro (Chauffeur) - `temove-pro`
- **Rôle** : Application pour les chauffeurs
- **Service API** : `lib/services/driver_api_service.dart`
- **Base URL** : `http://127.0.0.1:5000/api/v1`
- **Endpoints utilisés** :
  - `/api/v1/auth/*` - Authentification (partagé)
  - `/api/v1/drivers/*` - Gestion chauffeur
  - `/api/v1/rides/*` - Gestion des courses

## Backend - `allo-dakar-backend`

### Base de données partagée
- **Base de données** : MySQL `temove_db`
- **Tables principales** :
  - `users` - Utilisateurs (clients et chauffeurs)
  - `drivers` - Profils chauffeurs
  - `rides` - Courses
  - `payments` - Paiements
  - `vehicles` - Véhicules

### Routes API

#### Routes publiques (partagées)
- `POST /api/v1/auth/register` - Inscription
- `POST /api/v1/auth/login` - Connexion

#### Routes clients
- `POST /api/v1/rides/estimate` - Estimation de prix
- `POST /api/v1/rides/book` - Réservation
- `GET /api/v1/rides/history` - Historique

#### Routes chauffeurs
- `POST /api/v1/drivers/register` - Inscription chauffeur
- `POST /api/v1/drivers/set-status` - Changer statut
- `GET /api/v1/drivers/rides` - Courses disponibles
- `GET /api/v1/drivers/me` - Informations chauffeur
- `GET /api/v1/drivers/stats` - Statistiques

## Indépendance des applications

### ✅ Ce qui est indépendant
- **Code source** : Chaque application a son propre code Flutter
- **Services API** : Chaque application a son propre service API
- **Stockage local** : Chaque application stocke ses propres tokens JWT
- **Interface utilisateur** : Chaque application a sa propre UI
- **Navigation** : Chaque application a sa propre navigation

### ✅ Ce qui est partagé
- **Backend Flask** : Même serveur API
- **Base de données** : Même base MySQL
- **Authentification** : Même système JWT (mais tokens séparés)
- **Modèles de données** : Mêmes modèles dans la base de données

## Communication

Les deux applications communiquent avec le backend de manière **indépendante** :
- Aucune communication directe entre les applications
- Toute communication passe par le backend
- Les données sont synchronisées via la base de données partagée

## Exemple de flux

### Réservation d'une course (Client)
1. Client ouvre `allo-dakar-stitch-cursor`
2. Client se connecte → Token JWT stocké localement
3. Client réserve une course → POST `/api/v1/rides/book`
4. Backend crée la course dans la base de données
5. Course disponible pour les chauffeurs

### Acceptation d'une course (Chauffeur)
1. Chauffeur ouvre `temove-pro`
2. Chauffeur se connecte → Token JWT stocké localement (différent du client)
3. Chauffeur voit les courses disponibles → GET `/api/v1/drivers/rides`
4. Chauffeur accepte une course → POST `/api/v1/rides/{id}/accept`
5. Backend met à jour la course dans la base de données
6. Client peut voir que sa course a été acceptée

## Configuration CORS

Le backend est configuré pour accepter les requêtes depuis n'importe quelle origine (`origins='*'`), permettant aux deux applications de fonctionner indépendamment.

