import 'dart:async';
import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/map_placeholder.dart';
import 'package:temove/screens/rating_screen.dart';
import 'package:temove/services/api_service.dart';

class RideTrackingScreen extends StatefulWidget {
  final int? rideId;
  final int? driverId;
  final String? driverName;
  final String? driverCar;
  final String? driverAvatar;
  final List<dynamic>? availableDrivers; // Chauffeurs disponibles avec ETA

  const RideTrackingScreen({
    super.key,
    this.rideId,
    this.driverId,
    this.driverName,
    this.driverCar,
    this.driverAvatar,
    this.availableDrivers,
  });

  @override
  State<RideTrackingScreen> createState() => _RideTrackingScreenState();
}

class _RideTrackingScreenState extends State<RideTrackingScreen> {
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _rideStatus;
  int? _assignedDriverId;
  Map<String, dynamic>? _assignedDriver;
  List<dynamic> _availableDrivers = [];
  int _minEtaMinutes = 0;

  @override
  void initState() {
    super.initState();
    _rideStatus = widget.driverId != null ? 'driver_assigned' : 'pending';
    _assignedDriverId = widget.driverId;
    _availableDrivers = widget.availableDrivers ?? [];
    
    // Calculer l'ETA minimum si des chauffeurs sont disponibles
    if (_availableDrivers.isNotEmpty) {
      _minEtaMinutes = _availableDrivers
          .map((d) => d['eta_minutes'] as int? ?? 0)
          .reduce((a, b) => a < b ? a : b);
    }
    
    _loadRideStatus();
    _startPolling();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Rafraîchir toutes les 5 secondes pour vérifier si un chauffeur a accepté
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _rideStatus == 'pending' && widget.rideId != null) {
        _loadRideStatus();
        _loadAvailableDrivers();
      }
    });
  }

  Future<void> _loadRideStatus() async {
    if (widget.rideId == null) return;
    
    try {
      // Essayer d'abord de récupérer les détails de la course pour voir si un chauffeur a été assigné
      final rideDetailsResult = await ApiService.getRideDetails(widget.rideId!);
      
      if (rideDetailsResult['success'] == true) {
        final rideData = rideDetailsResult['ride'] as Map<String, dynamic>?;
        
        if (rideData != null) {
          final status = rideData['status'] as String? ?? 'pending';
          final driverId = rideData['driver_id'] as int?;
          final driver = rideData['driver'] as Map<String, dynamic>?;
          
          // Si un chauffeur est assigné, arrêter le polling et afficher ses informations
          if (driverId != null && driver != null && status != 'pending') {
            setState(() {
              _rideStatus = status;
              _assignedDriverId = driverId;
              _assignedDriver = driver;
              // Arrêter le polling car un chauffeur a été assigné
              _refreshTimer?.cancel();
              _isLoading = false;
            });
            return;
          }
        }
      }
      
      // Si aucun chauffeur n'est assigné, récupérer les chauffeurs disponibles
      final result = await ApiService.getAvailableDriversForRide(widget.rideId!);
      
      if (result['success'] == true) {
        final status = result['status'] as String? ?? 'pending';
        
        // Si le statut est toujours "pending", continuer à afficher les chauffeurs disponibles
        if (status == 'pending') {
          setState(() {
            _rideStatus = 'pending';
            _isLoading = false;
          });
          return;
        }
      } else {
        // Si l'endpoint retourne une erreur (ex: course déjà assignée),
        // récupérer les détails de la course pour obtenir le chauffeur assigné
        final errorMsg = result['message'] ?? '';
        if (errorMsg.contains('déjà un chauffeur') || errorMsg.contains('already')) {
          // Récupérer les détails de la course pour obtenir le chauffeur
          final rideDetailsResult2 = await ApiService.getRideDetails(widget.rideId!);
          
          if (rideDetailsResult2['success'] == true) {
            final rideData = rideDetailsResult2['ride'] as Map<String, dynamic>?;
            
            if (rideData != null) {
              final driverId = rideData['driver_id'] as int?;
              final driver = rideData['driver'] as Map<String, dynamic>?;
              
              if (driverId != null && driver != null) {
                setState(() {
                  _rideStatus = 'driver_assigned';
                  _assignedDriverId = driverId;
                  _assignedDriver = driver;
                  _refreshTimer?.cancel();
                  _isLoading = false;
                });
                return;
              }
            }
          }
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [RIDE_TRACKING] Erreur lors du chargement: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAvailableDrivers() async {
    if (widget.rideId == null || _rideStatus != 'pending') return;
    
    try {
      final result = await ApiService.getAvailableDriversForRide(widget.rideId!);
      
      if (result['success'] == true && mounted) {
        final drivers = result['available_drivers'] as List<dynamic>? ?? [];
        
        // Calculer l'ETA minimum
        int minEta = 0;
        if (drivers.isNotEmpty) {
          minEta = drivers
              .map((d) => d['eta_minutes'] as int? ?? 0)
              .reduce((a, b) => a < b ? a : b);
        }
        
        setState(() {
          _availableDrivers = drivers;
          _minEtaMinutes = minEta;
        });
      }
    } catch (e) {
      print('❌ [RIDE_TRACKING] Erreur lors du chargement des chauffeurs: $e');
    }
  }

  Widget _buildMapWidget() {
    // Utiliser MapPlaceholder avec OpenStreetMap (pas besoin de clé API)
    return const MapPlaceholder(
      latitude: 14.7167,
      longitude: -17.4677,
      locationName: 'Dakar',
      showCurrentLocation: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Map Background ou Placeholder
          _buildMapWidget(),
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        color: AppTheme.secondaryColor,
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                    const Text(
                      'Ton Chauffeur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.help_outline),
                        color: AppTheme.secondaryColor,
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Map Controls
          Positioned(
            right: 16,
            top: 140,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: AppTheme.secondaryColor,
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove),
                        color: AppTheme.secondaryColor,
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location),
                    color: AppTheme.secondaryColor,
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.backgroundDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            // Afficher l'état de la course
                            if (_rideStatus == 'pending' && _assignedDriverId == null) ...[
                              // État : Recherche de chauffeur
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Recherche de chauffeur...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark 
                                          ? AppTheme.textPrimary 
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_availableDrivers.isEmpty)
                                Text(
                                  'Aucun chauffeur disponible pour le moment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark 
                                        ? AppTheme.textMuted 
                                        : Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              else ...[
                                Text(
                                  '${_availableDrivers.length} chauffeur${_availableDrivers.length > 1 ? 's' : ''} disponible${_availableDrivers.length > 1 ? 's' : ''}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark 
                                        ? AppTheme.textMuted 
                                        : Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_minEtaMinutes > 0) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Temps d\'arrivée estimé: $_minEtaMinutes min',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                // Liste des chauffeurs disponibles
                                ..._availableDrivers.take(3).map((driver) {
                                  final driverName = driver['full_name'] ?? 'Chauffeur';
                                  final carMake = driver['car_make'] ?? '';
                                  final carModel = driver['car_model'] ?? '';
                                  final licensePlate = driver['license_plate'] ?? '';
                                  final rating = driver['rating_average'] ?? 0.0;
                                  final eta = driver['eta_minutes'] ?? 0;
                                  final distance = driver['distance_km'] ?? 0.0;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.grey.shade300,
                                          ),
                                          child: const Icon(
                                            Icons.person,
                                            size: 24,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                driverName,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                '$carMake $carModel - $licensePlate',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  rating.toStringAsFixed(1),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(
                                                  Icons.star,
                                                  color: AppTheme.primaryColor,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '$eta min • ${distance.toStringAsFixed(1)} km',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ] else if (_assignedDriverId != null || widget.driverId != null) ...[
                              // État : Chauffeur assigné
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ton chauffeur sera là dans',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isDark 
                                          ? AppTheme.textPrimary 
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_minEtaMinutes > 0 ? _minEtaMinutes : 5} MIN',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: 0.4, // Progression simulée
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Divider(
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              // Driver Info
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade300,
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      size: 32,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _assignedDriver?['full_name'] ?? 
                                          widget.driverName ?? 
                                          'Chauffeur',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark 
                                                ? AppTheme.textPrimary 
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _assignedDriver != null
                                              ? '${_assignedDriver!['car_make'] ?? ''} ${_assignedDriver!['car_model'] ?? ''} - ${_assignedDriver!['license_plate'] ?? ''}'.trim()
                                              : widget.driverCar ?? 'Véhicule',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark 
                                                ? AppTheme.textMuted 
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        (_assignedDriver?['rating_average'] ?? 
                                         _assignedDriver?['rating'] ?? 
                                         4.9).toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark 
                                              ? AppTheme.textPrimary 
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.star,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                            // Afficher les boutons d'action seulement si un chauffeur est assigné
                            if (_assignedDriverId != null || widget.driverId != null) ...[
                              const SizedBox(height: 24),
                              // Action Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.chat_bubble_outline),
                                      label: const Text('Message'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade200,
                                        foregroundColor: AppTheme.textSecondary,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.call),
                                      label: const Text('Appeler'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accentColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Additional Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.share),
                                      label: const Text('Share Trip'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: isDark 
                                            ? AppTheme.textPrimary 
                                            : AppTheme.textSecondary,
                                        side: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Annuler la course'),
                                            content: const Text(
                                              'Êtes-vous sûr de vouloir annuler cette course ?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Non'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Oui'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.cancel_outlined),
                                      label: const Text('Annuler'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.errorColor,
                                        side: BorderSide(
                                          color: AppTheme.errorColor.withOpacity(0.5),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Complete Ride Button (simulation)
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Aller à l'évaluation avec les informations du chauffeur
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RatingScreen(
                                          driverName: widget.driverName ?? 'Chauffeur',
                                          driverCar: widget.driverCar ?? 'Véhicule',
                                          driverAvatar: widget.driverAvatar,
                                          rideId: widget.rideId,
                                          driverId: widget.driverId,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Course terminée - Évaluer',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              // Afficher un bouton d'annulation si aucun chauffeur n'est assigné
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Annuler la course'),
                                        content: const Text(
                                          'Êtes-vous sûr de vouloir annuler cette course ?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Non'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Oui'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.cancel_outlined),
                                  label: const Text('Annuler la course'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.errorColor,
                                    side: BorderSide(
                                      color: AppTheme.errorColor.withOpacity(0.5),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

