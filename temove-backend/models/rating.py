"""
Modèle Rating (Évaluation)
"""
from datetime import datetime
from extensions import db


class Rating(db.Model):
    """Modèle d'évaluation"""
    __tablename__ = 'ratings'
    
    id = db.Column(db.Integer, primary_key=True)
    ride_id = db.Column(db.Integer, db.ForeignKey('rides.id'), nullable=False, unique=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False, index=True)
    
    rating = db.Column(db.Integer, nullable=False)  # 1-5
    comment = db.Column(db.Text, nullable=True)
    audio_url = db.Column(db.String(500), nullable=True)  # URL de l'avis vocal
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    
    def update_driver_rating(self):
        """Mettre à jour la note moyenne du conducteur"""
        from models.driver import Driver
        
        driver = Driver.query.get(self.driver_id)
        if driver:
            # Calculer la nouvelle moyenne
            from sqlalchemy import func
            total_ratings = Rating.query.filter_by(driver_id=self.driver_id).count()
            total_score = db.session.query(func.sum(Rating.rating)).filter_by(driver_id=self.driver_id).scalar() or 0
            
            driver.rating_count = total_ratings
            driver.rating_average = total_score / total_ratings if total_ratings > 0 else 0.0
            db.session.commit()
    
    def to_dict(self):
        """Convertir en dictionnaire"""
        return {
            'id': self.id,
            'ride_id': self.ride_id,
            'user_id': self.user_id,
            'driver_id': self.driver_id,
            'rating': self.rating,
            'comment': self.comment,
            'audio_url': self.audio_url,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }
    
    def __repr__(self):
        return f'<Rating {self.rating}/5 for Ride {self.ride_id}>'

