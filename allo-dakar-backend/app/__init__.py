from flask import Flask
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_socketio import SocketIO
from flask_bcrypt import Bcrypt
from dotenv import load_dotenv
import os

from flask_jwt_extended import JWTManager

db = SQLAlchemy()
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
    app.register_blueprint(auth_bp, url_prefix="/api/auth")
    app.register_blueprint(ride_bp, url_prefix="/api/rides")
    app.register_blueprint(driver_bp, url_prefix="/api/drivers")


    app.config["JWT_SECRET_KEY"] = os.getenv("JWT_SECRET_KEY", "jwt-secret")

    jwt = JWTManager()
    jwt.init_app(app)

    return app
