import 'package:flutter/material.dart';
import 'package:allo_dakar/theme/app_theme.dart';

/// Widget de carte de secours quand Google Maps n'est pas disponible
class MapPlaceholder extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;

  const MapPlaceholder({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName = 'Dakar',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: Stack(
        children: [
          // Fond avec motif de carte
          CustomPaint(
            painter: _MapPatternPainter(),
            child: const SizedBox.expand(),
          ),
          // Overlay sombre
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // Contenu centré
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.white.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carte de Dakar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                if (locationName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    locationName!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    'Configurez Google Maps pour voir la carte',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 1;

    // Lignes verticales (routes)
    for (double x = 0; x < size.width; x += size.width / 8) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint..color = Colors.grey.shade700.withOpacity(0.3),
      );
    }

    // Lignes horizontales (routes)
    for (double y = 0; y < size.height; y += size.height / 8) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint..color = Colors.grey.shade700.withOpacity(0.3),
      );
    }

    // Points représentant des bâtiments/localisations
    final pointPaint = Paint()
      ..color = Colors.grey.shade600.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 20; i++) {
      final x = (i * 37) % size.width.toInt();
      final y = (i * 53) % size.height.toInt();
      canvas.drawCircle(Offset(x.toDouble(), y.toDouble()), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

