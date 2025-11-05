import 'package:flutter/material.dart';

enum RideCategory { course, livraison }

enum RideMode { eco, confort, confortPlus, partageTaxi, famille, premium }

enum DeliveryMode { tiakTiak, voiture, express }

enum PaymentMethod { om, wave, freeMoney, carteBancaire, cash, deferred, emoney }

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
        return 'Covoiturage';
      case RideMode.famille:
        return 'Famille';
      case RideMode.premium:
        return 'Premium';
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
        return 'Partagez un taxi avec d\'autres passagers';
      case RideMode.famille:
        return 'Idéal pour familles nombreuses ou groupes (7-9 places)';
      case RideMode.premium:
        return 'Voiture de luxe avec chauffeur professionnel';
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
      case RideMode.famille:
        return Icons.family_restroom;
      case RideMode.premium:
        return Icons.diamond;
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
      case RideMode.famille:
        return '4500 XOF';
      case RideMode.premium:
        return '6000 XOF';
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
      case RideMode.famille:
        return '5 min';
      case RideMode.premium:
        return '2 min';
    }
  }
}

extension DeliveryModeExtension on DeliveryMode {
  String get displayName {
    switch (this) {
      case DeliveryMode.tiakTiak:
        return 'Tiak tiak (moto)';
      case DeliveryMode.voiture:
        return 'Voiture';
      case DeliveryMode.express:
        return 'Express';
    }
  }

  String get description {
    switch (this) {
      case DeliveryMode.tiakTiak:
        return 'Livraison rapide en moto';
      case DeliveryMode.voiture:
        return 'Livraison standard en voiture';
      case DeliveryMode.express:
        return 'Livraison express < 30 min';
    }
  }

  IconData get icon {
    switch (this) {
      case DeliveryMode.tiakTiak:
        return Icons.two_wheeler;
      case DeliveryMode.voiture:
        return Icons.local_shipping;
      case DeliveryMode.express:
        return Icons.flash_on;
    }
  }

  String get estimatedPrice {
    switch (this) {
      case DeliveryMode.tiakTiak:
        return '1000 XOF';
      case DeliveryMode.voiture:
        return '2000 XOF';
      case DeliveryMode.express:
        return '3000 XOF';
    }
  }

  String get arrivalTime {
    switch (this) {
      case DeliveryMode.tiakTiak:
        return '2 min';
      case DeliveryMode.voiture:
        return '5 min';
      case DeliveryMode.express:
        return '1 min';
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
      case PaymentMethod.deferred:
        return 'Payer plus tard';
      case PaymentMethod.emoney:
        return 'eMoney (Expresso)';
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
      case PaymentMethod.deferred:
        return Icons.access_time;
      case PaymentMethod.emoney:
        return Icons.mobile_off;
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
      case PaymentMethod.deferred:
        return 'Plus tard';
      case PaymentMethod.emoney:
        return 'eMoney';
    }
  }
  
  String? get description {
    switch (this) {
      case PaymentMethod.deferred:
        return 'Payer dans 7 jours';
      case PaymentMethod.emoney:
        return 'Porte-monnaie Expresso';
      default:
        return null;
    }
  }
}

