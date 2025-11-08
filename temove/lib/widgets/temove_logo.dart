import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';

/// Widget logo TeMove utilisant l'image du logo
/// Fond jaune vif avec logo TéMove
class TeMoveLogo extends StatelessWidget {
  final double size;
  final bool showSlogan;
  final Color? backgroundColor;
  final Color? textColor;

  const TeMoveLogo({
    super.key,
    this.size = 150,
    this.showSlogan = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Utiliser la couleur primaire TéMove (#FFC800) uniforme
    final bgColor = backgroundColor ?? AppTheme.primaryColor;
    final txtColor = textColor ?? AppTheme.secondaryColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo TéMove
          SizedBox(
            width: size * 0.8,
            height: size * 0.8,
            child: Image.asset(
              'assets/icons/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          if (showSlogan) ...[
            const SizedBox(height: 4),
            Text(
              'Votre trajet, notre hospitalité',
              style: TextStyle(
                fontSize: size * 0.08,
                color: txtColor.withOpacity(0.8),
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Variante du logo sans fond (pour usage sur fond sombre)
class TeMoveLogoOutline extends StatelessWidget {
  final double size;
  final bool showSlogan;

  const TeMoveLogoOutline({
    super.key,
    this.size = 150,
    this.showSlogan = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo TéMove
          SizedBox(
            width: size * 0.8,
            height: size * 0.8,
            child: Image.asset(
              'assets/icons/app_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          if (showSlogan) ...[
            const SizedBox(height: 4),
            Text(
              'Votre trajet, notre hospitalité',
              style: TextStyle(
                fontSize: size * 0.08,
                color: AppTheme.textPrimary.withOpacity(0.8),
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
