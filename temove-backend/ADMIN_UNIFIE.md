# 🎛️ Administration Unifiée - TeMove & TeMove Pro

## 📋 Vue d'ensemble

Ce document décrit la stratégie pour gérer l'administration des deux applications :
- **TeMove** : Application client/passager
- **TeMove Pro** : Application conducteur

Les deux applications partagent le même backend, mais nécessitent des vues administratives distinctes et des métriques séparées.

---

## 🏗️ Architecture

### Structure actuelle

```
├── allo-dakar-backend/        # Backend commun
│   ├── models/
│   │   ├── user.py           # Utilisateurs (clients)
│   │   ├── driver.py         # Conducteurs
│   │   ├── ride.py           # Courses (communes)
│   │   └── commission.py     # Commissions
│   └── routes/
│       └── admin_routes.py   # Routes admin
│
├── allo-dakar-stitch-cursor/  # TeMove (Client)
└── temove-pro/                # TeMove Pro (Conducteur)
```

### Relations

- **User** : Utilisateurs de TeMove (clients)
- **Driver** : Utilisateurs de TeMove Pro (conducteurs)
- **Ride** : Courses (liées à User et Driver)
- **Commission** : Commissions des conducteurs
- **Revenue** : Revenus de la plateforme

---

## 🎯 Stratégie d'Administration

### Option 1 : Dashboard Unifié avec Onglets (Recommandé)

Un seul dashboard admin avec des onglets pour basculer entre les deux applications :

```
Dashboard Admin
├── Vue d'ensemble (Combined)
│   ├── Statistiques globales
│   ├── Revenus totaux
│   └── Métriques croisées
│
├── TeMove (Client)
│   ├── Utilisateurs (clients)
│   ├── Courses
│   ├── Revenus
│   └── Statistiques
│
└── TeMove Pro (Conducteur)
    ├── Conducteurs
    ├── Courses
    ├── Commissions
    ├── Revenus
    └── Statistiques
```

### Option 2 : Applications séparées avec authentification unique

Deux dashboards séparés, mais avec le même système d'authentification admin.

---

## 🔧 Implémentation

### 1. Routes API Admin

#### Routes globales (les deux applications)
- `GET /api/v1/admin/dashboard/stats` - Statistiques globales
- `GET /api/v1/admin/dashboard/overview` - Vue d'ensemble combinée

#### Routes TeMove (Client)
- `GET /api/v1/admin/temove/users` - Liste des clients
- `GET /api/v1/admin/temove/rides` - Courses des clients
- `GET /api/v1/admin/temove/revenue` - Revenus TeMove
- `GET /api/v1/admin/temove/stats` - Statistiques TeMove

#### Routes TeMove Pro (Conducteur)
- `GET /api/v1/admin/temove-pro/drivers` - Liste des conducteurs
- `GET /api/v1/admin/temove-pro/rides` - Courses des conducteurs
- `GET /api/v1/admin/temove-pro/commissions` - Commissions
- `GET /api/v1/admin/temove-pro/revenue` - Revenus TeMove Pro
- `GET /api/v1/admin/temove-pro/stats` - Statistiques TeMove Pro

### 2. Filtrage des données

Les données sont naturellement séparées :
- **User** → TeMove (clients)
- **Driver** → TeMove Pro (conducteurs)
- **Ride** → Liée à User (TeMove) et Driver (TeMove Pro)

### 3. Interface Admin

Le dashboard admin affiche :
- **Sélecteur d'application** : TeMove / TeMove Pro / Vue globale
- **Statistiques spécifiques** selon l'application sélectionnée
- **Navigation** : Onglets ou menu latéral

---

## 📊 Métriques par Application

### TeMove (Client)
- Nombre de clients
- Nombre de courses
- Revenus (commissions sur courses)
- Taux de croissance des clients
- Courses par client
- Revenu par client

### TeMove Pro (Conducteur)
- Nombre de conducteurs
- Nombre de courses
- Commissions payées
- Revenus des conducteurs
- Taux d'acceptation des courses
- Note moyenne des conducteurs

### Vue globale
- Revenus totaux
- Nombre total de courses
- Utilisateurs actifs (clients + conducteurs)
- Taux de croissance global
- Métriques croisées

---

## 🚀 Prochaines Étapes

1. ✅ Ajouter des routes admin spécifiques par application
2. ✅ Créer des vues séparées dans le dashboard admin Flutter
3. ✅ Implémenter le sélecteur d'application
4. ✅ Ajouter des graphiques et visualisations par application
5. ✅ Créer des rapports séparés

