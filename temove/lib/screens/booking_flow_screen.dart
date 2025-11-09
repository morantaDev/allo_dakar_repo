import 'dart:async';
import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/models/ride_mode.dart';
import 'package:temove/models/dynamic_pricing.dart';
import 'package:temove/widgets/map_placeholder.dart';
import 'package:temove/services/location_service.dart';
import 'package:temove/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:temove/screens/driver_search_screen.dart';

/// Écran de réservation avec calcul dynamique du prix
/// 
/// Permet de :
/// - Saisir le point de départ et d'arrivée
/// - Voir la carte interactive
/// - Calculer automatiquement le prix et le temps
/// - Choisir le mode de transport
/// - Voir les facteurs influençant le prix
/// - Ajouter un pourboire optionnel
class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen>
    with SingleTickerProviderStateMixin {
  // Contrôleurs de texte
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  // Positions GPS
  Position? _departurePosition;
  Position? _destinationPosition;
  String? _departureAddress;
  String? _destinationAddress;

  // États de chargement
  bool _isLoadingDeparture = false;
  bool _isLoadingDestination = false;
  bool _isCalculatingPrice = false;

  // Mode sélectionné
  RideModeData? _selectedMode;

  // Calcul de prix dynamique
  DynamicPricing? _pricing;
  Timer? _searchTimer;

  // Pourboire
  double? _tipPercentage;
  final List<double> _tipSuggestions = [0, 5, 10, 15, 20];

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    _getCurrentLocation();
    _departureController.addListener(_onDepartureChanged);
    _destinationController.addListener(_onDestinationChanged);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _animationController.dispose();
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingDeparture = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _departurePosition = position;
        });

        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _departureAddress = address ?? 'Position actuelle';
            _departureController.text = _departureAddress ?? '';
            _isLoadingDeparture = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDeparture = false;
            _departureAddress = 'Dakar';
            _departurePosition = LocationService.getDefaultPosition();
            _departureController.text = 'Dakar';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDeparture = false;
          _departureAddress = 'Dakar';
          _departurePosition = LocationService.getDefaultPosition();
          _departureController.text = 'Dakar';
        });
      }
    }
  }

  void _onDepartureChanged() {
    _searchTimer?.cancel();
    final query = _departureController.text.trim();
    
    if (query.isEmpty || query.length < 3) {
      setState(() {
        _departureAddress = null;
        _departurePosition = null;
      });
      _calculatePrice();
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _departureController.text.trim() == query) {
        _searchDeparture(query);
      }
    });
  }

  void _onDestinationChanged() {
    _searchTimer?.cancel();
    final query = _destinationController.text.trim();
    
    if (query.isEmpty || query.length < 3) {
      setState(() {
        _destinationAddress = null;
        _destinationPosition = null;
      });
      _calculatePrice();
      return;
    }

    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _destinationController.text.trim() == query) {
        _searchDestination(query);
      }
    });
  }

  Future<void> _searchDeparture(String query) async {
    if (query.length < 3) return;

    setState(() {
      _isLoadingDeparture = true;
    });

    try {
      final position = await LocationService.getCoordinatesFromAddress(query);
      if (position != null && mounted) {
        setState(() {
          _departurePosition = position;
          _departureAddress = query;
          _isLoadingDeparture = false;
        });
        _calculatePrice();
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDeparture = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDeparture = false;
        });
      }
    }
  }

  Future<void> _searchDestination(String query) async {
    if (query.length < 3) return;

    setState(() {
      _isLoadingDestination = true;
    });

    try {
      final position = await LocationService.getCoordinatesFromAddress(query);
      if (position != null && mounted) {
        setState(() {
          _destinationPosition = position;
          _destinationAddress = query;
          _isLoadingDestination = false;
        });
        _calculatePrice();
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDestination = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDestination = false;
        });
      }
    }
  }

  Future<void> _calculatePrice() async {
    if (_departurePosition == null || _destinationPosition == null) {
      setState(() {
        _pricing = null;
      });
      return;
    }

    setState(() {
      _isCalculatingPrice = true;
    });

    try {
      // Appel API pour obtenir l'estimation
      final result = await ApiService.getTripEstimate(
        departureLat: _departurePosition!.latitude,
        departureLng: _departurePosition!.longitude,
        destinationLat: _destinationPosition!.latitude,
        destinationLng: _destinationPosition!.longitude,
        rideMode: _selectedMode?.name ?? 'confort',
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        setState(() {
          _pricing = DynamicPricing.fromApiData(
            data,
            tipPercentage: _tipPercentage,
            modeMultiplier: _selectedMode?.priceMultiplier, // Appliquer le coefficient du mode
          );
          _isCalculatingPrice = false;
        });
      } else {
        // Calcul local en fallback
        _calculatePriceLocal();
      }
    } catch (e) {
      if (mounted) {
        _calculatePriceLocal();
      }
    }
  }

  void _calculatePriceLocal() {
    if (_departurePosition == null || _destinationPosition == null) return;

    final distanceKm = LocationService.calculateDistanceInKm(
      _departurePosition!.latitude,
      _departurePosition!.longitude,
      _destinationPosition!.latitude,
      _destinationPosition!.longitude,
    );

    final durationMinutes = (distanceKm / 0.5).round();

    setState(() {
      _pricing = DynamicPricing(
        basePricePerKm: 300.0, // Prix de base par km
        baseFare: 500.0, // Prix de base fixe
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        tipPercentage: _tipPercentage,
        modeMultiplier: _selectedMode?.priceMultiplier, // Appliquer le coefficient du mode
      );
      _isCalculatingPrice = false;
    });
  }

  void _onModeSelected(RideModeData mode) {
    setState(() {
      _selectedMode = mode;
    });
    _calculatePrice();
  }

  void _onTipSelected(double? percentage) {
    setState(() {
      _tipPercentage = percentage;
    });
    if (_pricing != null) {
      setState(() {
        _pricing = DynamicPricing(
          basePricePerKm: _pricing!.basePricePerKm,
          baseFare: _pricing!.baseFare,
          distanceKm: _pricing!.distanceKm,
          durationMinutes: _pricing!.durationMinutes,
          surgeMultiplier: _pricing!.surgeMultiplier,
          isPeakHours: _pricing!.isPeakHours,
          isHighDemand: _pricing!.isHighDemand,
          isBadWeather: _pricing!.isBadWeather,
          waitingMinutes: _pricing!.waitingMinutes,
          tipPercentage: percentage,
          modeMultiplier: _selectedMode?.priceMultiplier, // Conserver le coefficient du mode
        );
      });
    }
  }

  Future<void> _confirmBooking() async {
    if (_departurePosition == null ||
        _destinationPosition == null ||
        _departureAddress == null ||
        _destinationAddress == null ||
        _selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Naviguer vers l'écran de recherche de chauffeur
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DriverSearchScreen(
          selectedMode: _selectedMode!,
          pickupPosition: _departurePosition!,
          pickupAddress: _departureAddress!,
          destinationPosition: _destinationPosition,
          destinationAddress: _destinationAddress,
          pricing: _pricing,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Carte interactive
          MapPlaceholder(
            showCurrentLocation: true,
            latitude: _departurePosition?.latitude,
            longitude: _departurePosition?.longitude,
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
                ],
              ),
            ),
          ),
          // Bottom Sheet avec formulaire
          DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
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
                          color: AppTheme.grayMedium,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              // Titre
                              Text(
                                'Réserver un trajet',
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 24),
                              // Champs de recherche
                              _buildLocationField(
                                controller: _departureController,
                                label: 'Départ',
                                icon: Icons.trip_origin,
                                isLoading: _isLoadingDeparture,
                                onLocationTap: _getCurrentLocation,
                              ),
                              const SizedBox(height: 16),
                              _buildLocationField(
                                controller: _destinationController,
                                label: 'Destination',
                                icon: Icons.location_on,
                                isLoading: _isLoadingDestination,
                              ),
                              const SizedBox(height: 24),
                              // Sélection du mode
                              Text(
                                'Mode de transport',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _buildModeSelection(),
                              const SizedBox(height: 24),
                              // Calcul du prix
                              if (_isCalculatingPrice)
                                _buildCalculatingPrice()
                              else if (_pricing != null)
                                _buildPriceDisplay(),
                              const SizedBox(height: 24),
                              // Pourboire
                              _buildTipSelection(),
                              const SizedBox(height: 24),
                              // Bouton de confirmation
                              _buildConfirmButton(),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isLoading,
    VoidCallback? onLocationTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
              ),
          decoration: InputDecoration(
            hintText: isLoading ? 'Recherche...' : 'Tapez une adresse',
            prefixIcon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  )
                : Icon(icon, color: AppTheme.primaryColor),
            suffixIcon: onLocationTap != null
                ? IconButton(
                    icon: const Icon(Icons.my_location),
                    color: AppTheme.primaryColor,
                    onPressed: onLocationTap,
                  )
                : null,
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.grayMedium.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppTheme.grayMedium.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelection() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: RideModes.all.length,
        itemBuilder: (context, index) {
          final mode = RideModes.all[index];
          final isSelected = _selectedMode?.id == mode.id;
          return Padding(
            padding: EdgeInsets.only(
              right: index < RideModes.all.length - 1 ? 12 : 0,
            ),
            child: _ModeCard(
              mode: mode,
              isSelected: isSelected,
              onTap: () => _onModeSelected(mode),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalculatingPrice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Calcul du prix en cours...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDisplay() {
    if (_pricing == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Prix final
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                'Prix estimé',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textPrimary.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_pricing!.finalPrice}',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'XOF',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textPrimary.withOpacity(0.7),
                          ),
                    ),
                  ),
                ],
              ),
              if (_pricing!.tipPercentage != null && _pricing!.tipPercentage! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'dont ${_pricing!.tipAmount} XOF de pourboire',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successColor,
                        ),
                  ),
                ),
            ],
          ),
        ),
        // Note: Les détails du calcul ne sont pas affichés au client
        // Seule l'estimation finale est visible avant validation
      ],
    );
  }

  Widget _buildTipSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pourboire (optionnel)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tipSuggestions.map((percentage) {
            final isSelected = _tipPercentage == percentage;
            return InkWell(
              onTap: () => _onTipSelected(percentage == 0 ? null : percentage),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.grayMedium.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  percentage == 0 ? 'Aucun' : '$percentage%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppTheme.secondaryColor
                            : AppTheme.textPrimary,
                      ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    final canConfirm = _departurePosition != null &&
        _destinationPosition != null &&
        _departureAddress != null &&
        _destinationAddress != null &&
        _selectedMode != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canConfirm ? _confirmBooking : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          'Confirmer la réservation',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.secondaryColor,
              ),
        ),
      ),
    );
  }
}

/// Carte de mode de transport
class _ModeCard extends StatelessWidget {
  final RideModeData mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.15)
              : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.grayMedium.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode.icon,
              size: 28,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                mode.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                mode.compactPrice(), // Prix calculé avec distance par défaut
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item de facteur de prix
class _PricingFactorItem extends StatelessWidget {
  final PricingFactor factor;

  const _PricingFactorItem({required this.factor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: factor.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              factor.icon,
              size: 18,
              color: factor.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  factor.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                ),
                if (factor.impact != null)
                  Text(
                    factor.impact!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: factor.color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
              ],
            ),
          ),
          Text(
            factor.value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: factor.color,
                ),
          ),
        ],
      ),
    );
  }
}

