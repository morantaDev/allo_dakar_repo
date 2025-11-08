import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/driver_api_service.dart';
import '../../widgets/temove_logo.dart';

/// Écran d'inscription en tant que chauffeur TéMove Pro
/// Permet à un utilisateur existant de s'inscrire en tant que chauffeur
class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _carMakeController = TextEditingController(text: 'Toyota');
  final _carModelController = TextEditingController(text: 'Corolla');
  final _carPlateController = TextEditingController();
  final _carColorController = TextEditingController(text: 'Blanc');
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _licenseController.dispose();
    _carMakeController.dispose();
    _carModelController.dispose();
    _carPlateController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await DriverApiService.register(
        licenseNumber: _licenseController.text.trim(),
        vehicle: {
          'make': _carMakeController.text.trim(),
          'model': _carModelController.text.trim(),
          'plate': _carPlateController.text.trim(),
          'color': _carColorController.text.trim(),
        },
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription réussie ! Vous êtes maintenant chauffeur. Veuillez vous reconnecter.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Rediriger vers le login pour se reconnecter
          // (maintenant que le profil chauffeur est créé, la connexion fonctionnera)
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors de l\'inscription';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Inscription Chauffeur'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo TéMove Pro
                Center(
                  child: TeMoveLogo(
                    size: 120,
                    showSlogan: false,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Devenez chauffeur TéMove',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complétez votre profil pour commencer',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Message d'erreur
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Numéro de permis
                TextFormField(
                  controller: _licenseController,
                  decoration: InputDecoration(
                    labelText: 'Numéro de permis de conduire *',
                    hintText: 'DL-12345',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de permis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Informations du véhicule
                Text(
                  'Informations du véhicule',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Marque du véhicule
                TextFormField(
                  controller: _carMakeController,
                  decoration: InputDecoration(
                    labelText: 'Marque *',
                    hintText: 'Toyota',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la marque du véhicule';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Modèle du véhicule
                TextFormField(
                  controller: _carModelController,
                  decoration: InputDecoration(
                    labelText: 'Modèle *',
                    hintText: 'Corolla',
                    prefixIcon: const Icon(Icons.car_rental),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer le modèle du véhicule';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Plaque d'immatriculation
                TextFormField(
                  controller: _carPlateController,
                  decoration: InputDecoration(
                    labelText: 'Plaque d\'immatriculation *',
                    hintText: 'ABC-123',
                    prefixIcon: const Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la plaque d\'immatriculation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Couleur du véhicule
                TextFormField(
                  controller: _carColorController,
                  decoration: InputDecoration(
                    labelText: 'Couleur *',
                    hintText: 'Blanc',
                    prefixIcon: const Icon(Icons.palette_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer la couleur du véhicule';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Bouton d'inscription
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'S\'inscrire en tant que chauffeur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                
                // Lien de retour
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Retour à la connexion',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

