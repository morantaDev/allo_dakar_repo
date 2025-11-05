import 'package:flutter/material.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              'Nom du Chauffeur',
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
                subtitle: 'Modifier',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'email@example.com',
              ),
              _ProfileTile(
                icon: Icons.phone_outlined,
                title: 'Téléphone',
                subtitle: '+221 XX XXX XX XX',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Informations véhicule
          _ProfileSection(
            title: 'Véhicule',
            children: [
              _ProfileTile(
                icon: Icons.directions_car,
                title: 'Marque',
                subtitle: 'Modifier',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.badge_outlined,
                title: 'Modèle',
                subtitle: 'Modifier',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.palette_outlined,
                title: 'Couleur',
                subtitle: 'Modifier',
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.confirmation_number_outlined,
                title: 'Plaque d\'immatriculation',
                subtitle: 'XX-XXX-XX',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Documents
          _ProfileSection(
            title: 'Documents',
            children: [
              _ProfileTile(
                icon: Icons.description_outlined,
                title: 'Permis de conduire',
                subtitle: 'Vérifié',
                trailing: Icon(Icons.check_circle, color: Colors.green),
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
                subtitle: '4.8 ⭐',
              ),
              _ProfileTile(
                icon: Icons.directions_car_outlined,
                title: 'Courses effectuées',
                subtitle: '150',
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Déconnexion
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implémenter la déconnexion
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

