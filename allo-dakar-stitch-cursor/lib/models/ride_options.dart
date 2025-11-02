import 'package:flutter/material.dart';

enum RideCategory { course, livraison }

enum RideMode { eco, confort, confortPlus, partageTaxi }

enum PaymentMethod { om, wave, freeMoney, carteBancaire, cash }

extension RideModeExtension on RideMode {
  String get displayName {
    switch (this) {
      case RideMode.eco:
        return 'Éco';
      case RideMode.confort:
        return 'Confort';
      case RideMode.confortPlus:
        return 'Confort+';
      case RideMode.partageTaxi:
        return 'Partage Taxi';
    }
  }

  String get description {
    switch (this) {
      case RideMode.eco:
        return 'Option économique';
      case RideMode.confort:
        return 'Confort standard';
      case RideMode.confortPlus:
        return 'Haute qualité';
      case RideMode.partageTaxi:
        return 'Partage de course';
    }
  }

  IconData get icon {
    switch (this) {
      case RideMode.eco:
        return Icons.electric_car;
      case RideMode.confort:
        return Icons.directions_car;
      case RideMode.confortPlus:
        return Icons.workspace_premium;
      case RideMode.partageTaxi:
        return Icons.people;
    }
  }

  String get estimatedPrice {
    switch (this) {
      case RideMode.eco:
        return '1500 XOF';
      case RideMode.confort:
        return '2500 XOF';
      case RideMode.confortPlus:
        return '4000 XOF';
      case RideMode.partageTaxi:
        return '1200 XOF';
    }
  }

  String get arrivalTime {
    switch (this) {
      case RideMode.eco:
        return '3 min';
      case RideMode.confort:
        return '5 min';
      case RideMode.confortPlus:
        return '3 min';
      case RideMode.partageTaxi:
        return '7 min';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.om:
        return 'Orange Money';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.freeMoney:
        return 'Free Money';
      case PaymentMethod.carteBancaire:
        return 'Carte Bancaire';
      case PaymentMethod.cash:
        return 'Espèces';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.om:
        return Icons.account_balance_wallet;
      case PaymentMethod.wave:
        return Icons.monetization_on;
      case PaymentMethod.freeMoney:
        return Icons.payment;
      case PaymentMethod.carteBancaire:
        return Icons.credit_card;
      case PaymentMethod.cash:
        return Icons.money;
    }
  }

  String get shortName {
    switch (this) {
      case PaymentMethod.om:
        return 'OM';
      case PaymentMethod.wave:
        return 'Wave';
      case PaymentMethod.freeMoney:
        return 'Free Money';
      case PaymentMethod.carteBancaire:
        return 'CB';
      case PaymentMethod.cash:
        return 'Espèces';
    }
  }
}

