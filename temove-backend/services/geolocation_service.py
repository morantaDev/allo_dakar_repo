"""
Service de géolocalisation
"""
from geopy.distance import geodesic
from config import Config
import requests


class GeolocationService:
    """Service pour les calculs de géolocalisation"""
    
    def __init__(self):
        self.google_api_key = Config.GOOGLE_MAPS_API_KEY
    
    def calculate_distance(self, lat1, lng1, lat2, lng2):
        """Calculer la distance entre deux points (en km)"""
        point1 = (lat1, lng1)
        point2 = (lat2, lng2)
        return geodesic(point1, point2).kilometers
    
    def calculate_duration(self, lat1, lng1, lat2, lng2):
        """Calculer la durée estimée (en minutes)"""
        if self.google_api_key:
            return self._calculate_duration_google(lat1, lng1, lat2, lng2)
        else:
            # Estimation basique : 30 km/h moyenne
            distance_km = self.calculate_distance(lat1, lng1, lat2, lng2)
            return int((distance_km / 30) * 60)
    
    def _calculate_duration_google(self, lat1, lng1, lat2, lng2):
        """Calculer la durée avec Google Maps API"""
        if not self.google_api_key:
            return self.calculate_duration(lat1, lng1, lat2, lng2)
        
        try:
            url = 'https://maps.googleapis.com/maps/api/directions/json'
            params = {
                'origin': f'{lat1},{lng1}',
                'destination': f'{lat2},{lng2}',
                'key': self.google_api_key,
                'language': 'fr',
            }
            response = requests.get(url, params=params, timeout=5)
            data = response.json()
            
            if data['status'] == 'OK' and data['routes']:
                duration_seconds = data['routes'][0]['legs'][0]['duration']['value']
                return int(duration_seconds / 60)
        except Exception:
            pass
        
        # Fallback si l'API échoue
        distance_km = self.calculate_distance(lat1, lng1, lat2, lng2)
        return int((distance_km / 30) * 60)
    
    def get_address(self, lat, lng):
        """Obtenir l'adresse à partir des coordonnées (reverse geocoding)"""
        if self.google_api_key:
            return self._get_address_google(lat, lng)
        return None
    
    def _get_address_google(self, lat, lng):
        """Obtenir l'adresse avec Google Geocoding API"""
        if not self.google_api_key:
            return None
        
        try:
            url = 'https://maps.googleapis.com/maps/api/geocode/json'
            params = {
                'latlng': f'{lat},{lng}',
                'key': self.google_api_key,
                'language': 'fr',
            }
            response = requests.get(url, params=params, timeout=5)
            data = response.json()
            
            if data['status'] == 'OK' and data['results']:
                return data['results'][0]['formatted_address']
        except Exception:
            pass
        
        return None

