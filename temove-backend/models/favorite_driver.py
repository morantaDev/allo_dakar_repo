"""
Modèle FavoriteDriver (Chauffeur Préféré)
"""
from datetime import datetime
from extensions import db


class FavoriteDriver(db.Model):
    """Modèle pour les chauffeurs préférés des utilisateurs"""
    __tablename__ = 'favorite_drivers'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False, index=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    # Contrainte unique pour éviter les doublons
    __table_args__ = (db.UniqueConstraint('user_id', 'driver_id', name='unique_user_driver'),)
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'driver_id': self.driver_id,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
    
    def __repr__(self):
        return f'<FavoriteDriver User {self.user_id} -> Driver {self.driver_id}>'

