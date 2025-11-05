"""
Routes pour les points de repère locaux
"""
from flask import Blueprint, request, jsonify

landmarks_bp = Blueprint('landmarks', __name__)

# Points de repère de Dakar (peuvent être dans une base de données plus tard)
LANDMARKS = [
    {
        'id': 1,
        'name': 'Aéroport Blaise Diagne',
        'name_wolof': 'Aéroport Blaise Diagne',
        'latitude': 14.6564,
        'longitude': -17.0730,
        'type': 'airport',
        'icon': '✈️',
    },
    {
        'id': 2,
        'name': 'Plage de Yoff',
        'name_wolof': 'Yoff',
        'latitude': 14.7694,
        'longitude': -17.4497,
        'type': 'beach',
        'icon': '🏖️',
    },
    {
        'id': 3,
        'name': 'Marché Sandaga',
        'name_wolof': 'Sandaga',
        'latitude': 14.6928,
        'longitude': -17.4467,
        'type': 'market',
        'icon': '🏪',
    },
    {
        'id': 4,
        'name': 'Monument de la Renaissance',
        'name_wolof': 'Monument de la Renaissance',
        'latitude': 14.7244,
        'longitude': -17.4956,
        'type': 'monument',
        'icon': '🗽',
    },
    {
        'id': 5,
        'name': 'Île de Gorée',
        'name_wolof': 'Gorée',
        'latitude': 14.6687,
        'longitude': -17.3989,
        'type': 'island',
        'icon': '🏝️',
    },
]


@landmarks_bp.route('/list', methods=['GET'])
def list_landmarks():
    """Lister les points de repère"""
    try:
        landmark_type = request.args.get('type')
        search = request.args.get('search')
        
        landmarks = LANDMARKS
        
        # Filtrer par type
        if landmark_type:
            landmarks = [l for l in landmarks if l['type'] == landmark_type]
        
        # Recherche
        if search:
            search_lower = search.lower()
            landmarks = [
                l for l in landmarks
                if search_lower in l['name'].lower() or search_lower in l['name_wolof'].lower()
            ]
        
        return jsonify({
            'landmarks': landmarks,
        }), 200
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@landmarks_bp.route('/types', methods=['GET'])
def get_landmark_types():
    """Obtenir les types de points de repère"""
    return jsonify({
        'types': [
            {'value': 'airport', 'label': 'Aéroport', 'icon': '✈️'},
            {'value': 'beach', 'label': 'Plage', 'icon': '🏖️'},
            {'value': 'market', 'label': 'Marché', 'icon': '🏪'},
            {'value': 'monument', 'label': 'Monument', 'icon': '🗽'},
            {'value': 'island', 'label': 'Île', 'icon': '🏝️'},
            {'value': 'hotel', 'label': 'Hôtel', 'icon': '🏨'},
            {'value': 'restaurant', 'label': 'Restaurant', 'icon': '🍽️'},
        ],
    }), 200

