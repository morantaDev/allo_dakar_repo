from datetime import datetime
from app import db, bcrypt


# -------------------------------
# 🧍 TABLE UTILISATEURS
# -------------------------------
class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    phone = db.Column(db.String(20), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    role = db.Column(db.String(20), nullable=False, default="client")  # 'client' ou 'driver'
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    # Relation avec les trajets
    rides = db.relationship("Ride", backref="client", lazy=True, foreign_keys="Ride.client_id")

    def set_password(self, password):
        self.password_hash = bcrypt.generate_password_hash(password).decode("utf-8")

    def check_password(self, password):
        return bcrypt.check_password_hash(self.password_hash, password)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "phone": self.phone,
            "role": self.role,
            "created_at": self.created_at.isoformat()
        }


# -------------------------------
# 🚖 TABLE CHAUFFEURS
# -------------------------------
class Driver(db.Model):
    __tablename__ = "drivers"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    car_model = db.Column(db.String(100), nullable=False)
    car_plate = db.Column(db.String(50), nullable=False)
    status = db.Column(db.String(20), default="offline")  # 'online' ou 'offline'
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    rating = db.Column(db.Float, default=5.0)

    user = db.relationship("User", backref=db.backref("driver_profile", uselist=False))
    rides = db.relationship("Ride", backref="driver", lazy=True, foreign_keys="Ride.driver_id")

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "car_model": self.car_model,
            "car_plate": self.car_plate,
            "status": self.status,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "rating": self.rating,
            "user": self.user.to_dict() if self.user else None
        }


# -------------------------------
# 🛺 TABLE TRAJETS
# -------------------------------
class Ride(db.Model):
    __tablename__ = "rides"

    id = db.Column(db.Integer, primary_key=True)
    client_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    driver_id = db.Column(db.Integer, db.ForeignKey("drivers.id"), nullable=True)
    pickup_location = db.Column(db.String(255), nullable=False)
    dropoff_location = db.Column(db.String(255), nullable=False)
    status = db.Column(db.String(20), default="pending")  # pending, accepted, in_progress, completed, cancelled
    price = db.Column(db.Float, nullable=True)
    distance_km = db.Column(db.Float, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, onupdate=datetime.utcnow)

    payment = db.relationship("Payment", backref="ride", uselist=False)

    def to_dict(self):
        return {
            "id": self.id,
            "client": self.client.to_dict() if self.client else None,
            "driver": self.driver.to_dict() if self.driver else None,
            "pickup_location": self.pickup_location,
            "dropoff_location": self.dropoff_location,
            "status": self.status,
            "price": self.price,
            "distance_km": self.distance_km,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }


# -------------------------------
# 💳 TABLE PAIEMENTS
# -------------------------------
class Payment(db.Model):
    __tablename__ = "payments"

    id = db.Column(db.Integer, primary_key=True)
    ride_id = db.Column(db.Integer, db.ForeignKey("rides.id"), nullable=False)
    amount = db.Column(db.Float, nullable=False)
    method = db.Column(db.String(20), nullable=False)  # cash, wallet, card
    status = db.Column(db.String(20), default="pending")  # pending, completed, failed
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "ride_id": self.ride_id,
            "amount": self.amount,
            "method": self.method,
            "status": self.status,
            "created_at": self.created_at.isoformat(),
        }
    


# -------------------------------
# 🔑 TABLE OTP
# -------------------------------
class OTP(db.Model):
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


class Location(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    latitude = db.Column(db.Float, nullable=False)
    longitude = db.Column(db.Float, nullable=False)
    address = db.Column(db.String(255), nullable=True)

    def __repr__(self):
        return f"<Location {self.address}>"
    

class Vehicle(db.Model):
    __tablename__ = 'vehicles'
    id = db.Column(db.Integer, primary_key=True)
    driver_id = db.Column(db.Integer, db.ForeignKey('drivers.id'), nullable=False)
    make = db.Column(db.String(100), nullable=False)      # marque (ex: Toyota)
    model = db.Column(db.String(100), nullable=False)     # modèle (ex: Corolla)
    plate_number = db.Column(db.String(50), nullable=False, unique=True)
    color = db.Column(db.String(50), nullable=True)

    driver = db.relationship('Driver', backref=db.backref('vehicles', lazy=True))

    def __repr__(self):
        return f"<Vehicle {self.plate_number}>"

