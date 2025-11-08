# 💻 Guide d'Implémentation - Système de Commission

Ce document explique comment implémenter le système de commission et de monétisation dans TeMove.

## 📋 Table des Matières

1. [Migration de Base de Données](#migration-de-base-de-données)
2. [Intégration du Service de Commission](#intégration-du-service-de-commission)
3. [Mise à Jour des Routes](#mise-à-jour-des-routes)
4. [Exemples d'Utilisation](#exemples-dutilisation)

---

## 1. Migration de Base de Données

### Étape 1 : Créer la Migration

```bash
cd allo-dakar-backend
flask db migrate -m "Add commission and revenue models"
flask db upgrade
```

### Étape 2 : Vérifier les Tables

Les nouvelles tables `commissions` et `revenues` seront créées automatiquement.

---

## 2. Intégration du Service de Commission

### 2.1 Mettre à Jour le Modèle Ride

Ajouter le calcul de commission lors de la finalisation d'une course :

```python
# Dans models/ride.py
from services.commission_service import CommissionService

class Ride(db.Model):
    # ... code existant ...
    
    def complete_ride(self, final_price: int, driver_id: int):
        """Finaliser une course et calculer la commission"""
        from models.commission import Commission
        from models.user import User
        from models.driver import Driver
        
        self.status = RideStatus.COMPLETED
        self.completed_at = datetime.utcnow()
        self.final_price = final_price
        
        # Obtenir les informations nécessaires
        user = User.query.get(self.user_id)
        driver = Driver.query.get(driver_id)
        
        # Calculer la commission
        commission_service = CommissionService()
        commission_data = commission_service.calculate_commission(
            ride_price=final_price,
            ride_mode=self.ride_mode.value,
            surge_multiplier=self.surge_multiplier,
            is_premium_user=user.is_premium if hasattr(user, 'is_premium') else False,
            driver_subscription=driver.subscription_type if hasattr(driver, 'subscription_type') else 'basic'
        )
        
        # Créer l'enregistrement de commission
        commission = Commission(
            ride_id=self.id,
            driver_id=driver_id,
            ride_price=final_price,
            platform_commission=commission_data['platform_commission'],
            driver_earnings=commission_data['driver_earnings'],
            service_fee=commission_data['service_fee'],
            commission_rate=commission_data['commission_rate'],
            base_commission=commission_data['base_commission'],
            surge_commission=commission_data['surge_commission'],
            base_price=commission_data['base_price'],
            surge_amount=commission_data['surge_amount'],
            status='pending'
        )
        
        db.session.add(commission)
        db.session.commit()
        
        return commission
```

### 2.2 Mettre à Jour les Routes de Courses

Modifier `routes/rides.py` pour inclure la commission :

```python
# Dans routes/rides.py
from services.commission_service import CommissionService

@rides_bp.route('/<int:ride_id>/complete', methods=['POST'])
@jwt_required()
def complete_ride(ride_id):
    """Finaliser une course"""
    from models.ride import Ride, RideStatus
    from models.commission import Commission
    
    ride = Ride.query.get_or_404(ride_id)
    
    if ride.status != RideStatus.IN_PROGRESS:
        return jsonify({'error': 'La course n\'est pas en cours'}), 400
    
    # Obtenir le prix final (peut être ajusté selon la distance réelle)
    data = request.get_json()
    final_price = data.get('final_price', ride.final_price)
    
    # Finaliser la course et calculer la commission
    commission = ride.complete_ride(final_price, ride.driver_id)
    
    return jsonify({
        'message': 'Course terminée avec succès',
        'ride': ride.to_dict(),
        'commission': commission.to_dict()
    }), 200
```

---

## 3. Mise à Jour des Routes

### 3.1 Créer une Route pour les Revenus

Créer `routes/revenue.py` :

```python
"""
Routes pour la gestion des revenus
"""
from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.commission import Commission, Revenue
from models.user import User
from services.commission_service import CommissionService
from extensions import db
from datetime import datetime

revenue_bp = Blueprint('revenue', __name__)

@revenue_bp.route('/platform/monthly', methods=['GET'])
@jwt_required()
def get_monthly_revenue():
    """Obtenir les revenus mensuels de la plateforme (admin only)"""
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    # Vérifier si l'utilisateur est admin
    if not user or not user.is_admin:
        return jsonify({'error': 'Accès non autorisé'}), 403
    
    year = request.args.get('year', datetime.now().year, type=int)
    month = request.args.get('month', datetime.now().month, type=int)
    
    revenue = Revenue.query.filter_by(year=year, month=month).first()
    
    if not revenue:
        return jsonify({'error': 'Revenus non trouvés pour cette période'}), 404
    
    return jsonify(revenue.to_dict()), 200

@revenue_bp.route('/driver/<int:driver_id>/earnings', methods=['GET'])
@jwt_required()
def get_driver_earnings(driver_id):
    """Obtenir les revenus d'un conducteur"""
    from models.driver import Driver
    
    current_user_id = get_jwt_identity()
    
    # Vérifier que c'est le conducteur ou un admin
    driver = Driver.query.get_or_404(driver_id)
    if driver.user_id != current_user_id:
        user = User.query.get(current_user_id)
        if not user or not user.is_admin:
            return jsonify({'error': 'Accès non autorisé'}), 403
    
    # Paramètres de période
    year = request.args.get('year', datetime.now().year, type=int)
    month = request.args.get('month', datetime.now().month, type=int)
    
    # Calculer les revenus du mois
    commissions = Commission.query.filter(
        Commission.driver_id == driver_id,
        db.extract('year', Commission.created_at) == year,
        db.extract('month', Commission.created_at) == month,
        Commission.status == 'paid'
    ).all()
    
    total_earnings = sum(c.driver_earnings for c in commissions)
    rides_count = len(commissions)
    
    return jsonify({
        'driver_id': driver_id,
        'year': year,
        'month': month,
        'total_earnings': total_earnings,
        'rides_count': rides_count,
        'average_earnings_per_ride': total_earnings / rides_count if rides_count > 0 else 0,
        'commissions': [c.to_dict() for c in commissions]
    }), 200

@revenue_bp.route('/platform/projection', methods=['GET'])
@jwt_required()
def get_revenue_projection():
    """Obtenir une projection des revenus (admin only)"""
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if not user or not user.is_admin:
        return jsonify({'error': 'Accès non autorisé'}), 403
    
    # Paramètres
    rides_count = request.args.get('rides_count', 1000, type=int)
    avg_ride_price = request.args.get('avg_ride_price', 2500, type=int)
    premium_users = request.args.get('premium_users', 100, type=int)
    
    driver_subscriptions = {
        'basic': request.args.get('drivers_basic', 50, type=int),
        'premium': request.args.get('drivers_premium', 10, type=int),
        'enterprise': request.args.get('drivers_enterprise', 5, type=int),
    }
    
    commission_service = CommissionService()
    projection = commission_service.get_monthly_revenue_projection(
        rides_count=rides_count,
        avg_ride_price=avg_ride_price,
        premium_users=premium_users,
        driver_subscriptions=driver_subscriptions
    )
    
    return jsonify(projection), 200
```

### 3.2 Enregistrer les Routes

Dans `app/__init__.py` ou `app.py` :

```python
from routes.revenue import revenue_bp

app.register_blueprint(revenue_bp, url_prefix='/api/v1/revenue')
```

---

## 4. Exemples d'Utilisation

### 4.1 Calculer une Commission

```python
from services.commission_service import CommissionService

commission_service = CommissionService()

# Exemple : Course confort de 3000 XOF avec surge 1.5x
result = commission_service.calculate_commission(
    ride_price=4500,  # 3000 * 1.5
    ride_mode='confort',
    surge_multiplier=1.5,
    is_premium_user=False,
    driver_subscription='basic'
)

print(f"Commission plateforme: {result['platform_commission']} XOF")
print(f"Revenus conducteur: {result['driver_earnings']} XOF")
print(f"Frais de service: {result['service_fee']} XOF")
```

### 4.2 Projeter les Revenus Mensuels

```python
projection = commission_service.get_monthly_revenue_projection(
    rides_count=5000,
    avg_ride_price=2500,
    premium_users=100,
    driver_subscriptions={
        'basic': 50,
        'premium': 10,
        'enterprise': 5
    }
)

print(f"Revenus totaux projetés: {projection['total_revenue']} XOF")
```

### 4.3 Calculer une Récompense de Parrainage

```python
# Récompense pour un utilisateur qui parraine
reward = commission_service.calculate_referral_reward(
    ride_price=2500,
    referrer_type='user'
)
print(f"Récompense: {reward} XOF")
```

---

## 5. Dashboard Administrateur

### 5.1 Endpoint pour Statistiques

Créer `routes/admin_stats.py` :

```python
"""
Routes pour les statistiques administrateur
"""
from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.commission import Commission, Revenue
from models.user import User
from models.ride import Ride
from models.driver import Driver
from extensions import db
from datetime import datetime, timedelta

admin_stats_bp = Blueprint('admin_stats', __name__)

@admin_stats_bp.route('/dashboard', methods=['GET'])
@jwt_required()
def get_dashboard_stats():
    """Obtenir les statistiques du dashboard admin"""
    current_user_id = get_jwt_identity()
    user = User.query.get(current_user_id)
    
    if not user or not user.is_admin:
        return jsonify({'error': 'Accès non autorisé'}), 403
    
    # Période : dernier mois
    today = datetime.now()
    last_month = today - timedelta(days=30)
    
    # Revenus du mois
    current_month_revenue = Revenue.query.filter_by(
        year=today.year,
        month=today.month
    ).first()
    
    # Commissions du mois
    monthly_commissions = Commission.query.filter(
        Commission.created_at >= datetime(today.year, today.month, 1),
        Commission.status == 'paid'
    ).all()
    
    total_commissions = sum(c.platform_commission for c in monthly_commissions)
    
    # Statistiques
    total_rides = Ride.query.filter(
        Ride.created_at >= datetime(today.year, today.month, 1)
    ).count()
    
    active_users = User.query.filter(
        User.created_at >= last_month
    ).count()
    
    active_drivers = Driver.query.filter(
        Driver.is_active == True
    ).count()
    
    return jsonify({
        'revenue': {
            'total': current_month_revenue.total_revenue if current_month_revenue else 0,
            'commissions': total_commissions,
            'premium': current_month_revenue.premium_revenue if current_month_revenue else 0,
            'driver_subscriptions': current_month_revenue.driver_subscription_revenue if current_month_revenue else 0,
        },
        'metrics': {
            'total_rides': total_rides,
            'active_users': active_users,
            'active_drivers': active_drivers,
        },
        'period': {
            'year': today.year,
            'month': today.month,
        }
    }), 200
```

---

## 6. Tests

### 6.1 Test du Service de Commission

Créer `tests/test_commission_service.py` :

```python
import unittest
from services.commission_service import CommissionService

class TestCommissionService(unittest.TestCase):
    def setUp(self):
        self.service = CommissionService()
    
    def test_calculate_commission_basic(self):
        """Test du calcul de commission basique"""
        result = self.service.calculate_commission(
            ride_price=2500,
            ride_mode='confort',
            surge_multiplier=1.0,
            is_premium_user=False,
            driver_subscription='basic'
        )
        
        self.assertIn('platform_commission', result)
        self.assertIn('driver_earnings', result)
        self.assertGreater(result['platform_commission'], 0)
        self.assertGreater(result['driver_earnings'], 0)
    
    def test_calculate_commission_surge(self):
        """Test du calcul de commission avec surge pricing"""
        result = self.service.calculate_commission(
            ride_price=3750,  # 2500 * 1.5
            ride_mode='confort',
            surge_multiplier=1.5,
            is_premium_user=False,
            driver_subscription='basic'
        )
        
        self.assertGreater(result['surge_commission'], 0)
        self.assertGreater(result['platform_commission'], 0)
```

---

## 7. Prochaines Étapes

1. ✅ Implémenter le service de commission
2. ✅ Créer les modèles de base de données
3. ✅ Intégrer dans les routes de courses
4. ⏳ Créer le dashboard admin
5. ⏳ Implémenter les abonnements premium
6. ⏳ Mettre en place le système de paiement des conducteurs
7. ⏳ Créer des rapports mensuels automatiques

---

**Date de création** : 2024
**Version** : 1.0

