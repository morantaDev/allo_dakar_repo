import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/admin_screen.dart';
import 'package:temove/widgets/admin_drawer.dart';

/// Écran d'accueil pour les administrateurs
/// Affiche le dashboard admin avec navigation dédiée
/// 
/// Ce widget contient le Scaffold avec AppBar et Drawer.
/// AdminScreen ne contient que le contenu du body (sans Scaffold).
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Clé globale pour accéder à l'état de AdminScreen
  final GlobalKey<AdminScreenState> _adminScreenKey = GlobalKey<AdminScreenState>();

  void _refreshDashboard() {
    // Appeler la méthode refresh() de AdminScreenState
    _adminScreenKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      // Ne pas définir de leading personnalisé - Flutter le gère automatiquement avec le drawer
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              'TeMove',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Admin',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true, // Permet à Flutter de gérer le bouton menu automatiquement
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: AdminScreen(key: _adminScreenKey),
    );
  }
}

