import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:temove_pro/theme/app_theme.dart';
import 'screens/auth/driver_login_screen.dart';
import 'screens/auth/driver_register_screen.dart';
import 'screens/auth/driver_signup_screen.dart';
import 'screens/dashboard/driver_dashboard_screen.dart';

/// Application principale TéMove Pro (Application Chauffeur)
/// Utilise le thème uniforme TéMove avec les couleurs jaune, noir, vert
void main() {
  runApp(const TemoveProApp());
}

class TemoveProApp extends StatelessWidget {
  const TemoveProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TéMove Pro',
      debugShowCheckedModeBanner: false,
      // Utiliser le thème uniforme TéMove
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Mode sombre par défaut
      routerConfig: _router,
      // Configuration pour le favicon et le titre
      // Le favicon est configuré dans web/index.html
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const DriverLoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const DriverSignupScreen(),
    ),
    GoRoute(
      path: '/register-driver',
      builder: (context, state) => const DriverRegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DriverDashboardScreen(),
    ),
  ],
  redirect: (context, state) {
    // TODO: Vérifier si l'utilisateur est connecté
    // Si non connecté et pas sur /login, rediriger vers /login
    return null;
  },
);
