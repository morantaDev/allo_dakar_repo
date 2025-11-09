import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';

/// Écran de gestion des conducteurs pour les administrateurs
class AdminDriversScreen extends StatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  State<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends State<AdminDriversScreen> {
  List<dynamic> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalDrivers = 0;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus; // 'pending', 'active', 'inactive'

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDrivers({bool resetPage = false}) async {
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
      final result = await AdminApiService.getDrivers(
        page: _currentPage,
        perPage: 20,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _selectedStatus,
      );

      if (result['success'] == true) {
        setState(() {
          _drivers = result['drivers'] ?? [];
          final pagination = result['pagination'] ?? {};
          _totalPages = pagination['pages'] ?? 1;
          _totalDrivers = pagination['total'] ?? 0;
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

  Future<void> _approveDriver(int driverId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approuver le conducteur'),
        content: const Text('Êtes-vous sûr de vouloir approuver ce conducteur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await AdminApiService.approveDriver(driverId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Conducteur approuvé avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadDrivers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de l\'approbation'),
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

  Future<void> _rejectDriver(int driverId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le conducteur'),
        content: const Text('Êtes-vous sûr de vouloir rejeter ce conducteur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await AdminApiService.rejectDriver(driverId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Conducteur rejeté'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        _loadDrivers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors du rejet'),
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

  Future<void> _toggleDriverStatus(int driverId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le statut'),
        content: const Text('Êtes-vous sûr de vouloir modifier le statut de ce conducteur ?'),
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
      final result = await AdminApiService.toggleDriverStatus(driverId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Statut modifié avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadDrivers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la modification'),
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
        title: const Text('Gestion des Conducteurs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDrivers(resetPage: true),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
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
                // Recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, email, plaque...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadDrivers(resetPage: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                  ),
                  onSubmitted: (_) => _loadDrivers(resetPage: true),
                ),
                const SizedBox(height: 12),
                // Filtres de statut
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Text('Statut: '),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Tous'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatus = null;
                            });
                            _loadDrivers(resetPage: true);
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
                            _loadDrivers(resetPage: true);
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
                            _loadDrivers(resetPage: true);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Inactifs'),
                        selected: _selectedStatus == 'inactive',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedStatus = 'inactive';
                            });
                            _loadDrivers(resetPage: true);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Liste des conducteurs
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
                              onPressed: () => _loadDrivers(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _drivers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_taxi_outlined,
                                  size: 64,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun conducteur trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadDrivers(),
                            child: Column(
                              children: [
                                // En-tête avec total
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: $_totalDrivers conducteur${_totalDrivers > 1 ? 's' : ''}',
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
                                    itemCount: _drivers.length,
                                    itemBuilder: (context, index) {
                                      final driver = _drivers[index] as Map<String, dynamic>;
                                      return _DriverCard(
                                        driver: driver,
                                        isDark: isDark,
                                        onApprove: () => _approveDriver(driver['id'] as int),
                                        onReject: () => _rejectDriver(driver['id'] as int),
                                        onToggleStatus: () => _toggleDriverStatus(driver['id'] as int),
                                        onTap: () {
                                          // TODO: Naviguer vers les détails du conducteur
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Détails de ${driver['full_name'] ?? 'Conducteur'}'),
                                            ),
                                          );
                                        },
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
                                                  _loadDrivers();
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
                                                  _loadDrivers();
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

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final bool isDark;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onToggleStatus;
  final VoidCallback onTap;

  const _DriverCard({
    required this.driver,
    required this.isDark,
    required this.onApprove,
    required this.onReject,
    required this.onToggleStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = driver['is_active'] == true || driver['is_active'] == 1;
    final isVerified = driver['is_verified'] == true || driver['is_verified'] == 1;
    final fullName = driver['full_name'] ?? 'Conducteur';
    final email = driver['email'] ?? '';
    final phone = driver['phone'] ?? '';
    final licensePlate = driver['license_plate'] ?? '';
    final carMake = driver['car_make'] ?? '';
    final carModel = driver['car_model'] ?? '';
    final rating = driver['rating_average'] ?? driver['rating'] ?? 0.0;
    final totalRides = driver['total_rides'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isVerified && isActive
              ? AppTheme.successColor
              : isVerified
                  ? AppTheme.warningColor
                  : AppTheme.errorColor,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (email.isNotEmpty) Text(email),
            if (phone.isNotEmpty) Text(phone),
            if (licensePlate.isNotEmpty) Text('Plaque: $licensePlate'),
            if (carMake.isNotEmpty || carModel.isNotEmpty)
              Text('$carMake $carModel'),
            Row(
              children: [
                Icon(Icons.star, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text('${rating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Text('$totalRides course${totalRides > 1 ? 's' : ''}'),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Statut
            Chip(
              label: Text(
                !isVerified
                    ? 'En attente'
                    : isActive
                        ? 'Actif'
                        : 'Inactif',
              ),
              backgroundColor: !isVerified
                  ? AppTheme.warningColor.withOpacity(0.2)
                  : isActive
                      ? AppTheme.successColor.withOpacity(0.2)
                      : AppTheme.errorColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: !isVerified
                    ? AppTheme.warningColor
                    : isActive
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                fontSize: 12,
              ),
            ),
            // Actions
            if (!isVerified) ...[
              IconButton(
                icon: const Icon(Icons.check_circle, color: AppTheme.successColor),
                onPressed: onApprove,
                tooltip: 'Approuver',
              ),
              IconButton(
                icon: const Icon(Icons.cancel, color: AppTheme.errorColor),
                onPressed: onReject,
                tooltip: 'Rejeter',
              ),
            ] else
              IconButton(
                icon: Icon(isActive ? Icons.block : Icons.check_circle),
                onPressed: onToggleStatus,
                tooltip: isActive ? 'Désactiver' : 'Activer',
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

