"""
Modèle Driver (Conducteur)
"""
from datetime import datetime
from enum import Enum
from extensions import db


class DriverStatus(Enum):
    """Statut du conducteur"""
    OFFLINE = 'offline'
    ONLINE = 'online'
    IN_RIDE = 'in_ride'
    UNAVAILABLE = 'unavailable'


class Driver(db.Model):
    """Modèle conducteur"""
    __tablename__ = 'drivers'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True, unique=True, index=True)  # Optionnel pour compatibilité
    email = db.Column(db.String(120), unique=True, nullable=True, index=True)  # Nullable si lié à User
    password_hash = db.Column(db.String(255), nullable=True)  # Nullable si lié à User
    full_name = db.Column(db.String(100), nullable=False)
    phone = db.Column(db.String(20), unique=True, nullable=True)  # Nullable si lié à User
    
    # Informations véhicule
    car_make = db.Column(db.String(50), nullable=False)
    car_model = db.Column(db.String(50), nullable=False)
    car_color = db.Column(db.String(30), nullable=False)
    license_plate = db.Column(db.String(20), unique=True, nullable=False)
    
    # Localisation
    current_latitude = db.Column(db.Float, nullable=True)
    current_longitude = db.Column(db.Float, nullable=True)
    
    # Statut
    status = db.Column(db.Enum(DriverStatus), default=DriverStatus.OFFLINE, nullable=False)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    is_verified = db.Column(db.Boolean, default=False, nullable=False)
    
    # Statistiques
    total_rides = db.Column(db.Integer, default=0, nullable=False)
    rating_average = db.Column(db.Float, default=0.0, nullable=False)
    rating_count = db.Column(db.Integer, default=0, nullable=False)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relations
    user = db.relationship('User', backref=db.backref('driver', uselist=False), foreign_keys=[user_id])
    rides = db.relationship('Ride', backref='driver', lazy=True)
    ratings = db.relationship('Rating', backref='driver', lazy=True)
    
    def set_password(self, password):
        """Hasher le mot de passe"""
        from flask_bcrypt import generate_password_hash
        self.password_hash = generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        """Vérifier le mot de passe"""
        from flask_bcrypt import check_password_hash
        return check_password_hash(self.password_hash, password)
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'full_name': self.full_name,
            'phone': self.phone,
            'email': self.email,
            'car_make': self.car_make,
            'car_model': self.car_model,
            'car_color': self.car_color,
            'license_plate': self.license_plate,
            'current_location': {
                'latitude': self.current_latitude,
                'longitude': self.current_longitude,
            } if self.current_latitude else None,
            'status': self.status.value if self.status else None,
            'rating_average': self.rating_average,
            'rating_count': self.rating_count,
            'total_rides': self.total_rides,
        }
    
    def __repr__(self):
        return f'<Driver {self.full_name}>'

