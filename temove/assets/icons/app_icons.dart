import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';

/// 🎨 Pack d'icônes TéMove (Client)
/// Style cohérent avec le logo : minimaliste, moderne, vectoriel

/// Icône de réservation/booking
class BookingIcon extends StatelessWidget {
  final double size;
  final Color? color;
  
  const BookingIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BookingIconPainter(color ?? AppTheme.primaryColor),
    );
  }
}

class _BookingIconPainter extends CustomPainter {
  final Color color;
  
  _BookingIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path();
    // Calendrier stylisé
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.15, size.width * 0.8, size.height * 0.7),
      const Radius.circular(4),
    ));
    // Lignes de dates
    for (int i = 0; i < 3; i++) {
      path.addRect(Rect.fromLTWH(
        size.width * 0.2 + i * size.width * 0.25,
        size.height * 0.4,
        size.width * 0.15,
        size.height * 0.1,
      ));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de trajet/ride
class RideIcon extends StatelessWidget {
  final double size;
  final Color? color;
  
  const RideIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RideIconPainter(color ?? AppTheme.primaryColor),
    );
  }
}

class _RideIconPainter extends CustomPainter {
  final Color color;
  
  _RideIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Flèche de trajet
    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.4);
    path.moveTo(size.width * 0.7, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.6);
    
    // Points de départ/arrivée
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.5), size.width * 0.08, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), size.width * 0.08, paint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de paiement
class PaymentIcon extends StatelessWidget {
  final double size;
  final Color? color;
  
  const PaymentIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PaymentIconPainter(color ?? AppTheme.primaryColor),
    );
  }
}

class _PaymentIconPainter extends CustomPainter {
  final Color color;
  
  _PaymentIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Carte de crédit stylisée
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.1, size.height * 0.3, size.width * 0.8, size.height * 0.4),
      const Radius.circular(4),
    );
    canvas.drawRRect(rect, paint);
    
    // Lignes de sécurité
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * 0.2 + i * size.width * 0.2, size.height * 0.5),
        Offset(size.width * 0.3 + i * size.width * 0.2, size.height * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Icône de notification
class NotificationIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool hasBadge;
  
  const NotificationIcon({
    super.key,
    this.size = 24,
    this.color,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _NotificationIconPainter(
        color ?? AppTheme.primaryColor,
        hasBadge,
      ),
    );
  }
}

class _NotificationIconPainter extends CustomPainter {
  final Color color;
  final bool hasBadge;
  
  _NotificationIconPainter(this.color, this.hasBadge);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Cloche
    final path = Path();
    path.moveTo(size.width * 0.5, size.height * 0.2);
    path.arcToPoint(
      Offset(size.width * 0.8, size.height * 0.5),
      radius: const Radius.circular(size.width * 0.3),
      clockwise: false,
    );
    path.lineTo(size.width * 0.2, size.height * 0.5);
    path.arcToPoint(
      Offset(size.width * 0.5, size.height * 0.2),
      radius: const Radius.circular(size.width * 0.3),
      clockwise: false,
    );
    path.close();
    canvas.drawPath(path, paint);
    
    // Badge de notification
    if (hasBadge) {
      final badgePaint = Paint()
        ..color = AppTheme.errorColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.25),
        size.width * 0.12,
        badgePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
