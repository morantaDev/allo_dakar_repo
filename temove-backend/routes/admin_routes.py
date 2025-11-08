"""
Routes pour l'administration
"""
from flask import Blueprint, request, jsonify, make_response, send_file, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from models.user import User
from models.ride import Ride, RideStatus
from models.driver import Driver, DriverStatus
from models.commission import Commission, Revenue
from models.payment import Payment
from extensions import db
from datetime import datetime, timedelta
from sqlalchemy import func, extract, or_
import os

admin_bp = Blueprint('admin', __name__)


# IMPORTANT: Ne pas gérer les requêtes OPTIONS ici car Flask-CORS le fait déjà
# au niveau global dans app.py. Gérer OPTIONS ici causerait des doublons de headers.
# Flask-CORS avec automatic_options=True gère automatiquement toutes les requêtes OPTIONS.


def _check_admin_access(user_id):
    """Vérifier que l'utilisateur est admin"""
    user = User.query.get(user_id)
    if not user or not getattr(user, 'is_admin', False):
        return None, jsonify({'error': 'Accès non autorisé'}), 403
    return user, None, None


@admin_bp.route('/dashboard/stats', methods=['GET'])
@jwt_required()
def get_dashboard_stats():
    """
    Obtenir les statistiques globales du dashboard admin
    
    Retourne :
    - Revenus (mois actuel, mois précédent, croissance, commissions)
    - Courses (aujourd'hui, mois actuel, mois précédent, croissance)
    - Utilisateurs (total, actifs 30j)
    - Conducteurs (actifs)
    - Trajets en cours
    """
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    # Période : aujourd'hui et ce mois
    today = datetime.now().date()
    start_of_month = datetime(today.year, today.month, 1)
    last_month = start_of_month - timedelta(days=1)
    start_of_last_month = datetime(last_month.year, last_month.month, 1)
    
    # Revenus du mois actuel (peut ne pas exister encore)
    current_month_revenue = None
    last_month_revenue = None
    
    try:
        current_month_revenue = Revenue.query.filter_by(
            year=today.year,
            month=today.month
        ).first()
        
        # Revenus du mois précédent
        last_month_revenue = Revenue.query.filter_by(
            year=last_month.year,
            month=last_month.month
        ).first()
    except Exception as e:
        # Si la table n'existe pas encore, continuer avec des valeurs par défaut
        print(f"⚠️ Table revenues pas encore créée: {e}")
        current_month_revenue = None
        last_month_revenue = None
    
    # Courses d'aujourd'hui (utiliser requested_at si disponible, sinon created_at)
    # Le modèle Ride utilise requested_at pour la date de création
    try:
        today_rides = Ride.query.filter(
            func.date(Ride.requested_at) == today
        ).count()
    except:
        # Fallback si requested_at n'existe pas
        today_rides = Ride.query.count()
    
    # Courses du mois (utiliser requested_at si disponible)
    try:
        month_rides = Ride.query.filter(
            Ride.requested_at >= start_of_month
        ).count()
    except:
        month_rides = Ride.query.count()
    
    # Courses du mois précédent
    try:
        last_month_rides = Ride.query.filter(
            Ride.requested_at >= start_of_last_month,
            Ride.requested_at < start_of_month
        ).count()
    except:
        last_month_rides = 0
    
    # Utilisateurs actifs (30 derniers jours)
    try:
        active_users_30d = User.query.filter(
            User.created_at >= datetime.now() - timedelta(days=30),
            User.is_active == True
        ).count()
    except:
        active_users_30d = User.query.filter(User.is_active == True).count()
    
    # Total utilisateurs
    total_users = User.query.filter(User.is_active == True).count()
    
    # Conducteurs actifs
    try:
        active_drivers = Driver.query.filter(Driver.is_active == True).count()
    except:
        active_drivers = Driver.query.count()
    
    # Trajets en cours (status: PENDING, DRIVER_ASSIGNED, ACCEPTED, IN_PROGRESS)
    # Gérer à la fois les Enum et les strings
    try:
        # Essayer avec Enum
        rides_in_progress = Ride.query.filter(
            Ride.status.in_([
                RideStatus.PENDING,
                RideStatus.DRIVER_ASSIGNED,
                RideStatus.ACCEPTED,
                RideStatus.IN_PROGRESS
            ])
        ).count()
    except:
        # Fallback avec strings
        rides_in_progress = Ride.query.filter(
            or_(
                Ride.status == 'pending',
                Ride.status == 'driver_assigned',
                Ride.status == 'accepted',
                Ride.status == 'in_progress'
            )
        ).count()
    
    # Trajets complétés aujourd'hui
    try:
        completed_rides_today = Ride.query.filter(
            func.date(Ride.requested_at) == today,
            Ride.status == RideStatus.COMPLETED
        ).count()
    except:
        try:
            completed_rides_today = Ride.query.filter(
                Ride.status == 'completed'
            ).count()
        except:
            completed_rides_today = 0
    
    # Commissions du mois (peut ne pas exister encore)
    total_commissions = 0
    try:
        monthly_commissions = Commission.query.filter(
            Commission.created_at >= start_of_month,
            Commission.status == 'paid'
        ).all()
        total_commissions = sum(c.platform_commission for c in monthly_commissions)
    except Exception as e:
        # Si la table n'existe pas encore
        print(f"⚠️ Table commissions pas encore créée: {e}")
        total_commissions = 0
    
    # Calculer les revenus depuis les paiements si Revenue n'existe pas
    if not current_month_revenue:
        try:
            payments = Payment.query.filter(
                Payment.created_at >= start_of_month,
                Payment.status == 'completed'
            ).all()
            current_month_total = sum(p.amount for p in payments if p.amount)
        except:
            current_month_total = 0
    else:
        current_month_total = current_month_revenue.total_revenue
    
    if not last_month_revenue:
        try:
            last_payments = Payment.query.filter(
                Payment.created_at >= start_of_last_month,
                Payment.created_at < start_of_month,
                Payment.status == 'completed'
            ).all()
            last_month_total = sum(p.amount for p in last_payments if p.amount)
        except:
            last_month_total = 0
    else:
        last_month_total = last_month_revenue.total_revenue
    
    # Calcul de croissance
    revenue_growth = 0
    if last_month_total > 0:
        revenue_growth = ((current_month_total - last_month_total) / last_month_total) * 100
    
    rides_growth = 0
    if last_month_rides > 0:
        rides_growth = ((month_rides - last_month_rides) / last_month_rides) * 100
    
    return jsonify({
        'revenue': {
            'current_month': current_month_total,
            'last_month': last_month_total,
            'growth': round(revenue_growth, 2),
            'commissions': total_commissions,
        },
        'rides': {
            'today': today_rides,
            'completed_today': completed_rides_today,
            'in_progress': rides_in_progress,
            'current_month': month_rides,
            'last_month': last_month_rides,
            'growth': round(rides_growth, 2),
        },
        'users': {
            'total': total_users,
            'active_30d': active_users_30d,
        },
        'drivers': {
            'active': active_drivers,
        },
        'period': {
            'year': today.year,
            'month': today.month,
            'day': today.day,
        },
        'timestamp': datetime.utcnow().isoformat()
    }), 200


@admin_bp.route('/dashboard/charts/rides', methods=['GET'])
@jwt_required()
def get_rides_chart_data():
    """Obtenir les données de graphique pour les courses (par jour sur 7 jours)"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    # Récupérer les courses des 7 derniers jours
    days = []
    for i in range(6, -1, -1):
        day = datetime.now().date() - timedelta(days=i)
        try:
            count = Ride.query.filter(func.date(Ride.requested_at) == day).count()
        except:
            count = 0
        days.append({
            'date': day.isoformat(),
            'label': day.strftime('%a'),
            'count': count
        })
    
    return jsonify({
        'data': days,
        'period': '7_days'
    }), 200


@admin_bp.route('/dashboard/charts/revenue', methods=['GET'])
@jwt_required()
def get_revenue_chart_data():
    """Obtenir les données de graphique pour les revenus (par jour sur 7 jours)"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    # Récupérer les revenus des 7 derniers jours depuis les paiements
    days = []
    for i in range(6, -1, -1):
        day = datetime.now().date() - timedelta(days=i)
        try:
            payments = Payment.query.filter(
                func.date(Payment.created_at) == day,
                Payment.status == 'completed'
            ).all()
            total = sum(p.amount for p in payments if p.amount)
        except:
            total = 0
        days.append({
            'date': day.isoformat(),
            'label': day.strftime('%a'),
            'amount': total
        })
    
    return jsonify({
        'data': days,
        'period': '7_days'
    }), 200


@admin_bp.route('/revenue/monthly', methods=['GET'])
@jwt_required()
def get_monthly_revenue():
    """Obtenir les revenus mensuels"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    year = request.args.get('year', datetime.now().year, type=int)
    month = request.args.get('month', datetime.now().month, type=int)
    
    try:
        revenue = Revenue.query.filter_by(year=year, month=month).first()
        
        if not revenue:
            # Calculer depuis les paiements si Revenue n'existe pas
            start_date = datetime(year, month, 1)
            if month == 12:
                end_date = datetime(year + 1, 1, 1)
            else:
                end_date = datetime(year, month + 1, 1)
            
            payments = Payment.query.filter(
                Payment.created_at >= start_date,
                Payment.created_at < end_date,
                Payment.status == 'completed'
            ).all()
            
            total = sum(p.amount for p in payments if p.amount)
            
            return jsonify({
                'year': year,
                'month': month,
                'total_revenue': total,
                'calculated_from_payments': True
            }), 200
        
        return jsonify(revenue.to_dict()), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@admin_bp.route('/users', methods=['GET'])
@jwt_required()
def list_users():
    """Liste des utilisateurs avec pagination et filtres"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    # Paramètres de pagination
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    search = request.args.get('search', '')
    status = request.args.get('status')  # active, inactive, all
    
    # Construction de la requête
    query = User.query
    
    # Filtre de recherche
    if search:
        query = query.filter(
            or_(
                User.email.ilike(f'%{search}%'),
                User.full_name.ilike(f'%{search}%'),
                User.phone.ilike(f'%{search}%')
            )
        )
    
    # Filtre de statut
    if status == 'active':
        query = query.filter(User.is_active == True)
    elif status == 'inactive':
        query = query.filter(User.is_active == False)
    
    # Pagination
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    users = pagination.items
    
    return jsonify({
        'users': [user.to_dict(include_sensitive=True) for user in users],
        'pagination': {
            'page': page,
            'per_page': per_page,
            'total': pagination.total,
            'pages': pagination.pages,
        }
    }), 200


@admin_bp.route('/users/<int:user_id>', methods=['GET'])
@jwt_required()
def get_user(user_id):
    """Obtenir les détails d'un utilisateur"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    target_user = User.query.get_or_404(user_id)
    
    # Récupérer les courses de l'utilisateur
    # Utiliser requested_at si disponible, sinon trier par id
    try:
        rides = Ride.query.filter_by(user_id=user_id).order_by(Ride.requested_at.desc()).limit(10).all()
    except:
        rides = Ride.query.filter_by(user_id=user_id).order_by(Ride.id.desc()).limit(10).all()
    
    return jsonify({
        'user': target_user.to_dict(include_sensitive=True),
        'recent_rides': [ride.to_dict() for ride in rides],
        'total_rides': Ride.query.filter_by(user_id=user_id).count(),
    }), 200


@admin_bp.route('/users/<int:user_id>/toggle-status', methods=['POST'])
@jwt_required()
def toggle_user_status(user_id):
    """Activer/Désactiver un utilisateur"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    target_user = User.query.get_or_404(user_id)
    target_user.is_active = not target_user.is_active
    db.session.commit()
    
    return jsonify({
        'message': f'Utilisateur {"activé" if target_user.is_active else "désactivé"} avec succès',
        'user': target_user.to_dict()
    }), 200


@admin_bp.route('/drivers', methods=['GET'])
@jwt_required()
def list_drivers():
    """Liste des conducteurs"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    status = request.args.get('status')  # pending, active, inactive
    search = request.args.get('search', '')
    
    query = Driver.query
    
    # Filtre de recherche
    if search:
        query = query.filter(
            or_(
                Driver.full_name.ilike(f'%{search}%'),
                Driver.email.ilike(f'%{search}%'),
                Driver.phone.ilike(f'%{search}%'),
                Driver.license_plate.ilike(f'%{search}%')
            )
        )
    
    if status == 'pending':
        query = query.filter(Driver.is_verified == False)
    elif status == 'active':
        query = query.filter(Driver.is_active == True, Driver.is_verified == True)
    elif status == 'inactive':
        query = query.filter(Driver.is_active == False)
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    drivers = pagination.items
    
    return jsonify({
        'drivers': [driver.to_dict() for driver in drivers],
        'pagination': {
            'page': page,
            'per_page': per_page,
            'total': pagination.total,
            'pages': pagination.pages,
        }
    }), 200


@admin_bp.route('/drivers/<int:driver_id>', methods=['GET'])
@jwt_required()
def get_driver(driver_id):
    """Obtenir les détails d'un conducteur"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    driver = Driver.query.get_or_404(driver_id)
    
    # Récupérer les courses du conducteur
    try:
        rides = Ride.query.filter_by(driver_id=driver_id).order_by(Ride.requested_at.desc()).limit(10).all()
    except:
        rides = Ride.query.filter_by(driver_id=driver_id).order_by(Ride.id.desc()).limit(10).all()
    
    return jsonify({
        'driver': driver.to_dict(),
        'recent_rides': [ride.to_dict() for ride in rides],
        'total_rides': Ride.query.filter_by(driver_id=driver_id).count(),
    }), 200


@admin_bp.route('/drivers/<int:driver_id>/approve', methods=['POST'])
@jwt_required()
def approve_driver(driver_id):
    """Approuver un conducteur"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    driver = Driver.query.get_or_404(driver_id)
    driver.is_verified = True
    driver.is_active = True
    db.session.commit()
    
    return jsonify({
        'message': 'Conducteur approuvé avec succès',
        'driver': driver.to_dict()
    }), 200


@admin_bp.route('/drivers/<int:driver_id>/reject', methods=['POST'])
@jwt_required()
def reject_driver(driver_id):
    """Rejeter un conducteur"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    driver = Driver.query.get_or_404(driver_id)
    driver.is_verified = False
    driver.is_active = False
    db.session.commit()
    
    return jsonify({
        'message': 'Conducteur rejeté',
        'driver': driver.to_dict()
    }), 200


@admin_bp.route('/drivers/<int:driver_id>/toggle-status', methods=['POST'])
@jwt_required()
def toggle_driver_status(driver_id):
    """Activer/Désactiver un conducteur"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    driver = Driver.query.get_or_404(driver_id)
    driver.is_active = not driver.is_active
    db.session.commit()
    
    return jsonify({
        'message': f'Conducteur {"activé" if driver.is_active else "désactivé"} avec succès',
        'driver': driver.to_dict()
    }), 200


@admin_bp.route('/rides', methods=['GET'])
@jwt_required()
def list_rides():
    """Liste des courses"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    status = request.args.get('status')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    query = Ride.query
    
    # Gérer le statut (Enum ou string)
    if status:
        try:
            query = query.filter(Ride.status == RideStatus[status.upper()])
        except:
            # Fallback avec string
            query = query.filter(Ride.status == status.lower())
    
    # Gérer les dates (utiliser requested_at si disponible)
    if start_date:
        try:
            query = query.filter(Ride.requested_at >= datetime.fromisoformat(start_date))
        except:
            pass
    
    if end_date:
        try:
            query = query.filter(Ride.requested_at <= datetime.fromisoformat(end_date))
        except:
            pass
    
    # Trier par date (requested_at si disponible)
    try:
        query = query.order_by(Ride.requested_at.desc())
    except:
        query = query.order_by(Ride.id.desc())
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    rides = pagination.items
    
    return jsonify({
        'rides': [ride.to_dict() for ride in rides],
        'pagination': {
            'page': page,
            'per_page': per_page,
            'total': pagination.total,
            'pages': pagination.pages,
        }
    }), 200


@admin_bp.route('/rides/active', methods=['GET'])
@jwt_required()
def get_active_rides():
    """Obtenir les trajets en cours pour la carte en temps réel"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    try:
        # Récupérer les trajets en cours
        active_rides = Ride.query.filter(
            or_(
                Ride.status == 'pending',
                Ride.status == 'driver_assigned',
                Ride.status == 'accepted',
                Ride.status == 'in_progress'
            )
        ).all()
    except:
        try:
            active_rides = Ride.query.filter(
                Ride.status.in_([
                    RideStatus.PENDING,
                    RideStatus.DRIVER_ASSIGNED,
                    RideStatus.ACCEPTED,
                    RideStatus.IN_PROGRESS
                ])
            ).all()
        except:
            active_rides = []
    
    # Formater les données pour la carte
    rides_data = []
    for ride in active_rides:
        rides_data.append({
            'id': ride.id,
            'pickup': {
                'latitude': ride.pickup_latitude,
                'longitude': ride.pickup_longitude,
                'address': ride.pickup_address,
            },
            'dropoff': {
                'latitude': ride.dropoff_latitude,
                'longitude': ride.dropoff_longitude,
                'address': ride.dropoff_address,
            } if ride.dropoff_latitude else None,
            'status': ride.status.value if hasattr(ride.status, 'value') else str(ride.status),
            'driver_id': ride.driver_id,
        })
    
    return jsonify({
        'active_rides': rides_data,
        'count': len(rides_data)
    }), 200


@admin_bp.route('/drivers/active', methods=['GET'])
@jwt_required()
def get_active_drivers():
    """Obtenir les conducteurs actifs pour la carte en temps réel"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    try:
        # Récupérer les conducteurs en ligne
        active_drivers = Driver.query.filter(
            Driver.is_active == True,
            Driver.status == DriverStatus.ONLINE,
            Driver.current_latitude.isnot(None),
            Driver.current_longitude.isnot(None)
        ).all()
    except:
        try:
            active_drivers = Driver.query.filter(
                Driver.is_active == True,
                Driver.status == 'online',
                Driver.current_latitude.isnot(None),
                Driver.current_longitude.isnot(None)
            ).all()
        except:
            active_drivers = []
    
    # Formater les données pour la carte
    drivers_data = []
    for driver in active_drivers:
        drivers_data.append({
            'id': driver.id,
            'name': driver.full_name,
            'location': {
                'latitude': driver.current_latitude,
                'longitude': driver.current_longitude,
            },
            'car_make': driver.car_make,
            'car_model': driver.car_model,
            'license_plate': driver.license_plate,
        })
    
    return jsonify({
        'active_drivers': drivers_data,
        'count': len(drivers_data)
    }), 200


@admin_bp.route('/commissions', methods=['GET'])
@jwt_required()
def list_commissions():
    """Liste des commissions avec pagination et filtres"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    status = request.args.get('status')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    try:
        query = Commission.query
        
        if status and status != 'all':
            query = query.filter(Commission.status == status)
        
        if start_date:
            try:
                start = datetime.fromisoformat(start_date)
                query = query.filter(Commission.created_at >= start)
            except:
                pass
        
        if end_date:
            try:
                end = datetime.fromisoformat(end_date)
                query = query.filter(Commission.created_at <= end)
            except:
                pass
        
        query = query.order_by(Commission.created_at.desc())
        
        pagination = query.paginate(page=page, per_page=per_page, error_out=False)
        commissions = pagination.items
        
        # Calculer les totaux
        all_commissions = Commission.query.all() if status is None else query.all()
        total_commission = sum(c.platform_commission for c in all_commissions)
        total_paid = sum(c.platform_commission for c in all_commissions if c.status == 'paid')
        total_pending = sum(c.platform_commission for c in all_commissions if c.status == 'pending')
        
        # Enrichir les commissions avec les données du driver
        commissions_dict = []
        for c in commissions:
            comm_dict = c.to_dict()
            if c.driver:
                comm_dict['driver'] = c.driver.to_dict()
            if c.ride:
                comm_dict['ride_id'] = c.ride.id
            commissions_dict.append(comm_dict)
        
        return jsonify({
            'commissions': commissions_dict,
            'total_commission': total_commission,
            'total_paid': total_paid,
            'total_pending': total_pending,
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': pagination.total,
                'pages': pagination.pages,
            }
        }), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({
            'commissions': [],
            'total_commission': 0,
            'total_paid': 0,
            'total_pending': 0,
            'error': f'Erreur: {str(e)}',
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': 0,
                'pages': 0,
            }
        }), 200


@admin_bp.route('/commissions/<int:commission_id>/mark-paid', methods=['POST'])
@jwt_required()
def mark_commission_paid(commission_id):
    """Marquer une commission comme payée"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    try:
        commission = Commission.query.get_or_404(commission_id)
        commission.status = 'paid'
        commission.paid_at = datetime.utcnow()
        db.session.commit()
        
        comm_dict = commission.to_dict()
        if commission.driver:
            comm_dict['driver'] = commission.driver.to_dict()
        
        return jsonify({
            'message': 'Commission marquée comme payée',
            'commission': comm_dict
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'error': f'Erreur: {str(e)}'
        }), 500


@admin_bp.route('/payments', methods=['GET'])
@jwt_required()
def list_payments():
    """Liste des paiements"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    status = request.args.get('status')
    start_date = request.args.get('start_date')
    end_date = request.args.get('end_date')
    
    query = Payment.query
    
    if status:
        query = query.filter(Payment.status == status)
    
    if start_date:
        try:
            query = query.filter(Payment.created_at >= datetime.fromisoformat(start_date))
        except:
            pass
    
    if end_date:
        try:
            query = query.filter(Payment.created_at <= datetime.fromisoformat(end_date))
        except:
            pass
    
    query = query.order_by(Payment.created_at.desc())
    
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)
    payments = pagination.items
    
    return jsonify({
        'payments': [p.to_dict() if hasattr(p, 'to_dict') else {
            'id': p.id,
            'ride_id': p.ride_id,
            'user_id': p.user_id,
            'amount': p.amount,
            'method': p.method,
            'status': p.status,
            'created_at': p.created_at.isoformat() if p.created_at else None,
        } for p in payments],
        'pagination': {
            'page': page,
            'per_page': per_page,
            'total': pagination.total,
            'pages': pagination.pages,
        }
    }), 200


# ============================================
# Routes spécifiques TeMove (Application Client)
# ============================================

@admin_bp.route('/temove/stats', methods=['GET'])
@jwt_required()
def get_temove_stats():
    """Statistiques spécifiques à TeMove (Application Client)"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    today = datetime.now().date()
    start_of_month = datetime(today.year, today.month, 1)
    last_month = start_of_month - timedelta(days=1)
    start_of_last_month = datetime(last_month.year, last_month.month, 1)
    
    # Clients (Users)
    total_clients = User.query.filter(User.is_active == True).count()
    new_clients_this_month = User.query.filter(
        User.created_at >= start_of_month,
        User.is_active == True
    ).count()
    new_clients_last_month = User.query.filter(
        User.created_at >= start_of_last_month,
        User.created_at < start_of_month,
        User.is_active == True
    ).count()
    
    # Courses des clients (utiliser requested_at si disponible)
    try:
        today_rides = Ride.query.filter(func.date(Ride.requested_at) == today).count()
        month_rides = Ride.query.filter(Ride.requested_at >= start_of_month).count()
        last_month_rides = Ride.query.filter(
            Ride.requested_at >= start_of_last_month,
            Ride.requested_at < start_of_month
        ).count()
    except:
        today_rides = Ride.query.count()
        month_rides = Ride.query.count()
        last_month_rides = 0
    
    # Revenus (commissions sur les courses)
    try:
        month_commissions = Commission.query.filter(
            Commission.created_at >= start_of_month,
            Commission.status == 'paid'
        ).all()
        month_revenue = sum(c.platform_commission for c in month_commissions)
        
        last_month_commissions = Commission.query.filter(
            Commission.created_at >= start_of_last_month,
            Commission.created_at < start_of_month,
            Commission.status == 'paid'
        ).all()
        last_month_revenue = sum(c.platform_commission for c in last_month_commissions)
    except:
        # Calculer depuis les paiements si Commission n'existe pas
        try:
            month_payments = Payment.query.filter(
                Payment.created_at >= start_of_month,
                Payment.status == 'completed'
            ).all()
            month_revenue = sum(p.amount * 0.15 for p in month_payments if p.amount)  # 15% de commission
            
            last_month_payments = Payment.query.filter(
                Payment.created_at >= start_of_last_month,
                Payment.created_at < start_of_month,
                Payment.status == 'completed'
            ).all()
            last_month_revenue = sum(p.amount * 0.15 for p in last_month_payments if p.amount)
        except:
            month_revenue = 0
            last_month_revenue = 0
    
    # Calculs de croissance
    clients_growth = 0
    if new_clients_last_month > 0:
        clients_growth = ((new_clients_this_month - new_clients_last_month) / new_clients_last_month) * 100
    
    rides_growth = 0
    if last_month_rides > 0:
        rides_growth = ((month_rides - last_month_rides) / last_month_rides) * 100
    
    revenue_growth = 0
    if last_month_revenue > 0:
        revenue_growth = ((month_revenue - last_month_revenue) / last_month_revenue) * 100
    
    # Revenu par client (moyenne)
    avg_revenue_per_client = month_revenue / total_clients if total_clients > 0 else 0
    rides_per_client = month_rides / total_clients if total_clients > 0 else 0
    
    return jsonify({
        'application': 'TeMove',
        'period': {
            'year': today.year,
            'month': today.month,
        },
        'clients': {
            'total': total_clients,
            'new_this_month': new_clients_this_month,
            'new_last_month': new_clients_last_month,
            'growth': round(clients_growth, 2),
        },
        'rides': {
            'today': today_rides,
            'this_month': month_rides,
            'last_month': last_month_rides,
            'growth': round(rides_growth, 2),
            'per_client': round(rides_per_client, 2),
        },
        'revenue': {
            'this_month': month_revenue,
            'last_month': last_month_revenue,
            'growth': round(revenue_growth, 2),
            'per_client': round(avg_revenue_per_client, 2),
        },
    }), 200


@admin_bp.route('/temove/users', methods=['GET'])
@jwt_required()
def list_temove_users():
    """Liste des clients TeMove (alias pour /users)"""
    return list_users()


@admin_bp.route('/temove/rides', methods=['GET'])
@jwt_required()
def list_temove_rides():
    """Liste des courses TeMove (alias pour /rides)"""
    return list_rides()


# ============================================
# Routes spécifiques TeMove Pro (Application Conducteur)
# ============================================

@admin_bp.route('/temove-pro/stats', methods=['GET'])
@jwt_required()
def get_temove_pro_stats():
    """Statistiques spécifiques à TeMove Pro (Application Conducteur)"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    today = datetime.now().date()
    start_of_month = datetime(today.year, today.month, 1)
    last_month = start_of_month - timedelta(days=1)
    start_of_last_month = datetime(last_month.year, last_month.month, 1)
    
    # Conducteurs
    total_drivers = Driver.query.filter(Driver.is_active == True).count()
    new_drivers_this_month = Driver.query.filter(
        Driver.created_at >= start_of_month,
        Driver.is_active == True
    ).count()
    new_drivers_last_month = Driver.query.filter(
        Driver.created_at >= start_of_last_month,
        Driver.created_at < start_of_month,
        Driver.is_active == True
    ).count()
    
    # Conducteurs approuvés/en attente
    approved_drivers = Driver.query.filter(
        Driver.is_active == True,
        Driver.is_verified == True
    ).count()
    pending_drivers = Driver.query.filter(
        Driver.is_verified == False
    ).count()
    
    # Courses des conducteurs (utiliser requested_at si disponible)
    try:
        today_rides = Ride.query.filter(func.date(Ride.requested_at) == today).count()
        month_rides = Ride.query.filter(Ride.requested_at >= start_of_month).count()
        last_month_rides = Ride.query.filter(
            Ride.requested_at >= start_of_last_month,
            Ride.requested_at < start_of_month
        ).count()
    except:
        today_rides = Ride.query.count()
        month_rides = Ride.query.count()
        last_month_rides = 0
    
    # Commissions
    try:
        month_commissions = Commission.query.filter(
            Commission.created_at >= start_of_month,
            Commission.status == 'paid'
        ).all()
        total_commissions = sum(c.platform_commission for c in month_commissions)
        total_driver_earnings = sum(c.driver_earnings for c in month_commissions)
        
        last_month_commissions = Commission.query.filter(
            Commission.created_at >= start_of_last_month,
            Commission.created_at < start_of_month,
            Commission.status == 'paid'
        ).all()
        last_month_commissions_total = sum(c.platform_commission for c in last_month_commissions)
    except:
        total_commissions = 0
        total_driver_earnings = 0
        last_month_commissions_total = 0
    
    # Note moyenne des conducteurs
    try:
        avg_rating = db.session.query(func.avg(Driver.rating_average)).filter(
            Driver.is_active == True,
            Driver.rating_count > 0
        ).scalar() or 0.0
    except:
        avg_rating = 0.0
    
    # Calculs de croissance
    drivers_growth = 0
    if new_drivers_last_month > 0:
        drivers_growth = ((new_drivers_this_month - new_drivers_last_month) / new_drivers_last_month) * 100
    
    rides_growth = 0
    if last_month_rides > 0:
        rides_growth = ((month_rides - last_month_rides) / last_month_rides) * 100
    
    commissions_growth = 0
    if last_month_commissions_total > 0:
        commissions_growth = ((total_commissions - last_month_commissions_total) / last_month_commissions_total) * 100
    
    # Revenu par conducteur (moyenne)
    avg_commission_per_driver = total_commissions / total_drivers if total_drivers > 0 else 0
    avg_earnings_per_driver = total_driver_earnings / total_drivers if total_drivers > 0 else 0
    rides_per_driver = month_rides / total_drivers if total_drivers > 0 else 0
    
    return jsonify({
        'application': 'TeMove Pro',
        'period': {
            'year': today.year,
            'month': today.month,
        },
        'drivers': {
            'total': total_drivers,
            'approved': approved_drivers,
            'pending': pending_drivers,
            'new_this_month': new_drivers_this_month,
            'new_last_month': new_drivers_last_month,
            'growth': round(drivers_growth, 2),
            'avg_rating': round(avg_rating, 2),
        },
        'rides': {
            'today': today_rides,
            'this_month': month_rides,
            'last_month': last_month_rides,
            'growth': round(rides_growth, 2),
            'per_driver': round(rides_per_driver, 2),
        },
        'commissions': {
            'platform_this_month': total_commissions,
            'driver_earnings_this_month': total_driver_earnings,
            'platform_last_month': last_month_commissions_total,
            'growth': round(commissions_growth, 2),
            'avg_per_driver': round(avg_commission_per_driver, 2),
        },
        'earnings': {
            'avg_per_driver': round(avg_earnings_per_driver, 2),
        },
    }), 200


@admin_bp.route('/temove-pro/drivers', methods=['GET'])
@jwt_required()
def list_temove_pro_drivers():
    """Liste des conducteurs TeMove Pro (alias pour /drivers)"""
    return list_drivers()


@admin_bp.route('/temove-pro/rides', methods=['GET'])
@jwt_required()
def list_temove_pro_rides():
    """Liste des courses TeMove Pro (alias pour /rides)"""
    return list_rides()


@admin_bp.route('/temove-pro/commissions', methods=['GET'])
@jwt_required()
def list_temove_pro_commissions():
    """Liste des commissions TeMove Pro (alias pour /commissions)"""
    return list_commissions()


# ============================================
# Vue d'ensemble combinée
# ============================================

@admin_bp.route('/dashboard/overview', methods=['GET'])
@jwt_required()
def get_dashboard_overview():
    """Vue d'ensemble combinée des deux applications"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    # Statistiques globales
    today = datetime.now().date()
    total_users = User.query.filter(User.is_active == True).count()
    active_drivers = Driver.query.filter(Driver.is_active == True).count()
    total_rides = Ride.query.count()
    
    # Calculer les stats TeMove (logique simplifiée)
    start_of_month = datetime(today.year, today.month, 1)
    try:
        month_rides = Ride.query.filter(Ride.requested_at >= start_of_month).count()
    except:
        month_rides = Ride.query.count()
    
    # Calculer les stats TeMove Pro (logique simplifiée)
    try:
        month_commissions = Commission.query.filter(
            Commission.created_at >= start_of_month,
            Commission.status == 'paid'
        ).all()
        total_commissions = sum(c.platform_commission for c in month_commissions)
    except:
        total_commissions = 0
    
    return jsonify({
        'overview': {
            'total_users': total_users,
            'total_drivers': active_drivers,
            'total_rides': total_rides,
            'month_rides': month_rides,
            'month_commissions': total_commissions,
            'period': {
                'year': today.year,
                'month': today.month,
            },
        },
        'applications': {
            'temove': {
                'name': 'TeMove',
                'description': 'Application Client',
                'users': total_users,
                'endpoint': '/api/v1/admin/temove/stats',
            },
            'temove_pro': {
                'name': 'TeMove Pro',
                'description': 'Application Conducteur',
                'drivers': active_drivers,
                'endpoint': '/api/v1/admin/temove-pro/stats',
            },
        },
    }), 200


@admin_bp.route('/subscriptions', methods=['GET'])
@jwt_required()
def list_subscriptions():
    """Liste des abonnements avec pagination et filtres"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    type_filter = request.args.get('type')  # 'driver', 'user'
    status = request.args.get('status')  # 'active', 'expired', 'cancelled'
    
    try:
        # Pour l'instant, retourner une liste vide car la table subscriptions n'existe pas encore
        # TODO: Implémenter la logique une fois que la table subscriptions sera créée
        
        return jsonify({
            'subscriptions': [],
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': 0,
                'pages': 0,
            },
            'message': 'Module abonnements - À implémenter'
        }), 200
    except Exception as e:
        return jsonify({
            'subscriptions': [],
            'error': f'Erreur: {str(e)}',
            'pagination': {
                'page': page,
                'per_page': per_page,
                'total': 0,
                'pages': 0,
            }
        }), 200


@admin_bp.route('/reports/generate', methods=['POST'])
@jwt_required()
def generate_report():
    """Générer un rapport (Excel/PDF) et le retourner pour téléchargement"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    try:
        data = request.get_json()
        report_type = data.get('report_type', 'revenue')
        start_date_str = data.get('start_date')
        end_date_str = data.get('end_date')
        format_type = data.get('format', 'excel')  # 'excel', 'pdf'
        
        # Parser les dates
        try:
            start_date = datetime.fromisoformat(start_date_str) if start_date_str else datetime.now() - timedelta(days=30)
            end_date = datetime.fromisoformat(end_date_str) if end_date_str else datetime.now()
        except:
            start_date = datetime.now() - timedelta(days=30)
            end_date = datetime.now()
        
        # Récupérer les données selon le type de rapport
        report_data = []
        title = f"Rapport {report_type.title()}"
        
        if report_type == 'revenue':
            # Récupérer les revenus par jour
            try:
                rides = Ride.query.filter(
                    Ride.requested_at >= start_date,
                    Ride.requested_at <= end_date,
                    Ride.status == RideStatus.COMPLETED
                ).all()
                
                # Grouper par jour
                revenue_by_day = {}
                for ride in rides:
                    day = ride.requested_at.date() if ride.requested_at else datetime.now().date()
                    if day not in revenue_by_day:
                        revenue_by_day[day] = {'amount': 0, 'ride_count': 0}
                    revenue_by_day[day]['amount'] += ride.final_price or 0
                    revenue_by_day[day]['ride_count'] += 1
                
                report_data = [
                    {
                        'date': str(day),
                        'amount': info['amount'],
                        'ride_count': info['ride_count']
                    }
                    for day, info in sorted(revenue_by_day.items())
                ]
                title = "Rapport des Revenus"
            except Exception as e:
                current_app.logger.error(f"Erreur lors de la récupération des revenus: {e}")
                report_data = []
        
        elif report_type == 'rides':
            # Récupérer les courses
            try:
                rides = Ride.query.filter(
                    Ride.requested_at >= start_date,
                    Ride.requested_at <= end_date
                ).order_by(Ride.requested_at.desc()).limit(1000).all()
                
                report_data = [ride.to_dict() for ride in rides]
                title = "Rapport des Courses"
            except Exception as e:
                current_app.logger.error(f"Erreur lors de la récupération des courses: {e}")
                report_data = []
        
        elif report_type == 'drivers':
            # Récupérer les conducteurs
            try:
                drivers = Driver.query.filter(
                    Driver.created_at >= start_date,
                    Driver.created_at <= end_date
                ).limit(1000).all()
                
                report_data = [driver.to_dict() for driver in drivers]
                title = "Rapport des Conducteurs"
            except Exception as e:
                current_app.logger.error(f"Erreur lors de la récupération des conducteurs: {e}")
                report_data = []
        
        elif report_type == 'users':
            # Récupérer les utilisateurs
            try:
                users = User.query.filter(
                    User.created_at >= start_date,
                    User.created_at <= end_date
                ).limit(1000).all()
                
                report_data = [user.to_dict() for user in users]
                # Ajouter le nombre de courses par utilisateur
                for user_dict in report_data:
                    user_id = user_dict.get('id')
                    if user_id:
                        user_dict['total_rides'] = Ride.query.filter_by(user_id=user_id).count()
                
                title = "Rapport des Utilisateurs"
            except Exception as e:
                current_app.logger.error(f"Erreur lors de la récupération des utilisateurs: {e}")
                report_data = []
        
        elif report_type == 'commissions':
            # Récupérer les commissions
            try:
                commissions = Commission.query.filter(
                    Commission.created_at >= start_date,
                    Commission.created_at <= end_date
                ).order_by(Commission.created_at.desc()).limit(1000).all()
                
                report_data = []
                for comm in commissions:
                    comm_dict = comm.to_dict()
                    if comm.driver:
                        comm_dict['driver'] = comm.driver.to_dict()
                    report_data.append(comm_dict)
                
                title = "Rapport des Commissions"
            except Exception as e:
                current_app.logger.error(f"Erreur lors de la récupération des commissions: {e}")
                report_data = []
        
        elif report_type == 'payments':
            # Récupérer les paiements
            try:
                payments = Payment.query.filter(
                    Payment.created_at >= start_date,
                    Payment.created_at <= end_date
                ).order_by(Payment.created_at.desc()).limit(1000).all()
                
                report_data = []
                for payment in payments:
                    if hasattr(payment, 'to_dict'):
                        report_data.append(payment.to_dict())
                    else:
                        report_data.append({
                            'id': payment.id,
                            'ride_id': payment.ride_id,
                            'user_id': payment.user_id,
                            'amount': payment.amount,
                            'method': payment.method,
                            'status': payment.status,
                            'created_at': payment.created_at.isoformat() if payment.created_at else None,
                        })
                
                title = "Rapport des Paiements"
            except Exception as e:
                current_app.logger.error(f"Erreur lors de la récupération des paiements: {e}")
                report_data = []
        
        # Importer le service de génération de rapports
        try:
            from services.report_service import ReportService
            
            # Préparer les données selon le type
            if report_type == 'revenue':
                prepared_data = ReportService.prepare_revenue_data(report_data)
            elif report_type == 'rides':
                prepared_data = ReportService.prepare_rides_data(report_data)
            elif report_type == 'drivers':
                prepared_data = ReportService.prepare_drivers_data(report_data)
            elif report_type == 'users':
                prepared_data = ReportService.prepare_users_data(report_data)
            elif report_type == 'commissions':
                prepared_data = ReportService.prepare_commissions_data(report_data)
            elif report_type == 'payments':
                prepared_data = ReportService.prepare_payments_data(report_data)
            else:
                prepared_data = report_data
            
            # Générer le fichier
            if format_type == 'excel':
                filepath = ReportService.generate_excel_report(
                    report_type=report_type,
                    data=prepared_data,
                    start_date=start_date,
                    end_date=end_date
                )
                mimetype = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
            elif format_type == 'pdf':
                filepath = ReportService.generate_pdf_report(
                    report_type=report_type,
                    data=prepared_data,
                    start_date=start_date,
                    end_date=end_date,
                    title=title
                )
                mimetype = 'application/pdf'
            else:
                return jsonify({'error': 'Format non supporté. Utilisez "excel" ou "pdf"'}), 400
            
            # Retourner le fichier pour téléchargement
            filename = os.path.basename(filepath)
            return send_file(
                filepath,
                mimetype=mimetype,
                as_attachment=True,
                download_name=filename
            )
        
        except ImportError as e:
            # Si les bibliothèques ne sont pas disponibles, retourner une erreur
            missing_lib = 'pandas/openpyxl' if format_type == 'excel' else 'reportlab'
            return jsonify({
                'error': f'Bibliothèque {missing_lib} non installée. Installez-la avec: pip install {missing_lib}'
            }), 500
        except Exception as e:
            current_app.logger.error(f"Erreur lors de la génération du rapport: {e}")
            import traceback
            traceback.print_exc()
            return jsonify({
                'error': f'Erreur lors de la génération du rapport: {str(e)}'
            }), 500
    
    except Exception as e:
        current_app.logger.error(f"Erreur dans generate_report: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({
            'error': f'Erreur lors de la génération du rapport: {str(e)}'
        }), 500


@admin_bp.route('/settings', methods=['GET'])
@jwt_required()
def get_settings():
    """Obtenir les paramètres administratifs"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    try:
        # Pour l'instant, retourner des paramètres par défaut
        # TODO: Créer une table settings pour stocker les paramètres
        
        settings = {
            'commission_rate': 10.0,  # 10% par défaut
            'service_fee': 0,  # Frais de service fixes
            'min_ride_price': 500,  # Prix minimum d'une course (XOF)
            'max_ride_price': 50000,  # Prix maximum d'une course (XOF)
            'surge_commission_rate': 40.0,  # 40% sur la surcharge
        }
        
        return jsonify({
            'settings': settings
        }), 200
    except Exception as e:
        return jsonify({
            'error': f'Erreur: {str(e)}'
        }), 500


@admin_bp.route('/settings', methods=['PUT'])
@jwt_required()
def update_settings():
    """Mettre à jour les paramètres administratifs"""
    current_user_id = get_jwt_identity()
    user, error_response, status_code = _check_admin_access(current_user_id)
    if error_response:
        return error_response, status_code
    
    try:
        data = request.get_json()
        
        # Pour l'instant, valider et retourner les paramètres mis à jour
        # TODO: Sauvegarder dans une table settings
        
        settings = {
            'commission_rate': data.get('commission_rate', 10.0),
            'service_fee': data.get('service_fee', 0),
            'min_ride_price': data.get('min_ride_price', 500),
            'max_ride_price': data.get('max_ride_price', 50000),
        }
        
        # Valider les valeurs
        if settings['commission_rate'] < 0 or settings['commission_rate'] > 100:
            return jsonify({'error': 'Le taux de commission doit être entre 0 et 100%'}), 400
        
        if settings['min_ride_price'] < 0 or settings['max_ride_price'] < settings['min_ride_price']:
            return jsonify({'error': 'Les prix doivent être valides (min <= max)'}), 400
        
        # TODO: Sauvegarder dans la base de données
        
        return jsonify({
            'message': 'Paramètres mis à jour avec succès',
            'settings': settings
        }), 200
    except Exception as e:
        return jsonify({
            'error': f'Erreur lors de la mise à jour: {str(e)}'
        }), 500
