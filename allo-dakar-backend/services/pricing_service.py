"""
Service de calcul de prix
"""
from datetime import datetime
from config import Config


class PricingService:
    """Service pour calculer les prix des courses"""
    
    def __init__(self):
        self.pricing = Config.PRICING
    
    def calculate_base_price(self, distance_km, ride_mode):
        """Calculer le prix de base"""
        price_per_km = self.pricing.get(ride_mode, self.pricing['confort'])
        base_fare = self.pricing['base_fare']
        return (distance_km * price_per_km) + base_fare
    
    def calculate_surge_multiplier(self, timestamp=None):
        """Calculer le multiplicateur de prix (surge pricing)"""
        time = timestamp or datetime.utcnow()
        hour = time.hour
        day_of_week = time.weekday()  # 0 = lundi, 6 = dimanche
        
        # Heures de pointe (7-9h et 17-19h)
        if (hour >= 7 and hour < 9) or (hour >= 17 and hour < 19):
            return 1.5  # +50%
        
        # Vendredi soir et week-end
        if day_of_week == 4 and hour >= 18:  # Vendredi soir
            return 1.4  # +40%
        if day_of_week >= 5:  # Samedi/Dimanche
            return 1.3  # +30%
        
        # Nuit (22h - 6h)
        if hour >= 22 or hour < 6:
            return 1.2  # +20%
        
        # Prix normal
        return 1.0
    
    def calculate_final_price(self, distance_km, ride_mode, timestamp=None):
        """Calculer le prix final"""
        base_price = self.calculate_base_price(distance_km, ride_mode)
        surge_multiplier = self.calculate_surge_multiplier(timestamp)
        final_price = int(base_price * surge_multiplier)
        
        return {
            'base_price': int(base_price),
            'surge_multiplier': surge_multiplier,
            'final_price': final_price,
        }
    
    def estimate_trip(self, pickup_lat, pickup_lng, dropoff_lat, dropoff_lng, ride_mode='confort'):
        """Estimer un trajet complet"""
        from services.geolocation_service import GeolocationService
        
        geo = GeolocationService()
        
        # Calculer distance et durée (approximation)
        distance_km = geo.calculate_distance(
            pickup_lat, pickup_lng,
            dropoff_lat, dropoff_lng
        )
        
        # Estimation de durée (basée sur 30 km/h moyenne à Dakar)
        duration_minutes = int((distance_km / 30) * 60)
        
        # Calculer le prix
        timestamp = datetime.utcnow()
        pricing = self.calculate_final_price(distance_km, ride_mode, timestamp)
        
        return {
            'distance_km': round(distance_km, 2),
            'duration_minutes': duration_minutes,
            'base_price': pricing['base_price'],
            'surge_multiplier': pricing['surge_multiplier'],
            'final_price': pricing['final_price'],
            'formatted_distance': self._format_distance(distance_km),
            'formatted_duration': self._format_duration(duration_minutes),
        }
    
    @staticmethod
    def _format_distance(km):
        """Formatter la distance"""
        if km < 1:
            return f'{int(km * 1000)} m'
        return f'{km:.1f} km'
    
    @staticmethod
    def _format_duration(minutes):
        """Formatter la durée"""
        if minutes < 60:
            return f'{minutes} min'
        hours = minutes // 60
        mins = minutes % 60
        if mins == 0:
            return f'{hours} h'
        return f'{hours} h {mins}'

