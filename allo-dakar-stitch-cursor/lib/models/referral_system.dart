/// Système de parrainage et références
class ReferralCode {
  final String code;
  final String userId;
  final DateTime createdAt;
  final int uses;
  final int maxUses;
  final int creditAmount; // XOF

  ReferralCode({
    required this.code,
    required this.userId,
    required this.createdAt,
    this.uses = 0,
    this.maxUses = 10,
    this.creditAmount = 1000,
  });

  bool get isValid => uses < maxUses;

  String get shareMessage {
    return '''
Rejoignez Allo Dakar avec mon code de parrainage : $code
Obtenez $creditAmount XOF de crédit gratuit sur votre première course !

Téléchargez l'app et utilisez ce code lors de l'inscription.
''';
  }
}

class ReferralReward {
  final String referrerId; // Celui qui parraine
  final String referredId; // Celui qui est parrainé
  final int referrerReward; // Crédit pour le parrain
  final int referredReward; // Crédit pour le parrainé
  final DateTime rewardedAt;
  final bool bothRideCompleted; // Les deux doivent faire une course pour activer

  ReferralReward({
    required this.referrerId,
    required this.referredId,
    required this.referrerReward,
    required this.referredReward,
    required this.rewardedAt,
    this.bothRideCompleted = false,
  });
}

/// Crédit utilisateur
class UserCredit {
  final String userId;
  final int totalCredit; // XOF
  final List<CreditTransaction> transactions;

  UserCredit({
    required this.userId,
    this.totalCredit = 0,
    this.transactions = const [],
  });

  UserCredit addCredit(int amount, String source) {
    final newTransaction = CreditTransaction(
      amount: amount,
      source: source,
      timestamp: DateTime.now(),
    );
    return UserCredit(
      userId: userId,
      totalCredit: totalCredit + amount,
      transactions: [...transactions, newTransaction],
    );
  }

  UserCredit useCredit(int amount) {
    if (amount > totalCredit) {
      throw Exception('Crédit insuffisant');
    }
    final transaction = CreditTransaction(
      amount: -amount,
      source: 'Course',
      timestamp: DateTime.now(),
    );
    return UserCredit(
      userId: userId,
      totalCredit: totalCredit - amount,
      transactions: [...transactions, transaction],
    );
  }
}

class CreditTransaction {
  final int amount;
  final String source;
  final DateTime timestamp;

  CreditTransaction({
    required this.amount,
    required this.source,
    required this.timestamp,
  });
}
