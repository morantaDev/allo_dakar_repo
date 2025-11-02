import 'package:flutter/material.dart';
import 'package:allo_dakar/theme/app_theme.dart';
import 'package:allo_dakar/screens/profile_screen.dart';
import 'package:allo_dakar/screens/history_screen.dart';
import 'package:allo_dakar/screens/map_screen.dart';
import 'package:allo_dakar/screens/loyalty_screen.dart';
import 'package:allo_dakar/screens/referral_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      child: Column(
        children: [
          // Header
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
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mor Anta SENE',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'morantadev@gmail.com',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _DrawerMenuItem(
                  icon: Icons.home,
                  title: 'Accueil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.history,
                  title: 'Historique',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.person,
                  title: 'Mon Profil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.payment,
                  title: 'Paiements',
                  onTap: () {
                    Navigator.pop(context);
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.local_offer,
                  title: 'Promotions',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Ouvrir écran promotions
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.emoji_events,
                  title: 'Fidélité',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoyaltyScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.person_add,
                  title: 'Parrainer un ami',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReferralScreen(),
                      ),
                    );
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.help_outline,
                  title: 'Aide',
                  onTap: () {
                    Navigator.pop(context);
                  },
                  isDark: isDark,
                ),
                _DrawerMenuItem(
                  icon: Icons.settings,
                  title: 'Paramètres',
                  onTap: () {
                    Navigator.pop(context);
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
                  icon: Icons.info_outline,
                  title: 'À propos',
                  onTap: () {
                    Navigator.pop(context);
                    showAboutDialog(
                      context: context,
                      applicationName: 'Allo Dakar',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '© 2025 Allo Dakar',
                    );
                  },
                  isDark: isDark,
                ),
              ],
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.backgroundColor.withOpacity(0.3)
                    : AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Besoin d\'aide ?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark 
                                ? AppTheme.textPrimary 
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contactez-nous',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? AppTheme.textMuted 
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDark;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDark 
              ? AppTheme.textPrimary 
              : AppTheme.textSecondary,
        ),
      ),
      onTap: onTap,
    );
  }
}

