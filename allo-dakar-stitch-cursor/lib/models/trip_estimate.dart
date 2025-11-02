class TripEstimate {
  final double distance; // en kilomètres
  final int duration; // en minutes
  final int basePrice; // prix de base en XOF
  final int finalPrice; // prix final avec variations
  final String formattedDistance;
  final String formattedDuration;
  final double? surgeMultiplier; // multiplicateur de prix (ex: 1.5x en heures de pointe)

  TripEstimate({
    required this.distance,
    required this.duration,
    required this.basePrice,
    required this.finalPrice,
    required this.formattedDistance,
    required this.formattedDuration,
    this.surgeMultiplier,
  });

  static TripEstimate calculate({
    required double distanceKm,
    required int durationMinutes,
    required int basePricePerKm,
    DateTime? time,
  }) {
    // Calcul du prix de base
    int basePrice = (distanceKm * basePricePerKm).round();
    
    // Prix dynamique selon l'heure (surge pricing)
    double surgeMultiplier = _calculateSurgeMultiplier(time ?? DateTime.now());
    int finalPrice = (basePrice * surgeMultiplier).round();

    return TripEstimate(
      distance: distanceKm,
      duration: durationMinutes,
      basePrice: basePrice,
      finalPrice: finalPrice,
      formattedDistance: _formatDistance(distanceKm),
      formattedDuration: _formatDuration(durationMinutes),
      surgeMultiplier: surgeMultiplier > 1.0 ? surgeMultiplier : null,
    );
  }

  static double _calculateSurgeMultiplier(DateTime time) {
    final hour = time.hour;
    final dayOfWeek = time.weekday;

    // Heures de pointe (7-9h et 17-19h)
    if ((hour >= 7 && hour < 9) || (hour >= 17 && hour < 19)) {
      return 1.5; // +50%
    }

    // Vendredi soir et week-end
    if (dayOfWeek == 5 && hour >= 18) {
      return 1.4; // +40%
    }
    if (dayOfWeek >= 6) {
      return 1.3; // +30%
    }

    // Nuit (22h - 6h)
    if (hour >= 22 || hour < 6) {
      return 1.2; // +20%
    }

    // Prix normal
    return 1.0;
  }

  static String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours h';
    }
    return '$hours h $mins';
  }
}

