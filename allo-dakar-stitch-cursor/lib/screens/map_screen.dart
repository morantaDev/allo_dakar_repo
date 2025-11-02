import 'package:flutter/material.dart';
import 'package:allo_dakar/theme/app_theme.dart';
import 'package:allo_dakar/screens/booking_screen.dart';
import 'package:allo_dakar/screens/profile_screen.dart';
import 'package:allo_dakar/screens/landmarks_screen.dart';
import 'package:allo_dakar/widgets/map_placeholder.dart';
import 'package:allo_dakar/widgets/app_drawer.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show GoogleMap, GoogleMapController, CameraPosition, LatLng, Marker, MarkerId, BitmapDescriptor, CameraUpdate;
import 'package:flutter/foundation.dart' show kIsWeb;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final LatLng _currentLocation = const LatLng(14.7167, -17.4677); // Dakar
  bool _mapsAvailable = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Sur le web ou si Google Maps n'est pas configuré, utiliser le placeholder
    if (kIsWeb) {
      _mapsAvailable = false;
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  Widget _buildMapWidget() {
    if (!_mapsAvailable) {
      return MapPlaceholder(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        locationName: 'Dakar',
      );
    }

    try {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 13,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: {
          // Marqueur position actuelle
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        },
      );
    } catch (e) {
      // Si erreur, utiliser le placeholder
      return MapPlaceholder(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
        locationName: 'Dakar',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Stack(
        children: [
          // Map ou Placeholder
          _buildMapWidget(),
          // Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu),
                      color: AppTheme.secondaryColor,
                      onPressed: _openDrawer,
                    ),
                  ),
                  // Profile button
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.person),
                      color: AppTheme.secondaryColor,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Search Bar
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Icon(
                      Icons.search,
                      color: AppTheme.secondaryColor,
                      size: 24,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Où allez-vous ?',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 16,
                        ),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final landmark = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LandmarksScreen(),
                          ),
                        );
                        if (landmark != null) {
                          // TODO: Utiliser le landmark sélectionné pour la destination
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.location_on),
                    color: AppTheme.primaryColor,
                    onPressed: () async {
                      final landmark = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LandmarksScreen(),
                        ),
                      );
                      if (landmark != null) {
                        // TODO: Utiliser le landmark
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          // Location button
          Positioned(
            bottom: 200,
            right: 16,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location),
                color: AppTheme.secondaryColor,
                onPressed: () {
                  if (_mapsAvailable && _mapController != null) {
                    try {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_currentLocation, 15),
                      );
                    } catch (e) {
                      // Ignorer l'erreur si la carte n'est pas disponible
                    }
                  }
                },
              ),
            ),
          ),
          // Bottom CTA
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookingScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Réserver un trajet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

