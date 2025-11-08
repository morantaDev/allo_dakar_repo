"""
Modèle PromoCode
"""
from datetime import datetime
from enum import Enum
from extensions import db


class PromoType(Enum):
    """Type de code promo"""
    PERCENTAGE = 'percentage'
    FIXED_AMOUNT = 'fixedAmount'


class PromoCode(db.Model):
    """Modèle de code promo"""
    __tablename__ = 'promo_codes'
    
    id = db.Column(db.Integer, primary_key=True)
    code = db.Column(db.String(50), unique=True, nullable=False, index=True)
    description = db.Column(db.String(255), nullable=False)
    
    promo_type = db.Column(db.Enum(PromoType), nullable=False)
    value = db.Column(db.Float, nullable=False)  # Pourcentage ou montant fixe
    
    # Limitations
    max_uses = db.Column(db.Integer, nullable=True)  # None = illimité
    current_uses = db.Column(db.Integer, default=0, nullable=False)
    max_uses_per_user = db.Column(db.Integer, default=1, nullable=False)
    
    # Dates
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    expiry_date = db.Column(db.DateTime, nullable=True)
    
    # Statut
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    
    # Relations
    rides = db.relationship('Ride', backref='promo_code', lazy=True)
    
    def is_valid(self):
        """Vérifier si le code est valide"""
        if not self.is_active:
            return False
        
        if self.expiry_date and datetime.utcnow() > self.expiry_date:
            return False
        
        if self.max_uses and self.current_uses >= self.max_uses:
            return False
        
        return True
    
    def calculate_discount(self, original_price):
        """Calculer la réduction"""
        if not self.is_valid():
            return 0
        
        if self.promo_type == PromoType.PERCENTAGE:
            return int(original_price * self.value / 100)
        else:  # FIXED_AMOUNT
            return int(min(self.value, original_price))
    
    def apply_discount(self, original_price):
        """Appliquer la réduction et retourner le prix final"""
        discount = self.calculate_discount(original_price)
        return max(0, original_price - discount)
    
    def increment_uses(self):
        """Incrémenter le nombre d'utilisations"""
        self.current_uses += 1
        db.session.commit()
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'code': self.code,
            'description': self.description,
            'type': self.promo_type.value if self.promo_type else None,
            'value': self.value,
            'max_uses': self.max_uses,
            'current_uses': self.current_uses,
            'expiry_date': self.expiry_date.isoformat() if self.expiry_date else None,
            'is_valid': self.is_valid(),
        }
    
    def __repr__(self):
        return f'<PromoCode {self.code}>'

