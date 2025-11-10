import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';
import 'package:intl/intl.dart';

/// Écran de gestion des commissions pour les administrateurs
/// 
/// Affiche les commissions dues aux conducteurs (10% par défaut)
/// et permet de gérer les paiements de commissions
class AdminCommissionsScreen extends StatefulWidget {
  const AdminCommissionsScreen({super.key});

  @override
  State<AdminCommissionsScreen> createState() => _AdminCommissionsScreenState();
}

class _AdminCommissionsScreenState extends State<AdminCommissionsScreen> {
  List<dynamic> _commissions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCommissions = 0;
  double _totalCommissionAmount = 0.0;
  double _totalPaidAmount = 0.0;
  double _totalPendingAmount = 0.0;
  String? _selectedStatus; // 'pending', 'paid', 'all'
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadCommissions();
  }

  Future<void> _loadCommissions({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminApiService.getCommissions(
        page: _currentPage,
        perPage: 20,
        status: _selectedStatus,
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
      );

      if (result['success'] == true) {
        setState(() {
          _commissions = result['commissions'] ?? [];
          final pagination = result['pagination'] ?? {};
          _totalPages = pagination['pages'] ?? 1;
          _totalCommissions = pagination['total'] ?? 0;
          
          // Calculer les totaux
          _totalCommissionAmount = result['total_commission'] ?? 0.0;
          _totalPaidAmount = result['total_paid'] ?? 0.0;
          _totalPendingAmount = result['total_pending'] ?? 0.0;
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Erreur lors du chargement';
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

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadCommissions(resetPage: true);
    }
  }

  Future<void> _markAsPaid(int commissionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Marquer comme payé'),
        content: const Text('Êtes-vous sûr de vouloir marquer cette commission comme payée ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await AdminApiService.markCommissionAsPaid(commissionId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Commission marquée comme payée'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadCommissions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la mise à jour'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Gestion des Commissions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadCommissions(resetPage: true),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques des commissions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CommissionStatBox(
                        label: 'Total Commissions',
                        value: '${_totalCommissionAmount.toStringAsFixed(0)} XOF',
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.primaryColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CommissionStatBox(
                        label: 'Payées',
                        value: '${_totalPaidAmount.toStringAsFixed(0)} XOF',
                        icon: Icons.check_circle,
                        color: AppTheme.successColor,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CommissionStatBox(
                        label: 'En attente',
                        value: '${_totalPendingAmount.toStringAsFixed(0)} XOF',
                        icon: Icons.pending,
                        color: AppTheme.warningColor,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Taux de commission: 10%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                ),
              ),
            ),
            child: Column(
              children: [
                // Filtre de statut
                Row(
                  children: [
                    const Text('Statut: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Tous'),
                              selected: _selectedStatus == null || _selectedStatus == 'all',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'all';
                                  });
                                  _loadCommissions(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('En attente'),
                              selected: _selectedStatus == 'pending',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'pending';
                                  });
                                  _loadCommissions(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Payées'),
                              selected: _selectedStatus == 'paid',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'paid';
                                  });
                                  _loadCommissions(resetPage: true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Sélection de dates
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                              : 'Sélectionner une période',
                        ),
                        onPressed: _selectDateRange,
                      ),
                    ),
                    if (_startDate != null && _endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                          _loadCommissions(resetPage: true);
                        },
                        tooltip: 'Effacer les dates',
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des commissions
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
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => _loadCommissions(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _commissions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 64,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune commission trouvée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadCommissions(),
                            child: Column(
                              children: [
                                // En-tête avec total
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: $_totalCommissions commission${_totalCommissions > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Liste
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _commissions.length,
                                    itemBuilder: (context, index) {
                                      final commission = _commissions[index] as Map<String, dynamic>;
                                      return _CommissionCard(
                                        commission: commission,
                                        isDark: isDark,
                                        onMarkAsPaid: () => _markAsPaid(commission['id'] as int),
                                      );
                                    },
                                  ),
                                ),
                                // Pagination
                                if (_totalPages > 1)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 1
                                              ? () {
                                                  setState(() {
                                                    _currentPage--;
                                                  });
                                                  _loadCommissions();
                                                }
                                              : null,
                                        ),
                                        Text(
                                          'Page $_currentPage sur $_totalPages',
                                          style: TextStyle(
                                            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < _totalPages
                                              ? () {
                                                  setState(() {
                                                    _currentPage++;
                                                  });
                                                  _loadCommissions();
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _CommissionStatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _CommissionStatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CommissionCard extends StatelessWidget {
  final Map<String, dynamic> commission;
  final bool isDark;
  final VoidCallback onMarkAsPaid;

  const _CommissionCard({
    required this.commission,
    required this.isDark,
    required this.onMarkAsPaid,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return 'Payée';
      case 'pending':
        return 'En attente';
      default:
        return status ?? 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = commission['status']?.toString().toLowerCase();
    final statusColor = _getStatusColor(status);
    final amount = commission['amount'] ?? 0.0;
    final driverName = commission['driver']?['full_name'] ?? 'Conducteur inconnu';
    final rideId = commission['ride_id'];
    final createdAt = commission['created_at'] as String?;
    final paidAt = commission['paid_at'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            Icons.account_balance_wallet,
            color: statusColor,
          ),
        ),
        title: Text(
          driverName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${amount.toStringAsFixed(0)} XOF'),
            if (rideId != null) Text('Course #$rideId'),
            if (createdAt != null)
              Text(
                'Créée: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(createdAt))}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                ),
              ),
            if (paidAt != null)
              Text(
                'Payée: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(paidAt))}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.successColor,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                _formatStatus(status),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: statusColor.withOpacity(0.2),
              labelStyle: TextStyle(color: statusColor),
            ),
            if (status == 'pending')
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppTheme.successColor),
                onPressed: onMarkAsPaid,
                tooltip: 'Marquer comme payée',
              ),
          ],
        ),
      ),
    );
  }
}

