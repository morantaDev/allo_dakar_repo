import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/services/api_service.dart';
import 'package:intl/intl.dart';

enum RideStatus { all, completed, inProgress, cancelled }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  RideStatus _selectedStatus = RideStatus.all;
  List<Map<String, dynamic>> _rides = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRideHistory();
  }

  Future<void> _loadRideHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.getRideHistory();
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        final ridesList = data['rides'] as List<dynamic>? ?? [];
        
        // Convertir les données du backend en format compatible avec l'écran
        final convertedRides = ridesList.map((rideData) {
          final ride = rideData as Map<String, dynamic>;
          
          // Mapper le statut du backend vers notre enum
          RideStatus status;
          final rideStatus = ride['status'] as String? ?? '';
          switch (rideStatus.toLowerCase()) {
            case 'completed':
              status = RideStatus.completed;
              break;
            case 'pending':
            case 'confirmed':
            case 'in_progress':
            case 'driver_assigned':
            case 'driver_arrived':
            case 'started':
              status = RideStatus.inProgress;
              break;
            case 'cancelled':
              status = RideStatus.cancelled;
              break;
            default:
              status = RideStatus.completed;
          }
          
          // Parser la date
          DateTime? date;
          if (ride['requested_at'] != null) {
            try {
              date = DateTime.parse(ride['requested_at'] as String);
            } catch (e) {
              date = DateTime.now();
            }
          } else {
            date = DateTime.now();
          }
          
          // Extraire les informations du driver
          final driver = ride['driver'] as Map<String, dynamic>?;
          final driverName = driver?['name'] as String? ?? 
                           driver?['full_name'] as String? ?? 
                           'Chauffeur';
          
          // Extraire les adresses
          final pickup = ride['pickup'] as Map<String, dynamic>?;
          final dropoff = ride['dropoff'] as Map<String, dynamic>?;
          final fromAddress = pickup?['address'] as String? ?? 'Départ';
          final toAddress = dropoff?['address'] as String? ?? 'Destination';
          
          // Formater le prix
          final finalPrice = ride['final_price'] as int? ?? 0;
          final priceFormatted = '${NumberFormat('#,###').format(finalPrice)} XOF';
          
          return {
            'id': ride['id'],
            'date': date,
            'driver': driverName,
            'driverAvatar': driver?['avatar'],
            'from': fromAddress,
            'to': toAddress,
            'price': priceFormatted,
            'status': status,
            'mapImage': null,
            'rideData': ride, // Garder les données complètes pour référence
          };
        }).toList();
        
        setState(() {
          _rides = convertedRides;
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

  List<Map<String, dynamic>> get _filteredRides {
    if (_selectedStatus == RideStatus.all) {
      return _rides;
    }
    return _rides.where((ride) => ride['status'] == _selectedStatus).toList();
  }

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return AppTheme.successColor;
      case RideStatus.inProgress:
        return AppTheme.warningColor;
      case RideStatus.cancelled:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return 'Terminée';
      case RideStatus.inProgress:
        return 'En cours';
      case RideStatus.cancelled:
        return 'Annulée';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Historique des courses'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Toutes',
                    isSelected: _selectedStatus == RideStatus.all,
                    onTap: () => setState(() => _selectedStatus = RideStatus.all),
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    label: 'Terminées',
                    isSelected: _selectedStatus == RideStatus.completed,
                    onTap: () => setState(() => _selectedStatus = RideStatus.completed),
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    label: 'En cours',
                    isSelected: _selectedStatus == RideStatus.inProgress,
                    onTap: () => setState(() => _selectedStatus = RideStatus.inProgress),
                  ),
                  const SizedBox(width: 12),
                  _FilterChip(
                    label: 'Annulées',
                    isSelected: _selectedStatus == RideStatus.cancelled,
                    onTap: () => setState(() => _selectedStatus = RideStatus.cancelled),
                  ),
                ],
              ),
            ),
          ),
          // Rides List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _ErrorState(
                        message: _errorMessage!,
                        onRetry: _loadRideHistory,
                      )
                    : _filteredRides.isEmpty
                        ? _EmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadRideHistory,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredRides.length,
                              itemBuilder: (context, index) {
                                final ride = _filteredRides[index];
                                return _RideCard(ride: ride, isDark: isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark
                  ? Colors.white.withOpacity(0.1)
                  : AppTheme.secondaryColor.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? AppTheme.secondaryColor
                : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
          ),
        ),
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

  Color _getStatusColor(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return AppTheme.successColor;
      case RideStatus.inProgress:
        return AppTheme.warningColor;
      case RideStatus.cancelled:
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(RideStatus status) {
    switch (status) {
      case RideStatus.completed:
        return 'Terminée';
      case RideStatus.inProgress:
        return 'En cours';
      case RideStatus.cancelled:
        return 'Annulée';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    // Format simple sans dépendre de la locale
    final months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final day = date.day;
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as RideStatus;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final formattedDate = _formatDate(ride['date'] as DateTime);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryColor.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Map Preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.map,
                size: 48,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          // Content
          Padding(
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
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark 
                                  ? AppTheme.textPrimary 
                                  : AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                statusText,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Avec ${ride['driver']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark 
                                ? AppTheme.textMuted 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'De: ${ride['from']}, À: ${ride['to']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark 
                                  ? AppTheme.textMuted 
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ride['price'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark 
                                  ? AppTheme.textPrimary 
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: status == RideStatus.inProgress
                          ? null
                          : () {
                              // TODO: Naviguer vers la réservation
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == RideStatus.inProgress
                            ? AppTheme.primaryColor.withOpacity(0.3)
                            : AppTheme.primaryColor,
                        foregroundColor: status == RideStatus.inProgress
                            ? AppTheme.secondaryColor.withOpacity(0.5)
                            : AppTheme.secondaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        status == RideStatus.inProgress
                            ? 'Voir la course'
                            : 'Réserver à nouveau',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: isDark 
                ? AppTheme.textMuted 
                : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark 
                  ? AppTheme.textPrimary 
                  : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de courses dans cette catégorie.',
            style: TextStyle(
              fontSize: 14,
              color: isDark 
                  ? AppTheme.textMuted 
                  : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'Erreur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark 
                    ? AppTheme.textPrimary 
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark 
                    ? AppTheme.textMuted 
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.secondaryColor,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

