import 'dart:async';
import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/ride_tracking_screen.dart';
import 'package:temove/screens/payment_method_screen.dart';
import 'package:temove/screens/promo_code_screen.dart';
import 'package:temove/widgets/map_placeholder.dart';
import 'package:temove/models/ride_options.dart';
import 'package:temove/models/trip_estimate.dart';
import 'package:temove/models/promo_code.dart';
import 'package:temove/services/location_service.dart';
import 'package:temove/services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  RideCategory _selectedCategory = RideCategory.course;
  RideMode _selectedRideMode = RideMode.confort;
  DeliveryMode _selectedDeliveryMode = DeliveryMode.tiakTiak;
  PaymentMethod? _selectedPaymentMethod = PaymentMethod.om;
  PromoCode? _appliedPromoCode;
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  
  // Positions GPS
  Position? _departurePosition;
  Position? _destinationPosition;
  String? _departureAddress;
  String? _destinationAddress;
  bool _isLoadingDeparture = false;
  bool _isLoadingDestination = false;
  String _destinationText = ''; // Pour suivre le texte de la destination
  String _departureText = ''; // Pour suivre le texte du départ
  Timer? _searchTimer; // Timer pour la recherche en temps réel
  Timer? _departureSearchTimer; // Timer séparé pour la recherche de départ
  
  // Réservation à l'avance
  bool _isScheduled = false;
  DateTime? _scheduledDateTime;
  
  // Estimation du trajet
  TripEstimate? _tripEstimate;
  bool _isCalculatingEstimate = false;
  bool _isCreatingBooking = false;

  @override
  void initState() {
    super.initState();
    _departureController.addListener(_onDepartureChanged);
    _destinationController.addListener(_onDestinationChanged);
    // Obtenir automatiquement la position de départ
    _getCurrentLocationForDeparture();
  }

  Future<void> _getCurrentLocationForDeparture() async {
    setState(() {
      _isLoadingDeparture = true;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      
      if (position != null && mounted) {
        setState(() {
          _departurePosition = position;
          _isLoadingDeparture = false;
        });
        
        // Obtenir l'adresse
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        if (mounted) {
          setState(() {
            // Si l'accuracy est élevée (> 500m), c'est probablement la position par défaut
            if (position.accuracy > 500) {
              _departureAddress = address ?? 'Dakar (position par défaut)';
            } else {
              _departureAddress = address ?? 'Position actuelle';
            }
            _departureController.text = _departureAddress ?? '';
            _departureText = _departureAddress ?? '';
          });
        }
        
        // Recalculer l'estimation si on a aussi une destination
        if (_destinationPosition != null) {
          _calculateEstimate();
        }
      } else {
        // Fallback si vraiment null - utiliser la position par défaut
        final defaultPos = LocationService.getDefaultPosition();
        if (mounted) {
          setState(() {
            _isLoadingDeparture = false;
            _departureAddress = 'Dakar (position par défaut)';
            _departureController.text = 'Dakar';
            _departureText = 'Dakar';
            _departurePosition = defaultPos; // Utiliser la position par défaut
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Utilisation de la position par défaut (Dakar)'),
              duration: Duration(seconds: 2),
            ),
          );
          
          // Recalculer l'estimation si on a aussi une destination
          if (_destinationPosition != null) {
            _calculateEstimate();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Utiliser la position par défaut en cas d'erreur
        final defaultPos = LocationService.getDefaultPosition();
        setState(() {
          _isLoadingDeparture = false;
          _departureAddress = 'Dakar (position par défaut)';
          _departureController.text = 'Dakar';
          _departureText = 'Dakar';
          _departurePosition = defaultPos;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de géolocalisation. Utilisation de la position par défaut (Dakar)'),
            duration: Duration(seconds: 3),
          ),
        );
        
        // Recalculer l'estimation si on a aussi une destination
        if (_destinationPosition != null) {
          _calculateEstimate();
        }
      }
    }
  }

  Future<void> _searchDeparture(String query) async {
    // Vérifier que la query n'est pas vide et a au moins 3 caractères
    if (query.isEmpty || query.trim().length < 3) {
      setState(() {
        _departureAddress = null;
        _departurePosition = null;
        _isLoadingDeparture = false;
      });
      _calculateEstimate();
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoadingDeparture = true;
    });

    try {
      print('Recherche du lieu de départ: ${query.trim()}');
      // Essayer de géocoder l'adresse
      final position = await LocationService.getCoordinatesFromAddress(query.trim());
      
      if (!mounted) return;
      
      if (position != null) {
        print('Position trouvée pour le départ: ${position.latitude}, ${position.longitude}');
        setState(() {
          _departurePosition = position;
          _departureAddress = query.trim();
          _isLoadingDeparture = false;
        });
        
        // Obtenir l'adresse complète (optionnel)
        try {
          final fullAddress = await LocationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
          
          if (mounted && fullAddress != null && fullAddress.isNotEmpty) {
            setState(() {
              _departureAddress = fullAddress;
              if (_departureController.text == query.trim()) {
                _departureController.text = fullAddress;
                _departureText = fullAddress;
              }
            });
          }
        } catch (e) {
          // Ignorer silencieusement
        }
        
        // Recalculer l'estimation si on a aussi une destination
        if (_destinationPosition != null) {
          _calculateEstimate();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDeparture = false;
            if (_departurePosition == null) {
              _departureAddress = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adresse non trouvée. Veuillez réessayer avec une autre adresse.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Erreur lors de la recherche du lieu de départ: $e');
      if (mounted) {
        setState(() {
          _departureAddress = null;
          _departurePosition = null;
          _isLoadingDeparture = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
        _calculateEstimate();
      }
    }
  }

  Future<void> _searchDestination(String query) async {
    // Vérifier que la query n'est pas vide et a au moins 3 caractères
    if (query.isEmpty || query.trim().length < 3) {
      setState(() {
        _destinationAddress = null;
        _destinationPosition = null;
        _isLoadingDestination = false;
      });
      _calculateEstimate();
      return;
    }

    // Vérifier que le widget est toujours monté
    if (!mounted) return;

    setState(() {
      _isLoadingDestination = true;
    });

    try {
      print('Recherche de la destination: ${query.trim()}');
      // Essayer de géocoder l'adresse
      final position = await LocationService.getCoordinatesFromAddress(query.trim());
      
      if (!mounted) return;
      
      if (position != null) {
        print('Position trouvée pour la destination: ${position.latitude}, ${position.longitude}');
        setState(() {
          _destinationPosition = position;
          _destinationAddress = query.trim();
          _isLoadingDestination = false;
        });
        
        // Obtenir l'adresse complète (optionnel, peut échouer)
        try {
          final fullAddress = await LocationService.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          );
          
          if (mounted && fullAddress != null && fullAddress.isNotEmpty) {
            setState(() {
              _destinationAddress = fullAddress;
              // Ne pas modifier le texte si l'utilisateur continue de taper
              if (_destinationController.text == query.trim()) {
                _destinationController.text = fullAddress;
              }
            });
          }
        } catch (e) {
          // Ignorer silencieusement l'erreur du géocodage inversé, on garde l'adresse originale
          // Ne pas afficher pour éviter les logs excessifs
        }
        
        // Recalculer l'estimation
        _calculateEstimate();
      } else {
        if (mounted) {
          setState(() {
            _isLoadingDestination = false;
            // Ne pas effacer la position si elle existe déjà
            if (_destinationPosition == null) {
              _destinationAddress = null;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adresse non trouvée. Veuillez réessayer avec une autre adresse.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Gérer les erreurs avec un message à l'utilisateur
      print('Erreur lors de la recherche de la destination: $e');
      if (mounted) {
        setState(() {
          _destinationAddress = null;
          _destinationPosition = null;
          _isLoadingDestination = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
        _calculateEstimate();
      }
    }
  }

  Future<void> _calculateEstimate() async {
    // Utiliser la position par défaut si aucune position n'est disponible
    Position? departurePos = _departurePosition;
    Position? destinationPos = _destinationPosition;
    
    departurePos ??= LocationService.getDefaultPosition();
    if (destinationPos == null) {
      setState(() {
        _tripEstimate = null;
      });
      return; // Pas de destination, pas d'estimation
    }

    setState(() {
      _isCalculatingEstimate = true;
    });

    try {
      // Appel API pour obtenir l'estimation réelle
      final result = await ApiService.getTripEstimate(
        departureLat: departurePos.latitude,
        departureLng: departurePos.longitude,
        destinationLat: destinationPos.latitude,
        destinationLng: destinationPos.longitude,
        rideMode: _selectedRideMode.name,
      );

      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        // api_service.dart extrait déjà 'estimate' de la réponse du backend
        final data = result['data'] as Map<String, dynamic>;
        
        print('📊 [ESTIMATE] Données reçues du backend: $data');
        
        // Extraire les données de l'API
        final distanceKm = (data['distance_km'] ?? data['distance'] ?? 0).toDouble();
        final durationMinutes = data['duration_minutes'] ?? data['duration'] ?? 0;
        final basePrice = data['base_price'] ?? 0;
        final finalPrice = data['estimated_price'] ?? data['final_price'] ?? data['price'] ?? 0;
        final surgeMultiplier = data['surge_multiplier'] != null 
            ? (data['surge_multiplier'] as num).toDouble() 
            : null;
        
        // Fonctions locales pour formater
        String formatDistance(double km) {
          if (km < 1) {
            return '${(km * 1000).round()} m';
          }
          return '${km.toStringAsFixed(1)} km';
        }
        
        String formatDuration(int minutes) {
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
        
        final durationInt = durationMinutes is int ? durationMinutes : durationMinutes.toInt();
        
        // Créer l'estimation à partir des données de l'API
        print('📊 [ESTIMATE] Création de TripEstimate avec:');
        print('  - distance: $distanceKm km');
        print('  - duration: $durationInt min');
        print('  - basePrice: $basePrice XOF');
        print('  - finalPrice: $finalPrice XOF');
        print('  - surgeMultiplier: $surgeMultiplier');
        
        setState(() {
          _tripEstimate = TripEstimate(
            distance: distanceKm,
            duration: durationInt,
            basePrice: basePrice is int ? basePrice : basePrice.toInt(),
            finalPrice: finalPrice is int ? finalPrice : finalPrice.toInt(),
            formattedDistance: data['formatted_distance'] ?? formatDistance(distanceKm),
            formattedDuration: data['formatted_duration'] ?? formatDuration(durationInt),
            surgeMultiplier: surgeMultiplier,
          );
          
          print('✅ [ESTIMATE] TripEstimate créé et mis à jour dans setState');
          print('  - _tripEstimate.finalPrice: ${_tripEstimate?.finalPrice}');
          print('  - _tripEstimate.formattedDistance: ${_tripEstimate?.formattedDistance}');
        });
      } else {
        // En cas d'erreur API (404, endpoint non trouvé, etc.), utiliser le calcul local comme fallback
        // Ne pas afficher d'erreur à l'utilisateur, utiliser simplement le calcul local
        _calculateEstimateLocal();
      }
    } catch (e) {
      // En cas d'erreur, utiliser le calcul local comme fallback
      if (mounted) {
        _calculateEstimateLocal();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCalculatingEstimate = false;
        });
      }
    }
  }

  void _calculateEstimateLocal() {
    if (_departurePosition == null || _destinationPosition == null) {
      return;
    }

    // Calculer la distance réelle entre départ et destination
    final distanceKm = LocationService.calculateDistanceInKm(
      _departurePosition!.latitude,
      _departurePosition!.longitude,
      _destinationPosition!.latitude,
      _destinationPosition!.longitude,
    );

    // Estimation de la durée (approximation : 30 km/h moyenne)
    final durationMinutes = (distanceKm / 0.5).round(); // 0.5 km/min = 30 km/h

    final basePrice = _selectedRideMode.estimatedPrice.replaceAll(' XOF', '').replaceAll(' ', '');
    final pricePerKm = int.tryParse(basePrice) ?? 2500;
    
    setState(() {
      _tripEstimate = TripEstimate.calculate(
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        basePricePerKm: (pricePerKm / 5).round(), // Approximation
        time: DateTime.now(),
      );
    });
  }

  int _getFinalPrice() {
    int price = _tripEstimate?.finalPrice ?? 2500;
    
    // Appliquer le code promo si présent
    if (_appliedPromoCode != null) {
      price = _appliedPromoCode!.applyDiscount(price);
    }
    
    return price;
  }

  Future<void> _confirmBooking() async {
    // Validation
    if (_departurePosition == null || 
        _destinationPosition == null ||
        _departureAddress == null ||
        _destinationAddress == null ||
        _selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingBooking = true;
    });

    try {
      // Déterminer le mode de transport selon la catégorie
      String rideMode;
      if (_selectedCategory == RideCategory.livraison) {
        // Pour la livraison, utiliser le mode de livraison sélectionné
        rideMode = _selectedDeliveryMode.name;
      } else {
        // Pour les courses, utiliser le mode de transport sélectionné
        rideMode = _selectedRideMode.name;
      }
      
      // Créer la réservation via l'API
      final result = await ApiService.bookRide(
        departureLat: _departurePosition!.latitude,
        departureLng: _departurePosition!.longitude,
        departureAddress: _departureAddress!,
        destinationLat: _destinationPosition!.latitude,
        destinationLng: _destinationPosition!.longitude,
        destinationAddress: _destinationAddress!,
        rideMode: rideMode,
        rideCategory: _selectedCategory.name,
        paymentMethod: _selectedPaymentMethod!.name,
        promoCode: _appliedPromoCode?.code,
        scheduledAt: _isScheduled ? _scheduledDateTime : null,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Afficher un message de succès avec les détails de la réservation
        final rideData = result['ride'];
        final rideId = rideData != null && rideData is Map ? rideData['id'] : null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result['message'] ?? 'Réservation créée avec succès',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (rideId != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('ID de réservation: #$rideId', style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Attendre un peu avant de naviguer pour que l'utilisateur voie le message
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!mounted) return;

        // Extraire les informations du driver depuis la réponse
        // Le driver_id peut être directement dans rideData, ou dans rideData['driver']
        final driverIdFromRide = rideData != null && rideData is Map ? rideData['driver_id'] : null;
        final driverData = rideData != null && rideData is Map ? rideData['driver'] : null;
        
        // Utiliser driver_id directement depuis rideData, ou depuis driver si disponible
        final driverId = driverIdFromRide ?? 
            (driverData != null && driverData is Map ? driverData['id'] : null);
        
        // Extraire les infos du driver si disponible
        final driverName = driverData != null && driverData is Map 
            ? (driverData['name'] ?? driverData['full_name'] ?? 'Chauffeur') 
            : 'Chauffeur';
        final driverCar = driverData != null && driverData is Map 
            ? (driverData['vehicle'] ?? driverData['car'] ?? 'Véhicule') 
            : 'Véhicule';
        final driverAvatar = driverData != null && driverData is Map 
            ? driverData['avatar'] 
            : null;

        // Convertir rideId et driverId en int
        int? rideIdInt;
        if (rideId != null) {
          if (rideId is int) {
            rideIdInt = rideId;
          } else if (rideId is String) {
            rideIdInt = int.tryParse(rideId);
          } else {
            rideIdInt = int.tryParse(rideId.toString());
          }
        }
        
        int? driverIdInt;
        if (driverId != null) {
          if (driverId is int) {
            driverIdInt = driverId;
          } else if (driverId is String) {
            driverIdInt = int.tryParse(driverId);
          } else {
            driverIdInt = int.tryParse(driverId.toString());
          }
        }

        // Extraire les chauffeurs disponibles depuis la réponse
        final availableDrivers = result['available_drivers'] as List<dynamic>? ?? [];
        final rideStatus = result['status'] as String? ?? 'pending';
        
        print('🚗 [BOOK] Navigation vers RideTrackingScreen');
        print('   Ride ID: $rideIdInt');
        print('   Driver ID: $driverIdInt');
        print('   Status: $rideStatus');
        print('   Available drivers: ${availableDrivers.length}');

        // Naviguer vers l'écran de suivi avec les informations
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RideTrackingScreen(
              rideId: rideIdInt,
              driverId: driverIdInt, // null si aucun chauffeur assigné
              driverName: driverName, // null si aucun chauffeur assigné
              driverCar: driverCar, // null si aucun chauffeur assigné
              driverAvatar: driverAvatar,
              availableDrivers: availableDrivers, // Liste des chauffeurs disponibles
            ),
          ),
        );
      } else {
        // Afficher un message d'erreur plus détaillé
        final errorMessage = result['message'] ?? 'Erreur lors de la création de la réservation';
        
        // Si l'endpoint n'existe pas, informer l'utilisateur mais de manière plus claire
        if (errorMessage.contains('Endpoint non trouvé') || errorMessage.contains('404')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'L\'endpoint de réservation n\'est pas encore disponible sur le backend.\n'
                'Voir ENDPOINTS_BACKEND.md pour les instructions de création.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBooking = false;
        });
      }
    }
  }

  void _onDepartureChanged() {
    // Annuler la recherche précédente
    _departureSearchTimer?.cancel();
    
    final query = _departureController.text.trim();
    
    // Mettre à jour le texte pour déclencher un rebuild
    setState(() {
      _departureText = query;
    });
    
    // Si la query est vide ou trop courte, réinitialiser
    if (query.isEmpty || query.length < 3) {
      setState(() {
        _departureAddress = null;
        _departurePosition = null;
        _isLoadingDeparture = false;
      });
      _calculateEstimate();
      return;
    }
    
    // Démarrer la recherche après un délai (debounce de 800ms)
    _departureSearchTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _departureController.text.trim() == query && query.length >= 3) {
        _searchDeparture(query);
      }
    });
  }

  void _onDestinationChanged() {
    // Annuler la recherche précédente
    _searchTimer?.cancel();
    
    final query = _destinationController.text.trim();
    
    // Mettre à jour le texte
    setState(() {
      _destinationText = query;
    });
    
    // Si la query est vide ou trop courte, réinitialiser
    if (query.isEmpty || query.length < 3) {
      setState(() {
        _destinationAddress = null;
        _destinationPosition = null;
        _isLoadingDestination = false;
      });
      _calculateEstimate();
      return;
    }
    
    // Démarrer la recherche après un délai (debounce de 800ms)
    _searchTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _destinationController.text.trim() == query && query.length >= 3) {
        _searchDestination(query);
      }
    });
  }

  Future<void> _showSchedulePicker() async {
    final now = DateTime.now();
    final maxDate = now.add(const Duration(hours: 48));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: maxDate,
      helpText: 'Sélectionner la date',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );
    
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        helpText: 'Sélectionner l\'heure',
        cancelText: 'Annuler',
        confirmText: 'Confirmer',
      );
      
      if (time != null && mounted) {
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

  String _formatDate(DateTime date) {
    final weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _departureSearchTimer?.cancel();
    _departureController.removeListener(_onDepartureChanged);
    _destinationController.removeListener(_onDestinationChanged);
    _departureController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Widget _buildMapWidget() {
    // Utiliser MapPlaceholder avec OpenStreetMap (pas besoin de clé API)
    return const MapPlaceholder(
      showCurrentLocation: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Stack(
        children: [
          // Map ou Placeholder
          _buildMapWidget(),
          // Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppTheme.secondaryColor,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Map Controls
          Positioned(
            right: 16,
            top: 200,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    color: AppTheme.secondaryColor,
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(8),
                    ),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    color: AppTheme.secondaryColor,
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.my_location),
                    color: AppTheme.secondaryColor,
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          // Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            // Location Inputs
                            Text(
                              'Lieu de départ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _departureController,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (value) {
                                _departureSearchTimer?.cancel();
                                if (value.trim().isNotEmpty && value.trim().length >= 3) {
                                  _searchDeparture(value.trim());
                                }
                              },
                              decoration: InputDecoration(
                                hintText: _isLoadingDeparture 
                                    ? 'Chargement de votre position...' 
                                    : 'Tapez une adresse ou utilisez votre position',
                                prefixIcon: _isLoadingDeparture 
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.trip_origin),
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_departureText.trim().isNotEmpty && !_isLoadingDeparture)
                                      IconButton(
                                        icon: const Icon(Icons.search),
                                        onPressed: () {
                                          if (_departureController.text.trim().isNotEmpty) {
                                            _searchDeparture(_departureController.text.trim());
                                          }
                                        },
                                        tooltip: 'Rechercher',
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.my_location),
                                      onPressed: _getCurrentLocationForDeparture,
                                      tooltip: 'Utiliser ma position actuelle',
                                    ),
                                  ],
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.backgroundColor.withOpacity(0.3)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _destinationController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                // Annuler le timer et rechercher immédiatement
                                _searchTimer?.cancel();
                                if (value.trim().isNotEmpty && value.trim().length >= 3) {
                                  _searchDestination(value.trim());
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Tapez une adresse (recherche en temps réel)',
                                prefixIcon: _isLoadingDestination
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Padding(
                                          padding: EdgeInsets.all(12.0),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : const Icon(Icons.location_on),
                                suffixIcon: _destinationText.trim().isNotEmpty
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Bouton de recherche
                                          IconButton(
                                            icon: const Icon(Icons.search),
                                            onPressed: () {
                                              if (_destinationController.text.trim().isNotEmpty) {
                                                _searchDestination(_destinationController.text.trim());
                                              }
                                            },
                                            tooltip: 'Rechercher',
                                          ),
                                          // Bouton de géolocalisation
                                          IconButton(
                                            icon: const Icon(Icons.my_location),
                                            onPressed: () async {
                                              // Utiliser la géolocalisation pour la destination
                                              setState(() {
                                                _isLoadingDestination = true;
                                              });
                                              
                                              final position = await LocationService.getCurrentPosition();
                                              
                                              if (position != null && mounted) {
                                                final address = await LocationService.getAddressFromCoordinates(
                                                  position.latitude,
                                                  position.longitude,
                                                );
                                                
                                                if (mounted) {
                                            setState(() {
                                              _destinationPosition = position;
                                              _destinationAddress = address ?? 'Position actuelle';
                                              _destinationController.text = _destinationAddress ?? '';
                                              _destinationText = _destinationAddress ?? '';
                                              _isLoadingDestination = false;
                                            });
                                                  _calculateEstimate();
                                                }
                                              } else {
                                                if (mounted) {
                                                  setState(() {
                                                    _isLoadingDestination = false;
                                                  });
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Impossible d\'obtenir votre position'),
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            tooltip: 'Utiliser ma position actuelle',
                                          ),
                                        ],
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.my_location),
                                        onPressed: () async {
                                          // Utiliser la géolocalisation pour la destination
                                          setState(() {
                                            _isLoadingDestination = true;
                                          });
                                          
                                          final position = await LocationService.getCurrentPosition();
                                          
                                          if (position != null && mounted) {
                                            final address = await LocationService.getAddressFromCoordinates(
                                              position.latitude,
                                              position.longitude,
                                            );
                                            
                                            if (mounted) {
                                            setState(() {
                                              _destinationPosition = position;
                                              _destinationAddress = address ?? 'Position actuelle';
                                              _destinationController.text = _destinationAddress ?? '';
                                              _destinationText = _destinationAddress ?? '';
                                              _isLoadingDestination = false;
                                            });
                                              _calculateEstimate();
                                            }
                                          } else {
                                            if (mounted) {
                                              setState(() {
                                                _isLoadingDestination = false;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Impossible d\'obtenir votre position'),
                                                  duration: Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        tooltip: 'Utiliser ma position actuelle',
                                      ),
                                filled: true,
                                fillColor: isDark
                                    ? AppTheme.backgroundColor.withOpacity(0.3)
                                    : Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Category Selection (Course / Livraison)
                            Text(
                              'Type de service',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _CategoryChip(
                                    label: 'Course',
                                    icon: Icons.directions_car,
                                    isSelected: _selectedCategory == RideCategory.course,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = RideCategory.course;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _CategoryChip(
                                    label: 'Livraison',
                                    icon: Icons.local_shipping,
                                    isSelected: _selectedCategory == RideCategory.livraison,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategory = RideCategory.livraison;
                                      });
                                    },
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Ride Mode Selection
                            Text(
                              _selectedCategory == RideCategory.livraison 
                                  ? 'Mode de livraison'
                                  : 'Mode de transport',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark 
                                    ? Colors.grey.shade300 
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Afficher les modes de livraison ou les modes de transport selon la catégorie
                            if (_selectedCategory == RideCategory.livraison) ...[
                              // Options de livraison
                              Row(
                                children: [
                                  Expanded(
                                    child: _DeliveryModeCard(
                                      mode: DeliveryMode.tiakTiak,
                                      isSelected: _selectedDeliveryMode == DeliveryMode.tiakTiak,
                                      onTap: () {
                                        setState(() {
                                          _selectedDeliveryMode = DeliveryMode.tiakTiak;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _DeliveryModeCard(
                                      mode: DeliveryMode.voiture,
                                      isSelected: _selectedDeliveryMode == DeliveryMode.voiture,
                                      onTap: () {
                                        setState(() {
                                          _selectedDeliveryMode = DeliveryMode.voiture;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _DeliveryModeCard(
                                      mode: DeliveryMode.express,
                                      isSelected: _selectedDeliveryMode == DeliveryMode.express,
                                      onTap: () {
                                        setState(() {
                                          _selectedDeliveryMode = DeliveryMode.express;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Espace vide pour garder la mise en page
                                  Expanded(child: Container()),
                                ],
                              ),
                            ] else ...[
                              // Options de transport pour les courses
                              Row(
                                children: [
                                  Expanded(
                                    child: _RideModeCard(
                                      mode: RideMode.eco,
                                      isSelected: _selectedRideMode == RideMode.eco,
                                      onTap: () {
                                        setState(() {
                                          _selectedRideMode = RideMode.eco;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RideModeCard(
                                      mode: RideMode.confort,
                                      isSelected: _selectedRideMode == RideMode.confort,
                                      onTap: () {
                                        setState(() {
                                          _selectedRideMode = RideMode.confort;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RideModeCard(
                                      mode: RideMode.confortPlus,
                                      isSelected: _selectedRideMode == RideMode.confortPlus,
                                      onTap: () {
                                        setState(() {
                                          _selectedRideMode = RideMode.confortPlus;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RideModeCard(
                                      mode: RideMode.partageTaxi,
                                      isSelected: _selectedRideMode == RideMode.partageTaxi,
                                      onTap: () {
                                        setState(() {
                                          _selectedRideMode = RideMode.partageTaxi;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _RideModeCard(
                                      mode: RideMode.famille,
                                      isSelected: _selectedRideMode == RideMode.famille,
                                      onTap: () {
                                        setState(() {
                                          _selectedRideMode = RideMode.famille;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _RideModeCard(
                                      mode: RideMode.premium,
                                      isSelected: _selectedRideMode == RideMode.premium,
                                      onTap: () {
                                        setState(() {
                                          _selectedRideMode = RideMode.premium;
                                        });
                                      },
                                      isDark: isDark,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Option de réservation à l'avance
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppTheme.secondaryColor.withOpacity(0.2)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isScheduled
                                      ? AppTheme.primaryColor
                                      : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            color: _isScheduled
                                                ? AppTheme.primaryColor
                                                : (isDark ? AppTheme.textMuted : Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Réserver à l\'avance',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark
                                                      ? AppTheme.textPrimary
                                                      : AppTheme.textSecondary,
                                                ),
                                              ),
                                              if (_isScheduled && _scheduledDateTime != null)
                                                Text(
                                                  '${_formatDate(_scheduledDateTime!)} à ${_formatTime(_scheduledDateTime!)}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.primaryColor,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Switch(
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
                                        activeThumbColor: AppTheme.primaryColor,
                                      ),
                                    ],
                                  ),
                                  if (_isScheduled)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        'Réservation disponible jusqu\'à 48h à l\'avance',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark
                                              ? AppTheme.textMuted
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Trip Estimate
                            if (_isCalculatingEstimate)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accentColor.withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Calcul de l\'estimation...',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.accentColor,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else if (_tripEstimate != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppTheme.accentColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _EstimateItem(
                                      icon: Icons.straighten,
                                      label: 'Distance',
                                      value: _tripEstimate!.formattedDistance,
                                      isDark: isDark,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: AppTheme.accentColor.withOpacity(0.3),
                                    ),
                                    _EstimateItem(
                                      icon: Icons.access_time,
                                      label: 'Durée',
                                      value: _tripEstimate!.formattedDuration,
                                      isDark: isDark,
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: AppTheme.accentColor.withOpacity(0.3),
                                    ),
                                    _EstimateItem(
                                      icon: Icons.monetization_on,
                                      label: 'Prix',
                                      value: '${_getFinalPrice()} XOF',
                                      isDark: isDark,
                                      highlight: true,
                                    ),
                                  ],
                                ),
                              ),
                            if (_tripEstimate?.surgeMultiplier != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.trending_up,
                                      color: AppTheme.warningColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Prix majoré en heures de pointe (${(_tripEstimate!.surgeMultiplier! * 100).toInt()}%)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.warningColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Promo Code
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push<PromoCode>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PromoCodeScreen(
                                      initialCode: _appliedPromoCode?.code,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    _appliedPromoCode = result;
                                    _calculateEstimate();
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.backgroundColor.withOpacity(0.3)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_offer,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Code Promo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppTheme.textPrimary
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (_appliedPromoCode != null) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.successColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _appliedPromoCode!.code,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.successColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Icon(
                                          Icons.chevron_right,
                                          color: isDark
                                              ? AppTheme.textMuted
                                              : Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Payment Method
                            InkWell(
                              onTap: () async {
                                final result = await Navigator.push<PaymentMethod>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PaymentMethodScreen(
                                      selectedMethod: _selectedPaymentMethod,
                                    ),
                                  ),
                                );
                                if (result != null) {
                                  setState(() {
                                    _selectedPaymentMethod = result;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppTheme.backgroundColor.withOpacity(0.3)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.payments,
                                          color: AppTheme.primaryColor,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Méthode de paiement',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: isDark 
                                                ? AppTheme.textPrimary 
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        if (_selectedPaymentMethod != null) ...[
                                          Icon(
                                            _selectedPaymentMethod!.icon,
                                            size: 20,
                                            color: AppTheme.primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _selectedPaymentMethod!.shortName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: isDark 
                                                  ? AppTheme.textPrimary 
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            'Sélectionner',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark 
                                                  ? AppTheme.textMuted 
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.chevron_right,
                                          color: isDark 
                                              ? AppTheme.textMuted 
                                              : Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Confirm Button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: (_isCreatingBooking || 
                                           _departurePosition == null || 
                                           _destinationPosition == null ||
                                           _departureAddress == null ||
                                           _destinationAddress == null ||
                                           _selectedPaymentMethod == null) 
                                    ? null 
                                    : _confirmBooking,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isCreatingBooking
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Confirmer la course',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (_getFinalPrice() != (_tripEstimate?.finalPrice ?? 2500))
                                            Text(
                                              '${_tripEstimate?.finalPrice ?? 2500} XOF → ${_getFinalPrice()} XOF',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EstimateItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool highlight;

  const _EstimateItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: highlight ? AppTheme.primaryColor : AppTheme.accentColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: highlight
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark
                  ? AppTheme.backgroundColor.withOpacity(0.3)
                  : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? AppTheme.secondaryColor
                  : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppTheme.secondaryColor
                    : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RideModeCard extends StatelessWidget {
  final RideMode mode;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _RideModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : (isDark
                  ? AppTheme.backgroundColor.withOpacity(0.3)
                  : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              mode.icon,
              size: 32,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.grey.shade400 : AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              mode.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode.estimatedPrice,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Arrivée dans ${mode.arrivalTime}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryModeCard extends StatelessWidget {
  final DeliveryMode mode;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _DeliveryModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.2)
              : (isDark
                  ? AppTheme.backgroundColor.withOpacity(0.3)
                  : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              mode.icon,
              size: 32,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? Colors.grey.shade400 : AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              mode.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode.estimatedPrice,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Arrivée dans ${mode.arrivalTime}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

