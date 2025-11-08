# 🚀 Installation du Dashboard Administrateur

## 📋 Prérequis

- Backend Flask fonctionnel
- Base de données MySQL/PostgreSQL configurée
- Python 3.8+

---

## 🔧 Installation

### Étape 1 : Ajouter le champ `is_admin` au modèle User

Ajoutez ce champ dans `models/user.py` :

```python
# Dans la classe User
is_admin = db.Column(db.Boolean, default=False, nullable=False)
```

### Étape 2 : Créer la migration

```bash
cd allo-dakar-backend
flask db migrate -m "Add is_admin field to users"
flask db upgrade
```

### Étape 3 : Enregistrer les routes admin

Dans `app/__init__.py` ou `app.py`, ajoutez :

```python
from routes.admin_routes import admin_bp

app.register_blueprint(admin_bp, url_prefix="/api/v1/admin")
```

### Étape 4 : Créer un utilisateur admin

Exécutez ce script Python :

```python
# scripts/create_admin.py
from app import create_app
from extensions import db
from models.user import User

app = create_app()

with app.app_context():
    # Créer un utilisateur admin
    admin_email = "admin@temove.sn"
    admin_password = "ChangezCeMotDePasse123!"
    
    # Vérifier si l'admin existe déjà
    admin = User.query.filter_by(email=admin_email).first()
    
    if admin:
        admin.is_admin = True
        print(f"Utilisateur {admin_email} est maintenant admin")
    else:
        admin = User(
            email=admin_email,
            full_name="Administrateur",
            is_admin=True,
            is_active=True,
            is_verified=True
        )
        admin.set_password(admin_password)
        db.session.add(admin)
        print(f"Admin créé : {admin_email}")
    
    db.session.commit()
    print("✅ Admin créé avec succès!")
```

Exécutez :

```bash
python scripts/create_admin.py
```

---

## 🔐 Authentification Admin

### Se connecter en tant qu'admin

Utilisez les mêmes endpoints d'authentification que les utilisateurs normaux :

```bash
POST /api/v1/auth/login
{
  "email": "admin@temove.sn",
  "password": "votre_mot_de_passe"
}
```

La réponse inclura un token JWT. Utilisez ce token pour les requêtes admin.

---

## 📡 Endpoints Admin Disponibles

### Dashboard

```bash
GET /api/v1/admin/dashboard/stats
Headers: Authorization: Bearer <token>
```

### Utilisateurs

```bash
# Liste des utilisateurs
GET /api/v1/admin/users?page=1&per_page=20&search=john&status=active

# Détails d'un utilisateur
GET /api/v1/admin/users/<user_id>

# Activer/Désactiver un utilisateur
POST /api/v1/admin/users/<user_id>/toggle-status
```

### Conducteurs

```bash
# Liste des conducteurs
GET /api/v1/admin/drivers?page=1&status=pending

# Approuver un conducteur
POST /api/v1/admin/drivers/<driver_id>/approve
```

### Courses

```bash
# Liste des courses
GET /api/v1/admin/rides?page=1&status=completed&start_date=2024-01-01
```

### Commissions

```bash
# Liste des commissions
GET /api/v1/admin/commissions?page=1&status=paid
```

### Revenus

```bash
# Revenus mensuels
GET /api/v1/admin/revenue/monthly?year=2024&month=1
```

---

## 🎨 Prochaines Étapes : Créer le Dashboard Frontend

### Option 1 : Dashboard Web React

Créez un nouveau projet React :

```bash
npx create-react-app allo-dakar-admin --template typescript
cd allo-dakar-admin
npm install axios react-router-dom @mui/material @emotion/react @emotion/styled
npm install recharts  # Pour les graphiques
```

### Option 2 : Utiliser un Template Admin

Templates recommandés :
- **AdminLTE** : https://adminlte.io
- **Material Dashboard** : https://www.creative-tim.com/product/material-dashboard
- **Ant Design Pro** : https://pro.ant.design

### Option 3 : Framework Full-Stack

- **Django Admin** : Si vous voulez un backend Django
- **Laravel Nova** : Si vous voulez un backend Laravel
- **Strapi Admin** : CMS avec admin intégré

---

## 📝 Structure du Dashboard Frontend (Recommandation)

```
allo-dakar-admin/
├── src/
│   ├── components/
│   │   ├── Dashboard/
│   │   │   ├── StatsCard.tsx
│   │   │   ├── RevenueChart.tsx
│   │   │   └── RidesChart.tsx
│   │   ├── Users/
│   │   │   ├── UserList.tsx
│   │   │   └── UserDetail.tsx
│   │   ├── Drivers/
│   │   │   ├── DriverList.tsx
│   │   │   └── DriverDetail.tsx
│   │   └── Common/
│   │       ├── Sidebar.tsx
│   │       ├── Header.tsx
│   │       └── DataTable.tsx
│   ├── pages/
│   │   ├── Dashboard.tsx
│   │   ├── Users.tsx
│   │   ├── Drivers.tsx
│   │   ├── Rides.tsx
│   │   ├── Revenue.tsx
│   │   └── Settings.tsx
│   ├── services/
│   │   └── api.ts  # Appels API
│   ├── hooks/
│   │   └── useAuth.ts
│   └── App.tsx
```

---

## 🔒 Sécurité

### Bonnes Pratiques

1. **Authentification** : Utilisez JWT avec expiration
2. **HTTPS** : Obligatoire en production
3. **Rate Limiting** : Limitez les requêtes API
4. **Logs** : Enregistrez toutes les actions admin
5. **2FA** : Recommandé pour les admins (à implémenter)

### Exemple de Middleware de Sécurité

```python
# Dans routes/admin_routes.py
from functools import wraps
from flask import request
import logging

logger = logging.getLogger(__name__)

def log_admin_action(action):
    """Logger les actions admin"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            current_user_id = get_jwt_identity()
            user = User.query.get(current_user_id)
            
            # Logger l'action
            logger.info(f"Admin {user.email} performed: {action}")
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator
```

---

## 📊 Exemple d'Utilisation avec React

### Service API

```typescript
// src/services/api.ts
import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:5000/api/v1';

const api = axios.create({
  baseURL: API_URL,
});

// Ajouter le token à chaque requête
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const adminAPI = {
  // Dashboard
  getDashboardStats: () => api.get('/admin/dashboard/stats'),
  
  // Users
  getUsers: (params: any) => api.get('/admin/users', { params }),
  getUser: (id: number) => api.get(`/admin/users/${id}`),
  toggleUserStatus: (id: number) => api.post(`/admin/users/${id}/toggle-status`),
  
  // Drivers
  getDrivers: (params: any) => api.get('/admin/drivers', { params }),
  approveDriver: (id: number) => api.post(`/admin/drivers/${id}/approve`),
  
  // Rides
  getRides: (params: any) => api.get('/admin/rides', { params }),
  
  // Revenue
  getMonthlyRevenue: (year: number, month: number) => 
    api.get('/admin/revenue/monthly', { params: { year, month } }),
};

export default api;
```

### Composant Dashboard

```typescript
// src/pages/Dashboard.tsx
import React, { useEffect, useState } from 'react';
import { adminAPI } from '../services/api';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState<any>(null);
  
  useEffect(() => {
    adminAPI.getDashboardStats()
      .then(response => setStats(response.data))
      .catch(error => console.error(error));
  }, []);
  
  if (!stats) return <div>Chargement...</div>;
  
  return (
    <div>
      <h1>Tableau de Bord</h1>
      <div className="stats-grid">
        <div className="stat-card">
          <h3>Revenus du Mois</h3>
          <p>{stats.revenue.current_month.toLocaleString()} XOF</p>
          <span className={stats.revenue.growth > 0 ? 'positive' : 'negative'}>
            {stats.revenue.growth > 0 ? '+' : ''}{stats.revenue.growth}%
          </span>
        </div>
        {/* Autres cartes de statistiques */}
      </div>
    </div>
  );
};

export default Dashboard;
```

---

## 🧪 Tests

### Tester les Endpoints Admin

```bash
# Obtenir le token
TOKEN=$(curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@temove.sn","password":"votre_mot_de_passe"}' \
  | jq -r '.access_token')

# Tester le dashboard
curl -X GET http://localhost:5000/api/v1/admin/dashboard/stats \
  -H "Authorization: Bearer $TOKEN"
```

---

## ✅ Checklist

- [ ] Ajouter champ `is_admin` au modèle User
- [ ] Créer la migration
- [ ] Enregistrer les routes admin
- [ ] Créer un utilisateur admin
- [ ] Tester les endpoints admin
- [ ] Créer le dashboard frontend (optionnel)
- [ ] Configurer HTTPS
- [ ] Mettre en place les logs
- [ ] Configurer le rate limiting

---

**Date de création** : 2024
**Version** : 1.0

