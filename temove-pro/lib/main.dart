import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/auth/driver_login_screen.dart';
import 'screens/dashboard/driver_dashboard_screen.dart';

void main() {
  runApp(const TemoveProApp());
}

class TemoveProApp extends StatelessWidget {
  const TemoveProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Témove Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.amber,
        primaryColor: const Color(0xFFFFC800), // Jaune Témove
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFC800),
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      routerConfig: _router,
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
