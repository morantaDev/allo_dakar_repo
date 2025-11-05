import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  String _selectedPeriod = 'Aujourd\'hui';

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
            child: Column(
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
                  '25,000 F CFA',
                  style: TextStyle(
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
                      value: '12',
                      icon: Icons.directions_car,
                    ),
                    _EarningStat(
                      label: 'Moyenne',
                      value: '2,083 F CFA',
                      icon: Icons.trending_up,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Liste des transactions
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _TransactionCard(
                  amount: 2500,
                  date: DateTime.now().subtract(Duration(days: index)),
                  rideId: 100 + index,
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

