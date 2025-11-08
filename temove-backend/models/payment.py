"""
Modèle Payment (Paiement)
"""
from datetime import datetime
from enum import Enum
from extensions import db


class PaymentMethod(Enum):
    """Méthodes de paiement"""
    ORANGE_MONEY = 'om'
    WAVE = 'wave'
    FREE_MONEY = 'freeMoney'
    CARTE_BANCAIRE = 'carteBancaire'
    CASH = 'cash'
    CREDIT = 'credit'  # Crédit utilisateur


class PaymentStatus(Enum):
    """Statuts de paiement"""
    PENDING = 'pending'
    PROCESSING = 'processing'
    COMPLETED = 'completed'
    FAILED = 'failed'
    REFUNDED = 'refunded'


class Payment(db.Model):
    """Modèle de paiement"""
    __tablename__ = 'payments'
    
    id = db.Column(db.Integer, primary_key=True)
    ride_id = db.Column(db.Integer, db.ForeignKey('rides.id'), nullable=False, unique=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    amount = db.Column(db.Integer, nullable=False)  # XOF
    method = db.Column(db.Enum(PaymentMethod), nullable=False)
    status = db.Column(db.Enum(PaymentStatus), default=PaymentStatus.PENDING, nullable=False)
    
    # Références externes (pour intégrations)
    external_transaction_id = db.Column(db.String(255), nullable=True)
    
    # Timestamps
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    processed_at = db.Column(db.DateTime, nullable=True)
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'ride_id': self.ride_id,
            'user_id': self.user_id,
            'amount': self.amount,
            'method': self.method.value if self.method else None,
            'status': self.status.value if self.status else None,
            'external_transaction_id': self.external_transaction_id,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'processed_at': self.processed_at.isoformat() if self.processed_at else None,
        }
    
    def __repr__(self):
        return f'<Payment {self.id} - {self.status.value if self.status else "unknown"}>'


class CreditTransaction(db.Model):
    """Transactions de crédit utilisateur"""
    __tablename__ = 'credit_transactions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    amount = db.Column(db.Integer, nullable=False)  # Peut être négatif
    source = db.Column(db.String(100), nullable=False)  # referral, ride_payment, manual, etc.
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'amount': self.amount,
            'source': self.source,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }

