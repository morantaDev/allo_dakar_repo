import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/driver_api_service.dart';

/// Écran d'historique des courses complétées
class RidesHistoryScreen extends StatefulWidget {
  const RidesHistoryScreen({super.key});

  @override
  State<RidesHistoryScreen> createState() => _RidesHistoryScreenState();
}

class _RidesHistoryScreenState extends State<RidesHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _completedRides = [];
  String? _errorMessage;
  String _selectedPeriod = 'Tout';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mapper la période sélectionnée
      String period = 'all';
      if (_selectedPeriod == 'Aujourd\'hui') {
        period = 'today';
      } else if (_selectedPeriod == 'Cette semaine') {
        period = 'week';
      } else if (_selectedPeriod == 'Ce mois') {
        period = 'month';
      }

      final result = await DriverApiService.getCompletedRides(period: period);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final rides = data?['rides'] as List<dynamic>? ?? [];

        final completedRides = rides.map<Map<String, dynamic>>((ride) {
          return {
            'id': ride['id'] ?? 0,
            'completed_at': ride['completed_at'] ?? DateTime.now().toIso8601String(),
            'pickup_address': ride['pickup_address'] ?? '',
            'dropoff_address': ride['dropoff_address'] ?? '',
            'ride_price': ride['ride_price'] ?? 0,
            'driver_earnings': ride['driver_earnings'] ?? 0,
            'platform_commission': ride['platform_commission'] ?? 0,
            'distance_km': ride['distance_km'] ?? 0.0,
            'duration_minutes': ride['duration_minutes'] ?? 0,
          };
        }).toList();

        setState(() {
          _completedRides = completedRides;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement de l\'historique';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des courses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur de période
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PeriodChip(
                    label: 'Tout',
                    isSelected: _selectedPeriod == 'Tout',
                    onTap: () {
                      setState(() => _selectedPeriod = 'Tout');
                      _loadHistory();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Aujourd\'hui',
                    isSelected: _selectedPeriod == 'Aujourd\'hui',
                    onTap: () {
                      setState(() => _selectedPeriod = 'Aujourd\'hui');
                      _loadHistory();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Cette semaine',
                    isSelected: _selectedPeriod == 'Cette semaine',
                    onTap: () {
                      setState(() => _selectedPeriod = 'Cette semaine');
                      _loadHistory();
                    },
                  ),
                  const SizedBox(width: 8),
                  _PeriodChip(
                    label: 'Ce mois',
                    isSelected: _selectedPeriod == 'Ce mois',
                    onTap: () {
                      setState(() => _selectedPeriod = 'Ce mois');
                      _loadHistory();
                    },
                  ),
                ],
              ),
            ),
          ),
          // Liste des courses
          Expanded(
            child: _isLoading
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadHistory,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _completedRides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune course dans l\'historique',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Les courses complétées apparaîtront ici',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadHistory,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _completedRides.length,
                              itemBuilder: (context, index) {
                                final ride = _completedRides[index];
                                return _RideHistoryCard(
                                  rideId: ride['id'] as int,
                                  completedAt: DateTime.parse(ride['completed_at'] as String),
                                  pickupAddress: ride['pickup_address'] as String,
                                  dropoffAddress: ride['dropoff_address'] as String,
                                  ridePrice: ride['ride_price'] as int,
                                  driverEarnings: ride['driver_earnings'] as int,
                                  distanceKm: (ride['distance_km'] as num?)?.toDouble() ?? 0.0,
                                  durationMinutes: ride['duration_minutes'] as int? ?? 0,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  final int rideId;
  final DateTime completedAt;
  final String pickupAddress;
  final String dropoffAddress;
  final int ridePrice;
  final int driverEarnings;
  final double distanceKm;
  final int durationMinutes;

  const _RideHistoryCard({
    required this.rideId,
    required this.completedAt,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.ridePrice,
    required this.driverEarnings,
    required this.distanceKm,
    required this.durationMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.2),
          child: const Icon(
            Icons.check_circle,
            color: Colors.green,
          ),
        ),
        title: Text(
          'Course #$rideId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(completedAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${driverEarnings.toString()} F CFA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            Text(
              'Net payé',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adresses
                if (pickupAddress.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pickupAddress,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (dropoffAddress.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dropoffAddress,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                // Informations du trajet
                if (distanceKm > 0 || durationMinutes > 0) ...[
                  Row(
                    children: [
                      if (distanceKm > 0) ...[
                        Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (durationMinutes > 0) ...[
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$durationMinutes min',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                ],
                // Détails financiers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Montant total',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${ridePrice.toString()} F CFA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Commission',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${(ridePrice - driverEarnings).toString()} F CFA',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Montant net payé',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      '${driverEarnings.toString()} F CFA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

