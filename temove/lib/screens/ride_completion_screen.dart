import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/models/dynamic_pricing.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/screens/map_screen.dart';

/// Écran de fin de trajet avec récapitulatif
/// 
/// Affiche :
/// - Récapitulatif du trajet (distance, durée, prix)
/// - Note au chauffeur (1-5 étoiles)
/// - Pourboire optionnel
/// - Paiement selon le mode choisi
class RideCompletionScreen extends StatefulWidget {
  final int rideId;
  final int driverId;
  final String driverName;
  final String? driverAvatar;
  final String? driverCar;
  final double distanceKm;
  final int durationMinutes;
  final int finalPrice;
  final String? paymentMethod;
  final DynamicPricing? pricing;

  const RideCompletionScreen({
    super.key,
    required this.rideId,
    required this.driverId,
    required this.driverName,
    this.driverAvatar,
    this.driverCar,
    required this.distanceKm,
    required this.durationMinutes,
    required this.finalPrice,
    this.paymentMethod,
    this.pricing,
  });

  @override
  State<RideCompletionScreen> createState() => _RideCompletionScreenState();
}

class _RideCompletionScreenState extends State<RideCompletionScreen> {
  int _rating = 0;
  double? _tipPercentage;
  final List<double> _tipSuggestions = [0, 5, 10, 15, 20];
  bool _isSubmitting = false;
  String? _ratingComment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppTheme.textPrimary,
                      onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                        (route) => false,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Titre
              Text(
                'Trajet terminé',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci d\'avoir voyagé avec TéMove',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textPrimary.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 32),
              // Récapitulatif du trajet
              _buildTripSummary(),
              const SizedBox(height: 32),
              // Note au chauffeur
              _buildRatingSection(),
              const SizedBox(height: 32),
              // Pourboire
              _buildTipSection(),
              const SizedBox(height: 32),
              // Paiement
              _buildPaymentSection(),
              const SizedBox(height: 32),
              // Bouton de confirmation
              _buildConfirmButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
          ),
          const SizedBox(height: 20),
          // Informations du chauffeur
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: widget.driverAvatar != null
                    ? ClipOval(
                        child: Image.network(
                          widget.driverAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, color: AppTheme.primaryColor),
                        ),
                      )
                    : const Icon(Icons.person, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driverName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    if (widget.driverCar != null)
                      Text(
                        widget.driverCar!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textPrimary.withOpacity(0.7),
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          // Détails du trajet
          _buildSummaryItem(
            icon: Icons.straighten,
            label: 'Distance',
            value: '${widget.distanceKm.toStringAsFixed(1)} km',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            icon: Icons.access_time,
            label: 'Durée',
            value: '${widget.durationMinutes} min',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            icon: Icons.monetization_on,
            label: 'Prix total',
            value: '${widget.finalPrice} XOF',
            highlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary.withOpacity(0.7),
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                color: highlight ? AppTheme.primaryColor : AppTheme.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notez votre chauffeur',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        // Étoiles
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starNumber = index + 1;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _rating = starNumber;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  starNumber <= _rating ? Icons.star : Icons.star_border,
                  size: 48,
                  color: starNumber <= _rating
                      ? AppTheme.primaryColor
                      : AppTheme.grayMedium,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        // Commentaire optionnel
        TextField(
          onChanged: (value) {
            setState(() {
              _ratingComment = value;
            });
          },
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Commentaire (optionnel)',
            filled: true,
            fillColor: AppTheme.backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.grayMedium.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.grayMedium.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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

  Widget _buildTipSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pourboire (optionnel)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Remerciez votre chauffeur avec un pourboire',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textPrimary.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tipSuggestions.map((percentage) {
            final isSelected = _tipPercentage == percentage;
            final tipAmount = percentage == 0
                ? 0
                : ((widget.finalPrice * percentage / 100).round());
            
            return InkWell(
              onTap: () {
                setState(() {
                  _tipPercentage = percentage == 0 ? null : percentage;
                });
              },
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      percentage == 0 ? 'Aucun' : '$percentage%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppTheme.secondaryColor
                                : AppTheme.textPrimary,
                          ),
                    ),
                    if (tipAmount > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$tipAmount XOF',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected
                                  ? AppTheme.secondaryColor.withOpacity(0.8)
                                  : AppTheme.textPrimary.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    final paymentMethodName = widget.paymentMethod ?? 'cash';
    String paymentDisplayName;
    IconData paymentIcon;

    switch (paymentMethodName) {
      case 'om':
        paymentDisplayName = 'Orange Money';
        paymentIcon = Icons.account_balance_wallet;
        break;
      case 'wave':
        paymentDisplayName = 'Wave';
        paymentIcon = Icons.monetization_on;
        break;
      case 'cash':
        paymentDisplayName = 'Espèces';
        paymentIcon = Icons.money;
        break;
      default:
        paymentDisplayName = 'Paiement';
        paymentIcon = Icons.payment;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            paymentIcon,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode de paiement',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  paymentDisplayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          if (paymentMethodName == 'cash')
            ElevatedButton(
              onPressed: () {
                // Confirmer le paiement en espèces
                _submitCompletion();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Confirmer'),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitCompletion,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondaryColor),
                ),
              )
            : Text(
                'Terminer',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
              ),
      ),
    );
  }

  Future<void> _submitCompletion() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez noter votre chauffeur'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Soumettre la note
      if (_rating > 0) {
        await ApiService.submitRating(
          rideId: widget.rideId,
          driverId: widget.driverId,
          rating: _rating,
          comment: _ratingComment,
        );
      }

      // Soumettre le pourboire si présent
      if (_tipPercentage != null && _tipPercentage! > 0) {
        final tipAmount = (widget.finalPrice * _tipPercentage! / 100).round();
        await ApiService.addTip(
          rideId: widget.rideId,
          tipAmount: tipAmount,
        );
      }

      // Confirmer le paiement si nécessaire
      if (widget.paymentMethod != 'cash') {
        await ApiService.confirmPayment(widget.rideId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Merci pour votre voyage avec TéMove !'),
          backgroundColor: AppTheme.successColor,
          duration: Duration(seconds: 2),
        ),
      );

      // Naviguer vers l'écran principal
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
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

