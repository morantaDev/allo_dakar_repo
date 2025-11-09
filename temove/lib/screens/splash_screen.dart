import 'package:flutter/material.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/screens/map_screen.dart';
import 'package:temove/screens/welcome_screen.dart';
import 'package:temove/screens/admin_home_screen.dart';
import 'package:temove/widgets/temove_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temove/utils/navigation.dart';
import 'dart:convert';
import 'package:temove/theme/app_theme.dart';

/// Écran de démarrage qui vérifie l'authentification et redirige automatiquement
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Attendre que le widget soit complètement construit avant de naviguer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  /// Vérifie si l'utilisateur est déjà connecté
  Future<void> _checkAuthentication() async {
    // Attendre un peu pour afficher le splash (minimum 1 seconde pour une meilleure UX)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    try {
      // Vérifier si un token existe
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userJson = prefs.getString('user_data');

      Widget targetScreen;

      if (token != null && token.isNotEmpty && userJson != null) {
        // Token existant, vérifier s'il est valide en appelant l'API
        try {
          // Tenter de vérifier le token avec l'API
          // getCurrentUser() retourne directement les données utilisateur ou lance une exception
          final userData = await ApiService.getCurrentUser();
          
          // Vérifier si l'utilisateur est admin
          final isAdmin = userData['is_admin'] == true || 
                         userData['is_admin'] == 'true' || 
                         userData['is_admin'] == 1;

          print('✅ [SPLASH] Utilisateur connecté - Admin: $isAdmin');
          
          // Déterminer l'écran cible
          targetScreen = isAdmin 
              ? const AdminHomeScreen()
              : const MapScreen();
        } catch (e) {
          // Erreur lors de la vérification (token invalide ou expiré)
          print('❌ [SPLASH] Erreur lors de la vérification du token: $e');
          print('❌ [SPLASH] Token invalide ou expiré, nettoyage et redirection vers WelcomeScreen');
          // Nettoyer les données invalides
          await prefs.remove('access_token');
          await prefs.remove('user_data');
          targetScreen = const WelcomeScreen();
        }
      } else {
        print('ℹ️ [SPLASH] Aucun token trouvé, redirection vers WelcomeScreen');
        targetScreen = const WelcomeScreen();
      }

      // Naviguer vers l'écran cible
      if (!mounted) return;
      
      // Utiliser Navigator.of pour une navigation simple et fiable
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => targetScreen,
        ),
      );
      
      print('✅ [SPLASH] Navigation vers ${targetScreen.runtimeType}');
    } catch (e, stackTrace) {
      // En cas d'erreur, aller à l'écran d'accueil
      print('❌ [SPLASH] Erreur: $e');
      print('❌ [SPLASH] Stack trace: $stackTrace');
      
      if (!mounted) return;
      
      // Navigation de secours vers WelcomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const WelcomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo TeMove
            TeMoveLogoOutline(
              size: 120,
            ),
            const SizedBox(height: 24),
            // Indicateur de chargement
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
