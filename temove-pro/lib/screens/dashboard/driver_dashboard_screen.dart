import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/driver_api_service.dart';
import '../../widgets/temove_logo.dart';
import '../rides/rides_list_screen.dart';
import '../profile/driver_profile_screen.dart';
import '../earnings/earnings_screen.dart';
import '../history/rides_history_screen.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentIndex = 0;
  bool _isOnline = false;

  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Clés pour accéder aux états des écrans
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();
  final GlobalKey _earningsKey = GlobalKey();
  
  Future<void> _toggleStatus() async {
    final newStatus = _isOnline ? 'offline' : 'online';
    final result = await DriverApiService.setStatus(newStatus);
    
    if (result['success'] == true) {
      setState(() {
        _isOnline = !_isOnline;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Utiliser IndexedStack pour préserver l'état des écrans
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            key: _homeTabKey,
            onNavigateToRides: () => _switchToTab(1),
          ),
          const RidesListScreen(key: ValueKey('rides')),
          EarningsScreen(key: _earningsKey),
          const DriverProfileScreen(key: ValueKey('profile')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          final previousIndex = _currentIndex;
          setState(() {
            _currentIndex = index;
          });
          
          // Recharger les données quand on change d'onglet
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (index == 0 && previousIndex != index && _homeTabKey.currentState != null) {
              // Recharger le dashboard
              _homeTabKey.currentState!._loadDriverData();
            } else if (index == 2 && previousIndex != index) {
              // Recharger les revenus si la méthode reload existe
              final earningsState = _earningsKey.currentState;
              if (earningsState != null && earningsState is State) {
                // Essayer d'appeler reload() si elle existe (via reflection ou méthode publique)
                try {
                  (earningsState as dynamic).reload();
                } catch (e) {
                  // Si reload() n'existe pas, on laisse l'écran se recharger via pull-to-refresh
                  print('⚠️ [DASHBOARD] Impossible de recharger les revenus: $e');
                }
              }
            }
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Revenus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleStatus,
        backgroundColor: _isOnline ? Colors.green : Colors.grey,
        icon: Icon(_isOnline ? Icons.check_circle : Icons.cancel),
        label: Text(_isOnline ? 'En ligne' : 'Hors ligne'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToRides;
  final VoidCallback? onRefresh;
  
  const _HomeTab({
    super.key,
    required this.onNavigateToRides,
    this.onRefresh,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> with AutomaticKeepAliveClientMixin {
  String _driverName = 'Chauffeur TéMove';
  double _rating = 0.0;
  int _totalRides = 0;
  double _todayEarnings = 0.0;
  int _todayRides = 0;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    // Rafraîchir les données toutes les 30 secondes
    _startAutoRefresh();
  }

  Timer? _refreshTimer;

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadDriverData();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadDriverData() async {
    try {
      final result = await DriverApiService.getDriverProfile();
      
      if (result['success'] == true && result['data'] != null) {
        final driverData = result['data'] as Map<String, dynamic>;
        final driver = driverData['driver'] as Map<String, dynamic>?;
        
        if (driver != null) {
          // Récupérer le nom depuis driver.full_name ou user.full_name
          final user = driver['user'] as Map<String, dynamic>?;
          String name = 'Chauffeur TéMove';
          
          // Essayer de récupérer le nom de manière sécurisée
          try {
            final driverName = driver['full_name'];
            final userName = user?['full_name'] ?? user?['name'];
            
            if (driverName != null && driverName.toString().isNotEmpty) {
              name = driverName.toString();
            } else if (userName != null && userName.toString().isNotEmpty) {
              name = userName.toString();
            }
          } catch (e) {
            print('⚠️ [DASHBOARD] Erreur lors de la récupération du nom: $e');
            name = 'Chauffeur TéMove';
          }
          
          // Récupérer la note de manière sécurisée
          double rating = 0.0;
          try {
            final ratingValue = driver['rating'] ?? driver['rating_average'] ?? 0.0;
            if (ratingValue is num) {
              rating = ratingValue.toDouble();
            } else if (ratingValue != null) {
              rating = double.tryParse(ratingValue.toString()) ?? 0.0;
            }
          } catch (e) {
            print('⚠️ [DASHBOARD] Erreur lors de la récupération de la note: $e');
            rating = 0.0;
          }
          
          // Récupérer le nombre de courses de manière sécurisée
          int totalRides = 0;
          try {
            final totalRidesValue = driver['total_rides'] ?? 0;
            if (totalRidesValue is int) {
              totalRides = totalRidesValue;
            } else if (totalRidesValue is num) {
              totalRides = totalRidesValue.toInt();
            } else if (totalRidesValue != null) {
              totalRides = int.tryParse(totalRidesValue.toString()) ?? 0;
            }
          } catch (e) {
            print('⚠️ [DASHBOARD] Erreur lors de la récupération du nombre de courses: $e');
            totalRides = 0;
          }
          
          // Charger les revenus et courses d'aujourd'hui
          await _loadTodayStats();
          
          if (mounted) {
            setState(() {
              _driverName = name;
              _rating = rating;
              _totalRides = totalRides;
              _isLoading = false;
            });
          }
        } else {
          // Fallback: utiliser les données du stockage local
          await _loadFromLocalStorage();
        }
      } else {
        // Fallback: utiliser les données du stockage local
        await _loadFromLocalStorage();
      }
    } catch (e) {
      print('❌ [DASHBOARD] Erreur lors du chargement des données: $e');
      // Fallback: utiliser les données du stockage local
      await _loadFromLocalStorage();
    }
  }

  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('user_name') ?? 'Chauffeur TéMove';
      
      // Charger les revenus d'aujourd'hui même si le profil n'est pas chargé
      await _loadTodayStats();
      
      if (mounted) {
        setState(() {
          _driverName = name;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ [DASHBOARD] Erreur lors du chargement depuis le stockage local: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Charge les statistiques d'aujourd'hui (revenus et courses)
  Future<void> _loadTodayStats() async {
    try {
      // Récupérer les courses complétées d'aujourd'hui
      final result = await DriverApiService.getCompletedRides(period: 'today');
      
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>?;
        final summary = data?['summary'] as Map<String, dynamic>? ?? {};
        
        final todayEarnings = (summary['total_earnings'] as num?)?.toDouble() ?? 0.0;
        final todayRides = summary['total_rides'] as int? ?? 0;
        
        if (mounted) {
          setState(() {
            _todayEarnings = todayEarnings;
            _todayRides = todayRides;
          });
        }
      }
    } catch (e) {
      print('⚠️ [DASHBOARD] Erreur lors du chargement des stats d\'aujourd\'hui: $e');
      // En cas d'erreur, laisser les valeurs à 0
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Nécessaire pour AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadDriverData();
            },
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo TéMove Pro en haut de la page
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: TeMoveLogo(
                  size: 120,
                  showText: false,
                ),
              ),
            ),
            
            // Carte de bienvenue
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bienvenue,',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _driverName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        _rating > 0 ? _rating.toStringAsFixed(1) : '--',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _totalRides > 0 
                              ? '($_totalRides ${_totalRides == 1 ? 'course' : 'courses'})'
                              : '(Aucune course)',
                          style: TextStyle(color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Statistiques rapides
            const Text(
              'Aujourd\'hui',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.directions_car,
                    label: 'Courses complétées',
                    value: _todayRides.toString(),
                    color: Colors.blue,
                    showEmptyMessage: _todayRides == 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.attach_money,
                    label: 'Revenus',
                    value: _todayEarnings > 0 
                        ? '${_todayEarnings.toStringAsFixed(0)} F'
                        : '0 F',
                    color: Colors.green,
                    showEmptyMessage: _todayEarnings == 0,
                  ),
                ),
              ],
            ),
            
            // Message informatif pour les nouveaux chauffeurs
            if (_totalRides == 0 && !_isLoading) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bienvenue ! Acceptez votre première course dans l\'onglet "Courses" pour commencer.',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Actions rapides
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.directions_car,
                    label: 'Nouvelles courses',
                    color: Theme.of(context).primaryColor,
                    onTap: widget.onNavigateToRides,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.history,
                    label: 'Historique',
                    color: Colors.orange,
                    onTap: () {
                      // Naviguer vers l'écran d'historique
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RidesHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool showEmptyMessage;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.showEmptyMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (showEmptyMessage && value == '0') ...[
              const SizedBox(height: 4),
              Text(
                'Aucune course aujourd\'hui',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

