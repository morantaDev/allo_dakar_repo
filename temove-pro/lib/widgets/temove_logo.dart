import 'package:flutter/material.dart';
import 'package:temove_pro/theme/app_theme.dart';

/// 🎨 Logo TéMove Pro (Chauffeurs) - Utilise app_logo.png
class TeMoveLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool monochrome;
  final Color? backgroundColor;
  final Color? textColor;

  // Note: Non-const pour permettre le hot reload lors des changements de structure
  TeMoveLogo({
    super.key,
    this.size = 150,
    this.showText = false,
    this.monochrome = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Logo app_logo.png
          Image.asset(
            'assets/icons/app_logo.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.directions_car,
                size: size * 0.6,
                color: AppTheme.secondaryColor,
              );
            },
          ),
          // Texte optionnel
          if (showText)
            Positioned(
              bottom: size * 0.05,
              child: Text(
                'TéMove Pro',
                style: TextStyle(
                  fontSize: size * 0.1,
                  fontWeight: FontWeight.bold,
                  color: textColor ?? AppTheme.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Logo TéMove Pro sans fond (pour usage sur fonds colorés)
class TeMoveLogoOutline extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? iconColor;

  // Note: Non-const pour permettre le hot reload lors des changements de structure
  TeMoveLogoOutline({
    super.key,
    this.size = 150,
    this.showText = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo app_logo.png
          Image.asset(
            'assets/icons/app_logo.png',
            width: size * 0.8,
            height: size * 0.8,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.directions_car,
                size: size * 0.5,
                color: AppTheme.secondaryColor,
              );
            },
          ),
          if (showText) ...[
            SizedBox(height: size * 0.05),
            Text(
              'TéMove Pro',
              style: TextStyle(
                fontSize: size * 0.09,
                fontWeight: FontWeight.bold,
                color: iconColor ?? AppTheme.textPrimary,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Logo compact (pour barre de navigation, etc.)
class TeMoveLogoCompact extends StatelessWidget {
  final double size;
  final Color? color;

  // Note: Non-const pour permettre le hot reload lors des changements de structure
  TeMoveLogoCompact({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: Image.asset(
        'assets/icons/app_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.directions_car,
            size: size * 0.6,
            color: AppTheme.secondaryColor,
          );
        },
      ),
    );
  }
}
