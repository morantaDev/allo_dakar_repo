import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';
import 'package:intl/intl.dart';

/// Écran de gestion des courses pour les administrateurs
class AdminRidesScreen extends StatefulWidget {
  const AdminRidesScreen({super.key});

  @override
  State<AdminRidesScreen> createState() => _AdminRidesScreenState();
}

class _AdminRidesScreenState extends State<AdminRidesScreen> {
  List<dynamic> _rides = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRides = 0;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides({bool resetPage = false}) async {
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
      final result = await AdminApiService.getRides(
        page: _currentPage,
        perPage: 20,
        status: _selectedStatus,
        startDate: _startDate?.toIso8601String().split('T')[0],
        endDate: _endDate?.toIso8601String().split('T')[0],
      );

      if (result['success'] == true) {
        setState(() {
          _rides = result['rides'] ?? [];
          final pagination = result['pagination'] ?? {};
          _totalPages = pagination['pages'] ?? 1;
          _totalRides = pagination['total'] ?? 0;
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
      _loadRides(resetPage: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Gestion des Courses'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadRides(resetPage: true),
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
                                  _loadRides(resetPage: true);
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
                                  _loadRides(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Assignée'),
                              selected: _selectedStatus == 'driver_assigned',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'driver_assigned';
                                  });
                                  _loadRides(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('En cours'),
                              selected: _selectedStatus == 'in_progress',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'in_progress';
                                  });
                                  _loadRides(resetPage: true);
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Terminée'),
                              selected: _selectedStatus == 'completed',
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedStatus = 'completed';
                                  });
                                  _loadRides(resetPage: true);
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
                          _loadRides(resetPage: true);
                        },
                        tooltip: 'Effacer les dates',
                      ),
                  ],
                ),
              ],
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
                              onPressed: () => _loadRides(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _rides.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.directions_car_outlined,
                                  size: 64,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucune course trouvée',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadRides(),
                            child: Column(
                              children: [
                                // En-tête avec total
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: $_totalRides course${_totalRides > 1 ? 's' : ''}',
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
                                    itemCount: _rides.length,
                                    itemBuilder: (context, index) {
                                      final ride = _rides[index] as Map<String, dynamic>;
                                      return _RideCard(
                                        ride: ride,
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
                                                  _loadRides();
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
                                                  _loadRides();
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

class _RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final bool isDark;

  const _RideCard({
    required this.ride,
    required this.isDark,
  });

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'driver_assigned':
      case 'accepted':
        return AppTheme.primaryColor;
      case 'in_progress':
        return AppTheme.accentColor;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'driver_assigned':
        return 'Chauffeur assigné';
      case 'accepted':
        return 'Acceptée';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status ?? 'Inconnu';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ride['status']?.toString().toLowerCase();
    final statusColor = _getStatusColor(status);
    final pickup = ride['pickup'] as Map<String, dynamic>?;
    final dropoff = ride['dropoff'] as Map<String, dynamic>?;
    final pickupAddress = pickup?['address'] ?? 'Adresse inconnue';
    final dropoffAddress = dropoff?['address'] ?? 'Adresse inconnue';
    final finalPrice = ride['final_price'] ?? 0;
    final distance = ride['distance_km'] ?? 0.0;
    final requestedAt = ride['requested_at'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(
            Icons.directions_car,
            color: statusColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Course #${ride['id']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ),
            Chip(
              label: Text(
                _formatStatus(status),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: statusColor.withOpacity(0.2),
              labelStyle: TextStyle(color: statusColor),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    pickupAddress,
                    style: TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (dropoffAddress.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: AppTheme.errorColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dropoffAddress,
                      style: TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${finalPrice.toString()} XOF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (requestedAt != null)
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(requestedAt))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                    ),
                  ),
                if (ride['driver'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Chauffeur: ${ride['driver']['full_name'] ?? 'Inconnu'}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
                if (ride['user'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Client: ${ride['user']['full_name'] ?? ride['user']['name'] ?? 'Inconnu'}',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

