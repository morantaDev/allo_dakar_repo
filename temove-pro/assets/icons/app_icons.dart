import 'package:flutter/material.dart';
import 'package:temove_pro/theme/app_theme.dart';

/// 🎨 Pack d'icônes TéMove Pro (Chauffeurs)
/// Style cohérent avec le logo : professionnel, moderne, vectoriel

/// Icône de courses disponibles
class AvailableRidesIcon extends StatelessWidget {
  final double size;
  final Color? color;
  
  const AvailableRidesIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _AvailableRidesIconPainter(color ?? AppTheme.secondaryColor),
    );
  }
}

class _AvailableRidesIconPainter extends CustomPainter {
  final Color color;
  
  _AvailableRidesIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Liste de courses
    for (int i = 0; i < 3; i++) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.1 + i * size.height * 0.3,
          size.width * 0.8,
          size.height * 0.2,
        ),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de véhicule
class VehicleIcon extends StatelessWidget {
  final double size;
  final Color? color;
  
  const VehicleIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _VehicleIconPainter(color ?? AppTheme.secondaryColor),
    );
  }
}

class _VehicleIconPainter extends CustomPainter {
  final Color color;
  
  _VehicleIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Véhicule stylisé
    final vehicleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.3, size.width * 0.7, size.height * 0.3),
      const Radius.circular(4),
    );
    canvas.drawRRect(vehicleRect, paint);
    
    // Roues
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.7), size.width * 0.1, paint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.7), size.width * 0.1, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de statut en ligne
class OnlineStatusIcon extends StatelessWidget {
  final double size;
  final bool isOnline;
  
  const OnlineStatusIcon({
    super.key,
    this.size = 24,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _OnlineStatusIconPainter(isOnline),
    );
  }
}

class _OnlineStatusIconPainter extends CustomPainter {
  final bool isOnline;
  
  _OnlineStatusIconPainter(this.isOnline);

  @override
  void paint(Canvas canvas, Size size) {
    final color = isOnline ? AppTheme.successColor : Colors.grey;
    
    // Signal de connexion
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    // Cercles concentriques
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.15, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.25, paint..color = color.withOpacity(0.5));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.35, paint..color = color.withOpacity(0.2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de revenus/gains
class EarningsIcon extends StatelessWidget {
  final double size;
  final Color? color;
  
  const EarningsIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _EarningsIconPainter(color ?? AppTheme.successColor),
    );
  }
}

class _EarningsIconPainter extends CustomPainter {
  final Color color;
  
  _EarningsIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Graphique de gains
    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.7);
    path.lineTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.5, size.height * 0.4);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.2);
    canvas.drawPath(path, paint);
    
    // Symbole monétaire
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.2), size.width * 0.08, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
