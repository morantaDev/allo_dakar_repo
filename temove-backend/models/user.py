"""
Modèle User
"""
from datetime import datetime
from extensions import db
from flask_bcrypt import generate_password_hash, check_password_hash


class User(db.Model):
    """Modèle utilisateur"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    
    # Noms pour compatibilité frontend (name et full_name)
    name = db.Column(db.String(100), nullable=True)  # Pour compatibilité avec app/models.py
    full_name = db.Column(db.String(100), nullable=False)  # Nom principal
    
    phone = db.Column(db.String(20), unique=True, nullable=True)
    
    # Rôle pour compatibilité frontend
    role = db.Column(db.String(20), default='client', nullable=False)  # 'client' ou 'driver'
    
    # Statut
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    is_verified = db.Column(db.Boolean, default=False, nullable=False)
    is_admin = db.Column(db.Boolean, default=False, nullable=False)  # Administrateur
    
    # Crédits
    credit_balance = db.Column(db.Integer, default=0, nullable=False)  # XOF
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relations
    rides = db.relationship('Ride', backref='user', lazy=True, cascade='all, delete-orphan')
    referral_code = db.relationship('ReferralCode', backref='user', uselist=False, cascade='all, delete-orphan')
    loyalty = db.relationship('LoyaltyPoints', backref='user', uselist=False, cascade='all, delete-orphan')
    ratings_given = db.relationship('Rating', backref='user', lazy=True)
    
    def set_password(self, password):
        """Hasher le mot de passe"""
        from flask_bcrypt import generate_password_hash
        self.password_hash = generate_password_hash(password).decode('utf-8')
    
    def check_password(self, password):
        """Vérifier le mot de passe"""
        from flask_bcrypt import check_password_hash
        return check_password_hash(self.password_hash, password)
    
    def add_credit(self, amount, source='manual'):
        """Ajouter du crédit"""
        from models.payment import CreditTransaction
        
        self.credit_balance += amount
        transaction = CreditTransaction(
            user_id=self.id,
            amount=amount,
            source=source
        )
        db.session.add(transaction)
        db.session.commit()
        return self
    
    def use_credit(self, amount):
        """Utiliser du crédit"""
        if amount > self.credit_balance:
            raise ValueError('Crédit insuffisant')
        from models.payment import CreditTransaction
        
        self.credit_balance -= amount
        transaction = CreditTransaction(
            user_id=self.id,
            amount=-amount,
            source='ride_payment'
        )
        db.session.add(transaction)
        db.session.commit()
        return self
    
    def to_dict(self, include_sensitive=False):
        """Convertir en dictionnaire - Compatible avec frontend"""
        data = {
            'id': self.id,
            'email': self.email,
            # Support à la fois 'name' et 'full_name' pour compatibilité
            'name': self.name or self.full_name,  # Pour compatibilité avec app/models.py
            'full_name': self.full_name,  # Nom principal
            'phone': self.phone,
            'role': self.role,  # Pour compatibilité frontend
            'credit_balance': self.credit_balance,
            'is_active': self.is_active,
            'is_verified': self.is_verified,
            'is_admin': getattr(self, 'is_admin', False),  # Statut administrateur
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
        if include_sensitive:
            data['total_rides'] = len(self.rides)
        return data
    
    def __repr__(self):
        return f'<User {self.email}>'

