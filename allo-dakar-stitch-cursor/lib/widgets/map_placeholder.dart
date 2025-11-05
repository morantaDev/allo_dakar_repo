import 'dart:ui' as ui show Path, Canvas, Paint, PaintingStyle, Size;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show CustomPainter;
import 'package:temove/theme/app_theme.dart';
import 'package:temove/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget de carte de secours quand Google Maps n'est pas disponible
/// Affiche la position actuelle avec un marqueur
class MapPlaceholder extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final bool showCurrentLocation;

  const MapPlaceholder({
    super.key,
    this.latitude,
    this.longitude,
    this.locationName,
    this.showCurrentLocation = true,
  });

  @override
  State<MapPlaceholder> createState() => _MapPlaceholderState();
}

class _MapPlaceholderState extends State<MapPlaceholder> {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = false;
  final MapController _mapController = MapController();
  // Position par défaut (Dakar) - utilisée immédiatement
  static const double _defaultLat = 14.7167;
  static const double _defaultLng = -17.4677;

  @override
  void initState() {
    super.initState();
    // Initialiser avec la position par défaut ou celle fournie
    if (widget.latitude != null && widget.longitude != null) {
      _currentPosition = Position(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _getAddressFromPosition();
    } else {
      // Utiliser la position par défaut immédiatement pour afficher la carte
      _currentPosition = Position(
        latitude: _defaultLat,
        longitude: _defaultLng,
        timestamp: DateTime.now(),
        accuracy: 1000, // Grande précision = position par défaut
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      
      // Charger la vraie position en arrière-plan si demandé
      if (widget.showCurrentLocation) {
        // Attendre un court délai pour laisser la carte s'afficher d'abord
        Future.delayed(const Duration(milliseconds: 300), () {
          _getCurrentLocation();
        });
      }
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (_isLoadingLocation) return; // Éviter les appels multiples
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final position = await LocationService.getCurrentPosition()
          .timeout(const Duration(seconds: 8)); // Timeout réduit à 8 secondes
      
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        
        // Centrer la carte sur la position (après le prochain frame pour que la carte soit rendue)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _mapController.mapEventStream != null) {
            try {
              _mapController.move(
                LatLng(position.latitude, position.longitude),
                17.0,
              );
            } catch (e) {
              // La carte n'est pas encore prête
            }
          }
        });
        _getAddressFromPosition();
      } else {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      // Timeout ou erreur - garder la position par défaut
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getAddressFromPosition() async {
    if (_currentPosition != null) {
      final address = await LocationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      ).timeout(const Duration(seconds: 5));
      
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayLat = _currentPosition?.latitude ?? _defaultLat;
    final displayLng = _currentPosition?.longitude ?? _defaultLng;
    final currentPoint = LatLng(displayLat, displayLng);
    final isDefaultPosition = _currentPosition?.accuracy == 1000;

    return Stack(
      children: [
        // Carte OpenStreetMap - toujours affichée
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: currentPoint,
            initialZoom: isDefaultPosition ? 14.0 : 16.0, // Zoom optimisé pour meilleure visibilité
            minZoom: 5.0,
            maxZoom: 19.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            // Améliorer la qualité du rendu
            keepAlive: true,
          ),
          children: [
            // Tuiles de carte - Utiliser Esri WorldStreetMap (très similaire à Google Maps)
            TileLayer(
              urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
              userAgentPackageName: 'com.temove.app',
              maxZoom: 19,
              maxNativeZoom: 19,
              tileProvider: NetworkTileProvider(),
              errorTileCallback: (tile, error, stackTrace) {
                // Fallback vers OpenStreetMap si Esri échoue
              },
            ),
            // Cercle de précision (si accuracy disponible et < 500m)
            if (_currentPosition != null && 
                _currentPosition!.accuracy > 0 && 
                _currentPosition!.accuracy < 500)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: currentPoint,
                    radius: _currentPosition!.accuracy,
                    useRadiusInMeter: true,
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderColor: AppTheme.primaryColor.withOpacity(0.4),
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            // Marqueur de position
            MarkerLayer(
              markers: [
                Marker(
                  point: currentPoint,
                  width: 40,
                  height: 55,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pin de localisation
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isLoadingLocation 
                              ? Colors.grey.shade400 
                              : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isLoadingLocation
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 24,
                              ),
                      ),
                      // Pointe du pin
                      CustomPaint(
                        size: const ui.Size(10, 15),
                        painter: _PinTailPainter(
                          color: _isLoadingLocation 
                              ? Colors.grey.shade400 
                              : AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // Indicateur de chargement en haut (discret)
        if (_isLoadingLocation)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chargement de la position...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        // Informations de position en bas (si disponible)
        if (_currentAddress != null && !_isLoadingLocation && !isDefaultPosition)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentAddress!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${displayLat.toStringAsFixed(4)}, ${displayLng.toStringAsFixed(4)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bouton pour actualiser la position
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _getCurrentLocation,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.refresh,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Bouton de localisation (flottant)
        if (!_isLoadingLocation)
          Positioned(
            bottom: _currentAddress != null && !isDefaultPosition ? 90 : 16,
            right: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location),
                  color: AppTheme.primaryColor,
                  onPressed: _getCurrentLocation,
                  tooltip: 'Actualiser la position',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Peintre pour la pointe du pin
class _PinTailPainter extends CustomPainter {
  final Color color;

  _PinTailPainter({required this.color});

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

