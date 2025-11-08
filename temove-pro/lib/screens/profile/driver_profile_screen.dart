import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/driver_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _driverData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer les informations du chauffeur depuis l'API
      final result = await DriverApiService.getDriverProfile();
      
      if (result['success'] == true && result['data'] != null) {
        final driverData = result['data'] as Map<String, dynamic>;
        
        // Récupérer les données utilisateur depuis l'API ou le stockage local
        final userData = driverData['user'] as Map<String, dynamic>?;
        final prefs = await SharedPreferences.getInstance();
        
        // Utiliser les données de l'API si disponibles, sinon le stockage local
        final userEmail = userData?['email'] ?? prefs.getString('user_email') ?? 'chauffeur@temove.com';
        final userName = userData?['full_name'] ?? prefs.getString('user_name') ?? 'Chauffeur TéMove';
        final userPhone = userData?['phone'] ?? prefs.getString('user_phone') ?? '';
        
        // Combiner les données API et locales
        setState(() {
          _driverData = {
            'name': userName,
            'email': userEmail,
            'phone': userPhone,
            'rating': (driverData['rating'] ?? 0.0).toDouble(),
            'total_rides': 0, // TODO: Récupérer depuis l'API
            'status': driverData['status'] ?? 'offline',
            'license_number': driverData['license_number'] ?? '',
            'vehicle': driverData['vehicle'] ?? {},
          };
          _isLoading = false;
        });
      } else {
        // Fallback: utiliser les données du stockage local
        final prefs = await SharedPreferences.getInstance();
        final userEmail = prefs.getString('user_email') ?? 'chauffeur@temove.com';
        final userName = prefs.getString('user_name') ?? 'Chauffeur TéMove';
        
        setState(() {
          _driverData = {
            'name': userName,
            'email': userEmail,
            'phone': prefs.getString('user_phone') ?? '+221 XX XXX XX XX',
            'rating': 0.0,
            'total_rides': 0,
            'status': 'offline',
          };
          _isLoading = false;
        });
        
        // Afficher un message si l'API a retourné une erreur
        if (result['message'] != null) {
          final errorMsg = result['message'] as String;
          print('⚠️ [PROFILE] Erreur API: $errorMsg - Utilisation des données locales');
          
          // Si l'utilisateur n'est pas un chauffeur, afficher un message d'erreur spécifique
          if (errorMsg.toLowerCase().contains('not a driver')) {
            setState(() {
              _errorMessage = 'Vous n\'avez pas encore de profil chauffeur. Veuillez compléter votre inscription en tant que chauffeur via l\'API /drivers/register.';
            });
          }
        }
      }
    } catch (e) {
      print('❌ [PROFILE] Exception: $e');
      setState(() {
        _errorMessage = 'Erreur lors du chargement: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon profil'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _driverData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon profil'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Données non disponibles',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDriverProfile,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Photo de profil
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.grey[600],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: const Icon(Icons.camera_alt, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _driverData!['name'] ?? 'Chauffeur TéMove',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Informations personnelles
          _ProfileSection(
            title: 'Informations personnelles',
            children: [
              _ProfileTile(
                icon: Icons.person_outline,
                title: 'Nom complet',
                subtitle: _driverData!['name'] ?? 'Non défini',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: _driverData!['email'] ?? 'Non défini',
              ),
              _ProfileTile(
                icon: Icons.phone_outlined,
                title: 'Téléphone',
                subtitle: _driverData!['phone'] ?? 'Non défini',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Informations véhicule
          if (_driverData!['vehicle'] != null && (_driverData!['vehicle'] as Map).isNotEmpty) ...[
            _ProfileSection(
              title: 'Véhicule',
              children: [
                _ProfileTile(
                  icon: Icons.directions_car,
                  title: 'Marque',
                  subtitle: (_driverData!['vehicle'] as Map)['make']?.toString() ?? 'Non défini',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.badge_outlined,
                  title: 'Modèle',
                  subtitle: (_driverData!['vehicle'] as Map)['model']?.toString() ?? 'Non défini',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.palette_outlined,
                  title: 'Couleur',
                  subtitle: (_driverData!['vehicle'] as Map)['color']?.toString() ?? 'Non défini',
                  onTap: () {},
                ),
                _ProfileTile(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Plaque d\'immatriculation',
                  subtitle: (_driverData!['vehicle'] as Map)['plate']?.toString() ?? 'Non définie',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          
          const SizedBox(height: 24),
          
          // Documents
          _ProfileSection(
            title: 'Documents',
            children: [
              _ProfileTile(
                icon: Icons.description_outlined,
                title: 'Permis de conduire',
                subtitle: _driverData!['license_number']?.toString() ?? 'Non défini',
                trailing: _driverData!['license_number'] != null && _driverData!['license_number'].toString().isNotEmpty
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.error_outline, color: Colors.orange),
              ),
              _ProfileTile(
                icon: Icons.security_outlined,
                title: 'Assurance',
                subtitle: 'Vérifié',
                trailing: Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Statistiques
          _ProfileSection(
            title: 'Statistiques',
            children: [
              _ProfileTile(
                icon: Icons.star_outline,
                title: 'Note moyenne',
                subtitle: '${_driverData!['rating'] ?? 0.0} ⭐',
              ),
              _ProfileTile(
                icon: Icons.directions_car_outlined,
                title: 'Courses effectuées',
                subtitle: '${_driverData!['total_rides'] ?? 0}',
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Déconnexion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () async {
                // Implémenter la déconnexion
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('auth_token');
                await prefs.remove('user_email');
                await prefs.remove('user_name');
                await prefs.remove('user_phone');
                
                if (mounted) {
                  // Utiliser go_router au lieu de Navigator.pushReplacementNamed
                  context.go('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Se déconnecter',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}

