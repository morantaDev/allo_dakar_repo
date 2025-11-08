"""
Modèle Commission pour suivre les commissions et revenus
"""
from datetime import datetime
from extensions import db


class Commission(db.Model):
    """Modèle de commission sur une course"""
    __tablename__ = 'commissions'
    
    id = db.Column(db.Integer, primary_key=True)
    ride_id = db.Column(db.Integer, db.ForeignKey('rides.id'), nullable=False, unique=True, index=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False, index=True)
    
    # Montants
    ride_price = db.Column(db.Integer, nullable=False)  # Prix total de la course (XOF)
    platform_commission = db.Column(db.Integer, nullable=False)  # Commission plateforme (XOF)
    driver_earnings = db.Column(db.Integer, nullable=False)  # Revenus conducteur (XOF)
    service_fee = db.Column(db.Integer, default=0, nullable=False)  # Frais de service (XOF)
    
    # Taux et détails
    commission_rate = db.Column(db.Float, nullable=False)  # Taux de commission (%)
    base_commission = db.Column(db.Integer, nullable=False)  # Commission de base
    surge_commission = db.Column(db.Integer, default=0, nullable=False)  # Commission sur surge
    base_price = db.Column(db.Integer, nullable=False)  # Prix de base (sans surge)
    surge_amount = db.Column(db.Integer, default=0, nullable=False)  # Montant de la surcharge
    
    # Statut
    status = db.Column(db.String(50), default='pending', nullable=False)  # pending, paid, failed
    paid_at = db.Column(db.DateTime, nullable=True)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relations
    ride = db.relationship('Ride', backref='commission')
    driver = db.relationship('Driver', backref='commissions')
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'ride_id': self.ride_id,
            'driver_id': self.driver_id,
            'ride_price': self.ride_price,
            'platform_commission': self.platform_commission,
            'driver_earnings': self.driver_earnings,
            'service_fee': self.service_fee,
            'commission_rate': self.commission_rate,
            'base_commission': self.base_commission,
            'surge_commission': self.surge_commission,
            'base_price': self.base_price,
            'surge_amount': self.surge_amount,
            'status': self.status,
            'paid_at': self.paid_at.isoformat() if self.paid_at else None,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
    
    def __repr__(self):
        return f'<Commission {self.id} - Ride {self.ride_id} - {self.platform_commission} XOF>'


class Revenue(db.Model):
    """Modèle pour suivre les revenus mensuels de la plateforme"""
    __tablename__ = 'revenues'
    
    id = db.Column(db.Integer, primary_key=True)
    
    # Période
    year = db.Column(db.Integer, nullable=False, index=True)
    month = db.Column(db.Integer, nullable=False, index=True)  # 1-12
    
    # Revenus par source
    commission_revenue = db.Column(db.Integer, default=0, nullable=False)  # Commissions courses
    premium_revenue = db.Column(db.Integer, default=0, nullable=False)  # Abonnements premium
    driver_subscription_revenue = db.Column(db.Integer, default=0, nullable=False)  # Abonnements conducteurs
    service_fees_revenue = db.Column(db.Integer, default=0, nullable=False)  # Frais de service
    delivery_revenue = db.Column(db.Integer, default=0, nullable=False)  # Commissions livraisons
    partnership_revenue = db.Column(db.Integer, default=0, nullable=False)  # Partenariats
    other_revenue = db.Column(db.Integer, default=0, nullable=False)  # Autres revenus
    
    # Totaux
    total_revenue = db.Column(db.Integer, nullable=False)
    
    # Métriques
    rides_count = db.Column(db.Integer, default=0, nullable=False)
    active_users = db.Column(db.Integer, default=0, nullable=False)
    active_drivers = db.Column(db.Integer, default=0, nullable=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Contrainte unique sur année/mois
    __table_args__ = (db.UniqueConstraint('year', 'month', name='_year_month_uc'),)
    
    def calculate_total(self):
        """Calculer le total des revenus"""
        self.total_revenue = (
            self.commission_revenue +
            self.premium_revenue +
            self.driver_subscription_revenue +
            self.service_fees_revenue +
            self.delivery_revenue +
            self.partnership_revenue +
            self.other_revenue
        )
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'year': self.year,
            'month': self.month,
            'commission_revenue': self.commission_revenue,
            'premium_revenue': self.premium_revenue,
            'driver_subscription_revenue': self.driver_subscription_revenue,
            'service_fees_revenue': self.service_fees_revenue,
            'delivery_revenue': self.delivery_revenue,
            'partnership_revenue': self.partnership_revenue,
            'other_revenue': self.other_revenue,
            'total_revenue': self.total_revenue,
            'rides_count': self.rides_count,
            'active_users': self.active_users,
            'active_drivers': self.active_drivers,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None,
        }
    
    def __repr__(self):
        return f'<Revenue {self.year}/{self.month:02d} - {self.total_revenue} XOF>'

