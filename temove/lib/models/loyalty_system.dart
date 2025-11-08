class UserLoyalty {
  final int points;
  final int level;
  final List<UserBadge> badges;
  final int totalRides;
  final double totalSpent;

  UserLoyalty({
    this.points = 0,
    this.level = 1,
    this.badges = const [],
    this.totalRides = 0,
    this.totalSpent = 0.0,
  });

  int get pointsToNextLevel {
    return level * 100 - points;
  }

  double get levelProgress {
    if (level == 1) return points / 100;
    final currentLevelPoints = (level - 1) * 100;
    final nextLevelPoints = level * 100;
    return (points - currentLevelPoints) / (nextLevelPoints - currentLevelPoints);
  }

  String get levelName {
    if (level >= 5) return 'VIP Gold';
    if (level >= 3) return 'VIP Silver';
    if (level >= 2) return 'VIP Bronze';
    return 'Membre';
  }

  UserLoyalty addPoints(int pointsEarned) {
    final newPoints = points + pointsEarned;
    final newLevel = _calculateLevel(newPoints);
    
    return UserLoyalty(
      points: newPoints,
      level: newLevel,
      badges: badges,
      totalRides: totalRides + 1,
      totalSpent: totalSpent,
    );
  }

  int _calculateLevel(int totalPoints) {
    if (totalPoints < 100) return 1;
    if (totalPoints < 300) return 2;
    if (totalPoints < 600) return 3;
    if (totalPoints < 1000) return 4;
    return 5;
  }
}

enum BadgeType {
  firstRide,
  tenRides,
  fiftyRides,
  hundredRides,
  nightOwl,
  earlyBird,
  loyalCustomer,
  bigSpender,
}

class UserBadge {
  final BadgeType type;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedDate;

  UserBadge({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedDate,
  });

  static UserBadge fromType(BadgeType type) {
    switch (type) {
      case BadgeType.firstRide:
        return UserBadge(
          type: type,
          name: 'Première Course',
          description: 'Vous avez effectué votre première course',
          icon: '🎉',
          earnedDate: DateTime.now(),
        );
      case BadgeType.tenRides:
        return UserBadge(
          type: type,
          name: 'Débutant',
          description: '10 courses effectuées',
          icon: '⭐',
          earnedDate: DateTime.now(),
        );
      case BadgeType.fiftyRides:
        return UserBadge(
          type: type,
          name: 'Régulier',
          description: '50 courses effectuées',
          icon: '🏆',
          earnedDate: DateTime.now(),
        );
      case BadgeType.hundredRides:
        return UserBadge(
          type: type,
          name: 'Expert',
          description: '100 courses effectuées',
          icon: '👑',
          earnedDate: DateTime.now(),
        );
      case BadgeType.nightOwl:
        return UserBadge(
          type: type,
          name: 'Oiseau de Nuit',
          description: 'Plus de 10 courses après 22h',
          icon: '🦉',
          earnedDate: DateTime.now(),
        );
      case BadgeType.earlyBird:
        return UserBadge(
          type: type,
          name: 'Lève-tôt',
          description: 'Plus de 10 courses avant 7h',
          icon: '🌅',
          earnedDate: DateTime.now(),
        );
      case BadgeType.loyalCustomer:
        return UserBadge(
          type: type,
          name: 'Client Fidèle',
          description: 'Utilisateur depuis plus de 6 mois',
          icon: '💎',
          earnedDate: DateTime.now(),
        );
      case BadgeType.bigSpender:
        return UserBadge(
          type: type,
          name: 'Grand Voyageur',
          description: 'Plus de 100,000 XOF dépensés',
          icon: '💳',
          earnedDate: DateTime.now(),
        );
    }
  }
}

