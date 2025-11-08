import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _loadEarnings();
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Appeler l'API pour récupérer les revenus réels
    // Pour l'instant, on affiche 0 pour un nouveau chauffeur
    // Simuler un délai de chargement
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _totalEarnings = 0.0;  // Aucun revenu pour un nouveau chauffeur
      _totalRides = 0;
      _transactions = [];  // Aucune transaction
      _isLoading = false;
    });
  }

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
                  onTap: () => setState(() => _selectedPeriod = 'Aujourd\'hui'),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Cette semaine',
                  isSelected: _selectedPeriod == 'Cette semaine',
                  onTap: () => setState(() => _selectedPeriod = 'Cette semaine'),
                ),
                const SizedBox(width: 8),
                _PeriodChip(
                  label: 'Ce mois',
                  isSelected: _selectedPeriod == 'Ce mois',
                  onTap: () => setState(() => _selectedPeriod = 'Ce mois'),
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
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];
                          return _TransactionCard(
                            amount: transaction['amount'] as int,
                            date: DateTime.parse(transaction['date'] as String),
                            rideId: transaction['ride_id'] as int,
                          );
                        },
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
  final int amount;
  final DateTime date;
  final int rideId;

  const _TransactionCard({
    required this.amount,
    required this.date,
    required this.rideId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
          child: Icon(
            Icons.directions_car,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text('Course #$rideId'),
        subtitle: Text(
          DateFormat('dd MMM yyyy, HH:mm').format(date),
          style: TextStyle(fontSize: 12),
        ),
        trailing: Text(
          '${amount.toString()} F CFA',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
      ),
    );
  }
}

