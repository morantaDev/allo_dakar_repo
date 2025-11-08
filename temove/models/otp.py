"""
Modèle OTP (One-Time Password)
"""
from datetime import datetime
from extensions import db


class OTP(db.Model):
    """Modèle pour les codes OTP de vérification"""
    __tablename__ = "otps"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    code = db.Column(db.String(6), nullable=False)
    phone = db.Column(db.String(20), nullable=False) 
    expires_at = db.Column(db.DateTime, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    user = db.relationship("User", backref=db.backref("otps", lazy=True))

    def is_expired(self):
        return datetime.utcnow() > self.expires_at

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "code": self.code,
            "expires_at": self.expires_at.isoformat(),
            "created_at": self.created_at.isoformat()
        }
