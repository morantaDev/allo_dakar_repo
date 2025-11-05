import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service API pour les chauffeurs
class DriverApiService {
  // URL du backend
  static const String baseUrl = 'http://127.0.0.1:5000/api/v1';

  /// Récupérer le token JWT stocké
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Sauvegarder le token JWT
  static Future<void> _saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      print('Erreur lors de la sauvegarde du token: $e');
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
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
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
        final token = data['access_token'] as String?;
        if (token != null) {
          await _saveAuthToken(token);
          print('✅ [DRIVER_LOGIN] Token sauvegardé');
        }
        
        return {
          'success': true,
          'data': data,
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

  /// Inscription d'un chauffeur
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String licenseNumber,
    required Map<String, dynamic> vehicle,
  }) async {
    try {
      print('📝 [DRIVER_REGISTER] Tentative d\'inscription pour: $email');
      
      final token = await _getAuthToken();
      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Vous devez d\'abord être connecté en tant qu\'utilisateur.',
        };
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/drivers/register'),
        headers: headers,
        body: jsonEncode({
          'license_number': licenseNumber,
          'vehicle': vehicle,
          'name': fullName,
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
        Uri.parse('$baseUrl/drivers/set-status'),
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

  /// Obtenir les courses disponibles
  static Future<Map<String, dynamic>> getAvailableRides() async {
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

      final response = await http.get(
        Uri.parse('$baseUrl/drivers/rides'),
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
          'message': data['error'] ?? 'Erreur lors de la récupération des courses',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Accepter une course
  static Future<Map<String, dynamic>> acceptRide(int rideId) async {
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
        Uri.parse('$baseUrl/rides/$rideId/accept'),
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
          'message': data['error'] ?? 'Erreur lors de l\'acceptation de la course',
        };
      }
    } catch (e) {
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

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/drivers/stats'),
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

