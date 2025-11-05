import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL du backend - s'adapte selon la plateforme
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api/v1';
    } else {
      // Pour un émulateur Android : 'http://10.0.2.2:5000/api/v1'
      // Pour un appareil physique : utilisez votre IP locale
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
        final errorMsg = data?['error'] ?? data?['message'] ?? 'Erreur lors du calcul de l\'estimation (${response.statusCode})';
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
        return {
          'success': true,
          'message': data['message'] ?? 'Réservation créée avec succès',
          'ride': data['ride'] ?? data['data'],
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

  /// Obtient l'historique des courses de l'utilisateur
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
}