import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/admin_screen.dart';
import 'package:temove/screens/admin_home_screen.dart';
import 'package:temove/screens/admin_users_screen.dart';
import 'package:temove/screens/admin_drivers_screen.dart';
import 'package:temove/screens/admin_rides_screen.dart';
import 'package:temove/screens/admin_payments_screen.dart';
import 'package:temove/screens/admin_commissions_screen.dart';
import 'package:temove/screens/admin_subscriptions_screen.dart';
import 'package:temove/screens/admin_reports_screen.dart';
import 'package:temove/screens/admin_settings_screen.dart';
import 'package:temove/screens/welcome_screen.dart';
import 'package:temove/screens/auth_screen.dart';
import 'package:temove/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
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

    try {
      final user = await ApiService.getCurrentUser();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(user));
      setState(() {
        userData = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  String get userName {
    return userData?['full_name'] ?? userData?['name'] ?? 'Administrateur';
  }

  String get userEmail {
    return userData?['email'] ?? 'admin@temove.sn';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      child: Column(
        children: [
          // Header Admin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 24,
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  isLoading ? 'Chargement...' : userName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isLoading ? '' : userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Menu Items Admin
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminHomeScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                  isSelected: true,
                ),
                const Divider(height: 1),
                _DrawerMenuItem(
                  icon: Icons.people,
                  title: 'Utilisateurs',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminUsersScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.local_taxi,
                  title: 'Conducteurs',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminDriversScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.directions_car,
                  title: 'Courses',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminRidesScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _DrawerMenuItem(
                  icon: Icons.credit_card,
                  title: 'Paiements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminPaymentsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.account_balance_wallet,
                  title: 'Commissions',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminCommissionsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.subscriptions,
                  title: 'Abonnements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminSubscriptionsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _DrawerMenuItem(
                  icon: Icons.map,
                  title: 'Suivi Temps Réel',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Naviguer vers écran suivi temps réel (à créer)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Suivi temps réel - À venir')),
                    );
                  },
                  isDark: isDark,
                ),
                const Divider(height: 1),
                _DrawerMenuItem(
                  icon: Icons.bar_chart,
                  title: 'Rapports',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminReportsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminSettingsScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                Divider(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                _DrawerMenuItem(
                  icon: Icons.logout,
                  title: 'Se déconnecter',
                  onTap: () async {
                    // Appeler directement la fonction de déconnexion
                    // Elle gérera la fermeture du drawer et la navigation
                    await _logout(context);
                  },
                  isDark: isDark,
                  iconColor: AppTheme.errorColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    print('🔐 [LOGOUT] Début du processus de déconnexion...');
    
    // Obtenir le NavigatorState root AVANT de fermer le drawer
    // Cela garantit que nous avons une référence stable pour la navigation
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    
    // Ouvrir le dialog AVANT de fermer le drawer pour garder le contexte valide
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    // Fermer le drawer après la fermeture du dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (confirm != true) {
      print('❌ [LOGOUT] Déconnexion annulée');
      return;
    }

    print('🔐 [LOGOUT] Déconnexion confirmée, nettoyage des données...');
    
    // Nettoyer les tokens et données utilisateur
    await ApiService.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    await prefs.remove('access_token');
    await prefs.remove('auth_token'); // Pour compatibilité
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    
    print('✅ [LOGOUT] Données nettoyées');
    
    // Naviguer vers l'écran de connexion en utilisant le Navigator root stocké
    // Utiliser un petit délai pour s'assurer que toutes les opérations sont terminées
    await Future.delayed(const Duration(milliseconds: 100));
    
    print('🔄 [LOGOUT] Navigation vers AuthScreen...');
    rootNavigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const AuthScreen(initialMode: 'login'),
      ),
      (route) => false, // Supprimer toutes les routes précédentes
    );
    
    print('✅ [LOGOUT] Redirection effectuée vers AuthScreen');
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final bool isSelected;
  final Color? iconColor;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
    this.isSelected = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppTheme.primaryColor;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryColor : color,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
      onTap: onTap,
    );
  }
}

