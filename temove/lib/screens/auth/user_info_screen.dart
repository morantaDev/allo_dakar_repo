import 'package:flutter/material.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/map_screen.dart';

/// Écran de saisie du nom pour les nouveaux utilisateurs
class UserInfoScreen extends StatefulWidget {
  final String phone;

  const UserInfoScreen({
    super.key,
    required this.phone,
  });

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Récupérer le code OTP depuis les arguments si disponible
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        // Le code OTP est stocké dans les arguments pour être utilisé lors de la soumission
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  /// Valide le prénom
  String? _validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre prénom';
    }
    if (value.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Valide le nom
  String? _validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre nom';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  /// Complète l'inscription avec le nom et prénom
  /// 
  /// Envoie les informations au backend pour compléter l'inscription
  /// puis redirige vers l'écran principal (MapScreen)
  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = '$firstName $lastName';

      // Appeler l'API pour compléter l'inscription
      // Note: Le backend devrait avoir un endpoint pour compléter l'inscription
      // Pour l'instant, on utilise verifyOtp avec le nom complet
      // L'utilisateur devra avoir un code OTP valide
      
      // Si nous avons reçu un code OTP dans les arguments, l'utiliser
      final args = ModalRoute.of(context)?.settings.arguments;
      String? otpCode;
      if (args != null && args is Map<String, dynamic>) {
        otpCode = args['otp_code'] as String?;
      }

      if (otpCode != null && otpCode.isNotEmpty) {
        // Vérifier l'OTP avec le nom complet
        final result = await ApiService.verifyOtp(
          phone: widget.phone,
          code: otpCode,
          fullName: fullName,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (result['success'] == true) {
            // Inscription complète - Afficher message de succès
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Profil complété avec succès ! Bienvenue sur TéMove.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Attendre un peu avant de rediriger
            await Future.delayed(const Duration(milliseconds: 500));
            
            // Rediriger vers l'écran principal
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
                (route) => false,
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['error'] ?? 'Erreur lors de l\'inscription'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // Pas de code OTP, retourner à l'écran de vérification
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez d\'abord vérifier votre code OTP'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Informations'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          color: AppTheme.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Icône
                Icon(
                  Icons.person_add,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Complétez votre profil',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Nous avons besoin de quelques informations pour créer votre compte',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Champ prénom
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Prénom',
                    hintText: 'Votre prénom',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                  ),
                  validator: _validateFirstName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                
                // Champ nom
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom',
                    hintText: 'Votre nom',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                  ),
                  validator: _validateLastName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 40),
                
                // Bouton de validation
                ElevatedButton(
                  onPressed: _isLoading ? null : _completeRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continuer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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

