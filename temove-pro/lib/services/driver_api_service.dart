import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Fonction utilitaire pour décoder un token JWT et extraire le payload
/// 
/// Les JWT sont composés de 3 parties séparées par des points :
/// - Header (base64)
/// - Payload (base64) - contient les claims (role, identity, etc.)
/// - Signature
/// 
/// Cette fonction décode uniquement le payload pour vérifier le rôle.
Map<String, dynamic>? _decodeJwtPayload(String token) {
  try {
    // Nettoyer le token (enlever "Bearer " si présent)
    String cleanToken = token.trim();
    if (cleanToken.startsWith('Bearer ')) {
      cleanToken = cleanToken.substring(7);
    }
    
    // Séparer les parties du JWT
    final parts = cleanToken.split('.');
    if (parts.length != 3) {
      print('⚠️ [DECODE_JWT] Token invalide: nombre de parties incorrect');
      return null;
    }
    
    // Décoder le payload (partie 2)
    final payload = parts[1];
    
    // Ajouter le padding si nécessaire (base64 peut nécessiter du padding)
    String normalizedPayload = payload;
    switch (payload.length % 4) {
      case 1:
        normalizedPayload += '===';
        break;
      case 2:
        normalizedPayload += '==';
        break;
      case 3:
        normalizedPayload += '=';
        break;
    }
    
    // Décoder base64
    final decodedBytes = base64Url.decode(normalizedPayload);
    final decodedString = utf8.decode(decodedBytes);
    
    // Parser le JSON
    final payloadMap = jsonDecode(decodedString) as Map<String, dynamic>;
    
    return payloadMap;
  } catch (e) {
    print('❌ [DECODE_JWT] Erreur lors du décodage: $e');
    return null;
  }
}

/// Service API pour les chauffeurs TéMove Pro
/// Utilise la même configuration d'URL que l'application client pour la compatibilité
class DriverApiService {
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

  /// Récupérer le token JWT stocké
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null && token.isNotEmpty) {
        print('✅ [GET_AUTH_TOKEN] Token trouvé (longueur: ${token.length})');
      } else {
        print('⚠️ [GET_AUTH_TOKEN] Aucun token trouvé dans SharedPreferences');
      }
      return token;
    } catch (e) {
      print('❌ [GET_AUTH_TOKEN] Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Sauvegarder le token JWT
  static Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      // Vérifier que le token a bien été sauvegardé
      final savedToken = prefs.getString('auth_token');
      if (savedToken != null && savedToken == token) {
        print('✅ [SAVE_AUTH_TOKEN] Token sauvegardé avec succès (longueur: ${token.length})');
      } else {
        print('⚠️ [SAVE_AUTH_TOKEN] Échec de la sauvegarde du token');
      }
    } catch (e) {
      print('❌ [SAVE_AUTH_TOKEN] Erreur lors de la sauvegarde du token: $e');
    }
  }

  /// Connexion d'un chauffeur
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [DRIVER_LOGIN] Tentative de connexion pour: $email');
      
      final response = await http.post(
        Uri.parse('${baseUrl}/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'driver_app': true,  // Indiquer que c'est une connexion depuis TéMove Pro
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      print('📥 [DRIVER_LOGIN] Réponse reçue - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // ============================================
        // VÉRIFICATION STRICTE DU RÔLE DANS LE TOKEN JWT
        // ============================================
        // Décoder le token JWT pour vérifier que le rôle est "driver"
        // IMPORTANT: Ne pas sauvegarder le token si le rôle n'est pas "driver"
        final token = data['access_token'] as String?;
        
        if (token == null || token.isEmpty) {
          print('❌ [DRIVER_LOGIN] Aucun token reçu dans la réponse');
          return {
            'success': false,
            'message': 'Erreur: Aucun token d\'authentification reçu',
          };
        }
        
        // Décoder le token pour vérifier le rôle
        final payload = _decodeJwtPayload(token);
        if (payload == null) {
          print('❌ [DRIVER_LOGIN] Impossible de décoder le token JWT');
          return {
            'success': false,
            'message': 'Erreur: Token invalide',
          };
        }
        
        // Vérifier le rôle dans le token
        final role = payload['role'] as String?;
        print('🔍 [DRIVER_LOGIN] Rôle détecté dans le token: $role');
        
        if (role != 'driver') {
          print('❌ [DRIVER_LOGIN] Accès refusé - Rôle dans le token: $role (attendu: driver)');
          // NE PAS sauvegarder le token si le rôle n'est pas "driver"
          return {
            'success': false,
            'message': 'Compte non autorisé. Cette application est réservée aux chauffeurs TéMove.',
            'code': 'NOT_A_DRIVER',
            'user_role': role,
          };
        }
        
        // Le rôle est "driver", on peut sauvegarder le token
        await _saveAuthToken(token);
        print('✅ [DRIVER_LOGIN] Token sauvegardé (rôle vérifié: driver)');
        
        // Sauvegarder les données utilisateur pour les utiliser dans le profil
        final user = data['user'] as Map<String, dynamic>?;
        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_email', user['email'] ?? '');
          await prefs.setString('user_name', user['full_name'] ?? user['name'] ?? '');
          await prefs.setString('user_phone', user['phone'] ?? '');
          print('✅ [DRIVER_LOGIN] Données utilisateur sauvegardées');
        }
        
        return {
          'success': true,
          'data': data,
        };
      } else if (response.statusCode == 403) {
        // Gérer les erreurs 403 (not a driver)
        final errorCode = data['code'] as String?;
        final errorMessage = data['message'] ?? data['error'] ?? 'Accès refusé';
        
        print('❌ [DRIVER_LOGIN] Erreur 403 - Code: $errorCode, Message: $errorMessage');
        
        // IMPORTANT: Ne pas sauvegarder le token en cas d'erreur 403
        return {
          'success': false,
          'message': errorMessage,
          'code': errorCode ?? 'NOT_A_DRIVER',
          'user_role': data['user_role'] as String?,
        };
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? 'Erreur lors de la connexion (${response.statusCode})';
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [DRIVER_LOGIN] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Inscription complète d'un nouveau chauffeur
  /// 
  /// Cette méthode permet à un nouveau chauffeur de s'inscrire directement avec :
  /// - Compte utilisateur (email, password, nom, téléphone)
  /// - Profil chauffeur (numéro de permis)
  /// - Véhicule (marque, modèle, plaque, couleur)
  /// 
  /// L'utilisateur est créé avec role='driver' dès le départ.
  static Future<Map<String, dynamic>> registerDriver({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String licenseNumber,
    required Map<String, dynamic> vehicle,
  }) async {
    try {
      print('📝 [DRIVER_REGISTER] Tentative d\'inscription complète pour: $email');
      
      final response = await http.post(
        Uri.parse('${baseUrl}/auth/register-driver'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
          'license_number': licenseNumber,
          'vehicle': vehicle,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      print('📥 [DRIVER_REGISTER] Réponse reçue - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        // Inscription réussie - sauvegarder le token
        final token = data['access_token'] as String?;
        if (token != null) {
          await _saveAuthToken(token);
          print('✅ [DRIVER_REGISTER] Token sauvegardé');
          
          // Sauvegarder les données utilisateur et driver
          final user = data['user'] as Map<String, dynamic>?;
          final driver = data['driver'] as Map<String, dynamic>?;
          
          if (user != null || driver != null) {
            final prefs = await SharedPreferences.getInstance();
            
            // Sauvegarder les données utilisateur
            if (user != null) {
              await prefs.setString('user_email', user['email'] ?? '');
              await prefs.setString('user_name', user['full_name'] ?? user['name'] ?? '');
              await prefs.setString('user_phone', user['phone'] ?? '');
            }
            
            // Sauvegarder les données driver (priorité sur user pour le nom)
            if (driver != null) {
              final driverName = driver['full_name'] ?? user?['full_name'] ?? user?['name'] ?? '';
              if (driverName.isNotEmpty) {
                await prefs.setString('user_name', driverName);
              }
              print('✅ [DRIVER_REGISTER] Données utilisateur et driver sauvegardées');
            } else {
              print('✅ [DRIVER_REGISTER] Données utilisateur sauvegardées');
            }
          }
        }
        
        print('✅ [DRIVER_REGISTER] Inscription réussie');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorMsg = data['error'] ?? data['message'] ?? 'Erreur lors de l\'inscription (${response.statusCode})';
        print('❌ [DRIVER_REGISTER] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [DRIVER_REGISTER] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }
  
  /// Inscription d'un chauffeur (ancienne méthode - pour compatibilité)
  /// 
  /// Cette méthode permet à un utilisateur déjà connecté de s'inscrire en tant que chauffeur.
  /// L'utilisateur doit déjà être authentifié (token JWT présent).
  /// 
  /// @deprecated Utiliser registerDriver() pour une inscription complète depuis zéro
  static Future<Map<String, dynamic>> register({
    required String licenseNumber,
    required Map<String, dynamic> vehicle,
  }) async {
    try {
      print('📝 [DRIVER_REGISTER] Tentative d\'inscription chauffeur (ancienne méthode)');
      
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Vous devez d\'abord vous connecter pour vous inscrire en tant que chauffeur.',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${baseUrl}/drivers/register'),
        headers: headers,
        body: jsonEncode({
          'license_number': licenseNumber,
          'vehicle': vehicle,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      print('📥 [DRIVER_REGISTER] Réponse reçue - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        print('✅ [DRIVER_REGISTER] Inscription réussie');
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorMsg = data['msg'] ?? data['error'] ?? data['message'] ?? 'Erreur lors de l\'inscription (${response.statusCode})';
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [DRIVER_REGISTER] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Définir le statut du chauffeur (online/offline)
  static Future<Map<String, dynamic>> setStatus(String status) async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentification requise.',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${baseUrl}/drivers/set-status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['msg'] ?? data['error'] ?? 'Erreur lors de la mise à jour du statut',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les courses disponibles pour le chauffeur
  /// 
  /// Cette méthode appelle l'endpoint /api/v1/drivers/rides qui retourne
  /// les courses en attente (PENDING) qui n'ont pas encore de chauffeur assigné.
  /// 
  /// Format de la réponse backend :
  /// {
  ///   "rides": [
  ///     {
  ///       "id": 1,
  ///       "pickup_address": "Adresse de départ",
  ///       "dropoff_address": "Adresse d'arrivée",
  ///       "price_xof": 1500,
  ///       "distance_km": 5.2,
  ///       "duration_minutes": 15,
  ///       ...
  ///     }
  ///   ]
  /// }
  static Future<Map<String, dynamic>> getAvailableRides() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
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

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };

      print('📤 [GET_AVAILABLE_RIDES] Requête vers: ${baseUrl}/drivers/rides');

      final response = await http.get(
        Uri.parse('${baseUrl}/drivers/rides'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      print('📥 [GET_AVAILABLE_RIDES] Réponse - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Le backend retourne directement {"rides": [...]}
        // On retourne les données dans le format attendu par l'écran
        final rides = data['rides'] as List<dynamic>? ?? [];
        print('✅ [GET_AVAILABLE_RIDES] ${rides.length} courses disponibles');
        
        return {
          'success': true,
          'data': {
            'rides': rides,  // Format uniforme pour l'affichage
          },
        };
      } else {
        final errorMsg = data['msg'] ?? data['error'] ?? data['message'] ?? 'Erreur lors de la récupération des courses';
        print('❌ [GET_AVAILABLE_RIDES] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [GET_AVAILABLE_RIDES] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Accepter une course
  /// 
  /// Cette méthode appelle l'endpoint /api/v1/rides/<ride_id>/accept
  /// pour qu'un chauffeur accepte une course disponible.
  /// 
  /// Format de la réponse backend (succès) :
  /// {
  ///   "msg": "accepted",
  ///   "ride_id": 1,
  ///   "status": "driver_assigned",
  ///   "driver": {
  ///     "id": 1,
  ///     "full_name": "Nom du Chauffeur",
  ///     ...
  ///   },
  ///   "ride": { ... }
  /// }
  static Future<Map<String, dynamic>> acceptRide(int rideId) async {
    try {
      print('📤 [ACCEPT_RIDE] Tentative d\'acceptation de la course: $rideId');
      
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        print('❌ [ACCEPT_RIDE] Aucun token d\'authentification');
        return {
          'success': false,
          'message': 'Authentification requise.',
        };
      }

      // Nettoyer le token (enlever "Bearer " s'il est déjà présent)
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanToken',
      };

      print('📤 [ACCEPT_RIDE] Requête vers: ${baseUrl}/rides/$rideId/accept');

      final response = await http.post(
        Uri.parse('${baseUrl}/rides/$rideId/accept'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      print('📥 [ACCEPT_RIDE] Réponse - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        print('✅ [ACCEPT_RIDE] Course acceptée avec succès');
        print('   Ride ID: ${data['ride_id']}');
        print('   Statut: ${data['status']}');
        if (data['driver'] != null) {
          print('   Chauffeur: ${data['driver']['full_name']}');
        }
        
        return {
          'success': true,
          'data': data,
        };
      } else {
        final errorMsg = data['msg'] ?? data['error'] ?? data['message'] ?? 'Erreur lors de l\'acceptation de la course';
        print('❌ [ACCEPT_RIDE] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [ACCEPT_RIDE] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les informations du chauffeur connecté
  /// 
  /// Cette méthode appelle l'endpoint /api/v1/drivers/me qui retourne
  /// les informations du profil chauffeur (statut, véhicule, note, etc.)
  static Future<Map<String, dynamic>> getDriverProfile() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentification requise.',
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

      print('📤 [GET_DRIVER_PROFILE] Requête vers: ${baseUrl}/drivers/me');

      final response = await http.get(
        Uri.parse('${baseUrl}/drivers/me'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      print('📥 [GET_DRIVER_PROFILE] Réponse - Status: ${response.statusCode}');

      if (response.body.isEmpty) {
        return {
          'success': false,
          'message': 'Réponse vide du serveur.',
        };
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final driver = data['driver'] as Map<String, dynamic>?;
        print('✅ [GET_DRIVER_PROFILE] Données du chauffeur récupérées');
        
        return {
          'success': true,
          'data': driver ?? {},
        };
      } else {
        final errorMsg = data['msg'] ?? data['error'] ?? data['message'] ?? 'Erreur lors de la récupération du profil';
        print('❌ [GET_DRIVER_PROFILE] Erreur: $errorMsg');
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      print('❌ [GET_DRIVER_PROFILE] Exception: $e');
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les statistiques du chauffeur
  static Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Authentification requise.',
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

      final response = await http.get(
        Uri.parse('${baseUrl}/drivers/stats'),
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['error'] ?? 'Erreur lors de la récupération des statistiques',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }
}

