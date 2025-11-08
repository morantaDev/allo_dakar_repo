import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';

/// Widget de carte statistique pour le dashboard admin
/// Affiche une métrique avec icône, valeur, label et indicateur de croissance
class AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? growth;
  final String? subtitle;
  final VoidCallback? onTap;

  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.growth,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // En-tête avec icône et croissance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                if (growth != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (growth! >= 0 
                          ? AppTheme.successColor 
                          : AppTheme.errorColor).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          growth! >= 0 ? Icons.trending_up : Icons.trending_down,
                          size: 16,
                          color: growth! >= 0 
                              ? AppTheme.successColor 
                              : AppTheme.errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${growth! >= 0 ? '+' : ''}${growth!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: growth! >= 0 
                                ? AppTheme.successColor 
                                : AppTheme.errorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Label
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isDark 
                    ? AppTheme.textMuted 
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            // Valeur
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark 
                    ? AppTheme.textPrimary 
                    : AppTheme.textSecondary,
                height: 1.2,
              ),
            ),
            // Sous-titre optionnel
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark 
                      ? AppTheme.textMuted 
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

