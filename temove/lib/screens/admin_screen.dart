import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/services/admin_api_service.dart';
import 'package:temove/widgets/admin_stat_card.dart';
import 'package:temove/widgets/admin_chart_card.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => AdminScreenState();
}

/// État publique pour permettre l'accès depuis AdminHomeScreen via GlobalKey
class AdminScreenState extends State<AdminScreen> {
  Map<String, dynamic>? dashboardStats;
  List<dynamic> ridesChartData = [];
  List<dynamic> revenueChartData = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }
  
  /// Méthode publique pour recharger les données du dashboard
  /// Peut être appelée depuis AdminHomeScreen via GlobalKey
  Future<void> refresh() async {
    await _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Charger les statistiques principales
      final stats = await ApiService.getAdminDashboardStats();
      
      // Charger les données des graphiques
      final ridesChart = await AdminApiService.getRidesChartData();
      final revenueChart = await AdminApiService.getRevenueChartData();
      
      setState(() {
        dashboardStats = stats;
        if (ridesChart['success'] == true) {
          ridesChartData = ridesChart['data'] ?? [];
        }
        if (revenueChart['success'] == true) {
          revenueChartData = revenueChart['data'] ?? [];
        }
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Ne pas créer de Scaffold ici car AdminHomeScreen le fournit déjà
    // Retourner uniquement le contenu du body
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }
    
    return Container(
      color: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      child: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPIs Principaux - Cartes améliorées (titre retiré car déjà dans l'AppBar)
              _buildImprovedKPICards(isDark),
              const SizedBox(height: 24),
              // Graphiques dynamiques
              if (dashboardStats != null) ...[
                _buildRidesChart(isDark),
                const SizedBox(height: 24),
                _buildRevenueChart(isDark),
                const SizedBox(height: 24),
              ],
              // Section Trajets
              _buildSectionTitle('Détails des Trajets', Icons.directions_car, isDark),
              const SizedBox(height: 12),
              _buildRideStats(isDark),
              const SizedBox(height: 24),
              // Section Utilisateurs
              _buildSectionTitle('Utilisateurs', Icons.people, isDark),
              const SizedBox(height: 12),
              _buildUserStats(isDark),
              const SizedBox(height: 24),
              // Section Conducteurs
              _buildSectionTitle('Conducteurs', Icons.local_taxi, isDark),
              const SizedBox(height: 12),
              _buildDriverStats(isDark),
              const SizedBox(height: 24),
              // Section Revenus
              _buildSectionTitle('Revenus', Icons.attach_money, isDark),
              const SizedBox(height: 12),
              _buildRevenueStats(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// Construction des cartes KPI améliorées avec le nouveau widget
  Widget _buildImprovedKPICards(bool isDark) {
    if (dashboardStats == null) return const SizedBox();

    final revenue = dashboardStats!['revenue'] ?? {};
    final rides = dashboardStats!['rides'] ?? {};
    final users = dashboardStats!['users'] ?? {};
    final drivers = dashboardStats!['drivers'] ?? {};

    return Column(
      children: [
        // Première ligne : Revenus et Courses
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Revenus du Mois',
                value: '${_formatNumber(revenue['current_month'] ?? 0)} XOF',
                icon: Icons.attach_money,
                color: AppTheme.primaryColor,
                growth: revenue['growth']?.toDouble(),
                subtitle: 'Mois précédent: ${_formatNumber(revenue['last_month'] ?? 0)} XOF',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatCard(
                title: 'Courses Aujourd\'hui',
                value: '${rides['today'] ?? 0}',
                icon: Icons.directions_car,
                color: AppTheme.warningColor,
                subtitle: 'En cours: ${rides['in_progress'] ?? 0}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Deuxième ligne : Utilisateurs et Conducteurs
        Row(
          children: [
            Expanded(
              child: AdminStatCard(
                title: 'Utilisateurs Actifs',
                value: '${users['total'] ?? 0}',
                icon: Icons.people,
                color: AppTheme.successColor,
                subtitle: 'Actifs (30j): ${users['active_30d'] ?? 0}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatCard(
                title: 'Conducteurs Actifs',
                value: '${drivers['active'] ?? 0}',
                icon: Icons.local_taxi,
                color: AppTheme.accentColor,
                subtitle: 'En ligne maintenant',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Graphique des courses des 7 derniers jours (données réelles)
  Widget _buildRidesChart(bool isDark) {
    // Utiliser les données réelles de l'API
    final chartData = ridesChartData.map((day) {
      return ChartDataPoint(
        label: day['label'] ?? '',
        value: (day['count'] ?? 0).toDouble(),
      );
    }).toList();

    if (chartData.isEmpty) {
      // Fallback avec données d'exemple si aucune donnée disponible
      final rides = dashboardStats?['rides'] ?? {};
      return AdminChartCard(
        title: 'Courses des 7 derniers jours',
        subtitle: 'Évolution quotidienne (données d\'exemple)',
        data: [
          ChartDataPoint(label: 'Lun', value: (rides['today'] ?? 0) * 0.8),
          ChartDataPoint(label: 'Mar', value: (rides['today'] ?? 0) * 0.9),
          ChartDataPoint(label: 'Mer', value: (rides['today'] ?? 0) * 1.1),
          ChartDataPoint(label: 'Jeu', value: (rides['today'] ?? 0) * 1.0),
          ChartDataPoint(label: 'Ven', value: (rides['today'] ?? 0) * 1.2),
          ChartDataPoint(label: 'Sam', value: (rides['today'] ?? 0) * 1.3),
          ChartDataPoint(label: 'Dim', value: (rides['today'] ?? 0).toDouble()),
        ],
        chartType: ChartType.bar,
      );
    }

    return AdminChartCard(
      title: 'Courses des 7 derniers jours',
      subtitle: 'Évolution quotidienne',
      data: chartData,
      chartType: ChartType.bar,
    );
  }

  /// Graphique des revenus des 7 derniers jours
  Widget _buildRevenueChart(bool isDark) {
    // Utiliser les données réelles de l'API
    final chartData = revenueChartData.map((day) {
      return ChartDataPoint(
        label: day['label'] ?? '',
        value: (day['amount'] ?? 0).toDouble(),
      );
    }).toList();

    if (chartData.isEmpty) {
      // Fallback avec données d'exemple si aucune donnée disponible
      final revenue = dashboardStats?['revenue'] ?? {};
      return AdminChartCard(
        title: 'Revenus des 7 derniers jours',
        subtitle: 'Évolution quotidienne (données d\'exemple)',
        data: [
          ChartDataPoint(label: 'Lun', value: ((revenue['current_month'] ?? 0) / 30) * 0.8),
          ChartDataPoint(label: 'Mar', value: ((revenue['current_month'] ?? 0) / 30) * 0.9),
          ChartDataPoint(label: 'Mer', value: ((revenue['current_month'] ?? 0) / 30) * 1.1),
          ChartDataPoint(label: 'Jeu', value: ((revenue['current_month'] ?? 0) / 30) * 1.0),
          ChartDataPoint(label: 'Ven', value: ((revenue['current_month'] ?? 0) / 30) * 1.2),
          ChartDataPoint(label: 'Sam', value: ((revenue['current_month'] ?? 0) / 30) * 1.3),
          ChartDataPoint(label: 'Dim', value: ((revenue['current_month'] ?? 0) / 30).toDouble()),
        ],
        chartType: ChartType.bar,
      );
    }

    return AdminChartCard(
      title: 'Revenus des 7 derniers jours',
      subtitle: 'Évolution quotidienne',
      data: chartData,
      chartType: ChartType.bar,
    );
  }

  /// Ancienne méthode de construction des KPIs (gardée pour compatibilité)
  Widget _buildKPICards(bool isDark) {
    return _buildImprovedKPICards(isDark);
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDark, {
    double? growth,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryColor.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (growth != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: growth >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: growth >= 0 ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRideStats(bool isDark) {
    final rides = dashboardStats?['rides'] ?? {};
    return _buildStatCard(
      [
        _buildStatRow('Aujourd\'hui', '${rides['today'] ?? 0}', isDark),
        _buildStatRow('Complétées Aujourd\'hui', '${rides['completed_today'] ?? 0}', isDark),
        _buildStatRow('En Cours', '${rides['in_progress'] ?? 0}', isDark, 
                     valueColor: AppTheme.warningColor),
        _buildStatRow('Ce Mois', '${rides['current_month'] ?? 0}', isDark),
        if (rides['growth'] != null)
          _buildStatRow('Croissance', 
                       '${rides['growth'] >= 0 ? '+' : ''}${rides['growth'].toStringAsFixed(1)}%', 
                       isDark,
                       valueColor: (rides['growth'] as num) >= 0 
                           ? AppTheme.successColor 
                           : AppTheme.errorColor),
      ],
      isDark,
    );
  }

  Widget _buildUserStats(bool isDark) {
    final users = dashboardStats?['users'] ?? {};
    return _buildStatCard(
      [
        _buildStatRow('Total Utilisateurs', '${users['total'] ?? 0}', isDark),
        _buildStatRow('Actifs (30j)', '${users['active_30d'] ?? 0}', isDark),
      ],
      isDark,
    );
  }

  Widget _buildDriverStats(bool isDark) {
    final drivers = dashboardStats?['drivers'] ?? {};
    return _buildStatCard(
      [
        _buildStatRow('Conducteurs Actifs', '${drivers['active'] ?? 0}', isDark),
      ],
      isDark,
    );
  }

  Widget _buildRevenueStats(bool isDark) {
    final revenue = dashboardStats?['revenue'] ?? {};
    return _buildStatCard(
      [
        _buildStatRow('Revenus du Mois', '${_formatNumber(revenue['current_month'] ?? 0)} XOF', isDark),
        _buildStatRow('Mois Précédent', '${_formatNumber(revenue['last_month'] ?? 0)} XOF', isDark),
        _buildStatRow('Commissions', '${_formatNumber(revenue['commissions'] ?? 0)} XOF', isDark),
      ],
      isDark,
    );
  }

  Widget _buildStatCard(List<Widget> children, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.secondaryColor.withOpacity(0.2) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

