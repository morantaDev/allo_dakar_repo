import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/driver_api_service.dart';

class RidesListScreen extends StatefulWidget {
  const RidesListScreen({super.key});

  @override
  State<RidesListScreen> createState() => _RidesListScreenState();
}

class _RidesListScreenState extends State<RidesListScreen> {
  bool _isLoading = true;
  List<dynamic> _availableRides = [];
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRides();
    // Rafraîchir automatiquement la liste toutes les 10 secondes
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    // Rafraîchir toutes les 10 secondes pour voir les nouvelles courses
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isLoading) {
        _loadRides(silent: true); // Rafraîchissement silencieux (pas de loader)
      }
    });
  }

  Future<void> _loadRides({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final result = await DriverApiService.getAvailableRides();
      
      print('📦 [RIDES] Résultat de getAvailableRides: $result');
      
      if (result['success'] == true) {
        // Le format de la réponse peut varier
        List<dynamic> rides = [];
        
        if (result['data'] != null) {
          final data = result['data'];
          if (data is Map<String, dynamic>) {
            // Si c'est un objet avec une clé 'rides'
            rides = data['rides'] as List<dynamic>? ?? [];
            // Sinon, vérifier si c'est directement une liste
            if (rides.isEmpty && data.containsKey('available_rides')) {
              rides = data['available_rides'] as List<dynamic>? ?? [];
            }
          } else if (data is List) {
            // Si c'est directement une liste
            rides = data;
          }
        }
        
        print('📦 [RIDES] Nombre de courses trouvées: ${rides.length}');
        
        // Comparer avec la liste précédente pour détecter les nouvelles courses
        final previousCount = _availableRides.length;
        final newRidesCount = rides.length - previousCount;
        
        if (mounted) {
          setState(() {
            _availableRides = rides;
            _isLoading = false;
          });
          
          // Afficher une notification si de nouvelles courses sont disponibles
          if (silent && newRidesCount > 0 && previousCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$newRidesCount nouvelle${newRidesCount > 1 ? 's' : ''} course${newRidesCount > 1 ? 's' : ''} disponible${newRidesCount > 1 ? 's' : ''}'),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        final errorMsg = result['message'] ?? 'Erreur lors du chargement des courses';
        print('❌ [RIDES] Erreur: $errorMsg');
        setState(() {
          _errorMessage = errorMsg;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ [RIDES] Exception: $e');
      print('❌ [RIDES] Stack trace: $stackTrace');
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRide(int rideId) async {
    // Désactiver temporairement le rafraîchissement automatique pendant l'acceptation
    _refreshTimer?.cancel();
    
    // Afficher un loader pendant l'acceptation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final result = await DriverApiService.acceptRide(rideId);
      
      // Fermer le loader
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (result['success'] == true) {
        if (mounted) {
          // Afficher un message de succès avec les détails du chauffeur
          final data = result['data'] as Map<String, dynamic>?;
          final driver = data?['driver'] as Map<String, dynamic>?;
          
          String message = 'Course acceptée avec succès !';
          if (driver != null) {
            final driverName = driver['full_name'] ?? 'Chauffeur';
            message = 'Course acceptée ! Chauffeur: $driverName';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Recharger la liste pour retirer la course acceptée
          await _loadRides();
          
          // Redémarrer le rafraîchissement automatique
          _startAutoRefresh();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de l\'acceptation'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Redémarrer le rafraîchissement automatique même en cas d'erreur
          _startAutoRefresh();
        }
      }
    } catch (e) {
      // Fermer le loader en cas d'erreur
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Redémarrer le rafraîchissement automatique
        _startAutoRefresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRides,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRides,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _availableRides.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.directions_car_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune course disponible',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les nouvelles demandes apparaîtront ici',
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRides,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _availableRides.length,
                        itemBuilder: (context, index) {
                          final ride = _availableRides[index];
                          return _RideCard(
                            ride: ride,
                            onAccept: () => _acceptRide(ride['id'] as int),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final VoidCallback onAccept;

  const _RideCard({
    required this.ride,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    // Gérer différents formats de données depuis l'API
    // Format 1: pickup/dropoff comme objets
    Map<String, dynamic>? pickup;
    if (ride['pickup'] != null && ride['pickup'] is Map) {
      pickup = ride['pickup'] as Map<String, dynamic>;
    } else if (ride['pickup_address'] != null) {
      // Format 2: pickup_address comme string
      pickup = {'address': ride['pickup_address']};
    }
    
    Map<String, dynamic>? dropoff;
    if (ride['dropoff'] != null && ride['dropoff'] is Map) {
      dropoff = ride['dropoff'] as Map<String, dynamic>;
    } else if (ride['dropoff_address'] != null) {
      // Format 2: dropoff_address comme string
      dropoff = {'address': ride['dropoff_address']};
    }
    
    // Gérer différents noms de champs pour le prix
    final finalPrice = (ride['final_price'] as num?)?.toInt() ?? 
                       (ride['price_xof'] as num?)?.toInt() ?? 
                       (ride['price'] as num?)?.toInt() ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (pickup != null)
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                pickup['address'] as String? ?? 'Départ',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      if (dropoff != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dropoff['address'] as String? ?? 'Destination',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${finalPrice.toString()} F CFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            if (ride['distance_km'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('${ride['distance_km']} km'),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text('${ride['duration_minutes'] ?? 0} min'),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Accepter la course',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

