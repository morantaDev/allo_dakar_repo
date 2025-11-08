import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
// Import conditionnel pour l'upload audio sur le web
import 'web_audio_upload_stub.dart' if (dart.library.html) 'web_audio_upload.dart';

/// Service API pour communiquer avec le backend Flask TeMove
/// 
/// Ce service gère toutes les requêtes HTTP entre l'application Flutter
/// et l'API Flask backend. Il inclut :
/// - Authentification (inscription, connexion)
/// - Gestion des courses (estimation, réservation, historique)
/// - Administration (statistiques, dashboard)
/// - Gestion des tokens JWT
/// 
/// Note: Les URLs s'adaptent automatiquement selon la plateforme
/// (Web, Android, iOS) pour garantir la compatibilité CORS.
class ApiService {
  /// URL de base du backend - s'adapte automatiquement selon la plateforme
  /// 
  /// - Web (Flutter Web) : http://127.0.0.1:5000/api/v1
  /// - Android émulateur : http://10.0.2.2:5000/api/v1
  /// - Android/iOS physique : http://<IP_LOCALE>:5000/api/v1
  static String get baseUrl {
    if (kIsWeb) {
      // Pour Flutter Web, utiliser localhost
      return 'http://127.0.0.1:5000/api/v1';
    } else {
      // Pour Android émulateur, utiliser 10.0.2.2 (alias pour localhost)
      // Pour un appareil physique, utiliser votre IP locale
      // TODO: Configurer cette IP via les variables d'environnement
      return 'http://192.168.18.10:5000/api/v1';
    }
  }
  
  /// Inscription d'un nouvel utilisateur
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      print('📝 [REGISTER] Tentative d\'inscription pour: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      );

      print('📥 [REGISTER] Réponse reçue - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur',
        };
      }

      // Vérifier si la réponse est du JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return {
          'success': false,
          'message': 'Le serveur a retourné une réponse invalide. Vérifiez que le backend est démarré.',
        };
      }

      // Parser le JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ [REGISTER] Erreur parsing JSON: $e');
        return {
          'success': false,
          'message': 'Réponse invalide du serveur.',
        };
      }

      if (response.statusCode == 201) {
        // Sauvegarder le token
        if (data['access_token'] != null) {
          final token = data['access_token'] as String;
          print('🔑 [REGISTER] Token reçu du backend: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
          await _saveAuthToken(token);
          
          final savedToken = await _getAuthToken();
          if (savedToken != null) {
            print('✅ [REGISTER] Token sauvegardé avec succès');
          } else {
            print('❌ [REGISTER] Erreur: Le token n\'a pas pu être sauvegardé');
          }
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Inscription réussie',
          'user': data['user'],
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
        };
      } else {
        print('❌ [REGISTER] Erreur - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e) {
      print('❌ [REGISTER] Exception: ${e.toString()}');
      String errorMessage = 'Erreur de connexion';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré.';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Connexion refusée. Le backend n\'est pas accessible sur le port 5000';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Connexion d'un utilisateur
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [LOGIN] Tentative de connexion pour: $email');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📥 [LOGIN] Réponse reçue - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        print('❌ [LOGIN] Réponse vide du serveur');
        return {
          'success': false,
          'message': 'Réponse vide du serveur',
        };
      }

      // Vérifier si la réponse est du JSON
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        print('❌ [LOGIN] Réponse non-JSON reçue: $contentType');
        return {
          'success': false,
          'message': 'Le serveur a retourné une réponse invalide.',
        };
      }

      // Parser le JSON
      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ [LOGIN] Erreur parsing JSON: $e');
        return {
          'success': false,
          'message': 'Réponse invalide du serveur.',
        };
      }

      if (response.statusCode == 200) {
        // Sauvegarder le token
        if (data['access_token'] != null) {
          final token = data['access_token'] as String;
          print('🔑 [LOGIN] Token reçu du backend: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
          await _saveAuthToken(token);
          
          final savedToken = await _getAuthToken();
          if (savedToken != null) {
            print('✅ [LOGIN] Token sauvegardé avec succès - Longueur: ${savedToken.length}');
            print('✅ [LOGIN] Token sauvegardé (premiers 30 chars): ${savedToken.substring(0, savedToken.length > 30 ? 30 : savedToken.length)}...');
          } else {
            print('❌ [LOGIN] Erreur: Le token n\'a pas pu être sauvegardé');
          }
        } else {
          print('⚠️ [LOGIN] Aucun token reçu dans la réponse de connexion');
        }
        
        return {
          'success': true,
          'message': data['message'] ?? 'Connexion réussie',
          'user': data['user'],
          'access_token': data['access_token'],
          'refresh_token': data['refresh_token'],
        };
      } else {
        print('❌ [LOGIN] Erreur de connexion - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': data['error'] ?? data['message'] ?? 'Erreur lors de la connexion',
        };
      }
    } catch (e) {
      print('❌ [LOGIN] Exception: ${e.toString()}');
      String errorMessage = 'Erreur de connexion';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Impossible de se connecter au serveur.';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Connexion refusée. Le backend n\'est pas accessible.';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Sauvegarde le token d'authentification dans le stockage local
  static Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Nettoyer le token avant de le sauvegarder (enlever "Bearer " s'il est présent)
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      await prefs.setString('access_token', cleanToken);
      print('💾 [SAVE_TOKEN] Token sauvegardé - Longueur: ${cleanToken.length}');
      print('💾 [SAVE_TOKEN] Token (premiers 30 chars): ${cleanToken.substring(0, cleanToken.length > 30 ? 30 : cleanToken.length)}...');
    } catch (e) {
      print('❌ [SAVE_TOKEN] Erreur lors de la sauvegarde: $e');
    }
  }

  /// Supprime le token d'authentification du stockage local
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    print('🗑️ [CLEAR_TOKEN] Token supprimé');
  }

  /// Obtient le token d'authentification depuis le stockage local
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token != null) {
        print('📖 [GET_TOKEN] Token récupéré - Longueur: ${token.length}');
        print('📖 [GET_TOKEN] Token (premiers 30 chars): ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      } else {
        print('⚠️ [GET_TOKEN] Aucun token trouvé dans le stockage');
      }
      return token;
    } catch (e) {
      print('❌ [GET_TOKEN] Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// Obtient une estimation de trajet depuis l'API
  static Future<Map<String, dynamic>> getTripEstimate({
    required double departureLat,
    required double departureLng,
    required double destinationLat,
    required double destinationLng,
    String? rideMode,
  }) async {
    try {
      print('📊 [ESTIMATE] Début de l\'estimation');
      
      // Récupérer le token d'authentification
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ [ESTIMATE] Token manquant');
        return {
          'success': false,
          'message': 'Authentification requise. Veuillez vous connecter.',
        };
      }
      
      // Nettoyer le token (enlever "Bearer " s'il est déjà présent)
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      
      print('🔑 [ESTIMATE] Token nettoyé - Longueur: ${cleanToken.length}');
      
      // ✅ CORRECTION : Utiliser les bons noms de champs que le backend attend
      final requestBody = {
        'pickup_latitude': departureLat,      // Changé de 'departure_lat'
        'pickup_longitude': departureLng,     // Changé de 'departure_lng'
        'dropoff_latitude': destinationLat,   // Changé de 'destination_lat'
        'dropoff_longitude': destinationLng,  // Changé de 'destination_lng'
        'ride_mode': rideMode ?? 'standard',  // Valeur par défaut
      };
      
      // 🔍 LOG POUR DÉBOGUER - Afficher les données exactes envoyées
      print('📦 [ESTIMATE] Données envoyées:');
      print(jsonEncode(requestBody));
      print('🔍 [ESTIMATE] Types des données:');
      print('  pickup_latitude: ${departureLat.runtimeType} = $departureLat');
      print('  pickup_longitude: ${departureLng.runtimeType} = $departureLng');
      print('  dropoff_latitude: ${destinationLat.runtimeType} = $destinationLat');
      print('  dropoff_longitude: ${destinationLng.runtimeType} = $destinationLng');
      print('  ride_mode: ${(rideMode ?? 'standard').runtimeType} = ${rideMode ?? 'standard'}');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };
      
      print('📤 [ESTIMATE] Envoi de la requête vers: $baseUrl/rides/estimate');
      print('📤 [ESTIMATE] Headers: ${headers.keys.toList()}');
      print('📤 [ESTIMATE] Authorization (premiers 40 chars): ${headers['Authorization']?.substring(0, 40)}...');
      print('📤 [ESTIMATE] Body length: ${jsonEncode(requestBody).length} caractères');
      
      print('📤 [ESTIMATE] Envoi de la requête POST maintenant...');
      
      http.Response response;
      
      // Sur Flutter Web, utiliser http.post directement (plus fiable)
      if (kIsWeb) {
        print('🌐 [ESTIMATE] Mode Web détecté - Utilisation de http.post');
        print('🌐 [ESTIMATE] URL complète: ${Uri.parse('$baseUrl/rides/estimate')}');
        print('🌐 [ESTIMATE] Headers envoyés: $headers');
        try {
          response = await http.post(
            Uri.parse('$baseUrl/rides/estimate'),
            headers: headers,
            body: jsonEncode(requestBody),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ [ESTIMATE] Timeout - La requête a pris trop de temps');
              throw Exception('Timeout: La requête a pris trop de temps');
            },
          );
          print('✅ [ESTIMATE] Requête HTTP envoyée - Status: ${response.statusCode}');
        } catch (e, stackTrace) {
          print('❌ [ESTIMATE] Erreur lors de l\'envoi HTTP: $e');
          print('❌ [ESTIMATE] Stack trace: $stackTrace');
          rethrow;
        }
      } else {
        // Pour les autres plateformes, utiliser Request pour plus de contrôle
        final uri = Uri.parse('$baseUrl/rides/estimate');
        final request = http.Request('POST', uri);
        request.headers.addAll(headers);
        request.body = jsonEncode(requestBody);
        
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout: La requête a pris trop de temps');
          },
        );
        
        response = await http.Response.fromStream(streamedResponse);
      }
      
      print('✅ [ESTIMATE] Requête POST envoyée avec succès');
      print('📥 [ESTIMATE] Réponse reçue - Status: ${response.statusCode}');
      print('📥 [ESTIMATE] Body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur. Vérifiez que le backend est démarré.',
        };
      }

      // Parser le JSON
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        final contentType = response.headers['content-type'] ?? '';
        print('❌ [ESTIMATE] Erreur parsing JSON: $e');
        print('❌ [ESTIMATE] Content-Type: $contentType');
        print('❌ [ESTIMATE] Body (premiers 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        
        if (response.statusCode == 404) {
          return {
            'success': false,
            'message': 'Endpoint non trouvé. Vérifiez que l\'endpoint /api/v1/rides/estimate existe.',
          };
        } else if (response.statusCode == 422) {
          return {
            'success': false,
            'message': 'Données invalides. Vérifiez les logs du backend pour plus de détails.',
          };
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          return {
            'success': false,
            'message': 'Authentification requise. Veuillez vous reconnecter.',
          };
        } else if (response.statusCode == 500) {
          return {
            'success': false,
            'message': 'Erreur serveur (500). Vérifiez les logs du backend.',
          };
        }
        
        return {
          'success': false,
          'message': 'Réponse invalide du serveur (${response.statusCode}).',
        };
      }

      if (response.statusCode == 200) {
        print('✅ [ESTIMATE] Estimation réussie');
        print('📦 [ESTIMATE] Structure des données reçues: ${data.keys.toList()}');
        
        // Le backend retourne {'estimate': {...}, 'promo_applied': bool}
        // On doit extraire 'estimate' et le mettre dans 'data'
        final estimateData = data['estimate'] ?? data;
        print('📦 [ESTIMATE] Données d\'estimation extraites: ${estimateData.keys.toList()}');
        
        return {
          'success': true,
          'data': estimateData,  // Retourner directement les données d'estimation
        };
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? 'Erreur lors du calcul de l\'estimation (${response.statusCode})';
        print('❌ [ESTIMATE] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [ESTIMATE] Exception: $e');
      print('❌ [ESTIMATE] Type d\'erreur: ${e.runtimeType}');
      
      // Détails supplémentaires pour les erreurs de réseau
      String errorMessage = 'Erreur lors du calcul de l\'estimation';
      if (e.toString().contains('Failed to fetch') || e.toString().contains('Failed host lookup')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur http://127.0.0.1:5000';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Connexion refusée. Le backend n\'est pas accessible.';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'La requête a pris trop de temps. Le serveur ne répond pas.';
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Crée une réservation de course
  static Future<Map<String, dynamic>> bookRide({
    required double departureLat,
    required double departureLng,
    required String departureAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    required String rideMode,
    required String rideCategory,
    required String paymentMethod,
    String? promoCode,
    DateTime? scheduledAt,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('📝 [BOOK] Début de la réservation');
      
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ [BOOK] Token manquant');
        return {
          'success': false,
          'message': 'Authentification requise. Veuillez vous connecter.',
        };
      }
      
      // Nettoyer le token
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      
      print('🔑 [BOOK] Token nettoyé - Longueur: ${cleanToken.length}');

      // ✅ CORRECTION : Utiliser les bons noms de champs
      final requestBody = {
        'pickup_latitude': departureLat,
        'pickup_longitude': departureLng,
        'pickup_address': departureAddress,  // ✅ Ajout de l'adresse de départ
        'dropoff_latitude': destinationLat,
        'dropoff_longitude': destinationLng,
        'dropoff_address': destinationAddress,  // ✅ Ajout de l'adresse d'arrivée
        'ride_mode': rideMode,
        'ride_category': rideCategory,
        'payment_method': paymentMethod,
        if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
        if (scheduledAt != null) 'scheduled_at': scheduledAt.toIso8601String(),
        if (additionalData != null) ...additionalData,
      };
      
      // 🔍 LOG POUR DÉBOGUER
      print('📦 [BOOK] Données envoyées:');
      print(jsonEncode(requestBody));

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };
      
      print('📤 [BOOK] Envoi de la requête vers: $baseUrl/rides/book');
      print('📤 [BOOK] Headers: ${headers.keys.toList()}');
      print('📤 [BOOK] Authorization (premiers 40 chars): ${headers['Authorization']?.substring(0, 40)}...');
      print('📤 [BOOK] Body length: ${jsonEncode(requestBody).length} caractères');
      
      print('📤 [BOOK] Envoi de la requête POST maintenant...');
      
      http.Response response;
      
      // Sur Flutter Web, utiliser http.post directement (plus fiable)
      if (kIsWeb) {
        print('🌐 [BOOK] Mode Web détecté - Utilisation de http.post');
        print('🌐 [BOOK] URL complète: ${Uri.parse('$baseUrl/rides/book')}');
        print('🌐 [BOOK] Headers envoyés: $headers');
        try {
          response = await http.post(
            Uri.parse('$baseUrl/rides/book'),
            headers: headers,
            body: jsonEncode(requestBody),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ [BOOK] Timeout - La requête a pris trop de temps');
              throw Exception('Timeout: La requête a pris trop de temps');
            },
          );
          print('✅ [BOOK] Requête HTTP envoyée - Status: ${response.statusCode}');
        } catch (e, stackTrace) {
          print('❌ [BOOK] Erreur lors de l\'envoi HTTP: $e');
          print('❌ [BOOK] Stack trace: $stackTrace');
          rethrow;
        }
      } else {
        // Pour les autres plateformes, utiliser Request pour plus de contrôle
        final uri = Uri.parse('$baseUrl/rides/book');
        final request = http.Request('POST', uri);
        request.headers.addAll(headers);
        request.body = jsonEncode(requestBody);
        
        final streamedResponse = await request.send().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout: La requête a pris trop de temps');
          },
        );
        
        response = await http.Response.fromStream(streamedResponse);
      }
      
      print('✅ [BOOK] Requête POST envoyée avec succès');
      print('📥 [BOOK] Réponse reçue - Status: ${response.statusCode}');
      print('📥 [BOOK] Body: ${response.body}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      // Parser le JSON
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        final contentType = response.headers['content-type'] ?? '';
        print('❌ [BOOK] Erreur parsing JSON: $e');
        print('❌ [BOOK] Content-Type: $contentType');
        
        if (response.statusCode == 404) {
          return {
            'success': false,
            'message': 'Endpoint non trouvé.',
          };
        } else if (response.statusCode == 422) {
          return {
            'success': false,
            'message': 'Données invalides. Vérifiez les logs du backend.',
          };
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          return {
            'success': false,
            'message': 'Authentification requise. Veuillez vous reconnecter.',
          };
        } else if (response.statusCode == 500) {
          return {
            'success': false,
            'message': 'Erreur serveur (500).',
          };
        }
        
        return {
          'success': false,
          'message': 'Réponse invalide du serveur (${response.statusCode}).',
        };
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ [BOOK] Réservation créée avec succès');
        final rideData = data['ride'] ?? data['data'];
        final availableDrivers = data['available_drivers'] as List<dynamic>? ?? [];
        final availableDriversCount = data['available_drivers_count'] as int? ?? availableDrivers.length;
        
        print('🚗 [BOOK] ${availableDriversCount} chauffeur(s) disponible(s)');
        
        return {
          'success': true,
          'message': data['message'] ?? 'Réservation créée avec succès',
          'ride': rideData,
          'available_drivers': availableDrivers,
          'available_drivers_count': availableDriversCount,
          'status': data['status'] ?? 'pending',
          'driver_id': data['driver_id'],
          'available_for_drivers': data['available_for_drivers'] ?? true,
        };
      } else {
        String errorMessage = data['error'] ?? data['message'] ?? 'Erreur lors de la réservation';
        print('❌ [BOOK] Erreur: $errorMessage');
        return {
          'success': false,
          'message': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ [BOOK] Exception: $e');
      print('❌ [BOOK] Type d\'erreur: ${e.runtimeType}');
      
      // Détails supplémentaires pour les erreurs de réseau
      String errorMessage = 'Erreur lors de la réservation';
      if (e.toString().contains('Failed to fetch') || e.toString().contains('Failed host lookup')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez que le backend est démarré sur http://127.0.0.1:5000';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Connexion refusée. Le backend n\'est pas accessible.';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'La requête a pris trop de temps. Le serveur ne répond pas.';
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Obtenir les chauffeurs disponibles pour une course avec leur ETA
  /// 
  /// Cette méthode appelle l'endpoint /api/v1/rides/<ride_id>/available-drivers
  /// pour obtenir la liste des chauffeurs disponibles proches du point de prise
  /// en charge avec leur temps d'arrivée estimé (ETA).
  /// 
  /// Returns:
  ///   {
  ///     'success': true,
  ///     'available_drivers': [
  ///       {
  ///         'driver_id': 1,
  ///         'full_name': 'Nom du Chauffeur',
  ///         'car_make': 'Toyota',
  ///         'car_model': 'Corolla',
  ///         'rating_average': 4.5,
  ///         'distance_km': 2.5,
  ///         'eta_minutes': 8,
  ///         'current_location': {'latitude': 14.7167, 'longitude': -17.4677}
  ///       },
  ///       ...
  ///     ],
  ///     'available_drivers_count': 3,
  ///     'pickup_location': {...}
  ///   }
  static Future<Map<String, dynamic>> getAvailableDriversForRide(int rideId) async {
    try {
      print('🚗 [GET_AVAILABLE_DRIVERS] Récupération des chauffeurs pour la course: $rideId');
      
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ [GET_AVAILABLE_DRIVERS] Token manquant');
        return {
          'success': false,
          'message': 'Authentification requise. Veuillez vous connecter.',
        };
      }
      
      // Nettoyer le token
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };
      
      print('📤 [GET_AVAILABLE_DRIVERS] Requête vers: $baseUrl/rides/$rideId/available-drivers');
      
      final response = await http.get(
        Uri.parse('$baseUrl/rides/$rideId/available-drivers'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );
      
      print('📥 [GET_AVAILABLE_DRIVERS] Réponse - Status: ${response.statusCode}');
      
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        final availableDrivers = data['available_drivers'] as List<dynamic>? ?? [];
        final availableDriversCount = data['available_drivers_count'] as int? ?? availableDrivers.length;
        
        print('✅ [GET_AVAILABLE_DRIVERS] ${availableDriversCount} chauffeur(s) disponible(s)');
        
        return {
          'success': true,
          'available_drivers': availableDrivers,
          'available_drivers_count': availableDriversCount,
          'ride_id': data['ride_id'],
          'status': data['status'],
          'pickup_location': data['pickup_location'],
        };
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? 'Erreur lors de la récupération des chauffeurs';
        print('❌ [GET_AVAILABLE_DRIVERS] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [GET_AVAILABLE_DRIVERS] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les détails d'une course par son ID
  /// 
  /// Cette méthode appelle l'endpoint /api/v1/rides/<ride_id>
  /// pour obtenir les détails complets d'une course, y compris
  /// les informations du chauffeur assigné si disponible.
  /// 
  /// Returns:
  ///   {
  ///     'success': true,
  ///     'ride': {
  ///       'id': 1,
  ///       'status': 'driver_assigned',
  ///       'driver_id': 1,
  ///       'driver': {
  ///         'id': 1,
  ///         'full_name': 'Nom du Chauffeur',
  ///         ...
  ///       },
  ///       ...
  ///     }
  ///   }
  static Future<Map<String, dynamic>> getRideDetails(int rideId) async {
    try {
      print('📋 [GET_RIDE_DETAILS] Récupération des détails de la course: $rideId');
      
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ [GET_RIDE_DETAILS] Token manquant');
        return {
          'success': false,
          'message': 'Authentification requise. Veuillez vous connecter.',
        };
      }
      
      // Nettoyer le token
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };
      
      print('📤 [GET_RIDE_DETAILS] Requête vers: $baseUrl/rides/$rideId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/rides/$rideId'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );
      
      print('📥 [GET_RIDE_DETAILS] Réponse - Status: ${response.statusCode}');
      
      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }
      
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode == 200) {
        print('✅ [GET_RIDE_DETAILS] Détails de la course récupérés');
        
        // Le backend retourne {'ride': {...}} ou directement {...}
        final rideData = data['ride'] ?? data;
        
        return {
          'success': true,
          'ride': rideData,
        };
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? data['msg'] ?? 'Erreur lors de la récupération de la course';
        print('❌ [GET_RIDE_DETAILS] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [GET_RIDE_DETAILS] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getRideHistory() async {
    try {
      print('📚 [HISTORY] Début du chargement de l\'historique');
      
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ [HISTORY] Token manquant');
        return {
          'success': false,
          'message': 'Authentification requise. Veuillez vous connecter.',
        };
      }
      
      // Nettoyer le token
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      
      print('🔑 [HISTORY] Token nettoyé - Longueur: ${cleanToken.length}');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };
      
      final url = '$baseUrl/rides/history';
      print('📤 [HISTORY] Envoi de la requête vers: $url');
      print('📤 [HISTORY] Headers: ${headers.keys.join(", ")}');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ [HISTORY] Timeout après 10 secondes');
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      print('📥 [HISTORY] Réponse reçue - Status: ${response.statusCode}');
      print('📥 [HISTORY] Headers de réponse: ${response.headers}');
      
      if (response.statusCode != 200) {
        print('📥 [HISTORY] Body: ${response.body}');
      }

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      // Parser le JSON
      Map<String, dynamic>? data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ [HISTORY] Erreur parsing JSON: $e');
        return {
          'success': false,
          'message': 'Réponse invalide du serveur.',
        };
      }

      if (response.statusCode == 200) {
        print('✅ [HISTORY] Historique chargé avec succès');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? 'Erreur lors du chargement de l\'historique (${response.statusCode})';
        print('❌ [HISTORY] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [HISTORY] Exception générale: $e');
      print('❌ [HISTORY] Type d\'erreur: ${e.runtimeType}');
      String errorMessage = 'Erreur lors du chargement de l\'historique';
      if (e.toString().contains('Failed host lookup')) {
        errorMessage = 'Impossible de se connecter au serveur';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Connexion refusée. Le backend n\'est pas accessible';
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  /// Soumettre une évaluation avec commentaire et/ou audio
  static Future<Map<String, dynamic>> submitRating({
    required int rideId,
    required int rating,
    String? comment,
    String? audioUrl,
  }) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token JWT invalide ou expiré. Veuillez vous connecter.',
        };
      }

      print('⭐ [RATING] Soumission d\'évaluation pour ride $rideId');

      final response = await http.post(
        Uri.parse('$baseUrl/ratings/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'ride_id': rideId,
          'rating': rating,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (audioUrl != null && audioUrl.isNotEmpty) 'audio_url': audioUrl,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ [RATING] Évaluation soumise avec succès');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur lors de la soumission';
        print('❌ [RATING] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [RATING] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la soumission de l\'évaluation',
      };
    }
  }

  /// Ajouter un chauffeur aux favoris
  static Future<Map<String, dynamic>> addFavoriteDriver(int driverId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token JWT invalide ou expiré. Veuillez vous connecter.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/favorite-drivers/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'driver_id': driverId}),
      );

      if (response.statusCode == 201) {
        return {'success': true};
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Retirer un chauffeur des favoris
  static Future<Map<String, dynamic>> removeFavoriteDriver(int driverId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token JWT invalide ou expiré. Veuillez vous connecter.',
        };
      }

      final response = await http.post(
        Uri.parse('$baseUrl/favorite-drivers/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'driver_id': driverId}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur';
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  /// Vérifier si un chauffeur est dans les favoris
  static Future<bool> isFavoriteDriver(int driverId) async {
    try {
      final token = await _getAuthToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/favorite-drivers/check/$driverId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['is_favorite'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir les informations de l'utilisateur connecté
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentification requise');
      }

      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['user'] as Map<String, dynamic>;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Erreur lors de la récupération des données utilisateur');
      }
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Obtenir les statistiques du dashboard admin (globales)
  static Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentification requise');
      }

      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Erreur lors du chargement des statistiques');
      }
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Obtenir les statistiques de TeMove (Application Client)
  static Future<Map<String, dynamic>> getTeMoveStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentification requise');
      }

      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/temove/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Erreur lors du chargement des statistiques TeMove');
      }
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Obtenir les statistiques de TeMove Pro (Application Conducteur)
  static Future<Map<String, dynamic>> getTeMoveProStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentification requise');
      }

      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/temove-pro/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Erreur lors du chargement des statistiques TeMove Pro');
      }
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Obtenir la vue d'ensemble combinée (les deux applications)
  static Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authentification requise');
      }

      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/overview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(errorData['error'] ?? 'Erreur lors du chargement de la vue d\'ensemble');
      }
    } catch (e) {
      throw Exception('Erreur: ${e.toString()}');
    }
  }

  /// Uploader un fichier audio
  static Future<Map<String, dynamic>> uploadAudio(String audioPath) async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Token JWT invalide ou expiré. Veuillez vous connecter.',
        };
      }

      print('🎤 [UPLOAD_AUDIO] Upload du fichier: $audioPath');

      // Créer une requête multipart
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/audio'),
      );

      // Ajouter le header Authorization
      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter le fichier audio
      if (kIsWeb) {
        // Sur Flutter Web, le package record retourne un blob URL
        // Il faut lire le blob et le convertir en bytes
        try {
          if (audioPath.startsWith('blob:')) {
            print('🌐 [UPLOAD_AUDIO] Lecture du blob URL: $audioPath');
            
            // Utiliser la fonction helper pour lire le blob
            final audioFile = await createMultipartFileFromBlob(audioPath);
            request.files.add(audioFile);
            print('✅ [UPLOAD_AUDIO] Blob converti en MultipartFile');
          } else {
            // Si ce n'est pas un blob, essayer fromPath (peut ne pas fonctionner)
            final audioFile = await http.MultipartFile.fromPath('audio', audioPath);
            request.files.add(audioFile);
          }
        } catch (e) {
          print('❌ [UPLOAD_AUDIO] Erreur upload sur web: $e');
          return {
            'success': false,
            'message': 'Erreur lors de l\'upload audio sur le web: ${e.toString()}',
          };
        }
      } else {
        // Sur mobile, utiliser fromPath normalement
        final audioFile = await http.MultipartFile.fromPath('audio', audioPath);
        request.files.add(audioFile);
      }

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ [UPLOAD_AUDIO] Fichier uploadé avec succès: ${data['audio_url']}');
        return {
          'success': true,
          'audio_url': data['audio_url'],
        };
      } else {
        final errorMsg = jsonDecode(response.body)['error'] ?? 'Erreur lors de l\'upload';
        print('❌ [UPLOAD_AUDIO] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [UPLOAD_AUDIO] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur lors de l\'upload du fichier audio: ${e.toString()}',
      };
    }
  }
}