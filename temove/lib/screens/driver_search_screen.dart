import 'dart:async';
import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/models/ride_mode.dart';
import 'package:temove/models/dynamic_pricing.dart';
import 'package:temove/widgets/map_placeholder.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/screens/active_ride_screen.dart';
import 'package:geolocator/geolocator.dart';

/// Écran de création de réservation
/// 
/// Affiche :
/// - La carte avec la position actuelle du client
/// - Une animation de création de réservation
/// - Crée la réservation immédiatement via l'API
/// - Navigue vers ActiveRideScreen qui attendra l'acceptation d'un chauffeur via TéMove Pro
class DriverSearchScreen extends StatefulWidget {
  final RideModeData selectedMode;
  final Position pickupPosition;
  final String pickupAddress;
  final Position? destinationPosition;
  final String? destinationAddress;
  final DynamicPricing? pricing;

  const DriverSearchScreen({
    super.key,
    required this.selectedMode,
    required this.pickupPosition,
    required this.pickupAddress,
    this.destinationPosition,
    this.destinationAddress,
    this.pricing,
  });

  @override
  State<DriverSearchScreen> createState() => _DriverSearchScreenState();
}

class _DriverSearchScreenState extends State<DriverSearchScreen>
    with TickerProviderStateMixin {
  // État de recherche
  bool _isSearching = true;

  // Animations
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Attendre que le widget soit complètement construit avant d'afficher le dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startDriverSearch();
      }
    });
  }

  void _setupAnimations() {
    // Animation de pulsation pour l'indicateur de recherche
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startDriverSearch() async {
    // Créer la réservation après que le widget soit complètement construit
    // La course sera en statut "pending" et attendra l'acceptation d'un chauffeur via TéMove Pro
    await _createReservation();
  }

  Future<void> _createReservation() async {
    // Vérifier que le widget est toujours monté
    if (!mounted) return;
    
    // Attendre un frame supplémentaire pour s'assurer que le context est disponible
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      ),
    );

    try {
      // Créer la réservation via l'API
      // La course sera créée avec le statut "pending" (pas de chauffeur assigné)
      final result = await ApiService.bookRide(
        departureLat: widget.pickupPosition.latitude,
        departureLng: widget.pickupPosition.longitude,
        departureAddress: widget.pickupAddress,
        destinationLat: widget.destinationPosition?.latitude,
        destinationLng: widget.destinationPosition?.longitude,
        destinationAddress: widget.destinationAddress,
        rideMode: widget.selectedMode.name,
        rideCategory: 'course',
        paymentMethod: 'cash', // Par défaut
        promoCode: null,
        scheduledAt: null,
      );

      if (!mounted) return;

      Navigator.pop(context); // Fermer le dialog de chargement

      if (result['success'] == true) {
        final rideData = result['ride'] as Map<String, dynamic>?;
        final rideId = rideData?['id'] as int?;
        final driverData = rideData?['driver'] as Map<String, dynamic>?;
        
        // Note: driverData sera null car aucun chauffeur n'est encore assigné
        // La course attend l'acceptation d'un chauffeur via TéMove Pro
        
        // Naviguer directement vers l'écran de suivi actif
        // ActiveRideScreen affichera l'animation d'attente jusqu'à ce qu'un chauffeur accepte
        if (rideId != null && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ActiveRideScreen(
                rideId: rideId,
                driverId: driverData?['id'] as int?, // Sera null au début (statut pending)
                driverName: driverData?['name'], // Sera null au début
                driverPhone: driverData?['phone'] ?? driverData?['phone_number'],
                driverCar: driverData?['vehicle'],
                driverAvatar: driverData?['avatar'],
                pickupPosition: widget.pickupPosition,
                destinationPosition: widget.destinationPosition,
                pickupAddress: widget.pickupAddress,
                destinationAddress: widget.destinationAddress,
              ),
            ),
          );
        } else {
          // Afficher un message d'erreur si pas de rideId
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur: Impossible de créer la réservation'),
                backgroundColor: AppTheme.errorColor,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Afficher une erreur
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? result['message'] ?? 'Erreur lors de la réservation'),
              backgroundColor: AppTheme.errorColor,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Carte avec position actuelle
          MapPlaceholder(
            showCurrentLocation: true,
            latitude: widget.pickupPosition.latitude,
            longitude: widget.pickupPosition.longitude,
          ),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Text(
                        widget.selectedMode.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      Text(
                        widget.pricing != null
                            ? '${widget.pricing!.finalPrice} XOF'
                            : widget.selectedMode.formattedPrice(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Indicateur de recherche (toujours affiché pendant la création de la réservation)
          if (_isSearching)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: _buildSearchingIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchingIndicator() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
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
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Création de la réservation...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Votre course sera proposée aux chauffeurs disponibles',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}

