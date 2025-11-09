import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/driver_api_service.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedPeriod = 'Aujourd\'hui';
  double _totalEarnings = 0.0;
  int _totalRides = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }


  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mapper la période sélectionnée vers le paramètre API
      String period = 'all';
      if (_selectedPeriod == 'Aujourd\'hui') {
        period = 'today';
      } else if (_selectedPeriod == 'Cette semaine') {
        period = 'week';
      } else if (_selectedPeriod == 'Ce mois') {
        period = 'month';
      }

      // Appeler l'API pour récupérer les courses complétées avec commissions
      final result = await DriverApiService.getCompletedRides(period: period);

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final rides = data?['rides'] as List<dynamic>? ?? [];
        final summary = data?['summary'] as Map<String, dynamic>? ?? {};

        // Convertir les courses en transactions
        final transactions = rides.map<Map<String, dynamic>>((ride) {
          return {
            'ride_id': ride['id'] ?? 0,
            'date': ride['completed_at'] ?? DateTime.now().toIso8601String(),
            'ride_price': ride['ride_price'] ?? 0,
            'platform_commission': ride['platform_commission'] ?? 0,
            'driver_earnings': ride['driver_earnings'] ?? 0,
            'service_fee': ride['service_fee'] ?? 0,
            'commission_rate': ride['commission_rate'] ?? 0.0,
            'pickup_address': ride['pickup_address'] ?? '',
            'dropoff_address': ride['dropoff_address'] ?? '',
          };
        }).toList();

        setState(() {
          _totalEarnings = (summary['total_earnings'] as num?)?.toDouble() ?? 0.0;
          _totalRides = summary['total_rides'] as int? ?? 0;
          _transactions = transactions;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement des revenus';
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

  // Méthode publique pour recharger les données (accessible depuis l'extérieur)
  void reload() {
    if (mounted) {
      _loadEarnings();
    }
  }
  
  // Getter pour exposer la méthode de chargement (pour compatibilité)
  void Function() get loadEarnings => _loadEarnings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenus'),
      ),
      body: Column(
        children: [
          // Sélecteur de période
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _PeriodChip(
                  label: 'Aujourd\'hui',
                  isSelected: _selectedPeriod == 'Aujourd\'hui',
                  onTap: () {
                    setState(() => _selectedPeriod = 'Aujourd\'hui');
                    _loadEarnings();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Cette semaine',
                  isSelected: _selectedPeriod == 'Cette semaine',
                  onTap: () {
                    setState(() => _selectedPeriod = 'Cette semaine');
                    _loadEarnings();
                  },
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Ce mois',
                  isSelected: _selectedPeriod == 'Ce mois',
                  onTap: () {
                    setState(() => _selectedPeriod = 'Ce mois');
                    _loadEarnings();
                  },
                ),
              ],
            ),
          ),
          
          // Montant total
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Column(
                    children: [
                      Text(
                        'Total gagné',
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _totalEarnings > 0
                            ? '${_totalEarnings.toStringAsFixed(0)} F CFA'
                            : '0 F CFA',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _EarningStat(
                            label: 'Courses',
                            value: '$_totalRides',
                            icon: Icons.directions_car,
                          ),
                          _EarningStat(
                            label: 'Moyenne',
                            value: _totalRides > 0
                                ? '${(_totalEarnings / _totalRides).toStringAsFixed(0)} F CFA'
                                : '0 F CFA',
                            icon: Icons.trending_up,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          
          // Liste des transactions
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
                              onPressed: _loadEarnings,
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun revenu pour le moment',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Commencez à accepter des courses\npour voir vos revenus ici',
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
                            onRefresh: _loadEarnings,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _transactions.length,
                              itemBuilder: (context, index) {
                                final transaction = _transactions[index];
                                return _TransactionCard(
                                  rideId: transaction['ride_id'] as int,
                                  date: DateTime.parse(transaction['date'] as String),
                                  ridePrice: transaction['ride_price'] as int,
                                  platformCommission: transaction['platform_commission'] as int,
                                  driverEarnings: transaction['driver_earnings'] as int,
                                  serviceFee: transaction['service_fee'] as int,
                                  commissionRate: (transaction['commission_rate'] as num?)?.toDouble() ?? 0.0,
                                  pickupAddress: transaction['pickup_address'] as String? ?? '',
                                  dropoffAddress: transaction['dropoff_address'] as String? ?? '',
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

class _EarningStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _EarningStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.black.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final int rideId;
  final DateTime date;
  final int ridePrice;
  final int platformCommission;
  final int driverEarnings;
  final int serviceFee;
  final double commissionRate;
  final String pickupAddress;
  final String dropoffAddress;

  const _TransactionCard({
    required this.rideId,
    required this.date,
    required this.ridePrice,
    required this.platformCommission,
    required this.driverEarnings,
    required this.serviceFee,
    required this.commissionRate,
    required this.pickupAddress,
    required this.dropoffAddress,
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
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: Icon(
            Icons.directions_car,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          'Course #$rideId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(date),
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
                if (pickupAddress.isNotEmpty || dropoffAddress.isNotEmpty) ...[
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
                  const Divider(),
                  const SizedBox(height: 8),
                ],
                // Détails financiers
                _FinanceRow(
                  label: 'Montant final du trajet',
                  amount: ridePrice,
                  color: Colors.blue[700]!,
                  isTotal: true,
                ),
                const SizedBox(height: 8),
                _FinanceRow(
                  label: 'Commission TéMove (${commissionRate.toStringAsFixed(1)}%)',
                  amount: platformCommission,
                  color: Colors.orange[700]!,
                ),
                if (serviceFee > 0) ...[
                  const SizedBox(height: 8),
                  _FinanceRow(
                    label: 'Frais de service',
                    amount: serviceFee,
                    color: Colors.grey[700]!,
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _FinanceRow(
                  label: 'Montant net payé',
                  amount: driverEarnings,
                  color: Colors.green[700]!,
                  isTotal: true,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceRow extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;
  final bool isTotal;
  final bool isBold;

  const _FinanceRow({
    required this.label,
    required this.amount,
    required this.color,
    this.isTotal = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey[700],
          ),
        ),
        Text(
          '${amount.toString()} F CFA',
          style: TextStyle(
            fontSize: isTotal ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

