# Témove Pro - Application Chauffeurs

Application mobile Flutter dédiée aux chauffeurs de Témove. Cette application permet aux chauffeurs de gérer leurs courses, leur disponibilité, leurs revenus et leur profil.

## 🎯 Fonctionnalités

### Authentification
- Connexion/Inscription pour les chauffeurs
- Vérification de compte
- Gestion de session

### Tableau de bord
- Vue d'ensemble des statistiques
- Revenus du jour/semaine/mois
- Nombre de courses effectuées
- Note moyenne

### Gestion des courses
- Réception des demandes de course en temps réel
- Acceptation/Refus de courses
- Navigation vers le client
- Démarrer/Terminer une course
- Historique des courses

### Disponibilité
- Activer/Désactiver la disponibilité
- Mode hors ligne/en ligne
- Statut automatique (en course, disponible, etc.)

### Profil
- Gestion du profil chauffeur
- Informations du véhicule
- Documents (permis, assurance, etc.)
- Statistiques personnelles

### Revenus
- Vue détaillée des revenus
- Historique des paiements
- Retraits

## 🏗️ Structure du projet

```
temove-pro/
├── lib/
│   ├── main.dart              # Point d'entrée
│   ├── models/                # Modèles de données
│   ├── screens/               # Écrans de l'application
│   │   ├── auth/              # Authentification
│   │   ├── dashboard/          # Tableau de bord
│   │   ├── rides/             # Gestion des courses
│   │   ├── profile/           # Profil chauffeur
│   │   └── earnings/          # Revenus
│   ├── services/               # Services (API, etc.)
│   ├── widgets/                # Widgets réutilisables
│   └── theme/                  # Thème de l'application
├── assets/                     # Images, icônes
└── pubspec.yaml               # Dépendances
```

## 🚀 Installation

1. Installer Flutter : https://flutter.dev/docs/get-started/install

2. Installer les dépendances :
```bash
flutter pub get
```

3. Lancer l'application :
```bash
flutter run
```

## 📱 Backend API

L'application se connecte au backend Témove à :
- **URL**: `http://127.0.0.1:5000/api/v1` (développement)
- **Endpoints chauffeurs**: `/api/v1/drivers/*`

## 🔐 Authentification

Les chauffeurs utilisent le même système d'authentification JWT que l'application principale, mais avec des endpoints spécifiques aux chauffeurs.

## 📝 Notes

- Cette application est séparée de l'application principale (allo-dakar-stitch-cursor)
- Elle partage le même backend que l'application principale
- Les chauffeurs doivent avoir un compte vérifié pour utiliser l'application
