"""
Routes pour l'upload de fichiers (audio, images, etc.)
"""
import os
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from datetime import datetime
import uuid

upload_bp = Blueprint('upload', __name__)

# Dossier pour stocker les fichiers uploadés
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'m4a', 'mp3', 'wav', 'aac', 'ogg'}


def allowed_file(filename):
    """Vérifier si le fichier a une extension autorisée"""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


@upload_bp.route('/audio', methods=['POST'])
@jwt_required()
def upload_audio():
    """Uploader un fichier audio (avis vocal)"""
    try:
        user_id = get_jwt_identity()
        
        # Vérifier qu'un fichier a été envoyé
        if 'audio' not in request.files:
            return jsonify({'error': 'Aucun fichier audio fourni'}), 400
        
        file = request.files['audio']
        
        # Vérifier que le fichier n'est pas vide
        if file.filename == '':
            return jsonify({'error': 'Fichier vide'}), 400
        
        # Vérifier l'extension
        if not allowed_file(file.filename):
            return jsonify({
                'error': f'Extension non autorisée. Extensions autorisées: {", ".join(ALLOWED_EXTENSIONS)}'
            }), 400
        
        # Créer le dossier uploads s'il n'existe pas
        upload_path = os.path.join(current_app.instance_path, UPLOAD_FOLDER, 'audio')
        os.makedirs(upload_path, exist_ok=True)
        
        # Générer un nom de fichier unique
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        unique_id = str(uuid.uuid4())[:8]
        extension = file.filename.rsplit('.', 1)[1].lower()
        filename = f'rating_{user_id}_{timestamp}_{unique_id}.{extension}'
        filename = secure_filename(filename)
        
        # Sauvegarder le fichier
        file_path = os.path.join(upload_path, filename)
        file.save(file_path)
        
        # Générer l'URL du fichier (relatif au serveur)
        # En production, cela devrait être une URL complète (ex: https://api.example.com/uploads/audio/...)
        audio_url = f'/uploads/audio/{filename}'
        
        # Pour le développement local, utiliser l'URL complète
        base_url = request.host_url.rstrip('/')
        full_audio_url = f'{base_url}uploads/audio/{filename}'
        
        return jsonify({
            'message': 'Fichier audio uploadé avec succès',
            'audio_url': full_audio_url,
            'filename': filename,
        }), 200
    
    except Exception as e:
        current_app.logger.error(f'Erreur upload audio: {str(e)}')
        return jsonify({'error': f'Erreur lors de l\'upload: {str(e)}'}), 500



