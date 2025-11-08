import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Service API spécialisé pour les fonctionnalités d'administration
/// 
/// Ce service étend ApiService avec des méthodes spécifiques à l'administration
/// pour gérer les utilisateurs, conducteurs, courses, paiements, etc.
class AdminApiService {
  /// URL de base (héritée de ApiService)
  static String get baseUrl => ApiService.baseUrl;

  /// Obtenir le token d'authentification
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Utiliser la même clé que ApiService ('access_token')
      final token = prefs.getString('access_token');
      if (token == null) {
        print('⚠️ [ADMIN_API] Aucun token trouvé dans SharedPreferences (clé: access_token)');
      } else {
        print('✅ [ADMIN_API] Token récupéré - Longueur: ${token.length}');
      }
      return token;
    } catch (e) {
      print('❌ [ADMIN_API] Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  /// Vérifier et nettoyer le token d'authentification
  /// Retourne le token nettoyé ou null si invalide
  static String? _cleanToken(String? token) {
    if (token == null || token.isEmpty) {
      return null;
    }
    String cleanToken = token.trim();
    if (cleanToken.startsWith('Bearer ')) {
      cleanToken = cleanToken.substring(7);
    }
    return cleanToken;
  }

  /// Créer une réponse d'erreur d'authentification
  static Map<String, dynamic> _authErrorResponse() {
    return {
      'success': false,
      'error': 'Authentification requise. Veuillez vous reconnecter.',
    };
  }

  /// ============================================
  /// GESTION DES UTILISATEURS (CLIENTS)
  /// ============================================

  /// Obtenir la liste des utilisateurs avec pagination et filtres
  /// 
  /// Paramètres:
  /// - page: Numéro de page (défaut: 1)
  /// - perPage: Nombre d'éléments par page (défaut: 20)
  /// - search: Recherche par nom, email, téléphone
  /// - status: 'active', 'inactive', ou null pour tous
  static Future<Map<String, dynamic>> getUsers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status,
  }) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        print('❌ [ADMIN_API] getUsers - Token manquant');
        return _authErrorResponse();
      }

      // Construire l'URL avec les paramètres
      final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout: La requête a pris trop de temps');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'users': data['users'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des utilisateurs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les détails d'un utilisateur
  static Future<Map<String, dynamic>> getUser(int userId) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'user': data['user'],
          'recent_rides': data['recent_rides'] ?? [],
          'total_rides': data['total_rides'] ?? 0,
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement de l\'utilisateur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Activer/Désactiver un utilisateur
  static Future<Map<String, dynamic>> toggleUserStatus(int userId) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/users/$userId/toggle-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Statut modifié avec succès',
          'user': data['user'],
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la modification du statut',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// GESTION DES CONDUCTEURS
  /// ============================================

  /// Obtenir la liste des conducteurs avec pagination et filtres
  static Future<Map<String, dynamic>> getDrivers({
    int page = 1,
    int perPage = 20,
    String? search,
    String? status, // 'pending', 'active', 'inactive'
  }) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final uri = Uri.parse('$baseUrl/admin/drivers').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'drivers': data['drivers'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des conducteurs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les détails d'un conducteur
  static Future<Map<String, dynamic>> getDriver(int driverId) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/drivers/$driverId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'driver': data['driver'],
          'recent_rides': data['recent_rides'] ?? [],
          'total_rides': data['total_rides'] ?? 0,
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement du conducteur',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Approuver un conducteur
  static Future<Map<String, dynamic>> approveDriver(int driverId) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/drivers/$driverId/approve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Conducteur approuvé avec succès',
          'driver': data['driver'],
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de l\'approbation',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Rejeter un conducteur
  static Future<Map<String, dynamic>> rejectDriver(int driverId) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/drivers/$driverId/reject'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Conducteur rejeté',
          'driver': data['driver'],
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du rejet',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Activer/Désactiver un conducteur
  static Future<Map<String, dynamic>> toggleDriverStatus(int driverId) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/drivers/$driverId/toggle-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Statut modifié avec succès',
          'driver': data['driver'],
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la modification du statut',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// GESTION DES COURSES
  /// ============================================

  /// Obtenir la liste des courses avec pagination et filtres
  static Future<Map<String, dynamic>> getRides({
    int page = 1,
    int perPage = 20,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final uri = Uri.parse('$baseUrl/admin/rides').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'rides': data['rides'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des courses',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les trajets actifs pour le suivi en temps réel
  static Future<Map<String, dynamic>> getActiveRides() async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/rides/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'active_rides': data['active_rides'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des trajets actifs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// GESTION DES PAIEMENTS
  /// ============================================

  /// Obtenir la liste des paiements avec pagination et filtres
  static Future<Map<String, dynamic>> getPayments({
    int page = 1,
    int perPage = 20,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final uri = Uri.parse('$baseUrl/admin/payments').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'payments': data['payments'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des paiements',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// SUIVI EN TEMPS RÉEL
  /// ============================================

  /// Obtenir les conducteurs actifs pour la carte en temps réel
  static Future<Map<String, dynamic>> getActiveDrivers() async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/drivers/active'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'active_drivers': data['active_drivers'] ?? [],
          'count': data['count'] ?? 0,
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des conducteurs actifs',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// GRAPHIQUES
  /// ============================================

  /// Obtenir les données pour le graphique des courses (7 jours)
  static Future<Map<String, dynamic>> getRidesChartData() async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/charts/rides'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'data': data['data'] ?? [],
          'period': data['period'] ?? '7_days',
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des données',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Obtenir les données pour le graphique des revenus (7 jours)
  static Future<Map<String, dynamic>> getRevenueChartData() async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard/charts/revenue'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'data': data['data'] ?? [],
          'period': data['period'] ?? '7_days',
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des données',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// GESTION DES COMMISSIONS
  /// ============================================

  /// Obtenir la liste des commissions avec pagination et filtres
  static Future<Map<String, dynamic>> getCommissions({
    int page = 1,
    int perPage = 20,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final uri = Uri.parse('$baseUrl/admin/commissions').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (startDate != null && startDate.isNotEmpty) 'start_date': startDate,
        if (endDate != null && endDate.isNotEmpty) 'end_date': endDate,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'commissions': data['commissions'] ?? [],
          'pagination': data['pagination'] ?? {},
          'total_commission': (data['total_commission'] ?? 0).toDouble(),
          'total_paid': (data['total_paid'] ?? 0).toDouble(),
          'total_pending': (data['total_pending'] ?? 0).toDouble(),
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des commissions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Marquer une commission comme payée
  static Future<Map<String, dynamic>> markCommissionAsPaid(int commissionId) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/commissions/$commissionId/mark-paid'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Commission marquée comme payée',
          'commission': data['commission'],
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// GESTION DES ABONNEMENTS
  /// ============================================

  /// Obtenir la liste des abonnements avec pagination et filtres
  static Future<Map<String, dynamic>> getSubscriptions({
    int page = 1,
    int perPage = 20,
    String? type, // 'driver', 'user'
    String? status, // 'active', 'expired', 'cancelled'
  }) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final uri = Uri.parse('$baseUrl/admin/subscriptions').replace(queryParameters: {
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (type != null && type.isNotEmpty && type != 'all') 'type': type,
        if (status != null && status.isNotEmpty && status != 'all') 'status': status,
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'subscriptions': data['subscriptions'] ?? [],
          'pagination': data['pagination'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des abonnements',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// GÉNÉRATION DE RAPPORTS
  /// ============================================

  /// Générer un rapport et le télécharger
  static Future<Map<String, dynamic>> generateReport({
    required String reportType, // 'revenue', 'rides', 'drivers', 'users', 'commissions', 'payments'
    required DateTime startDate,
    required DateTime endDate,
    required String format, // 'excel', 'pdf'
  }) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.post(
        Uri.parse('$baseUrl/admin/reports/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
        body: jsonEncode({
          'report_type': reportType,
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'format': format,
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        // Le backend retourne le fichier directement
        // Il faut le télécharger côté client
        final contentType = response.headers['content-type'] ?? '';
        final contentDisposition = response.headers['content-disposition'] ?? '';
        
        // Extraire le nom de fichier depuis content-disposition
        String? filename;
        if (contentDisposition.contains('filename=')) {
          filename = contentDisposition.split('filename=')[1].replaceAll('"', '');
        } else {
          // Générer un nom de fichier par défaut
          final timestamp = DateTime.now().toIso8601String().split('T')[0];
          filename = 'rapport_${reportType}_$timestamp.${format == 'excel' ? 'xlsx' : 'pdf'}';
        }
        
        // Pour Flutter Web, créer un blob et déclencher le téléchargement
        // Pour Flutter Mobile, sauvegarder le fichier
        return {
          'success': true,
          'message': 'Rapport généré avec succès',
          'file_data': response.bodyBytes,
          'filename': filename,
          'content_type': contentType,
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la génération du rapport',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// ============================================
  /// PARAMÈTRES ADMIN
  /// ============================================

  /// Obtenir les paramètres administratifs
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'settings': data['settings'] ?? {},
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors du chargement des paramètres',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }

  /// Mettre à jour les paramètres administratifs
  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settings) async {
    try {
      final token = await _getAuthToken();
      final cleanToken = _cleanToken(token);
      if (cleanToken == null) {
        return _authErrorResponse();
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $cleanToken',
        },
        body: jsonEncode(settings),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'message': data['message'] ?? 'Paramètres mis à jour avec succès',
          'settings': data['settings'],
        };
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': false,
          'error': errorData['error'] ?? 'Erreur lors de la mise à jour des paramètres',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur: ${e.toString()}',
      };
    }
  }
}

