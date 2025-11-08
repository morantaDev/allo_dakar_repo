"""
Modèle Ride (Course)
"""
from datetime import datetime
from enum import Enum
from extensions import db


class RideStatus(Enum):
    """Statuts de course"""
    PENDING = 'pending'
    CONFIRMED = 'confirmed'
    DRIVER_ASSIGNED = 'driver_assigned'
    DRIVER_ARRIVED = 'driver_arrived'
    IN_PROGRESS = 'in_progress'
    COMPLETED = 'completed'
    CANCELLED = 'cancelled'


class RideCategory(Enum):
    """Catégories de course"""
    COURSE = 'course'
    LIVRAISON = 'livraison'


class RideMode(Enum):
    """Modes de transport"""
    ECO = 'eco'
    CONFORT = 'confort'
    CONFORT_PLUS = 'confortPlus'
    PARTAGE_TAXI = 'partageTaxi'
    FAMILLE = 'famille'
    PREMIUM = 'premium'
    # Modes de livraison
    TIAK_TIAK = 'tiakTiak'
    VOITURE = 'voiture'
    EXPRESS = 'express'


class Ride(db.Model):
    """Modèle de course"""
    __tablename__ = 'rides'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=True, index=True)
    
    # Catégorie et mode
    category = db.Column(db.Enum(RideCategory), nullable=False, default=RideCategory.COURSE)
    ride_mode = db.Column(db.Enum(RideMode), nullable=False, default=RideMode.CONFORT)
    
    # Localisation
    pickup_latitude = db.Column(db.Float, nullable=False)
    pickup_longitude = db.Column(db.Float, nullable=False)
    pickup_address = db.Column(db.String(255), nullable=False)
    
    dropoff_latitude = db.Column(db.Float, nullable=True)
    dropoff_longitude = db.Column(db.Float, nullable=True)
    dropoff_address = db.Column(db.String(255), nullable=True)
    
    # Distance et durée (en km et minutes)
    distance_km = db.Column(db.Float, nullable=True)
    duration_minutes = db.Column(db.Integer, nullable=True)
    
    # Prix
    base_price = db.Column(db.Integer, nullable=False)  # XOF
    surge_multiplier = db.Column(db.Float, default=1.0, nullable=False)
    final_price = db.Column(db.Integer, nullable=False)  # XOF
    discount_amount = db.Column(db.Integer, default=0, nullable=False)  # XOF
    
    # Statut
    status = db.Column(db.Enum(RideStatus), default=RideStatus.PENDING, nullable=False, index=True)
    
    # Codes promo et paiement
    promo_code_id = db.Column(db.Integer, db.ForeignKey('promo_codes.id'), nullable=True)
    payment_method = db.Column(db.String(50), nullable=True)
    
    # Timestamps
    scheduled_at = db.Column(db.DateTime, nullable=True)  # Pour réservations programmées
    requested_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    confirmed_at = db.Column(db.DateTime, nullable=True)
    started_at = db.Column(db.DateTime, nullable=True)
    completed_at = db.Column(db.DateTime, nullable=True)
    cancelled_at = db.Column(db.DateTime, nullable=True)
    
    # Relations
    payment = db.relationship('Payment', backref='ride', uselist=False, cascade='all, delete-orphan')
    rating = db.relationship('Rating', backref='ride', uselist=False, cascade='all, delete-orphan')
    
    def calculate_price(self, base_price_per_km, distance_km, surge_multiplier=1.0):
        """Calculer le prix de la course"""
        base_price = (distance_km * base_price_per_km) + 500  # + frais de base
        final_price = int(base_price * surge_multiplier)
        
        self.base_price = int(base_price)
        self.surge_multiplier = surge_multiplier
        self.final_price = final_price
        return final_price
    
    def apply_discount(self, discount_amount):
        """Appliquer une réduction"""
        self.discount_amount = discount_amount
        self.final_price = max(0, self.final_price - discount_amount)
        return self.final_price
    
    def is_scheduled(self):
        """Vérifier si c'est une réservation programmée"""
        return self.scheduled_at is not None and self.scheduled_at > datetime.utcnow()
    
    def get_estimated_arrival(self):
        """
        Calculer le temps d'arrivée estimé du chauffeur
        
        Returns:
            dict: {
                'arrival_time': datetime or None,
                'arrival_in_minutes': int or None,
                'message': str,
                'is_scheduled': bool
            }
        """
        from datetime import timedelta
        
        now = datetime.utcnow()
        
        # Si c'est une réservation programmée
        if self.scheduled_at and self.scheduled_at > now:
            # Le chauffeur arrivera à l'heure programmée
            delta = self.scheduled_at - now
            minutes = int(delta.total_seconds() / 60)
            
            # Formater l'heure programmée
            scheduled_time = self.scheduled_at.strftime('%H:%M')
            scheduled_date = self.scheduled_at.strftime('%d/%m/%Y')
            today = now.strftime('%d/%m/%Y')
            
            # Si c'est aujourd'hui, afficher juste l'heure
            if scheduled_date == today:
                message = f"Réservation programmée pour {scheduled_time}"
            else:
                message = f"Réservation programmée pour le {scheduled_date} à {scheduled_time}"
            
            return {
                'arrival_time': self.scheduled_at.isoformat(),
                'arrival_in_minutes': minutes,
                'message': message,
                'is_scheduled': True,
                'scheduled_at': self.scheduled_at.isoformat(),
                'scheduled_time': scheduled_time,
                'scheduled_date': scheduled_date
            }
        
        # Si c'est une course immédiate avec chauffeur assigné
        if self.driver_id and self.status in [RideStatus.DRIVER_ASSIGNED, RideStatus.CONFIRMED]:
            # Estimation basique : 5 minutes par défaut
            # TODO: Améliorer avec calcul réel basé sur la position du chauffeur
            estimated_arrival = now + timedelta(minutes=5)
            return {
                'arrival_time': estimated_arrival.isoformat(),
                'arrival_in_minutes': 5,
                'message': "Le chauffeur sera là dans 5 min",
                'is_scheduled': False,
                'scheduled_at': None
            }
        
        # Pas encore de chauffeur assigné
        return {
            'arrival_time': None,
            'arrival_in_minutes': None,
            'message': "En attente d'un chauffeur",
            'is_scheduled': False,
            'scheduled_at': None
        }
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        arrival_info = self.get_estimated_arrival()
        
        return {
            'id': self.id,
            'user_id': self.user_id,
            'driver_id': self.driver_id,
            'category': self.category.value if self.category else None,
            'ride_mode': self.ride_mode.value if self.ride_mode else None,
            'pickup': {
                'latitude': self.pickup_latitude,
                'longitude': self.pickup_longitude,
                'address': self.pickup_address,
            },
            'dropoff': {
                'latitude': self.dropoff_latitude,
                'longitude': self.dropoff_longitude,
                'address': self.dropoff_address,
            } if self.dropoff_latitude else None,
            'distance_km': self.distance_km,
            'duration_minutes': self.duration_minutes,
            'base_price': self.base_price,
            'surge_multiplier': self.surge_multiplier,
            'discount_amount': self.discount_amount,
            'final_price': self.final_price,
            'status': self.status.value if self.status else None,
            'payment_method': self.payment_method,
            'scheduled_at': self.scheduled_at.isoformat() if self.scheduled_at else None,
            'is_scheduled': self.is_scheduled(),
            'requested_at': self.requested_at.isoformat() if self.requested_at else None,
            'confirmed_at': self.confirmed_at.isoformat() if self.confirmed_at else None,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'completed_at': self.completed_at.isoformat() if self.completed_at else None,
            'driver': self.driver.to_dict() if self.driver else None,
            # Informations sur le temps d'arrivée
            'estimated_arrival': arrival_info,
        }
    
    def __repr__(self):
        return f'<Ride {self.id} - {self.status.value if self.status else "unknown"}>'

