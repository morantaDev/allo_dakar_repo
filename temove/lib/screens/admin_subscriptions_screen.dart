import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';
import 'package:intl/intl.dart';

/// Écran de gestion des abonnements pour les administrateurs
/// 
/// Permet de gérer les abonnements des conducteurs et utilisateurs
class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  List<dynamic> _subscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalSubscriptions = 0;
  String? _selectedType; // 'driver', 'user', 'all'
  String? _selectedStatus; // 'active', 'expired', 'cancelled', 'all'

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions({bool resetPage = false}) async {
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
      final result = await AdminApiService.getSubscriptions(
        page: _currentPage,
        perPage: 20,
        type: _selectedType,
        status: _selectedStatus,
      );

      if (result['success'] == true) {
        setState(() {
          _subscriptions = result['subscriptions'] ?? [];
          final pagination = result['pagination'] ?? {};
          _totalPages = pagination['pages'] ?? 1;
          _totalSubscriptions = pagination['total'] ?? 0;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Gestion des Abonnements'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.secondaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Ajouter un abonnement
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ajouter un abonnement - À venir')),
              );
            },
            tooltip: 'Ajouter un abonnement',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadSubscriptions(resetPage: true),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
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
                // Filtre par type
                Row(
                  children: [
                    const Text('Type: '),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Tous'),
                              selected: _selectedType == null || _selectedType == 'all',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedType = 'all';
                                  });
                                  _loadSubscriptions(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Conducteurs'),
                              selected: _selectedType == 'driver',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedType = 'driver';
                                  });
                                  _loadSubscriptions(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Utilisateurs'),
                              selected: _selectedType == 'user',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedType = 'user';
                                  });
                                  _loadSubscriptions(resetPage: true);
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
                // Filtre par statut
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
                                  _loadSubscriptions(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Actifs'),
                              selected: _selectedStatus == 'active',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'active';
                                  });
                                  _loadSubscriptions(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Expirés'),
                              selected: _selectedStatus == 'expired',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'expired';
                                  });
                                  _loadSubscriptions(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Annulés'),
                              selected: _selectedStatus == 'cancelled',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'cancelled';
                                  });
                                  _loadSubscriptions(resetPage: true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des abonnements
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
                              onPressed: () => _loadSubscriptions(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _subscriptions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.subscriptions_outlined,
                                  size: 64,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun abonnement trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Ajouter un abonnement'),
                                  onPressed: () {
                                    // TODO: Ajouter un abonnement
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Ajouter un abonnement - À venir')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadSubscriptions(),
                            child: Column(
                              children: [
                                // En-tête avec total
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: $_totalSubscriptions abonnement${_totalSubscriptions > 1 ? 's' : ''}',
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
                                    itemCount: _subscriptions.length,
                                    itemBuilder: (context, index) {
                                      final subscription = _subscriptions[index] as Map<String, dynamic>;
                                      return _SubscriptionCard(
                                        subscription: subscription,
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
                                                  _loadSubscriptions();
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
                                                  _loadSubscriptions();
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

class _SubscriptionCard extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final bool isDark;

  const _SubscriptionCard({
    required this.subscription,
    required this.isDark,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return AppTheme.successColor;
      case 'expired':
        return AppTheme.errorColor;
      case 'cancelled':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'expired':
        return 'Expiré';
      case 'cancelled':
        return 'Annulé';
      default:
        return status ?? 'Inconnu';
    }
  }

  String _formatPlan(String? plan) {
    switch (plan?.toLowerCase()) {
      case 'basic':
        return 'Basique';
      case 'premium':
        return 'Premium';
      case 'enterprise':
        return 'Entreprise';
      default:
        return plan ?? 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = subscription['status']?.toString().toLowerCase();
    final statusColor = _getStatusColor(status);
    final plan = subscription['plan'] ?? 'basic';
    final userName = subscription['user']?['full_name'] ?? subscription['driver']?['full_name'] ?? 'Utilisateur inconnu';
    final startDate = subscription['start_date'] as String?;
    final endDate = subscription['end_date'] as String?;
    final price = subscription['price'] ?? 0.0;
    final type = subscription['type'] ?? 'user'; // 'user' ou 'driver'

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            type == 'driver' ? Icons.local_taxi : Icons.person,
            color: statusColor,
          ),
        ),
        title: Text(
          userName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Plan: ${_formatPlan(plan)}'),
            Text('${price.toStringAsFixed(0)} XOF/mois'),
            if (startDate != null && endDate != null)
              Text(
                '${DateFormat('dd/MM/yyyy').format(DateTime.parse(startDate))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(endDate))}',
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

