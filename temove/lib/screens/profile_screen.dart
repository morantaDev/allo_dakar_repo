import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/history_screen.dart';
import 'package:temove/screens/welcome_screen.dart';
import 'package:temove/screens/admin_screen.dart';
import 'package:temove/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Essayer de récupérer les données utilisateur depuis SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        setState(() {
          userData = jsonDecode(userJson) as Map<String, dynamic>;
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    }

    // Si pas de données sauvegardées, récupérer depuis l'API
    try {
      final user = await ApiService.getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user));
      setState(() {
        userData = user;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors de la récupération des données utilisateur: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  bool get isAdmin {
    if (userData == null) return false;
    return userData!['is_admin'] == true || userData!['is_admin'] == 'true';
  }

  String get userName {
    return userData?['full_name'] ?? userData?['name'] ?? 'Utilisateur';
  }

  String get userEmail {
    return userData?['email'] ?? 'email@exemple.com';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
        appBar: AppBar(
          title: const Text('Mon Profil'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mon Profil'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Avatar et Info
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark 
                          ? AppTheme.textPrimary 
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark 
                          ? AppTheme.textMuted 
                          : Colors.grey.shade600,
                    ),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Administrateur',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '4.8',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu Items
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark 
                    ? AppTheme.secondaryColor.withOpacity(0.2) 
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (isAdmin) ...[
                    _ProfileMenuItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard Admin',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                      color: AppTheme.primaryColor,
                    ),
                    _Divider(isDark: isDark),
                  ],
                  _ProfileMenuItem(
                    icon: Icons.history,
                    title: 'Historique des courses',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HistoryScreen(),
                        ),
                      );
                    },
                    isDark: isDark,
                  ),
                  _Divider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.payment,
                    title: 'Méthodes de paiement',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _Divider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.location_on,
                    title: 'Adresses enregistrées',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _Divider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _Divider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.help_outline,
                    title: 'Aide & Support',
                    onTap: () {},
                    isDark: isDark,
                  ),
                  _Divider(isDark: isDark),
                  _ProfileMenuItem(
                    icon: Icons.settings,
                    title: 'Paramètres',
                    onTap: () {},
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Déconnexion
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Déconnexion'),
                        content: const Text(
                          'Êtes-vous sûr de vouloir vous déconnecter ?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Fermer le dialog
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WelcomeScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Déconnexion',
                              style: TextStyle(color: AppTheme.errorColor),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final Color? color;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color ?? AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark 
                      ? AppTheme.textPrimary 
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark 
                  ? AppTheme.textMuted 
                  : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      color: isDark 
          ? Colors.white.withOpacity(0.1) 
          : Colors.grey.shade200,
    );
  }
}

