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
        
        print('📊 [HISTORY] Nombre de courses reçues: ${ridesList.length}');
        
        // Convertir les données du backend en format compatible avec l'écran
        final convertedRides = ridesList.map((rideData) {
          print('📊 [HISTORY] Traitement d\'une course: ${rideData.toString().substring(0, rideData.toString().length > 200 ? 200 : rideData.toString().length)}...');
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
          
          // Formater le prix - gérer int, double ou null
          dynamic priceValue = ride['final_price'] ?? ride['price'] ?? ride['estimated_price'] ?? 0;
          double finalPrice = 0.0;
          if (priceValue is int) {
            finalPrice = priceValue.toDouble();
          } else if (priceValue is double) {
            finalPrice = priceValue;
          } else if (priceValue is String) {
            finalPrice = double.tryParse(priceValue) ?? 0.0;
          }
          final priceFormatted = finalPrice > 0 
              ? '${NumberFormat('#,###').format(finalPrice.toInt())} XOF'
              : 'Non défini';
          
          // Extraire distance et durée
          final distance = ride['distance_km'] ?? ride['distance'];
          final duration = ride['duration_minutes'] ?? ride['duration'];
          
          return {
            'id': ride['id'],
            'date': date,
            'driver': driverName,
            'driverAvatar': driver?['avatar'] ?? driver?['avatar_url'],
            'from': fromAddress,
            'to': toAddress,
            'price': priceFormatted,
            'priceValue': finalPrice,
            'status': status,
            'mapImage': null,
            'distance': distance is double ? distance : (distance is int ? distance.toDouble() : null),
            'duration': duration is int ? duration : (duration is double ? duration.toInt() : null),
            'rideData': ride, // Garder les données complètes pour référence
          };
        }).toList();
        
        print('✅ [HISTORY] ${convertedRides.length} courses converties avec succès');
        
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rideDate = DateTime(date.year, date.month, date.day);
    
    if (rideDate == today) {
      return 'Aujourd\'hui, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (rideDate == today.subtract(const Duration(days: 1))) {
      return 'Hier, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      final months = [
        'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
        'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
      ];
      return '${date.day} ${months[date.month - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showRideDetails(BuildContext context) {
    final rideData = ride['rideData'] as Map<String, dynamic>?;
    if (rideData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RideDetailsSheet(
        ride: rideData,
        isDark: isDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ride['status'] as RideStatus;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final formattedDate = _formatDate(ride['date'] as DateTime);
    final rideData = ride['rideData'] as Map<String, dynamic>?;
    
    // Extraire les détails supplémentaires - utiliser les valeurs stockées ou celles du rideData
    double? distance;
    if (ride['distance'] != null) {
      distance = ride['distance'] as double?;
    } else if (rideData?['distance_km'] != null) {
      final distValue = rideData!['distance_km'];
      if (distValue is double) {
        distance = distValue;
      } else if (distValue is int) {
        distance = distValue.toDouble();
      }
    }
    
    int? duration;
    if (ride['duration'] != null) {
      duration = ride['duration'] as int?;
    } else if (rideData?['duration_minutes'] != null) {
      final durValue = rideData!['duration_minutes'];
      if (durValue is int) {
        duration = durValue;
      } else if (durValue is double) {
        duration = durValue.toInt();
      }
    }
    
    final rideMode = rideData?['ride_mode'] as String?;
    final paymentMethod = rideData?['payment_method'] as String?;
    
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
      child: InkWell(
        onTap: () => _showRideDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec date et statut
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark 
                                ? AppTheme.textPrimary 
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Prix
                  if (ride['priceValue'] != null && (ride['priceValue'] as double) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ride['price'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Adresses avec icônes
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 24,
                        color: Colors.grey.shade300,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride['from'] as String? ?? 'Adresse de départ non disponible',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark 
                                ? AppTheme.textPrimary 
                                : AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          ride['to'] as String? ?? 'Adresse de destination non disponible',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark 
                                ? AppTheme.textPrimary 
                                : AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Détails supplémentaires
              Row(
                children: [
                  if (distance != null) ...[
                    _DetailChip(
                      icon: Icons.straighten,
                      label: '${distance.toStringAsFixed(1)} km',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (duration != null) ...[
                    _DetailChip(
                      icon: Icons.access_time,
                      label: '$duration min',
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (rideMode != null) ...[
                    _DetailChip(
                      icon: Icons.directions_car,
                      label: _formatRideMode(rideMode),
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Footer avec chauffeur et bouton
              Row(
                children: [
                  // Avatar du chauffeur
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade300,
                      image: ride['driverAvatar'] != null && (ride['driverAvatar'] as String).isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(ride['driverAvatar'] as String),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                // Gérer les erreurs de chargement d'image
                              },
                            )
                          : null,
                    ),
                    child: ride['driverAvatar'] == null || (ride['driverAvatar'] as String).isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 20,
                            color: Colors.grey,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chauffeur',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark 
                                ? AppTheme.textMuted 
                                : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          ride['driver'] as String? ?? 'Non assigné',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark 
                                ? AppTheme.textPrimary 
                                : AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showRideDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Détails',
                      style: TextStyle(
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
      ),
    );
  }

  String _formatRideMode(String mode) {
    final modes = {
      'eco': 'Éco',
      'confort': 'Confort',
      'confortPlus': 'Confort+',
      'partageTaxi': 'Partagé',
      'famille': 'Famille',
      'premium': 'Premium',
      'tiakTiak': 'Tiak Tiak',
      'voiture': 'Voiture',
      'express': 'Express',
    };
    return modes[mode.toLowerCase()] ?? mode;
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

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.textMuted : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RideDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> ride;
  final bool isDark;

  const _RideDetailsSheet({
    required this.ride,
    required this.isDark,
  });

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatRideMode(String? mode) {
    if (mode == null) return 'N/A';
    final modes = {
      'eco': 'Éco',
      'confort': 'Confort',
      'confortPlus': 'Confort+',
      'partageTaxi': 'Partagé',
      'famille': 'Famille',
      'premium': 'Premium',
      'tiakTiak': 'Tiak Tiak',
      'voiture': 'Voiture',
      'express': 'Express',
    };
    return modes[mode.toLowerCase()] ?? mode;
  }

  String _formatPaymentMethod(String? method) {
    if (method == null) return 'N/A';
    final methods = {
      'cash': 'Espèces',
      'om': 'Orange Money',
      'momo': 'MoMo',
      'card': 'Carte',
    };
    return methods[method.toLowerCase()] ?? method;
  }

  @override
  Widget build(BuildContext context) {
    final pickup = ride['pickup'] as Map<String, dynamic>?;
    final dropoff = ride['dropoff'] as Map<String, dynamic>?;
    final driver = ride['driver'] as Map<String, dynamic>?;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Titre
                Text(
                  'Détails de la course',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Informations principales
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: _formatDate(ride['requested_at'] as String?),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.attach_money,
                  label: 'Prix',
                  value: '${NumberFormat('#,###').format(ride['final_price'] ?? 0)} XOF',
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.directions_car,
                  label: 'Mode',
                  value: _formatRideMode(ride['ride_mode'] as String?),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  icon: Icons.payment,
                  label: 'Paiement',
                  value: _formatPaymentMethod(ride['payment_method'] as String?),
                  isDark: isDark,
                ),
                if (ride['distance_km'] != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${(ride['distance_km'] as double).toStringAsFixed(1)} km',
                    isDark: isDark,
                  ),
                ],
                if (ride['duration_minutes'] != null) ...[
                  const SizedBox(height: 16),
                  _DetailRow(
                    icon: Icons.access_time,
                    label: 'Durée',
                    value: '${ride['duration_minutes']} minutes',
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 32),
                // Adresses
                Text(
                  'Itinéraire',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                if (pickup != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Départ',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickup['address'] as String? ?? 'N/A',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (dropoff != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destination',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dropoff['address'] as String? ?? 'N/A',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                if (driver != null) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Chauffeur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                            image: driver['avatar'] != null
                                ? DecorationImage(
                                    image: NetworkImage(driver['avatar'] as String),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: driver['avatar'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver['name'] as String? ??
                                    driver['full_name'] as String? ??
                                    'Chauffeur',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                                ),
                              ),
                              if (driver['phone'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  driver['phone'] as String,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppTheme.primaryColor,
        ),
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
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
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
            const Icon(
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
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

