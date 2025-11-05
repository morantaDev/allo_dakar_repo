"""
Modèle Location pour suivre les positions des chauffeurs
"""
from extensions import db


class Location(db.Model):
    """Modèle pour stocker les positions GPS des chauffeurs"""
    __tablename__ = 'locations'
    
    id = db.Column(db.Integer, primary_key=True)
    ride_id = db.Column(db.Integer, db.ForeignKey('rides.id'), nullable=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False)
    lat = db.Column(db.Float, nullable=False)
    lng = db.Column(db.Float, nullable=False)
    address = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=db.func.now())

    def __repr__(self):
        return f"<Location {self.address}>"
