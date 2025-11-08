import 'package:flutter/material.dart';
import 'package:temove_pro/theme/app_theme.dart';

/// Widget logo TeMove uniformisé entre Client et Pro
/// Utilise les couleurs TéMove : jaune (#FFC800), noir, vert
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
      child: Padding(
        padding: EdgeInsets.all(size * 0.1), // Padding pour éviter le débordement
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Prendre seulement l'espace nécessaire
          children: [
            // Logo TéMove - Utiliser Flexible pour éviter le débordement
            Flexible(
              child: SizedBox(
                width: double.infinity,
                height: showSlogan ? size * 0.65 : size * 0.8, // Réduire la taille si slogan présent
                child: Image.asset(
                  'assets/icons/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback vers l'icône si l'image n'existe pas
                    return Icon(
                      Icons.directions_car,
                      size: showSlogan ? size * 0.5 : size * 0.6,
                      color: txtColor,
                    );
                  },
                ),
              ),
            ),
            if (showSlogan) ...[
              SizedBox(height: size * 0.03), // Espacement réduit
              Flexible(
                child: Text(
                  'Votre trajet, notre hospitalité',
                  style: TextStyle(
                    fontSize: size * 0.07, // Taille réduite
                    color: txtColor.withOpacity(0.8),
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Limiter à 2 lignes
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Variante du logo sans fond (pour usage sur fond sombre)
/// Uniformisé avec l'application Client
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
      child: Padding(
        padding: EdgeInsets.all(size * 0.1), // Padding pour éviter le débordement
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Prendre seulement l'espace nécessaire
          children: [
            // Logo TéMove - Utiliser Flexible pour éviter le débordement
            Flexible(
              child: SizedBox(
                width: double.infinity,
                height: showSlogan ? size * 0.65 : size * 0.8, // Réduire la taille si slogan présent
                child: Image.asset(
                  'assets/icons/app_logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback vers l'icône si l'image n'existe pas
                    return Icon(
                      Icons.directions_car,
                      size: showSlogan ? size * 0.5 : size * 0.6,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
            ),
            if (showSlogan) ...[
              SizedBox(height: size * 0.03), // Espacement réduit
              Flexible(
                child: Text(
                  'Votre trajet, notre hospitalité',
                  style: TextStyle(
                    fontSize: size * 0.07, // Taille réduite
                    color: AppTheme.textPrimary.withOpacity(0.8),
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2, // Limiter à 2 lignes
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

