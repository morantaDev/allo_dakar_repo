import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';

/// Modèle pour le calcul dynamique du prix
class DynamicPricing {
  final double basePricePerKm;
  final double baseFare;
  final double distanceKm;
  final int durationMinutes;
  final double surgeMultiplier;
  final double waitingTimeMultiplier;
  final bool isPeakHours;
  final bool isHighDemand;
  final bool isBadWeather;
  final int waitingMinutes;
  final double? tipPercentage;
  final double? modeMultiplier; // Coefficient du mode de transport

  DynamicPricing({
    required this.basePricePerKm,
    this.baseFare = 500,
    required this.distanceKm,
    required this.durationMinutes,
    this.surgeMultiplier = 1.0,
    this.waitingTimeMultiplier = 1.0,
    this.isPeakHours = false,
    this.isHighDemand = false,
    this.isBadWeather = false,
    this.waitingMinutes = 0,
    this.tipPercentage,
    this.modeMultiplier, // Coefficient du mode (ex: 1.0, 1.2, 1.5, 0.8)
  });

  /// Calculer le prix de base (distance + temps)
  int get basePrice {
    final distancePrice = (distanceKm * basePricePerKm).round();
    final timePrice = (durationMinutes * 50).round(); // 50 XOF par minute
    return (baseFare + distancePrice + timePrice).round();
  }

  /// Calculer le multiplicateur de surcharge total
  double get totalSurgeMultiplier {
    double multiplier = 1.0;
    
    // Heures de pointe : +20%
    if (isPeakHours) multiplier += 0.2;
    
    // Forte demande : +30%
    if (isHighDemand) multiplier += 0.3;
    
    // Mauvais temps : +15%
    if (isBadWeather) multiplier += 0.15;
    
    // Multiplicateur de surcharge personnalisé
    multiplier *= surgeMultiplier;
    
    return multiplier;
  }

  /// Calculer le coût d'attente
  int get waitingCost {
    if (waitingMinutes <= 5) return 0; // Gratuit les 5 premières minutes
    final extraMinutes = waitingMinutes - 5;
    return (extraMinutes * 100).round(); // 100 XOF par minute supplémentaire
  }

  /// Prix final avant pourboire
  int get finalPriceBeforeTip {
    final base = basePrice;
    final withSurge = (base * totalSurgeMultiplier).round();
    final withWaiting = withSurge + waitingCost;
    // Appliquer le coefficient du mode si présent
    if (modeMultiplier != null) {
      return (withWaiting * modeMultiplier!).round();
    }
    return withWaiting;
  }

  /// Prix final avec pourboire
  int get finalPrice {
    if (tipPercentage == null) return finalPriceBeforeTip;
    final tipAmount = (finalPriceBeforeTip * tipPercentage! / 100).round();
    return finalPriceBeforeTip + tipAmount;
  }

  /// Montant du pourboire
  int get tipAmount {
    if (tipPercentage == null) return 0;
    return (finalPriceBeforeTip * tipPercentage! / 100).round();
  }

  /// Liste des facteurs influençant le prix
  List<PricingFactor> get pricingFactors {
    final factors = <PricingFactor>[];
    
    // Distance
    factors.add(PricingFactor(
      label: 'Distance',
      value: '${distanceKm.toStringAsFixed(1)} km',
      impact: '+${basePrice.toStringAsFixed(0)} XOF',
      icon: Icons.straighten,
      color: AppTheme.accentColor,
    ));
    
    // Durée
    factors.add(PricingFactor(
      label: 'Durée estimée',
      value: '$durationMinutes min',
      impact: null,
      icon: Icons.access_time,
      color: AppTheme.accentColor,
    ));
    
    // Heures de pointe
    if (isPeakHours) {
      factors.add(PricingFactor(
        label: 'Heures de pointe',
        value: '+20%',
        impact: '+${((basePrice * 0.2).round()).toStringAsFixed(0)} XOF',
        icon: Icons.trending_up,
        color: AppTheme.warningColor,
      ));
    }
    
    // Forte demande
    if (isHighDemand) {
      factors.add(PricingFactor(
        label: 'Forte demande',
        value: '+30%',
        impact: '+${((basePrice * 0.3).round()).toStringAsFixed(0)} XOF',
        icon: Icons.people,
        color: AppTheme.warningColor,
      ));
    }
    
    // Mauvais temps
    if (isBadWeather) {
      factors.add(PricingFactor(
        label: 'Conditions météo',
        value: '+15%',
        impact: '+${((basePrice * 0.15).round()).toStringAsFixed(0)} XOF',
        icon: Icons.cloud,
        color: AppTheme.infoColor,
      ));
    }
    
    // Surcharge personnalisée
    if (surgeMultiplier > 1.0) {
      factors.add(PricingFactor(
        label: 'Surcharge dynamique',
        value: '${(surgeMultiplier * 100).toStringAsFixed(0)}%',
        impact: '+${((basePrice * (surgeMultiplier - 1.0)).round()).toStringAsFixed(0)} XOF',
        icon: Icons.local_fire_department,
        color: AppTheme.errorColor,
      ));
    }
    
    // Temps d'attente
    if (waitingMinutes > 5) {
      factors.add(PricingFactor(
        label: 'Temps d\'attente',
        value: '$waitingMinutes min',
        impact: '+$waitingCost XOF',
        icon: Icons.timer,
        color: AppTheme.warningColor,
      ));
    }
    
    // Pourboire
    if (tipPercentage != null && tipPercentage! > 0) {
      factors.add(PricingFactor(
        label: 'Pourboire',
        value: '${tipPercentage!.toStringAsFixed(0)}%',
        impact: '+$tipAmount XOF',
        icon: Icons.volunteer_activism,
        color: AppTheme.successColor,
      ));
    }
    
    return factors;
  }

  /// Créer une instance depuis les données de l'API
  factory DynamicPricing.fromApiData(
    Map<String, dynamic> data, {
    double? tipPercentage,
    int waitingMinutes = 0,
    double? modeMultiplier,
  }) {
    final distanceKm = (data['distance_km'] ?? data['distance'] ?? 0).toDouble();
    final durationMinutes = data['duration_minutes'] ?? data['duration'] ?? 0;
    final basePricePerKm = (data['base_price_per_km'] ?? 300).toDouble();
    final surgeMultiplier = (data['surge_multiplier'] ?? 1.0).toDouble();
    
    // Détecter les conditions
    final now = DateTime.now();
    final hour = now.hour;
    final isPeakHours = (hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19);
    final isHighDemand = surgeMultiplier > 1.2;
    final isBadWeather = data['bad_weather'] == true;
    
    return DynamicPricing(
      basePricePerKm: basePricePerKm,
      baseFare: (data['base_fare'] ?? 500).toDouble(),
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      surgeMultiplier: surgeMultiplier,
      isPeakHours: isPeakHours,
      isHighDemand: isHighDemand,
      isBadWeather: isBadWeather,
      waitingMinutes: waitingMinutes,
      tipPercentage: tipPercentage,
      modeMultiplier: modeMultiplier,
    );
  }
}

/// Facteur influençant le prix
class PricingFactor {
  final String label;
  final String value;
  final String? impact;
  final IconData icon;
  final Color color;

  const PricingFactor({
    required this.label,
    required this.value,
    this.impact,
    required this.icon,
    required this.color,
  });
}

