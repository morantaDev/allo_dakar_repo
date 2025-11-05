"""
Service pour vérifier la disponibilité des chauffeurs
Prend en compte les réservations à l'avance
"""
from datetime import datetime, timedelta
from extensions import db
from models.driver import Driver, DriverStatus
from models.ride import Ride, RideStatus


class DriverAvailabilityService:
    """Service pour gérer la disponibilité des chauffeurs"""
    
    @staticmethod
    def is_driver_available(driver_id, requested_time, estimated_duration_minutes=30):
        """
        Vérifier si un chauffeur est disponible à une heure donnée
        
        Args:
            driver_id: ID du chauffeur
            requested_time: DateTime de la réservation demandée
            estimated_duration_minutes: Durée estimée de la course (défaut: 30 min)
        
        Returns:
            tuple: (is_available: bool, reason: str)
        """
        driver = Driver.query.get(driver_id)
        if not driver:
            return False, "Chauffeur introuvable"
        
        # Vérifier que le chauffeur est en ligne
        # Gérer à la fois DriverStatus enum et string
        driver_status = driver.status
        if hasattr(driver_status, 'value'):
            driver_status = driver_status.value
        elif hasattr(driver_status, 'name'):
            driver_status = driver_status.name.lower()
        
        if driver_status != 'online':
            return False, "Chauffeur hors ligne"
        
        # Calculer la fenêtre de temps de la course
        ride_start = requested_time
        ride_end = requested_time + timedelta(minutes=estimated_duration_minutes)
        
        # Buffer de 15 minutes avant et après pour éviter les conflits
        buffer_minutes = 15
        check_start = ride_start - timedelta(minutes=buffer_minutes)
        check_end = ride_end + timedelta(minutes=buffer_minutes)
        
        # Vérifier les réservations programmées qui se chevauchent
        # Vérifier si le modèle utilise un enum ou string pour status
        has_scheduled_at = hasattr(Ride, 'scheduled_at')
        
        # Statuts qui indiquent qu'une course est active
        try:
            # Essayer avec enum (models/ride.py)
            active_statuses = [
                RideStatus.PENDING,
                RideStatus.CONFIRMED,
                RideStatus.DRIVER_ASSIGNED,
                RideStatus.DRIVER_ARRIVED,
                RideStatus.IN_PROGRESS,
            ]
            use_enum = True
        except:
            # Fallback vers strings (app/models.py)
            active_statuses = ['pending', 'confirmed', 'accepted', 'in_progress']
            use_enum = False
        
        # Récupérer toutes les courses programmées du chauffeur
        if has_scheduled_at:
            # Modèle avec scheduled_at (models/ride.py)
            if use_enum:
                scheduled_rides = Ride.query.filter(
                    Ride.driver_id == driver_id,
                    Ride.status.in_(active_statuses),
                    Ride.scheduled_at.isnot(None),
                ).all()
            else:
                # Si status est string mais scheduled_at existe
                scheduled_rides = Ride.query.filter(
                    Ride.driver_id == driver_id,
                    Ride.status.in_(active_statuses),
                    Ride.scheduled_at.isnot(None),
                ).all()
        else:
            # Modèle sans scheduled_at (app/models.py) - pas de réservations à l'avance
            scheduled_rides = []
        
        # Vérifier manuellement les chevauchements
        conflicting_rides = None
        for scheduled_ride in scheduled_rides:
            if hasattr(scheduled_ride, 'scheduled_at') and scheduled_ride.scheduled_at:
                scheduled_start = scheduled_ride.scheduled_at
                scheduled_duration = None
                if hasattr(scheduled_ride, 'duration_minutes'):
                    scheduled_duration = scheduled_ride.duration_minutes
                scheduled_duration = scheduled_duration if scheduled_duration else 30
                scheduled_end = scheduled_start + timedelta(minutes=scheduled_duration)
                
                # Vérifier si les fenêtres de temps se chevauchent
                if (scheduled_start < check_end and scheduled_end > check_start):
                    conflicting_rides = scheduled_ride
                    break
        
        if conflicting_rides:
            return False, f"Chauffeur déjà réservé à {conflicting_rides.scheduled_at.strftime('%H:%M')}"
        
        # Vérifier aussi les courses en cours (sans scheduled_at)
        # Si une course est en cours et pourrait se terminer après le début de la nouvelle réservation
        current_time = datetime.utcnow()
        if requested_time < current_time + timedelta(minutes=30):
            # Vérifier les courses en cours
            # Gérer les deux modèles (avec et sans scheduled_at)
            if has_scheduled_at:
                active_rides = Ride.query.filter(
                    Ride.driver_id == driver_id,
                    Ride.status.in_([
                        RideStatus.DRIVER_ASSIGNED,
                        RideStatus.DRIVER_ARRIVED,
                        RideStatus.IN_PROGRESS,
                    ]),
                    Ride.scheduled_at.is_(None),  # Courses immédiates
                ).first()
            else:
                # Modèle simple : vérifier juste les statuts actifs
                active_statuses_simple = ['accepted', 'in_progress']
                active_rides = Ride.query.filter(
                    Ride.driver_id == driver_id,
                    Ride.status.in_(active_statuses_simple),
                ).first()
            
            if active_rides:
                return False, "Chauffeur actuellement en course"
        
        return True, "Disponible"
    
    @staticmethod
    def get_available_drivers(requested_time=None, estimated_duration_minutes=30):
        """
        Obtenir la liste des chauffeurs disponibles
        
        Args:
            requested_time: DateTime de la réservation (None pour immédiat)
            estimated_duration_minutes: Durée estimée
        
        Returns:
            list: Liste des IDs de chauffeurs disponibles
        """
        if requested_time is None:
            requested_time = datetime.utcnow()
        
        # Chauffeurs en ligne
        # Gérer à la fois enum et string
        try:
            online_drivers = Driver.query.filter_by(status=DriverStatus.ONLINE).all()
        except:
            # Fallback si status est string
            online_drivers = Driver.query.filter(Driver.status == 'online').all()
        
        available_driver_ids = []
        
        for driver in online_drivers:
            is_available, _ = DriverAvailabilityService.is_driver_available(
                driver.id,
                requested_time,
                estimated_duration_minutes
            )
            if is_available:
                available_driver_ids.append(driver.id)
        
        return available_driver_ids

