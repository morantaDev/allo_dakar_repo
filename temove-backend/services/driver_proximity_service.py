"""
Service pour calculer la proximité et l'ETA des chauffeurs disponibles
"""
from models.driver import Driver, DriverStatus
from services.geolocation_service import GeolocationService
from extensions import db
from flask import current_app


class DriverProximityService:
    """Service pour trouver les chauffeurs disponibles proches et calculer leur ETA"""
    
    def __init__(self):
        self.geo = GeolocationService()
    
    def get_available_drivers_with_eta(self, pickup_lat, pickup_lng, max_distance_km=10, max_drivers=10):
        """
        Obtenir les chauffeurs disponibles avec leur ETA vers le point de prise en charge
        
        Args:
            pickup_lat: Latitude du point de prise en charge
            pickup_lng: Longitude du point de prise en charge
            max_distance_km: Distance maximale en km pour inclure un chauffeur (défaut: 10 km)
            max_drivers: Nombre maximum de chauffeurs à retourner (défaut: 10)
        
        Returns:
            Liste de dictionnaires contenant les informations du chauffeur avec distance et ETA
            [
                {
                    'driver_id': 1,
                    'full_name': 'Nom du Chauffeur',
                    'car_make': 'Toyota',
                    'car_model': 'Corolla',
                    'car_color': 'Blanc',
                    'license_plate': 'ABC-123',
                    'rating_average': 4.5,
                    'distance_km': 2.5,
                    'eta_minutes': 8,
                    'current_location': {
                        'latitude': 14.7167,
                        'longitude': -17.4677
                    }
                },
                ...
            ]
        """
        try:
            # Récupérer les chauffeurs disponibles (ONLINE et actifs)
            # Seuls les chauffeurs avec statut ONLINE et is_active=True sont disponibles
            available_drivers = Driver.query.filter(
                Driver.status == DriverStatus.ONLINE,
                Driver.is_active == True,
                Driver.current_latitude.isnot(None),
                Driver.current_longitude.isnot(None)
            ).all()
            
            current_app.logger.info(f"[DRIVER_PROXIMITY] Trouvé {len(available_drivers)} chauffeurs ONLINE")
            
            # Calculer la distance et l'ETA pour chaque chauffeur
            drivers_with_eta = []
            
            for driver in available_drivers:
                try:
                    # Calculer la distance entre le chauffeur et le point de prise en charge
                    distance_km = self.geo.calculate_distance(
                        driver.current_latitude,
                        driver.current_longitude,
                        pickup_lat,
                        pickup_lng
                    )
                    
                    # Filtrer par distance maximale
                    if distance_km > max_distance_km:
                        continue
                    
                    # Calculer l'ETA (temps estimé d'arrivée)
                    eta_minutes = self.geo.calculate_duration(
                        driver.current_latitude,
                        driver.current_longitude,
                        pickup_lat,
                        pickup_lng
                    )
                    
                    # Ajouter les informations du chauffeur avec distance et ETA
                    driver_info = {
                        'driver_id': driver.id,
                        'user_id': driver.user_id,
                        'full_name': driver.full_name,
                        'phone': driver.phone,
                        'car_make': driver.car_make,
                        'car_model': driver.car_model,
                        'car_color': driver.car_color,
                        'license_plate': driver.license_plate,
                        'rating_average': float(driver.rating_average) if driver.rating_average else 0.0,
                        'rating_count': driver.rating_count,
                        'distance_km': round(distance_km, 2),
                        'eta_minutes': eta_minutes,
                        'current_location': {
                            'latitude': driver.current_latitude,
                            'longitude': driver.current_longitude,
                        }
                    }
                    
                    drivers_with_eta.append(driver_info)
                    
                except Exception as e:
                    current_app.logger.warning(f"[DRIVER_PROXIMITY] Erreur lors du calcul pour chauffeur {driver.id}: {e}")
                    continue
            
            # Trier par distance (du plus proche au plus loin)
            drivers_with_eta.sort(key=lambda x: x['distance_km'])
            
            # Limiter le nombre de résultats
            drivers_with_eta = drivers_with_eta[:max_drivers]
            
            current_app.logger.info(f"[DRIVER_PROXIMITY] {len(drivers_with_eta)} chauffeurs disponibles trouvés pour pickup ({pickup_lat}, {pickup_lng})")
            
            return drivers_with_eta
            
        except Exception as e:
            current_app.logger.error(f"[DRIVER_PROXIMITY] Erreur lors de la récupération des chauffeurs: {e}")
            import traceback
            current_app.logger.error(traceback.format_exc())
            return []
    
    def get_nearest_driver(self, pickup_lat, pickup_lng, max_distance_km=10):
        """
        Obtenir le chauffeur disponible le plus proche
        
        Args:
            pickup_lat: Latitude du point de prise en charge
            pickup_lng: Longitude du point de prise en charge
            max_distance_km: Distance maximale en km (défaut: 10 km)
        
        Returns:
            Dictionnaire avec les informations du chauffeur le plus proche, ou None si aucun disponible
        """
        drivers = self.get_available_drivers_with_eta(
            pickup_lat,
            pickup_lng,
            max_distance_km=max_distance_km,
            max_drivers=1
        )
        
        return drivers[0] if drivers else None

