import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';
import 'package:intl/intl.dart';

/// Écran de gestion des paiements pour les administrateurs
class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalPayments = 0;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments({bool resetPage = false}) async {
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
      final result = await AdminApiService.getPayments(
        page: _currentPage,
        perPage: 20,
        status: _selectedStatus,
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
      );

      if (result['success'] == true) {
        setState(() {
          _payments = result['payments'] ?? [];
          final pagination = result['pagination'] ?? {};
          _totalPages = pagination['pages'] ?? 1;
          _totalPayments = pagination['total'] ?? 0;
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
      _loadPayments(resetPage: true);
    }
  }

  Future<void> _exportPayments() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une période'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    // Afficher un dialogue pour choisir le format
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Format d\'export'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Excel'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
      ),
    );

    if (format == null) return;

    try {
      final result = await AdminApiService.generateReport(
        reportType: 'payments',
        startDate: _startDate!,
        endDate: _endDate!,
        format: format,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Export généré avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de l\'export'),
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

    // Calculer le total des paiements
    double totalAmount = 0;
    for (var payment in _payments) {
      totalAmount += (payment['amount'] ?? 0).toDouble();
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Gestion des Paiements'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportPayments,
            tooltip: 'Exporter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadPayments(resetPage: true),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques rapides
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
            child: Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Total',
                    value: '${totalAmount.toStringAsFixed(0)} XOF',
                    icon: Icons.attach_money,
                    color: AppTheme.primaryColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatBox(
                    label: 'Paiements',
                    value: '$_totalPayments',
                    icon: Icons.credit_card,
                    color: AppTheme.accentColor,
                    isDark: isDark,
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
                              selected: _selectedStatus == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = null;
                                  });
                                  _loadPayments(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Complété'),
                              selected: _selectedStatus == 'completed',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'completed';
                                  });
                                  _loadPayments(resetPage: true);
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
                                  _loadPayments(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Échoué'),
                              selected: _selectedStatus == 'failed',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'failed';
                                  });
                                  _loadPayments(resetPage: true);
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
                          _loadPayments(resetPage: true);
                        },
                        tooltip: 'Effacer les dates',
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des paiements
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
                              onPressed: () => _loadPayments(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _payments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card_outlined,
                                  size: 64,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun paiement trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadPayments(),
                            child: Column(
                              children: [
                                // En-tête avec total
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: $_totalPayments paiement${_totalPayments > 1 ? 's' : ''}',
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
                                    itemCount: _payments.length,
                                    itemBuilder: (context, index) {
                                      final payment = _payments[index] as Map<String, dynamic>;
                                      return _PaymentCard(
                                        payment: payment,
                                        isDark: isDark,
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
                                                  _loadPayments();
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
                                                  _loadPayments();
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Map<String, dynamic>? payment;
  final bool isDark;

  const _PaymentCard({
    required this.payment,
    required this.isDark,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'failed':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return 'Complété';
      case 'pending':
        return 'En attente';
      case 'failed':
        return 'Échoué';
      default:
        return status ?? 'Inconnu';
    }
  }

  IconData _getMethodIcon(String? method) {
    switch (method?.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'om':
      case 'orange_money':
        return Icons.account_balance_wallet;
      case 'momo':
      case 'mobile_money':
        return Icons.phone_android;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (payment == null) return const SizedBox();

    final status = payment!['status']?.toString().toLowerCase();
    final statusColor = _getStatusColor(status);
    final amount = payment!['amount'] ?? 0;
    final method = payment!['method']?.toString().toUpperCase() ?? 'INCONNU';
    final createdAt = payment!['created_at'] as String?;
    final rideId = payment!['ride_id'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            _getMethodIcon(payment!['method']?.toString()),
            color: statusColor,
          ),
        ),
        title: Text(
          '${amount.toString()} XOF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.primaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Méthode: $method'),
            if (rideId != null) Text('Course #$rideId'),
            if (createdAt != null)
              Text(
                'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(createdAt))}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: Chip(
          label: Text(
            _formatStatus(status),
            style: const TextStyle(fontSize: 12),
          ),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
      ),
    );
  }
}

