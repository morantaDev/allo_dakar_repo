import 'package:flutter/material.dart';
import 'package:allo_dakar/theme/app_theme.dart';
import 'package:allo_dakar/screens/ride_tracking_screen.dart';
import 'package:allo_dakar/screens/payment_method_screen.dart';
import 'package:allo_dakar/screens/promo_code_screen.dart';
import 'package:allo_dakar/widgets/map_placeholder.dart';
import 'package:allo_dakar/models/ride_options.dart';
import 'package:allo_dakar/models/trip_estimate.dart';
import 'package:allo_dakar/models/promo_code.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show GoogleMap, CameraPosition, LatLng;
import 'package:flutter/foundation.dart' show kIsWeb;

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  RideCategory _selectedCategory = RideCategory.course;
  RideMode _selectedRideMode = RideMode.confort;
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.om;
  PromoCode? _appliedPromoCode;
  final TextEditingController _destinationController = TextEditingController();
  
  // Estimation du trajet (exemple)
  TripEstimate? _tripEstimate;

  @override
  void initState() {
    super.initState();
    // Calculer l'estimation par défaut
    _calculateEstimate();
  }

  void _calculateEstimate() {
    // Simulation d'un trajet : 5 km, 15 minutes
    final basePrice = _selectedRideMode.estimatedPrice.replaceAll(' XOF', '').replaceAll(' ', '');
    final pricePerKm = int.tryParse(basePrice) ?? 2500;
    
    setState(() {
      _tripEstimate = TripEstimate.calculate(
        distanceKm: 5.2,
        durationMinutes: 15,
        basePricePerKm: (pricePerKm / 5).round(), // Approximation
        time: DateTime.now(),
      );
    });
  }

  int _getFinalPrice() {
    int price = _tripEstimate?.finalPrice ?? 2500;
    
    // Appliquer le code promo si présent
    if (_appliedPromoCode != null) {
      price = _appliedPromoCode!.applyDiscount(price);
    }
    
    return price;
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Widget _buildMapWidget() {
    if (kIsWeb) {
      return MapPlaceholder(
        latitude: 14.7167,
        longitude: -17.4677,
        locationName: 'Dakar',
      );
    }

    try {
      return const GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(14.7167, -17.4677), // Dakar
          zoom: 13,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
      );
    } catch (e) {
      return MapPlaceholder(
        latitude: 14.7167,
        longitude: -17.4677,
        locationName: 'Dakar',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Map ou Placeholder
          _buildMapWidget(),
          // Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppTheme.secondaryColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Map Controls
          Positioned(
            right: 16,
            top: 200,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    color: AppTheme.secondaryColor,
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    color: AppTheme.secondaryColor,
                    onPressed: () {},
                    padding: EdgeInsets.zero,
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
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
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
                            // Location Inputs
                            Text(
                              'Lieu de départ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              readOnly: true,
                              decoration: InputDecoration(
                                hintText: 'Avenue Cheikh Anta Diop',
                                prefixIcon: const Icon(Icons.trip_origin),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.backgroundColor.withOpacity(0.3)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _destinationController,
                              decoration: InputDecoration(
                                hintText: 'Où allez-vous ?',
                                prefixIcon: const Icon(Icons.location_on),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.backgroundColor.withOpacity(0.3)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Category Selection (Course / Livraison)
                            Text(
                              'Type de service',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _CategoryChip(
                                    label: 'Course',
                                    icon: Icons.directions_car,
                                    isSelected: _selectedCategory == RideCategory.course,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = RideCategory.course;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CategoryChip(
                                    label: 'Livraison',
                                    icon: Icons.local_shipping,
                                    isSelected: _selectedCategory == RideCategory.livraison,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = RideCategory.livraison;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Ride Mode Selection
                            Text(
                              'Mode de transport',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Grid of ride modes - 2 columns
                            Row(
                              children: [
                                Expanded(
                                  child: _RideModeCard(
                                    mode: RideMode.eco,
                                    isSelected: _selectedRideMode == RideMode.eco,
                                    onTap: () {
                                      setState(() {
                                        _selectedRideMode = RideMode.eco;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _RideModeCard(
                                    mode: RideMode.confort,
                                    isSelected: _selectedRideMode == RideMode.confort,
                                    onTap: () {
                                      setState(() {
                                        _selectedRideMode = RideMode.confort;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _RideModeCard(
                                    mode: RideMode.confortPlus,
                                    isSelected: _selectedRideMode == RideMode.confortPlus,
                                    onTap: () {
                                      setState(() {
                                        _selectedRideMode = RideMode.confortPlus;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _RideModeCard(
                                    mode: RideMode.partageTaxi,
                                    isSelected: _selectedRideMode == RideMode.partageTaxi,
                                    onTap: () {
                                      setState(() {
                                        _selectedRideMode = RideMode.partageTaxi;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Trip Estimate
                            if (_tripEstimate != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accentColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _EstimateItem(
                                      icon: Icons.straighten,
                                      label: 'Distance',
                                      value: _tripEstimate!.formattedDistance,
                                      isDark: isDark,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: AppTheme.accentColor.withOpacity(0.3),
                                    ),
                                    _EstimateItem(
                                      icon: Icons.access_time,
                                      label: 'Durée',
                                      value: _tripEstimate!.formattedDuration,
                                      isDark: isDark,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: AppTheme.accentColor.withOpacity(0.3),
                                    ),
                                    _EstimateItem(
                                      icon: Icons.monetization_on,
                                      label: 'Prix',
                                      value: '${_getFinalPrice()} XOF',
                                      isDark: isDark,
                                      highlight: true,
                                    ),
                                  ],
                                ),
                              ),
                            if (_tripEstimate?.surgeMultiplier != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up,
                                      color: AppTheme.warningColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Prix majoré en heures de pointe (${(_tripEstimate!.surgeMultiplier! * 100).toInt()}%)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.warningColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Promo Code
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push<PromoCode>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PromoCodeScreen(
                                      initialCode: _appliedPromoCode?.code,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    _appliedPromoCode = result;
                                    _calculateEstimate();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.backgroundColor.withOpacity(0.3)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.local_offer,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Code Promo',
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
                                    Row(
                                      children: [
                                        if (_appliedPromoCode != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _appliedPromoCode!.code,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.successColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Icon(
                                          Icons.chevron_right,
                                          color: isDark
                                              ? AppTheme.textMuted
                                              : Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Payment Method
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push<PaymentMethod>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentMethodScreen(
                                      selectedMethod: _selectedPaymentMethod,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    _selectedPaymentMethod = result;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.backgroundColor.withOpacity(0.3)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.payments,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Méthode de paiement',
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
                                    Row(
                                      children: [
                                        if (_selectedPaymentMethod != null) ...[
                                          Icon(
                                            _selectedPaymentMethod!.icon,
                                            size: 20,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedPaymentMethod!.shortName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark 
                                                  ? AppTheme.textPrimary 
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'Sélectionner',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark 
                                                  ? AppTheme.textMuted 
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: isDark 
                                              ? AppTheme.textMuted 
                                              : Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Confirm Button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RideTrackingScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: AppTheme.secondaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Confirmer la course',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_getFinalPrice() != (_tripEstimate?.finalPrice ?? 2500))
                                      Text(
                                        '${_tripEstimate?.finalPrice ?? 2500} XOF → ${_getFinalPrice()} XOF',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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

class _EstimateItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _EstimateItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: highlight ? AppTheme.primaryColor : AppTheme.accentColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark
                  ? AppTheme.backgroundColor.withOpacity(0.3)
                  : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppTheme.secondaryColor
                  : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.secondaryColor
                    : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideModeCard extends StatelessWidget {
  final RideMode mode;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _RideModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : (isDark
                  ? AppTheme.backgroundColor.withOpacity(0.3)
                  : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              mode.icon,
              size: 32,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.grey.shade400 : AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              mode.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode.estimatedPrice,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Arrivée dans ${mode.arrivalTime}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

