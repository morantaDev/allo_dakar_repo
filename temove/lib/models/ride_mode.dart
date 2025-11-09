import 'package:flutter/material.dart';

/// Modèle pour les modes de transport avec tarifs dynamiques
class RideModeData {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final double priceMultiplier; // Coefficient de tarification (ex: 1.0, 1.2, 1.5, 0.8)
  final String estimatedArrival; // Temps d'arrivée estimé (ex: "5 min")
  final IconData icon;
  final Color color;
  final List<String> features; // Caractéristiques du mode

  const RideModeData({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    required this.priceMultiplier,
    required this.estimatedArrival,
    required this.icon,
    required this.color,
    this.features = const [],
  });

  /// Calculer le prix à partir d'un prix de base
  /// [basePrice] : Prix de base en XOF (calculé selon la distance, durée, etc.)
  int calculatePrice(int basePrice) {
    return (basePrice * priceMultiplier).round();
  }

  /// Obtenir le prix pour une distance et durée données
  /// [distanceKm] : Distance en kilomètres
  /// [durationMinutes] : Durée en minutes
  /// [basePricePerKm] : Prix de base par kilomètre (par défaut 300 XOF/km)
  /// [baseFare] : Prix de base fixe (par défaut 500 XOF)
  int getPriceForTrip({
    double distanceKm = 5.0, // Distance par défaut (5 km)
    int durationMinutes = 15, // Durée par défaut (15 min)
    double basePricePerKm = 300.0, // Prix par km
    double baseFare = 500.0, // Prix de base fixe
  }) {
    // Calcul du prix de base : prix fixe + (distance × prix/km) + (durée × prix/min)
    final pricePerMinute = 50.0; // 50 XOF par minute
    final basePrice = (baseFare + (distanceKm * basePricePerKm) + (durationMinutes * pricePerMinute)).round();
    
    // Appliquer le coefficient du mode
    return calculatePrice(basePrice);
  }

  /// Formater le prix avec devise
  String formattedPrice({int? basePrice}) {
    final price = basePrice != null ? calculatePrice(basePrice) : getPriceForTrip();
    return '$price XOF';
  }

  /// Formater le prix de manière compacte
  String compactPrice({int? basePrice}) {
    final price = basePrice != null ? calculatePrice(basePrice) : getPriceForTrip();
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k XOF';
    }
    return '$price XOF';
  }

  /// Description du coefficient (pour affichage)
  String get multiplierDescription {
    if (priceMultiplier == 1.0) {
      return 'Prix standard';
    } else if (priceMultiplier > 1.0) {
      return '+${((priceMultiplier - 1.0) * 100).toStringAsFixed(0)}%';
    } else {
      return '${((priceMultiplier - 1.0) * 100).toStringAsFixed(0)}%';
    }
  }
}

/// Modes de transport disponibles pour TéMove Client
class RideModes {
  /// Éco : Coefficient x1.0 (prix standard)
  static const eco = RideModeData(
    id: 'eco',
    name: 'eco',
    displayName: 'Éco',
    description: 'Option économique',
    priceMultiplier: 1.0, // Prix standard
    estimatedArrival: '3 min',
    icon: Icons.electric_car,
    color: Color(0xFF00C897), // Vert
    features: ['Économique', 'Rapide'],
  );

  /// Confort : Coefficient x1.2 (+20%)
  static const confort = RideModeData(
    id: 'confort',
    name: 'confort',
    displayName: 'Confort',
    description: 'Confort standard',
    priceMultiplier: 1.2, // +20%
    estimatedArrival: '5 min',
    icon: Icons.directions_car,
    color: Color(0xFFFFD60A), // Jaune TéMove
    features: ['Confortable', 'Climatisé'],
  );

  /// Confort+ : Coefficient x1.5 (+50%)
  static const confortPlus = RideModeData(
    id: 'confortPlus',
    name: 'confortPlus',
    displayName: 'Confort+',
    description: 'Haute qualité',
    priceMultiplier: 1.5, // +50%
    estimatedArrival: '3 min',
    icon: Icons.workspace_premium,
    color: Color(0xFFFFD60A), // Jaune TéMove
    features: ['Premium', 'Véhicule récent'],
  );

  /// Covoiturage : Coefficient x0.8 (-20%)
  static const covoiturage = RideModeData(
    id: 'partageTaxi',
    name: 'partageTaxi',
    displayName: 'Covoiturage',
    description: 'Partagez un taxi avec d\'autres passagers',
    priceMultiplier: 0.8, // -20%
    estimatedArrival: '7 min',
    icon: Icons.people,
    color: Color(0xFF00C897), // Vert
    features: ['Économique', 'Écologique'],
  );

  /// Liste de tous les modes disponibles
  static const List<RideModeData> all = [
    eco,
    confort,
    confortPlus,
    covoiturage,
  ];

  /// Obtenir un mode par son ID
  static RideModeData? getById(String id) {
    try {
      return all.firstWhere((mode) => mode.id == id);
    } catch (e) {
      return null;
    }
  }
}

