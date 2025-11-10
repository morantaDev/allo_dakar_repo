import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/models/ride_mode.dart';
import 'package:temove/screens/driver_search_screen.dart';
import 'package:temove/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

/// Écran de sélection de mode de transport avec tarifs fixes
/// 
/// Affiche les modes disponibles avec leurs prix et temps d'arrivée estimés.
/// Le client peut choisir un mode sans avoir besoin de saisir sa destination.
class RideModeSelectionScreen extends StatefulWidget {
  const RideModeSelectionScreen({super.key});

  @override
  State<RideModeSelectionScreen> createState() => _RideModeSelectionScreenState();
}

class _RideModeSelectionScreenState extends State<RideModeSelectionScreen>
    with SingleTickerProviderStateMixin {
  RideModeData? _selectedMode;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = true;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });

        // Obtenir l'adresse
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _currentAddress = address ?? 'Position actuelle';
            _isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _currentAddress = 'Dakar';
            _currentPosition = LocationService.getDefaultPosition();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _currentAddress = 'Dakar';
          _currentPosition = LocationService.getDefaultPosition();
        });
      }
    }
  }

  void _onModeSelected(RideModeData mode) {
    setState(() {
      _selectedMode = mode;
    });

    // Animation de sélection
    _animationController.reset();
    _animationController.forward();

    // Naviguer vers l'écran de recherche de chauffeur après un court délai
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && _currentPosition != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DriverSearchScreen(
              selectedMode: mode,
              pickupPosition: _currentPosition!,
              pickupAddress: _currentAddress ?? 'Position actuelle',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Content
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        'Choisissez votre mode de transport',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les prix et temps d\'arrivée sont fixes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textPrimary.withOpacity(0.7),
                            ),
                      ),
                      const SizedBox(height: 32),
                      // Liste des modes
                      ...RideModes.all.map((mode) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _RideModeCard(
                              mode: mode,
                              isSelected: _selectedMode?.id == mode.id,
                              onTap: () => _onModeSelected(mode),
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton retour
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              color: AppTheme.textPrimary,
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 16),
          // Position actuelle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Départ depuis',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary.withOpacity(0.6),
                      ),
                ),
                const SizedBox(height: 2),
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentAddress ?? 'Chargement...',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de mode de transport
class _RideModeCard extends StatefulWidget {
  final RideModeData mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _RideModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_RideModeCard> createState() => _RideModeCardState();
}

class _RideModeCardState extends State<_RideModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppTheme.primaryColor.withOpacity(0.15)
                : AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.grayMedium.withOpacity(0.3),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? AppTheme.primaryColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: widget.isSelected ? 20 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.mode.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.mode.icon,
                  size: 32,
                  color: widget.mode.color,
                ),
              ),
              const SizedBox(width: 16),
              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.mode.displayName,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.mode.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textPrimary.withOpacity(0.7),
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Features
                    if (widget.mode.features.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.mode.features.map((feature) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              feature,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: AppTheme.textPrimary.withOpacity(0.8),
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Prix et temps
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.mode.formattedPrice(), // Prix calculé avec distance par défaut (5 km)
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.mode.estimatedArrival,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

