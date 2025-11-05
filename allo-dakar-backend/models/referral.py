"""
Modèle Referral (Parrainage)
"""
from datetime import datetime
from extensions import db
import secrets
import string


class ReferralCode(db.Model):
    """Code de parrainage utilisateur"""
    __tablename__ = 'referral_codes'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, unique=True, index=True)
    
    code = db.Column(db.String(20), unique=True, nullable=False, index=True)
    
    # Statistiques
    uses = db.Column(db.Integer, default=0, nullable=False)
    max_uses = db.Column(db.Integer, default=10, nullable=False)
    
    credit_amount = db.Column(db.Integer, default=1000, nullable=False)  # XOF
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    # Relations
    rewards = db.relationship('ReferralReward', backref='referral_code', lazy=True)
    
    @staticmethod
    def generate_code(length=8):
        """Générer un code unique"""
        while True:
            code = ''.join(secrets.choice(string.ascii_uppercase + string.digits) for _ in range(length))
            if not ReferralCode.query.filter_by(code=code).first():
                return code
    
    def is_valid(self):
        """Vérifier si le code est valide"""
        return self.uses < self.max_uses
    
    def increment_uses(self):
        """Incrémenter les utilisations"""
        self.uses += 1
        db.session.commit()
    
    def get_share_message(self):
        """Message de partage"""
        return f'''Rejoignez Allo Dakar avec mon code de parrainage : {self.code}
Obtenez {self.credit_amount} XOF de crédit gratuit sur votre première course !

Téléchargez l'app et utilisez ce code lors de l'inscription.'''
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'code': self.code,
            'uses': self.uses,
            'max_uses': self.max_uses,
            'credit_amount': self.credit_amount,
            'is_valid': self.is_valid(),
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
    
    def __repr__(self):
        return f'<ReferralCode {self.code}>'


class ReferralReward(db.Model):
    """Récompense de parrainage"""
    __tablename__ = 'referral_rewards'
    
    id = db.Column(db.Integer, primary_key=True)
    referral_code_id = db.Column(db.Integer, db.ForeignKey('referral_codes.id'), nullable=False)
    
    referrer_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    referred_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    
    referrer_reward = db.Column(db.Integer, nullable=False)  # XOF
    referred_reward = db.Column(db.Integer, nullable=False)  # XOF
    
    both_ride_completed = db.Column(db.Boolean, default=False, nullable=False)
    
    rewarded_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'referrer_id': self.referrer_id,
            'referred_id': self.referred_id,
            'referrer_reward': self.referrer_reward,
            'referred_reward': self.referred_reward,
            'both_ride_completed': self.both_ride_completed,
            'rewarded_at': self.rewarded_at.isoformat() if self.rewarded_at else None,
        }

