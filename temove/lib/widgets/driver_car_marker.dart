import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';

/// Widget pour afficher un marqueur animé de voiture sur la carte
/// 
/// Simule le mouvement du chauffeur vers le client avec une animation fluide
class DriverCarMarker extends StatefulWidget {
  final double? heading; // Direction en degrés (0-360)
  final bool isMoving; // Si la voiture est en mouvement

  const DriverCarMarker({
    super.key,
    this.heading,
    this.isMoving = true,
  });

  @override
  State<DriverCarMarker> createState() => _DriverCarMarkerState();
}

class _DriverCarMarkerState extends State<DriverCarMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    if (widget.isMoving) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DriverCarMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isMoving && !oldWidget.isMoving) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isMoving && oldWidget.isMoving) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isMoving ? _pulseAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.heading != null
                ? (widget.heading! * 3.14159 / 180) - (3.14159 / 2)
                : 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        );
      },
    );
  }
}

