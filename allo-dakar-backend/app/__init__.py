from flask import Flask
from flask_cors import CORS
from flask_socketio import SocketIO
from flask_bcrypt import Bcrypt
from dotenv import load_dotenv
import os

from flask_jwt_extended import JWTManager

# Use the shared extensions module for the SQLAlchemy instance to avoid
# creating multiple `SQLAlchemy` objects (which causes the runtime error
# seen when calling `db.create_all()` from scripts that import the
# `extensions.db`).
from extensions import db
bcrypt = Bcrypt()
socketio = SocketIO(cors_allowed_origins="*")

def create_app():
    load_dotenv()
    app = Flask(__name__)
    CORS(app)
    app.config['SECRET_KEY'] = os.getenv("SECRET_KEY")
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv("DATABASE_URL")
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    db.init_app(app)
    bcrypt.init_app(app)
    socketio.init_app(app)

    from app.routes.auth_routes import auth_bp
    from app.routes.ride_routes import ride_bp
    from app.routes.driver_routes import driver_bp
    app.register_blueprint(auth_bp, url_prefix="/api/v1/auth")
    app.register_blueprint(ride_bp, url_prefix="/api/v1/rides")
    app.register_blueprint(driver_bp, url_prefix="/api/v1/drivers")


    app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "jwt-secret")

    jwt = JWTManager()
    jwt.init_app(app)

    return app
