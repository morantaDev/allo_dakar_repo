import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';

/// Widget de carte avec graphique simple pour le dashboard admin
/// Affiche une série de données sous forme de barres ou lignes
class AdminChartCard extends StatelessWidget {
  final String title;
  final List<ChartDataPoint> data;
  final ChartType chartType;
  final String? subtitle;

  const AdminChartCard({
    super.key,
    required this.title,
    required this.data,
    this.chartType = ChartType.bar,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? AppTheme.secondaryColor.withOpacity(0.3) 
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark 
                  ? AppTheme.textPrimary 
                  : AppTheme.textSecondary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: isDark 
                    ? AppTheme.textMuted 
                    : Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Graphique
          if (chartType == ChartType.bar)
            _buildBarChart(context, isDark)
          else
            _buildLineChart(context, isDark),
        ],
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, bool isDark) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Aucune donnée disponible'),
        ),
      );
    }

    final maxValue = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
    ];

    return SizedBox(
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: data.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          final height = maxValue > 0 ? (point.value / maxValue) * 180 : 0.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Barre
                  Flexible(
                    flex: 1,
                    child: Container(
                      height: height.clamp(0.0, 180.0),
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Label
                  Flexible(
                    flex: 0,
                    child: Text(
                      point.label,
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark 
                            ? AppTheme.textMuted 
                            : Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Valeur
                  Flexible(
                    flex: 0,
                    child: Text(
                      _formatValue(point.value),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark 
                            ? AppTheme.textPrimary 
                            : AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, bool isDark) {
    // Implémentation simple d'un graphique linéaire
    // Pour une version plus avancée, utiliser un package comme fl_chart
    return SizedBox(
      height: 200,
      child: Center(
        child: Text(
          'Graphique linéaire (à implémenter avec fl_chart)',
          style: TextStyle(
            color: isDark 
                ? AppTheme.textMuted 
                : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }
}

/// Type de graphique
enum ChartType {
  bar,
  line,
}

/// Point de données pour les graphiques
class ChartDataPoint {
  final String label;
  final double value;
  final Color? color;

  ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

