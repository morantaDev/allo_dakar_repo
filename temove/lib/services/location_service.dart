import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// Service de géolocalisation utilisant uniquement geolocator (sans Google Maps API)
class LocationService {
  /// Vérifier et demander les permissions de localisation
  static Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Le service de localisation n'est pas activé
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Les permissions sont refusées
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Les permissions sont refusées de manière permanente
      return false;
    }

    return true;
  }

  /// Obtenir la position actuelle de l'utilisateur
  static Future<Position?> getCurrentPosition() async {
    try {
      bool hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) {
        print('Permissions de localisation refusées');
        return getDefaultPosition(); // Retourner position par défaut (Dakar)
      }

      // Ajuster la précision selon la plateforme
      // Utiliser une précision moyenne pour être plus rapide (on peut améliorer ensuite si nécessaire)
      LocationAccuracy accuracy = kIsWeb 
          ? LocationAccuracy.medium  // Medium pour le web (plus rapide)
          : LocationAccuracy.medium;  // Medium pour mobile aussi (plus rapide que high)
      
      // Timeout réduit pour une réponse plus rapide
      Duration timeout = kIsWeb 
          ? const Duration(seconds: 8) 
          : const Duration(seconds: 8);

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: timeout,
        forceAndroidLocationManager: false,
      );

      // Vérifier que la position est valide
      if (position.latitude.isNaN || position.longitude.isNaN ||
          position.latitude.isInfinite || position.longitude.isInfinite) {
        print('Position invalide reçue, utilisation de la position par défaut');
        return getDefaultPosition();
      }

      return position;
    } on TimeoutException catch (e) {
      print('Timeout lors de la récupération de la position: $e');
      print('Utilisation de la position par défaut (Dakar)');
      return getDefaultPosition();
    } catch (e) {
      print('Erreur lors de la récupération de la position: $e');
      return getDefaultPosition();
    }
  }

  /// Position par défaut (Dakar) si la géolocalisation échoue
  static Position getDefaultPosition() {
    return Position(
      latitude: 14.7167,  // Dakar
      longitude: -17.4677,
      timestamp: DateTime.now(),
      accuracy: 1000, // 1 km de précision par défaut
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Obtenir la position actuelle avec un callback en temps réel
  static Stream<Position>? getPositionStream() {
    // Ajuster la précision selon la plateforme
    LocationAccuracy accuracy = kIsWeb 
        ? LocationAccuracy.medium 
        : LocationAccuracy.high;
    
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: kIsWeb ? 10 : 5, // Plus de mètres sur web pour éviter trop de mises à jour
      ),
    );
  }

  /// Calculer la distance entre deux points (en mètres)
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculer la distance en kilomètres
  static double calculateDistanceInKm(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return calculateDistance(
          startLatitude,
          startLongitude,
          endLatitude,
          endLongitude,
        ) /
        1000;
  }

  /// Obtenir l'adresse à partir de coordonnées (géocodage inversé)
  static Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // Vérifier que les coordonnées sont valides
      if (latitude.isNaN || longitude.isNaN || 
          latitude.isInfinite || longitude.isInfinite) {
        return null;
      }

      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  // Timeout silencieux
                  return <Placemark>[];
                },
              );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        try {
          if (place.street != null && place.street!.isNotEmpty) {
            address += place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += place.subLocality!;
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += place.locality!;
          }
          if (place.country != null && place.country!.isNotEmpty) {
            if (address.isNotEmpty) address += ', ';
            address += place.country!;
          }
        } catch (e) {
          // Si erreur lors de la construction de l'adresse, continuer
          // Ne pas afficher pour éviter les logs excessifs
        }

        return address.isNotEmpty ? address : 'Position inconnue';
      }
      return null;
    } on TimeoutException {
      // Timeout silencieux, retourner null
      return null;
    } catch (e) {
      // Ne pas afficher l'erreur pour éviter les logs excessifs
      // Les erreurs de géocodage sont normales (adresses non trouvées)
      return null;
    }
  }

  /// Obtenir les coordonnées à partir d'une adresse (géocodage)
  static Future<Position?> getCoordinatesFromAddress(String address) async {
    // Déclarer searchQuery en dehors du try pour qu'il soit accessible dans le catch
    String searchQuery = address.trim();
    
    try {
      // Vérifier que l'adresse n'est pas vide
      if (address.isEmpty || address.trim().isEmpty) {
        return null;
      }

      // Normaliser la recherche et ajouter le contexte géographique si nécessaire
      final lowerQuery = searchQuery.toLowerCase();
      
      // Si ce n'est pas déjà une recherche avec contexte (Dakar, Sénégal, etc.)
      final hasContext = lowerQuery.contains('dakar') || 
                        lowerQuery.contains('senegal') || 
                        lowerQuery.contains('sénégal') ||
                        lowerQuery.contains('thies') ||
                        lowerQuery.contains('thiès');
      
      if (!hasContext) {
        // Ajouter "Dakar, Sénégal" pour améliorer les résultats de géocodage
        searchQuery = '$searchQuery, Dakar, Sénégal';
      } else if (lowerQuery.contains('thies') || lowerQuery.contains('thiès')) {
        // Pour Thiès, ajouter le contexte Sénégal si pas déjà présent
        if (!lowerQuery.contains('senegal') && !lowerQuery.contains('sénégal')) {
          searchQuery = '$searchQuery, Sénégal';
        }
      }

      print('Recherche de géocodage: $searchQuery');
      
      List<Location> locations;
      try {
        locations = await locationFromAddress(searchQuery)
            .timeout(
              const Duration(seconds: 15), // Timeout plus long pour le web
              onTimeout: () {
                print('Timeout lors du géocodage de: $searchQuery');
                return <Location>[];
              },
            );
      } catch (e) {
        // Capturer les erreurs de null ou autres erreurs de la bibliothèque geocoding
        print('Erreur lors de l\'appel locationFromAddress: $e');
        if (e.toString().contains('null') || e.toString().contains('Null')) {
          print('Erreur null détectée dans locationFromAddress pour: $searchQuery');
          print('Tentative de fallback avec la base de données locale...');
        }
        
        // Utiliser le fallback local si disponible
        // Particulièrement utile sur le web où geocoding ne fonctionne pas bien
        final localPosition = _searchLocalCoordinates(address.trim());
        if (localPosition != null) {
          print('Utilisation des coordonnées locales pour: ${address.trim()}');
          return localPosition;
        }
        
        return null;
      }

      if (locations.isNotEmpty) {
        Location location = locations[0];
        
        // Vérifier que les coordonnées ne sont pas null
        final lat = location.latitude;
        final lng = location.longitude;
        
        if (lng == null) {
          print('Coordonnées null reçues pour: $searchQuery');
          return null;
        }
        
        print('Géocodage réussi: $lat, $lng');
        
        // Vérifier que les coordonnées sont valides (pas NaN ni Infinite)
        if (lat.isNaN || lng.isNaN || lat.isInfinite || lng.isInfinite) {
          print('Coordonnées invalides reçues');
          return null;
        }

        return Position(
          latitude: lat,
          longitude: lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      } else {
        print('Aucun résultat trouvé pour: $searchQuery');
        // Essayer le fallback local avant de retourner null
        final localPosition = _searchLocalCoordinates(address.trim());
        if (localPosition != null) {
          print('Utilisation des coordonnées locales pour: ${address.trim()}');
          return localPosition;
        }
      }
      return null;
    } on TimeoutException catch (e) {
      print('Timeout exception lors du géocodage: $e');
      return null;
    } catch (e, stackTrace) {
      // Gestion plus détaillée des erreurs pour le débogage
      print('Erreur lors du géocodage: $e');
      print('Stack trace: $stackTrace');
      
      // Si c'est une erreur de null, la gérer spécifiquement
      if (e.toString().contains('null') || e.toString().contains('Null')) {
        print('Erreur de valeur null détectée pour: $searchQuery');
        print('Tentative de fallback avec la base de données locale...');
      }
      
      // Essayer le fallback local en dernier recours
      final localPosition = _searchLocalCoordinates(address.trim());
      if (localPosition != null) {
        print('Utilisation des coordonnées locales (fallback) pour: ${address.trim()}');
        return localPosition;
      }
      
      return null;
    }
  }

  /// Base de données locale de coordonnées pour les lieux populaires au Sénégal
  /// Utilisé comme fallback quand le géocodage en ligne échoue (notamment sur le web)
  static final Map<String, Position> _localCoordinates = {
    // Villes principales
    'dakar': Position(
      latitude: 14.7167,
      longitude: -17.4677,
      timestamp: DateTime.now(),
      accuracy: 1000,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'thies': Position(
      latitude: 14.7833,
      longitude: -16.9167,
      timestamp: DateTime.now(),
      accuracy: 1000,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'thiès': Position(
      latitude: 14.7833,
      longitude: -16.9167,
      timestamp: DateTime.now(),
      accuracy: 1000,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    // Lieux populaires à Dakar
    'liberté': Position(
      latitude: 14.7500,
      longitude: -17.4500,
      timestamp: DateTime.now(),
      accuracy: 500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'sandaga': Position(
      latitude: 14.7167,
      longitude: -17.4677,
      timestamp: DateTime.now(),
      accuracy: 500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'marché sandaga': Position(
      latitude: 14.7167,
      longitude: -17.4677,
      timestamp: DateTime.now(),
      accuracy: 500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'plateau': Position(
      latitude: 14.7167,
      longitude: -17.4677,
      timestamp: DateTime.now(),
      accuracy: 500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'almadies': Position(
      latitude: 14.7500,
      longitude: -17.5000,
      timestamp: DateTime.now(),
      accuracy: 500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'yoff': Position(
      latitude: 14.7500,
      longitude: -17.4833,
      timestamp: DateTime.now(),
      accuracy: 500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
    'gare routière': Position(
      latitude: 14.7000,
      longitude: -17.4500,
      timestamp: DateTime.now(),
      accuracy: 500,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    ),
  };

  /// Rechercher dans la base de données locale
  static Position? _searchLocalCoordinates(String query) {
    // Nettoyer la requête : enlever les suffixes comme ", Dakar, Sénégal"
    String cleanQuery = query.toLowerCase().trim();
    cleanQuery = cleanQuery.replaceAll(RegExp(r',\s*(dakar|senegal|sénégal).*'), '');
    cleanQuery = cleanQuery.trim();
    
    // Recherche exacte
    if (_localCoordinates.containsKey(cleanQuery)) {
      return _localCoordinates[cleanQuery];
    }
    
    // Recherche partielle (la requête contient le lieu ou le lieu contient la requête)
    for (final entry in _localCoordinates.entries) {
      final key = entry.key;
      // Si la requête contient au moins 3 caractères et correspond partiellement
      if (cleanQuery.length >= 3) {
        if (cleanQuery.contains(key) || key.contains(cleanQuery)) {
          return entry.value;
        }
      }
    }
    
    // Recherche spéciale pour des variations communes
    if (cleanQuery.startsWith('thi') || cleanQuery == 'thi') {
      return _localCoordinates['thies'];
    }
    
    if (cleanQuery.contains('sandaga')) {
      return _localCoordinates['sandaga'];
    }
    
    if (cleanQuery.contains('liberte') || cleanQuery.contains('liberté')) {
      return _localCoordinates['liberté'];
    }
    
    return null;
  }

  /// Obtenir le bearing (direction) entre deux points
  static double getBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Vérifier si le service de localisation est activé
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Ouvrir les paramètres de localisation
  static Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Ouvrir les paramètres d'application
  static Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}

