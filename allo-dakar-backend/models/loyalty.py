"""
Modèle Loyalty (Fidélité)
"""
from datetime import datetime
from enum import Enum
from extensions import db


class BadgeType(Enum):
    """Types de badges"""
    FIRST_RIDE = 'firstRide'
    TEN_RIDES = 'tenRides'
    FIFTY_RIDES = 'fiftyRides'
    HUNDRED_RIDES = 'hundredRides'
    NIGHT_OWL = 'nightOwl'
    EARLY_BIRD = 'earlyBird'
    LOYAL_CUSTOMER = 'loyalCustomer'
    BIG_SPENDER = 'bigSpender'


class LoyaltyPoints(db.Model):
    """Points de fidélité utilisateur"""
    __tablename__ = 'loyalty_points'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True, index=True)
    
    points = db.Column(db.Integer, default=0, nullable=False)
    level = db.Column(db.Integer, default=1, nullable=False)
    
    # Statistiques
    total_rides = db.Column(db.Integer, default=0, nullable=False)
    total_spent = db.Column(db.Float, default=0.0, nullable=False)  # XOF
    
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relations
    badges = db.relationship('UserBadge', backref='loyalty', lazy=True, cascade='all, delete-orphan')
    
    def calculate_level(self):
        """Calculer le niveau basé sur les points"""
        if self.points < 100:
            return 1
        elif self.points < 300:
            return 2
        elif self.points < 600:
            return 3
        elif self.points < 1000:
            return 4
        else:
            return 5
    
    def get_level_name(self):
        """Nom du niveau"""
        level_names = {
            1: 'Membre',
            2: 'VIP Bronze',
            3: 'VIP Silver',
            4: 'VIP Gold',
            5: 'VIP Platinum'
        }
        return level_names.get(self.level, 'Membre')
    
    def get_points_to_next_level(self):
        """Points nécessaires pour le niveau suivant"""
        level_thresholds = {
            1: 100,
            2: 300,
            3: 600,
            4: 1000,
            5: float('inf')
        }
        next_threshold = level_thresholds.get(self.level + 1, float('inf'))
        return max(0, next_threshold - self.points)
    
    def add_points(self, points_earned):
        """Ajouter des points et mettre à jour le niveau"""
        self.points += points_earned
        new_level = self.calculate_level()
        if new_level > self.level:
            self.level = new_level
        db.session.commit()
        return self
    
    def add_ride(self, ride_price):
        """Ajouter une course et mettre à jour les statistiques"""
        self.total_rides += 1
        self.total_spent += ride_price
        # Calculer les points (1 point pour 100 XOF)
        points_earned = int(ride_price / 100)
        self.add_points(points_earned)
        return self
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'points': self.points,
            'level': self.level,
            'level_name': self.get_level_name(),
            'points_to_next_level': self.get_points_to_next_level(),
            'total_rides': self.total_rides,
            'total_spent': self.total_spent,
            'badges': [badge.to_dict() for badge in self.badges],
        }


class UserBadge(db.Model):
    """Badge utilisateur"""
    __tablename__ = 'user_badges'
    
    id = db.Column(db.Integer, primary_key=True)
    loyalty_id = db.Column(db.Integer, db.ForeignKey('loyalty_points.id'), nullable=False)
    
    badge_type = db.Column(db.Enum(BadgeType), nullable=False)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.String(255), nullable=False)
    icon = db.Column(db.String(10), nullable=False)  # Emoji
    
    earned_date = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    @staticmethod
    def get_badge_info(badge_type):
        """Informations du badge"""
        badges_info = {
            BadgeType.FIRST_RIDE: {
                'name': 'Première Course',
                'description': 'Vous avez effectué votre première course',
                'icon': '🎉'
            },
            BadgeType.TEN_RIDES: {
                'name': 'Débutant',
                'description': '10 courses effectuées',
                'icon': '⭐'
            },
            BadgeType.FIFTY_RIDES: {
                'name': 'Régulier',
                'description': '50 courses effectuées',
                'icon': '🏆'
            },
            BadgeType.HUNDRED_RIDES: {
                'name': 'Expert',
                'description': '100 courses effectuées',
                'icon': '👑'
            },
            BadgeType.NIGHT_OWL: {
                'name': 'Oiseau de Nuit',
                'description': 'Plus de 10 courses après 22h',
                'icon': '🦉'
            },
            BadgeType.EARLY_BIRD: {
                'name': 'Lève-tôt',
                'description': 'Plus de 10 courses avant 7h',
                'icon': '🌅'
            },
            BadgeType.LOYAL_CUSTOMER: {
                'name': 'Client Fidèle',
                'description': 'Utilisateur depuis plus de 6 mois',
                'icon': '💎'
            },
            BadgeType.BIG_SPENDER: {
                'name': 'Grand Voyageur',
                'description': 'Plus de 100,000 XOF dépensés',
                'icon': '💳'
            },
        }
        return badges_info.get(badge_type, {
            'name': 'Badge',
            'description': '',
            'icon': '🏅'
        })
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'type': self.badge_type.value if self.badge_type else None,
            'name': self.name,
            'description': self.description,
            'icon': self.icon,
            'earned_date': self.earned_date.isoformat() if self.earned_date else None,
        }

