import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui show Path, Canvas, Paint, PaintingStyle, Size;
import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/map_placeholder.dart';
import 'package:temove/widgets/driver_car_marker.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/services/location_service.dart';
import 'package:temove/screens/ride_completion_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Écran de suivi de course en temps réel avec acceptation chauffeur
/// 
/// Affiche :
/// - Attente d'acceptation du chauffeur (pas d'assignation automatique)
/// - Position du chauffeur en temps réel sur la carte avec animation
/// - Voiture animée se déplaçant vers le client
/// - Temps d'arrivée estimé mis à jour dynamiquement
/// - Boutons de communication et d'annulation
class ActiveRideScreen extends StatefulWidget {
  final int rideId;
  final int? driverId;
  final String? driverName;
  final String? driverPhone;
  final String? driverCar;
  final String? driverAvatar;
  final Position? pickupPosition;
  final Position? destinationPosition;
  final String? pickupAddress;
  final String? destinationAddress;

  const ActiveRideScreen({
    super.key,
    required this.rideId,
    this.driverId,
    this.driverName,
    this.driverPhone,
    this.driverCar,
    this.driverAvatar,
    this.pickupPosition,
    this.destinationPosition,
    this.pickupAddress,
    this.destinationAddress,
  });

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen>
    with TickerProviderStateMixin {
  Timer? _positionUpdateTimer;
  String _rideStatus = 'pending'; // pending, driver_assigned, in_progress, completed
  Position? _driverPosition;
  double? _driverHeading; // Direction du chauffeur en degrés
  int _estimatedArrivalMinutes = 0;
  double _distanceToPickupKm = 0.0;
  bool _canCancel = true;
  bool _isLoading = true;

  // Animation pour l'attente
  late AnimationController _waitingAnimationController;
  late Animation<double> _waitingAnimation;

  // Position du client
  Position? _clientPosition;
  
  // Informations du chauffeur (mises à jour dynamiquement depuis l'API)
  int? _currentDriverId;
  String? _currentDriverName;
  String? _currentDriverPhone;
  String? _currentDriverCar;
  String? _currentDriverAvatar;
  double? _currentDriverRating;

  @override
  void initState() {
    super.initState();
    _rideStatus = widget.driverId != null ? 'driver_assigned' : 'pending';
    
    // Initialiser les informations du chauffeur depuis les paramètres du widget
    _currentDriverId = widget.driverId;
    _currentDriverName = widget.driverName;
    _currentDriverPhone = widget.driverPhone;
    _currentDriverCar = widget.driverCar;
    _currentDriverAvatar = widget.driverAvatar;
    
    // Animation d'attente
    _waitingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _waitingAnimation = CurvedAnimation(
      parent: _waitingAnimationController,
      curve: Curves.easeInOut,
    );
    
    if (_rideStatus == 'pending') {
      _waitingAnimationController.repeat(reverse: true);
    }
    
    _getClientPosition();
    _loadRideStatus();
    _startPositionUpdates();
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _waitingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _getClientPosition() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _clientPosition = position;
        });
      } else if (widget.pickupPosition != null) {
        setState(() {
          _clientPosition = widget.pickupPosition;
        });
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération de la position client: $e');
      if (widget.pickupPosition != null) {
        setState(() {
          _clientPosition = widget.pickupPosition;
        });
      }
    }
  }

  void _startPositionUpdates() {
    // Mettre à jour la position du chauffeur toutes les 3 secondes
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _rideStatus != 'completed') {
        _loadRideStatus();
        if (_rideStatus == 'driver_assigned' || _rideStatus == 'in_progress') {
          _loadDriverPosition();
        }
      }
    });
  }

  Future<void> _loadRideStatus() async {
    try {
      final result = await ApiService.getRideDetails(widget.rideId);
      if (result['success'] == true && mounted) {
        final rideData = result['ride'] as Map<String, dynamic>?;
        if (rideData != null) {
          final newStatus = rideData['status'] ?? 'pending';
          final driverId = rideData['driver_id'] as int?;
          final driver = rideData['driver'] as Map<String, dynamic>?;
          
          final previousStatus = _rideStatus;
          
          // Si un chauffeur vient d'être assigné, mettre à jour toutes les informations
          if (newStatus == 'driver_assigned' && driver != null && driverId != null) {
            print('✅ [ACTIVE_RIDE] Chauffeur assigné détecté: ${driver['full_name']}');
            print('   Driver ID: $driverId');
            print('   Statut précédent: $previousStatus');
            print('   Données chauffeur: ${driver.keys.toList()}');
            
            // Mettre à jour les informations du chauffeur depuis l'API
            final driverName = driver['full_name'] as String?;
            final driverPhone = driver['phone'] as String?;
            final carMake = driver['car_make'] as String?;
            final carModel = driver['car_model'] as String?;
            final carColor = driver['car_color'] as String?;
            final licensePlate = driver['license_plate'] as String?;
            final driverRating = (driver['rating_average'] as num?)?.toDouble();
            
            // Construire la description du véhicule
            final carDescription = [
              if (carMake != null) carMake,
              if (carModel != null) carModel,
              if (licensePlate != null) licensePlate,
            ].where((e) => e != null).join(' ');
            
            setState(() {
              _rideStatus = newStatus;
              _isLoading = false;
              _canCancel = _rideStatus == 'pending' || _rideStatus == 'driver_assigned';
              
              // Mettre à jour les informations du chauffeur
              _currentDriverId = driverId;
              _currentDriverName = driverName ?? widget.driverName ?? 'Chauffeur';
              _currentDriverPhone = driverPhone ?? widget.driverPhone;
              _currentDriverCar = carDescription.isNotEmpty 
                  ? carDescription 
                  : (widget.driverCar ?? 'Véhicule');
              _currentDriverAvatar = driver['avatar'] as String? ?? widget.driverAvatar;
              _currentDriverRating = driverRating;
              
              // Arrêter l'animation d'attente
              if (previousStatus == 'pending') {
                _waitingAnimationController.stop();
                print('🛑 [ACTIVE_RIDE] Animation d\'attente arrêtée');
              }
            });
            
            // Charger immédiatement la position du chauffeur
            _loadDriverPosition();
            
            // Afficher une notification à l'utilisateur
            if (mounted && previousStatus == 'pending') {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Chauffeur assigné: ${_currentDriverName ?? 'Chauffeur'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppTheme.successColor,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            // Pas de changement de statut ou pas de chauffeur assigné
            setState(() {
              _rideStatus = newStatus;
              _isLoading = false;
              _canCancel = _rideStatus == 'pending' || _rideStatus == 'driver_assigned';
            });
          }
          
          // Si le trajet est terminé, naviguer vers l'écran de fin
          if (newStatus == 'completed' && mounted) {
            _navigateToCompletion(rideData);
          }
        }
      } else {
        // Erreur lors de la récupération du statut
        print('❌ [ACTIVE_RIDE] Erreur lors de la récupération du statut: ${result['message']}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ [ACTIVE_RIDE] Exception lors du chargement du statut: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToCompletion(Map<String, dynamic> rideData) {
    _positionUpdateTimer?.cancel();
    _waitingAnimationController.stop();
    
    final driver = rideData['driver'] as Map<String, dynamic>?;
    final distanceKm = (rideData['distance_km'] as num?)?.toDouble() ?? 0.0;
    final durationMinutes = (rideData['duration_minutes'] as int?) ?? 0;
    final finalPrice = (rideData['final_price'] as int?) ?? (rideData['price'] as int?) ?? 0;
    final paymentMethod = rideData['payment_method'] as String?;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => RideCompletionScreen(
          rideId: widget.rideId,
          driverId: _currentDriverId ?? driver?['id'] ?? widget.driverId ?? 0,
          driverName: _currentDriverName ?? driver?['name'] ?? driver?['full_name'] ?? widget.driverName ?? 'Chauffeur',
          driverAvatar: _currentDriverAvatar ?? driver?['avatar'] ?? widget.driverAvatar,
          driverCar: _currentDriverCar ?? driver?['vehicle'] ?? widget.driverCar,
          distanceKm: distanceKm,
          durationMinutes: durationMinutes,
          finalPrice: finalPrice,
          paymentMethod: paymentMethod,
        ),
      ),
    );
  }

  Future<void> _loadDriverPosition() async {
    final driverId = _currentDriverId ?? widget.driverId;
    if (driverId == null || _clientPosition == null) return;

    try {
      // Appel API pour obtenir la position actuelle du chauffeur
      final result = await ApiService.getDriverPosition(widget.rideId);
      
      if (result['success'] == true && result['data'] != null && mounted) {
        final data = result['data'] as Map<String, dynamic>;
        final lat = data['latitude'] as num?;
        final lng = data['longitude'] as num?;
        final heading = data['heading'] as num?;
        
        if (lat != null && lng != null) {
          final newDriverPosition = Position(
            latitude: lat.toDouble(),
            longitude: lng.toDouble(),
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: heading?.toDouble() ?? 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          
          // Calculer la distance et le temps d'arrivée
          final distanceMeters = LocationService.calculateDistance(
            newDriverPosition.latitude,
            newDriverPosition.longitude,
            _clientPosition!.latitude,
            _clientPosition!.longitude,
          );
          final distanceKm = distanceMeters / 1000;
          
          // Estimation : vitesse moyenne de 30 km/h en ville
          final estimatedMinutes = (distanceKm / 0.5).round(); // 0.5 km/min = 30 km/h
          
          // Calculer la direction (heading) si pas fournie
          double? calculatedHeading;
          if (heading == null && _driverPosition != null) {
            calculatedHeading = Geolocator.bearingBetween(
              _driverPosition!.latitude,
              _driverPosition!.longitude,
              newDriverPosition.latitude,
              newDriverPosition.longitude,
            );
          }
          
          setState(() {
            _driverPosition = newDriverPosition;
            _driverHeading = heading?.toDouble() ?? calculatedHeading ?? 0;
            _distanceToPickupKm = distanceKm;
            _estimatedArrivalMinutes = estimatedMinutes;
          });
        }
      } else {
        // Fallback : simuler le mouvement si l'API n'est pas disponible
        _simulateDriverMovement();
      }
    } catch (e) {
      print('❌ Erreur lors du chargement de la position: $e');
      // Fallback : simuler le mouvement
      _simulateDriverMovement();
    }
  }

  void _simulateDriverMovement() {
    if (_clientPosition == null) return;
    
    // Position initiale du chauffeur (simulée : 2 km au nord du client)
    final initialLat = _clientPosition!.latitude + (2.0 / 111.0); // ~2 km au nord
    final initialLng = _clientPosition!.longitude;
    
    if (_driverPosition == null) {
      setState(() {
        _driverPosition = Position(
          latitude: initialLat,
          longitude: initialLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 180, // Direction sud (vers le client)
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _driverHeading = 180;
      });
    }
    
    // Simuler le mouvement progressif vers le client
    if (_driverPosition != null && _clientPosition != null) {
      final currentLat = _driverPosition!.latitude;
      final currentLng = _driverPosition!.longitude;
      final targetLat = _clientPosition!.latitude;
      final targetLng = _clientPosition!.longitude;
      
      // Distance actuelle
      final currentDistance = LocationService.calculateDistance(
        currentLat,
        currentLng,
        targetLat,
        targetLng,
      );
      
        // Si on est encore loin (plus de 50 mètres), se rapprocher
        if (currentDistance > 50) {
          // Se déplacer de 50 mètres vers le client à chaque mise à jour
          final bearing = Geolocator.bearingBetween(
            currentLat,
            currentLng,
            targetLat,
            targetLng,
          );
          
          // Calculer le nouveau point (50 mètres dans la direction du client)
          final newPosition = _calculateDestinationPoint(
            currentLat,
            currentLng,
            bearing,
            50, // 50 mètres
          );
          
          final newDistance = LocationService.calculateDistance(
            newPosition.latitude,
            newPosition.longitude,
            targetLat,
            targetLng,
          );
          final newDistanceKm = newDistance / 1000;
          final estimatedMinutes = (newDistanceKm / 0.5).round();
          
          setState(() {
            _driverPosition = Position(
              latitude: newPosition.latitude,
              longitude: newPosition.longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: bearing,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
            _driverHeading = bearing;
            _distanceToPickupKm = newDistanceKm;
            _estimatedArrivalMinutes = estimatedMinutes;
          });
        } else {
          // Arrivé à destination
          setState(() {
            _estimatedArrivalMinutes = 0;
            _distanceToPickupKm = 0;
          });
        }
    }
  }

  Future<void> _callDriver() async {
    final driverPhone = _currentDriverPhone ?? widget.driverPhone;
    if (driverPhone == null || driverPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone non disponible'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final phoneUrl = Uri.parse('tel:$driverPhone');
    if (await canLaunchUrl(phoneUrl)) {
      await launchUrl(phoneUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application téléphone'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _messageDriver() async {
    final driverPhone = _currentDriverPhone ?? widget.driverPhone;
    if (driverPhone == null || driverPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Numéro de téléphone non disponible'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final smsUrl = Uri.parse('sms:$driverPhone');
    if (await canLaunchUrl(smsUrl)) {
      await launchUrl(smsUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir l\'application SMS'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _cancelRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Annuler la course',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette course ?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non', style: TextStyle(color: AppTheme.textPrimary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await ApiService.cancelRide(widget.rideId);
        if (result['success'] == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course annulée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Erreur lors de l\'annulation'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Carte avec position du chauffeur et du client
          _buildMap(),
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: AppTheme.textPrimary,
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Sheet avec informations
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Statut de la course
                    _buildStatusIndicator(),
                    const SizedBox(height: 20),
                    // Informations du chauffeur (si assigné)
                    if (_rideStatus == 'driver_assigned' || _rideStatus == 'in_progress')
                      _buildDriverInfo(),
                    if (_rideStatus == 'pending') _buildWaitingIndicator(),
                    const SizedBox(height: 20),
                    // Boutons d'action
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // Centrer la carte entre le client et le chauffeur si les deux positions sont disponibles
    double? centerLat;
    double? centerLng;
    double zoom = 15.0;
    
    if (_clientPosition != null && _driverPosition != null) {
      centerLat = (_clientPosition!.latitude + _driverPosition!.latitude) / 2;
      centerLng = (_clientPosition!.longitude + _driverPosition!.longitude) / 2;
      // Ajuster le zoom pour voir les deux positions
      final distance = LocationService.calculateDistance(
        _clientPosition!.latitude,
        _clientPosition!.longitude,
        _driverPosition!.latitude,
        _driverPosition!.longitude,
      );
      if (distance > 5000) {
        zoom = 12.0; // Zoom out si distance > 5 km
      } else if (distance > 2000) {
        zoom = 13.0;
      } else {
        zoom = 14.0;
      }
    } else if (_clientPosition != null) {
      centerLat = _clientPosition!.latitude;
      centerLng = _clientPosition!.longitude;
    } else if (widget.pickupPosition != null) {
      centerLat = widget.pickupPosition!.latitude;
      centerLng = widget.pickupPosition!.longitude;
    } else {
      centerLat = 14.7167; // Dakar par défaut
      centerLng = -17.4677;
    }

    final centerPoint = LatLng(centerLat!, centerLng!);
    final clientPoint = _clientPosition != null
        ? LatLng(_clientPosition!.latitude, _clientPosition!.longitude)
        : null;
    final driverPoint = _driverPosition != null
        ? LatLng(_driverPosition!.latitude, _driverPosition!.longitude)
        : null;

    return FlutterMap(
      options: MapOptions(
        initialCenter: centerPoint,
        initialZoom: zoom,
        minZoom: 5.0,
        maxZoom: 19.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Tuiles OpenStreetMap
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.temove.app',
          maxZoom: 19,
          maxNativeZoom: 19,
          tileProvider: NetworkTileProvider(),
        ),
        // Ligne entre le chauffeur et le client (si les deux positions sont disponibles)
        if (clientPoint != null && driverPoint != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [driverPoint, clientPoint],
                strokeWidth: 3,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ],
          ),
        // Marqueurs
        MarkerLayer(
          markers: [
            // Marqueur du client
            if (clientPoint != null)
              Marker(
                point: clientPoint,
                width: 40,
                height: 55,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(40, 15),
                      painter: _PinPainter(color: AppTheme.accentColor),
                    ),
                  ],
                ),
              ),
            // Marqueur du chauffeur (avec animation)
            if (driverPoint != null)
              Marker(
                point: driverPoint,
                width: 48,
                height: 48,
                child: DriverCarMarker(
                  heading: _driverHeading,
                  isMoving: _rideStatus == 'driver_assigned' || _rideStatus == 'in_progress',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (_rideStatus) {
      case 'pending':
        statusText = 'En attente d\'acceptation';
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'driver_assigned':
        statusText = 'Chauffeur en route';
        statusColor = AppTheme.infoColor;
        statusIcon = Icons.directions_car;
        break;
      case 'in_progress':
        statusText = 'En cours';
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusText = 'Terminé';
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusText = 'En attente';
        statusColor = AppTheme.textPrimary;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              statusIcon,
              size: 20,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                ),
                if (_estimatedArrivalMinutes > 0 && 
                    (_rideStatus == 'driver_assigned' || _rideStatus == 'in_progress'))
                  Text(
                    'Arrivée dans $_estimatedArrivalMinutes min • ${_distanceToPickupKm.toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textPrimary.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingIndicator() {
    return FadeTransition(
      opacity: _waitingAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animation de recherche
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle pulsant
                  AnimatedBuilder(
                    animation: _waitingAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 60 + (_waitingAnimation.value * 20),
                        height: 60 + (_waitingAnimation.value * 20),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(
                            0.3 * (1 - _waitingAnimation.value),
                          ),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  // Icône de recherche
                  const Icon(
                    Icons.search,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recherche d\'un chauffeur disponible...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Un chauffeur va bientôt accepter votre course',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withOpacity(0.7),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Indicateur de chargement animé
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _waitingAnimation,
                  builder: (context, child) {
                    final delay = index * 0.2;
                    final animationValue = (_waitingAnimation.value + delay) % 1.0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(
                          0.3 + (animationValue * 0.7),
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    // Utiliser les informations mises à jour depuis l'API
    final driverName = _currentDriverName ?? widget.driverName ?? 'Chauffeur';
    final driverCar = _currentDriverCar ?? widget.driverCar ?? 'Véhicule';
    final driverPhone = _currentDriverPhone ?? widget.driverPhone;
    final driverAvatar = _currentDriverAvatar ?? widget.driverAvatar;
    final driverRating = _currentDriverRating;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Photo du chauffeur avec animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: driverAvatar != null
                ? ClipOval(
                    child: Image.network(
                      driverAvatar!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: 16),
          // Nom et véhicule
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
                if (driverRating != null && driverRating! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        driverRating!.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        driverCar,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (_distanceToPickupKm > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 14,
                          color: AppTheme.accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_distanceToPickupKm.toStringAsFixed(1)} km',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Utiliser les informations mises à jour depuis l'API
    final driverPhone = _currentDriverPhone ?? widget.driverPhone;
    
    return Row(
      children: [
        // Bouton d'appel (seulement si chauffeur assigné)
        if (driverPhone != null && driverPhone.isNotEmpty &&
            (_rideStatus == 'driver_assigned' || _rideStatus == 'in_progress'))
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _callDriver,
              icon: const Icon(Icons.phone, size: 20),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (driverPhone != null && driverPhone.isNotEmpty &&
            (_rideStatus == 'driver_assigned' || _rideStatus == 'in_progress'))
          const SizedBox(width: 12),
        // Bouton de messagerie (seulement si chauffeur assigné)
        if (driverPhone != null && driverPhone.isNotEmpty &&
            (_rideStatus == 'driver_assigned' || _rideStatus == 'in_progress'))
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _messageDriver,
              icon: const Icon(Icons.message, size: 20),
              label: const Text('Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.infoColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        if (driverPhone != null && driverPhone.isNotEmpty &&
            (_rideStatus == 'driver_assigned' || _rideStatus == 'in_progress'))
          const SizedBox(width: 12),
        // Bouton d'annulation
        if (_canCancel)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelRide,
              icon: const Icon(Icons.cancel, size: 20),
              label: const Text('Annuler'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
                side: const BorderSide(color: AppTheme.errorColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 32,
      color: AppTheme.primaryColor,
    );
  }

  /// Calculer un point de destination à partir d'un point de départ, d'un bearing et d'une distance
  /// [lat] : Latitude de départ
  /// [lng] : Longitude de départ
  /// [bearing] : Direction en degrés (0 = Nord, 90 = Est, 180 = Sud, 270 = Ouest)
  /// [distanceMeters] : Distance en mètres
  Position _calculateDestinationPoint(
    double lat,
    double lng,
    double bearing,
    double distanceMeters,
  ) {
    // Convertir en radians
    final latRad = lat * math.pi / 180;
    final lngRad = lng * math.pi / 180;
    final bearingRad = bearing * math.pi / 180;
    
    // Rayon de la Terre en mètres
    const earthRadius = 6371000.0;
    
    // Distance angulaire
    final angularDistance = distanceMeters / earthRadius;
    
    // Calculer la nouvelle latitude
    final newLatRad = math.asin(
      math.sin(latRad) * math.cos(angularDistance) +
      math.cos(latRad) * math.sin(angularDistance) * math.cos(bearingRad),
    );
    
    // Calculer la nouvelle longitude
    final newLngRad = lngRad + math.atan2(
      math.sin(bearingRad) * math.sin(angularDistance) * math.cos(latRad),
      math.cos(angularDistance) - math.sin(latRad) * math.sin(newLatRad),
    );
    
    // Convertir en degrés
    final newLat = newLatRad * 180 / math.pi;
    final newLng = newLngRad * 180 / math.pi;
    
    return Position(
      latitude: newLat,
      longitude: newLng,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: bearing,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

/// Peintre personnalisé pour la pointe du pin de localisation
class _PinPainter extends CustomPainter {
  final Color color;

  _PinPainter({required this.color});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
