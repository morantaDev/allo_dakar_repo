"""
ModÃ¨le Vehicle pour les vÃ©hicules des chauffeurs
"""
from extensions import db


class Vehicle(db.Model):
    """ModÃ¨le pour les vÃ©hicules des chauffeurs"""
    __tablename__ = 'vehicles'
    
    id = db.Column(db.Integer, primary_key=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False)
    make = db.Column(db.String(100), nullable=False)      # marque (ex: Toyota)
    model = db.Column(db.String(100), nullable=False)     # modÃ¨le (ex: Corolla)
    plate_number = db.Column(db.String(50), nullable=False, unique=True)
    color = db.Column(db.String(50), nullable=True)

    driver = db.relationship('Driver', backref=db.backref('vehicles', lazy=True))

    def __repr__(self):
        return f"<Vehicle {self.plate_number}>"
