# 🔧 Plan d'Implémentation Technique - Fonctionnalités Prioritaires

## 🎯 Fonctionnalités à Implémenter en Priorité

### 1. 🇸🇳 Support Multi-Langues (Wolof + Français)

#### A. Configuration i18n
```dart
// lib/l10n/app_localizations.dart
class AppLocalizations {
  static const supportedLocales = [
    Locale('fr', 'SN'), // Français Sénégal
    Locale('wo', 'SN'), // Wolof
  ];
  
  // Traductions clés
  static Map<String, Map<String, String>> translations = {
    'fr': {
      'welcome': 'Bienvenue sur TeMove',
      'book_ride': 'Réserver une course',
      // ...
    },
    'wo': {
      'welcome': 'Ñëw ci TeMove',
      'book_ride': 'Tàggal jëf',
      // ...
    },
  };
}
```

#### B. Points de repère en Wolof
```dart
// lib/models/landmarks.dart
class Landmark {
  final String nameFr;
  final String nameWolof; // ✅ Ajouter
  final String? descriptionWolof; // ✅ Ajouter
}

// Exemples
Landmark(
  nameFr: 'Marché Sandaga',
  nameWolof: 'Sandaga',
  descriptionWolof: 'Marché bu mag ci Dakar',
);
```

---

### 2. 💰 Paiement Différé

#### A. Modèle Backend
```python
# models/payment.py - Ajouter
class PaymentMethod(Enum):
    # ... existants
    DEFERRED = 'deferred'  # ✅ Nouveau
    CREDIT = 'credit'      # ✅ Déjà existant

class CreditAccount(db.Model):
    """Compte crédit utilisateur"""
    __tablename__ = 'credit_accounts'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    balance = db.Column(db.Integer, default=0, nullable=False)  # XOF
    credit_limit = db.Column(db.Integer, default=5000, nullable=False)  # XOF
    due_date = db.Column(db.DateTime, nullable=True)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
```

#### B. Frontend
```dart
// lib/models/payment_method.dart
enum PaymentMethod {
  om,
  wave,
  freeMoney,
  carteBancaire,
  cash,
  deferred, // ✅ Nouveau
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.deferred:
        return 'Payer plus tard (7 jours)';
      // ...
    }
  }
  
  String? get description {
    switch (this) {
      case PaymentMethod.deferred:
        return 'Le paiement sera effectué dans 7 jours';
      // ...
    }
  }
}
```

---

### 3. 📅 Réservation à l'Avance

#### A. Backend
```python
# routes/rides.py - Modifier book_ride()
@rides_bp.route('/book', methods=['POST'])
@jwt_required()
def book_ride():
    # ... code existant
    
    scheduled_at = None
    if data.get('scheduled_at'):
        scheduled_at = datetime.fromisoformat(data['scheduled_at'])
        # Vérifier que c'est dans les 48h
        if scheduled_at < datetime.utcnow() + timedelta(hours=48):
            return jsonify({'error': 'Réservation max 48h à l\'avance'}), 400
    
    # Créer la course avec scheduled_at
    ride = Ride(
        # ...
        scheduled_at=scheduled_at,
        status=RideStatus.SCHEDULED if scheduled_at else RideStatus.PENDING,
    )
```

#### B. Frontend
```dart
// lib/screens/booking_screen.dart - Ajouter
DateTime? _scheduledDateTime;
bool _isScheduled = false;

Widget _buildScheduleOption() {
  return SwitchListTile(
    title: const Text('Réserver à l\'avance'),
    subtitle: _isScheduled 
      ? Text('Le ${_formatDate(_scheduledDateTime!)} à ${_formatTime(_scheduledDateTime!)}')
      : const Text('Disponible jusqu\'à 48h à l\'avance'),
    value: _isScheduled,
    onChanged: (value) {
      if (value) {
        _showSchedulePicker();
      } else {
        setState(() {
          _isScheduled = false;
          _scheduledDateTime = null;
        });
      }
    },
  );
}

Future<void> _showSchedulePicker() async {
  final now = DateTime.now();
  final maxDate = now.add(const Duration(hours: 48));
  
  final picked = await showDatePicker(
    context: context,
    initialDate: now,
    firstDate: now,
    lastDate: maxDate,
  );
  
  if (picked != null) {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (time != null) {
      setState(() {
        _scheduledDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          time.hour,
          time.minute,
        );
        _isScheduled = true;
      });
    }
  }
}
```

---

### 4. 🚗 Mode Transport Familial

#### A. Backend
```python
# models/ride.py - Modifier RideMode
class RideMode(Enum):
    ECO = 'eco'
    CONFORT = 'confort'
    CONFORT_PLUS = 'confortPlus'
    PARTAGE_TAXI = 'partageTaxi'
    FAMILLE = 'famille'  # ✅ Nouveau (7-9 places)
    PREMIUM = 'premium'  # ✅ Nouveau (voiture de luxe)
```

#### B. Frontend
```dart
// lib/models/ride_options.dart
enum RideMode {
  eco,
  confort,
  confortPlus,
  partageTaxi,
  famille, // ✅ Nouveau
  premium, // ✅ Nouveau
}

extension RideModeExtension on RideMode {
  String get displayName {
    switch (this) {
      case RideMode.famille:
        return 'Famille (7-9 places)';
      case RideMode.premium:
        return 'Premium';
      // ...
    }
  }
  
  String get description {
    switch (this) {
      case RideMode.famille:
        return 'Idéal pour familles nombreuses ou groupes';
      case RideMode.premium:
        return 'Voiture de luxe avec chauffeur';
      // ...
    }
  }
  
  IconData get icon {
    switch (this) {
      case RideMode.famille:
        return Icons.family_restroom;
      case RideMode.premium:
        return Icons.diamond;
      // ...
    }
  }
}
```

---

### 5. 🎁 Programme de Fidélité Renforcé

#### A. Backend - Cashback
```python
# models/loyalty.py - Ajouter
class LoyaltyTransaction(db.Model):
    """Transaction de fidélité"""
    __tablename__ = 'loyalty_transactions'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    ride_id = db.Column(db.Integer, db.ForeignKey('rides.id'), nullable=True)
    points = db.Column(db.Integer, nullable=False)
    cashback_amount = db.Column(db.Integer, nullable=False)  # XOF
    transaction_type = db.Column(db.String(50), nullable=False)  # 'earned', 'redeemed', 'expired'
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

# services/loyalty_service.py
class LoyaltyService:
    CASHBACK_RATE = 0.05  # 5% cashback
    
    @staticmethod
    def calculate_cashback(ride_price: int) -> int:
        """Calculer le cashback (5%)"""
        return int(ride_price * LoyaltyService.CASHBACK_RATE)
    
    @staticmethod
    def apply_cashback(user_id: int, ride_id: int, ride_price: int):
        """Appliquer le cashback après une course"""
        cashback = LoyaltyService.calculate_cashback(ride_price)
        
        # Créer transaction
        transaction = LoyaltyTransaction(
            user_id=user_id,
            ride_id=ride_id,
            points=0,  # Points séparés
            cashback_amount=cashback,
            transaction_type='earned',
        )
        
        # Ajouter au solde utilisateur
        user = User.query.get(user_id)
        user.cashback_balance += cashback
        
        db.session.add(transaction)
        db.session.commit()
```

#### B. Frontend - Affichage Cashback
```dart
// lib/screens/loyalty_screen.dart - Ajouter
class _LoyaltyScreenState extends State<LoyaltyScreen> {
  int _cashbackBalance = 0;
  
  Widget _buildCashbackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Cashback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_cashbackBalance} XOF',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              '5% de cashback sur chaque course',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Utiliser le cashback
              },
              child: const Text('Utiliser mon cashback'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 6. 🗺️ Navigation Offline

#### A. Cacher les tuiles de carte
```dart
// lib/services/map_cache_service.dart - Nouveau fichier
class MapCacheService {
  static Future<void> cacheMapTiles(LatLng center, double radiusKm) async {
    // Télécharger et cacher les tuiles dans un rayon
    // Utiliser flutter_map avec cache local
  }
  
  static Future<void> preloadDakarMap() async {
    // Précharger les tuiles de Dakar au démarrage
    final dakarCenter = LatLng(14.7167, -17.4677);
    await cacheMapTiles(dakarCenter, 50); // 50 km de rayon
  }
}
```

#### B. Utiliser flutter_map avec cache
```yaml
# pubspec.yaml - Ajouter
dependencies:
  flutter_map: ^7.0.2
  flutter_map_cache: ^0.1.0  # ✅ Pour cache offline
```

---

### 7. 📱 Support Client Intégré

#### A. WhatsApp Business API
```dart
// lib/services/support_service.dart - Nouveau fichier
class SupportService {
  static const String whatsappNumber = '+221XXXXXXXXX'; // Numéro TeMove
  
  static Future<void> openWhatsAppChat() async {
    final url = 'https://wa.me/$whatsappNumber?text=Bonjour, j\'ai besoin d\'aide';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
  
  static Future<void> callSupport() async {
    final url = 'tel:$whatsappNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}
```

---

## 📋 Checklist d'Implémentation

### Phase 1 (Urgent)
- [ ] Support Wolof dans l'interface
- [ ] Paiement différé
- [ ] Réservation à l'avance
- [ ] Mode Transport Familial
- [ ] Cashback 5%

### Phase 2 (Important)
- [ ] Navigation offline
- [ ] Support WhatsApp intégré
- [ ] Points de repère en Wolof
- [ ] Mode Premium
- [ ] Réservation récurrente

### Phase 3 (Nice to have)
- [ ] Intégration taxis traditionnels
- [ ] API entreprises
- [ ] Analyse prédictive
- [ ] Programme ambassadeur

---

## 🚀 Prochaines Étapes

1. **Prioriser les fonctionnalités** selon le budget/temps
2. **Créer les tickets** pour chaque fonctionnalité
3. **Assigner les développeurs** aux tâches
4. **Tester progressivement** chaque fonctionnalité
5. **Déployer par phases** pour minimiser les risques

