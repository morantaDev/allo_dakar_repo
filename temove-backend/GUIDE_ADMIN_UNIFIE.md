# 📖 Guide d'Administration Unifiée - TeMove & TeMove Pro

## 🎯 Vue d'ensemble

Ce guide explique comment utiliser le système d'administration unifiée pour gérer les deux applications :
- **TeMove** : Application client/passager
- **TeMove Pro** : Application conducteur

---

## 🔌 Endpoints API

### Vue d'ensemble globale

#### `GET /api/v1/admin/dashboard/stats`
Statistiques globales (les deux applications)

**Réponse :**
```json
{
  "revenue": {
    "current_month": 0,
    "last_month": 0,
    "growth": 0,
    "commissions": 0
  },
  "rides": {
    "today": 0,
    "current_month": 0,
    "last_month": 0,
    "growth": 0
  },
  "users": {
    "total": 0,
    "active_30d": 0
  },
  "drivers": {
    "active": 0
  }
}
```

#### `GET /api/v1/admin/dashboard/overview`
Vue d'ensemble combinée avec détails des deux applications

---

### Routes TeMove (Application Client)

#### `GET /api/v1/admin/temove/stats`
Statistiques spécifiques à TeMove

**Réponse :**
```json
{
  "application": "TeMove",
  "clients": {
    "total": 0,
    "new_this_month": 0,
    "new_last_month": 0,
    "growth": 0
  },
  "rides": {
    "today": 0,
    "this_month": 0,
    "last_month": 0,
    "growth": 0,
    "per_client": 0
  },
  "revenue": {
    "this_month": 0,
    "last_month": 0,
    "growth": 0,
    "per_client": 0
  }
}
```

#### `GET /api/v1/admin/temove/users`
Liste des clients TeMove (alias de `/api/v1/admin/users`)

#### `GET /api/v1/admin/temove/rides`
Liste des courses TeMove (alias de `/api/v1/admin/rides`)

---

### Routes TeMove Pro (Application Conducteur)

#### `GET /api/v1/admin/temove-pro/stats`
Statistiques spécifiques à TeMove Pro

**Réponse :**
```json
{
  "application": "TeMove Pro",
  "drivers": {
    "total": 0,
    "approved": 0,
    "pending": 0,
    "new_this_month": 0,
    "new_last_month": 0,
    "growth": 0,
    "avg_rating": 0
  },
  "rides": {
    "today": 0,
    "this_month": 0,
    "last_month": 0,
    "growth": 0,
    "per_driver": 0
  },
  "commissions": {
    "platform_this_month": 0,
    "driver_earnings_this_month": 0,
    "platform_last_month": 0,
    "growth": 0,
    "avg_per_driver": 0
  },
  "earnings": {
    "avg_per_driver": 0
  }
}
```

#### `GET /api/v1/admin/temove-pro/drivers`
Liste des conducteurs TeMove Pro (alias de `/api/v1/admin/drivers`)

#### `GET /api/v1/admin/temove-pro/rides`
Liste des courses TeMove Pro (alias de `/api/v1/admin/rides`)

#### `GET /api/v1/admin/temove-pro/commissions`
Liste des commissions TeMove Pro (alias de `/api/v1/admin/commissions`)

---

## 📊 Utilisation dans le Frontend

### 1. Sélecteur d'application

Dans le dashboard admin Flutter, ajoutez un sélecteur pour basculer entre les applications :

```dart
enum ApplicationType { all, temove, temovePro }

ApplicationType selectedApp = ApplicationType.all;
```

### 2. Chargement des statistiques

```dart
Future<void> loadStats() async {
  switch (selectedApp) {
    case ApplicationType.all:
      stats = await ApiService.getAdminDashboardStats();
      break;
    case ApplicationType.temove:
      stats = await ApiService.getTeMoveStats();
      break;
    case ApplicationType.temovePro:
      stats = await ApiService.getTeMoveProStats();
      break;
  }
}
```

### 3. Affichage conditionnel

Affichez différentes métriques selon l'application sélectionnée :
- **TeMove** : Clients, courses, revenus par client
- **TeMove Pro** : Conducteurs, commissions, revenus par conducteur
- **Vue globale** : Métriques combinées

---

## 🔐 Authentification

Toutes les routes admin nécessitent :
- Un token JWT valide dans le header `Authorization: Bearer <token>`
- L'utilisateur doit avoir `is_admin = true`

---

## 📝 Exemple d'utilisation

### Python (curl)

```bash
# Statistiques globales
curl -H "Authorization: Bearer <token>" \
  http://127.0.0.1:5000/api/v1/admin/dashboard/stats

# Statistiques TeMove
curl -H "Authorization: Bearer <token>" \
  http://127.0.0.1:5000/api/v1/admin/temove/stats

# Statistiques TeMove Pro
curl -H "Authorization: Bearer <token>" \
  http://127.0.0.1:5000/api/v1/admin/temove-pro/stats
```

---

## 🚀 Prochaines étapes

1. ✅ Implémenter le sélecteur d'application dans le dashboard Flutter
2. ✅ Créer des vues séparées pour chaque application
3. ✅ Ajouter des graphiques et visualisations
4. ✅ Créer des rapports détaillés par application

