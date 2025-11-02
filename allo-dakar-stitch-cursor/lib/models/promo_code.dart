class PromoCode {
  final String code;
  final String description;
  final PromoType type;
  final double value; // pourcentage ou montant fixe
  final DateTime? expiryDate;
  final int? maxUses;
  final int currentUses;

  PromoCode({
    required this.code,
    required this.description,
    required this.type,
    required this.value,
    this.expiryDate,
    this.maxUses,
    this.currentUses = 0,
  });

  bool get isValid {
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) {
      return false;
    }
    if (maxUses != null && currentUses >= maxUses!) {
      return false;
    }
    return true;
  }

  int calculateDiscount(int originalPrice) {
    if (!isValid) return 0;

    switch (type) {
      case PromoType.percentage:
        return (originalPrice * value / 100).round();
      case PromoType.fixedAmount:
        return value.round();
    }
  }

  int applyDiscount(int originalPrice) {
    final discount = calculateDiscount(originalPrice);
    return (originalPrice - discount).clamp(0, double.infinity).toInt();
  }

  static final List<PromoCode> sampleCodes = [
    PromoCode(
      code: 'BIENVENUE10',
      description: '10% de réduction sur votre première course',
      type: PromoType.percentage,
      value: 10,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
    ),
    PromoCode(
      code: 'DAKAR500',
      description: '500 XOF de réduction',
      type: PromoType.fixedAmount,
      value: 500,
      expiryDate: DateTime.now().add(const Duration(days: 7)),
      maxUses: 1000,
    ),
    PromoCode(
      code: 'WEEKEND20',
      description: '20% de réduction ce week-end',
      type: PromoType.percentage,
      value: 20,
      expiryDate: DateTime.now().add(const Duration(days: 2)),
    ),
  ];
}

enum PromoType { percentage, fixedAmount }

