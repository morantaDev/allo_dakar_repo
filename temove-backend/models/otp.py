"""
Modèle OTP (One-Time Password)
"""
from datetime import datetime
from extensions import db


class OTP(db.Model):
    """Modèle pour les codes OTP de vérification par téléphone"""
    __tablename__ = "otps"

    id = db.Column(db.Integer, primary_key=True)
    phone = db.Column(db.String(20), nullable=False, index=True)
    code = db.Column(db.String(6), nullable=False)
    method = db.Column(db.String(10), nullable=False, default='SMS')  # 'SMS' ou 'WHATSAPP'
    is_used = db.Column(db.Boolean, default=False, nullable=False)  # Empêcher la réutilisation
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=True)  # Optionnel (utilisateur existant)
    expires_at = db.Column(db.DateTime, nullable=False, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    verified_at = db.Column(db.DateTime, nullable=True)  # Timestamp de vérification

    user = db.relationship("User", backref=db.backref("otps", lazy=True))

    def is_expired(self):
        """Vérifier si le code OTP est expiré"""
        return datetime.utcnow() > self.expires_at

    def is_valid(self):
        """Vérifier si le code OTP est valide (non expiré et non utilisé)"""
        return not self.is_expired() and not self.is_used

    def mark_as_used(self):
        """Marquer le code OTP comme utilisé"""
        self.is_used = True
        self.verified_at = datetime.utcnow()

    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            "id": self.id,
            "phone": self.phone,
            "method": self.method,
            "is_used": self.is_used,
            "expires_at": self.expires_at.isoformat() if self.expires_at else None,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

    def __repr__(self):
        return f'<OTP {self.phone} - {self.code}>'
