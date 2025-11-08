import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/map_screen.dart';
import 'package:temove/screens/admin_home_screen.dart';
import 'package:temove/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthScreen extends StatefulWidget {
  /// Mode initial de l'écran : 'login' pour connexion, 'signup' pour inscription
  final String? initialMode;
  
  const AuthScreen({
    super.key,
    this.initialMode, // 'login' ou 'signup', null = signup par défaut
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isSignUp;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _acceptTerms = true;
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Définir le mode initial : 'login' affiche le formulaire de connexion
    _isSignUp = widget.initialMode != 'login';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isSignUp && !_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions d\'utilisation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic> result;

      if (_isSignUp) {
        // Inscription
        result = await ApiService.register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );
      } else {
        // Connexion
        result = await ApiService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      if (result['success'] == true) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Opération réussie'),
            backgroundColor: Colors.green,
          ),
        );

        // Sauvegarder les données utilisateur (incluant is_admin)
        Map<String, dynamic>? userData;
        if (result['user'] != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            userData = result['user'] as Map<String, dynamic>;
            await prefs.setString('user_data', jsonEncode(userData));
            print('✅ Données utilisateur sauvegardées: ${result['user']}');
          } catch (e) {
            print('❌ Erreur lors de la sauvegarde des données utilisateur: $e');
          }
        }

        // Vérifier si l'utilisateur est admin et rediriger vers le bon écran
        final isAdmin = userData != null && 
                       (userData!['is_admin'] == true || 
                        userData!['is_admin'] == 'true' ||
                        userData!['is_admin'] == 1);
        
        print('🔍 [AUTH] Utilisateur connecté - is_admin: $isAdmin');
        print('🔍 [AUTH] Données utilisateur: $userData');
        
        // Naviguer vers l'écran approprié
        if (isAdmin) {
          // Rediriger les admins vers le dashboard admin
          print('✅ [AUTH] Redirection vers AdminHomeScreen (Dashboard Admin)');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminHomeScreen(),
            ),
          );
        } else {
          // Rediriger les clients vers l'écran principal
          print('✅ [AUTH] Redirection vers MapScreen');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MapScreen(),
            ),
          );
        }
      } else {
        // Afficher un message d'erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Une erreur est survenue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Header
                    Column(
                      children: [
                        Text(
                          'TéMove',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Votre trajet, vos règles',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark 
                            ? const Color(0xFF1C1F27) 
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Segmented Control
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? AppTheme.backgroundDark 
                                    : AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isSignUp = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: _isSignUp 
                                              ? AppTheme.primaryColor 
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'S\'inscrire',
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: _isSignUp 
                                                  ? FontWeight.bold 
                                                  : FontWeight.w500,
                                              color: _isSignUp
                                                  ? AppTheme.secondaryColor
                                                  : (isDark 
                                                      ? AppTheme.textMuted 
                                                      : Colors.grey.shade600),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isSignUp = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                        decoration: BoxDecoration(
                                          color: !_isSignUp 
                                              ? AppTheme.primaryColor 
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Se connecter',
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: !_isSignUp 
                                                  ? FontWeight.bold 
                                                  : FontWeight.w500,
                                              color: !_isSignUp
                                                  ? AppTheme.secondaryColor
                                                  : (isDark 
                                                      ? AppTheme.textMuted 
                                                      : Colors.grey.shade600),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Form Fields
                            if (_isSignUp) ...[
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom complet',
                                  hintText: 'Entrez votre nom complet',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer votre nom complet';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Adresse email',
                                hintText: 'Entrez votre email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre email';
                                }
                                if (!value.contains('@')) {
                                  return 'Merci d\'entrer un email valide';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                hintText: 'Entrez votre mot de passe',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword 
                                        ? Icons.visibility_off 
                                        : Icons.visibility,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                if (value.length < 6) {
                                  return 'Le mot de passe doit contenir au moins 6 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Checkbox & Forgot Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Checkbox(
                                        value: _acceptTerms,
                                        onChanged: (value) {
                                          setState(() {
                                            _acceptTerms = value ?? false;
                                          });
                                        },
                                        activeColor: AppTheme.primaryColor,
                                      ),
                                      Flexible(
                                        child: RichText(
                                          overflow: TextOverflow.visible,
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark 
                                                  ? AppTheme.textMuted 
                                                  : Colors.grey.shade600,
                                            ),
                                            children: const [
                                              TextSpan(text: 'J\'accepte les '),
                                              TextSpan(
                                                text: 'Conditions d\'utilisation',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Mot de passe oublié ?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Submit Button
                            ElevatedButton(
                              onPressed: (_isLoading || (_isSignUp && !_acceptTerms)) ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: AppTheme.secondaryColor,
                                minimumSize: const Size(double.infinity, 48),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
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
                                  : Text(
                                      _isSignUp ? 'S\'inscrire' : 'Se connecter',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: isDark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'Ou continuez avec',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark 
                                          ? AppTheme.textMuted 
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: isDark 
                                        ? Colors.grey.shade700 
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Social Login Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialLoginButton(
                                    icon: Icons.g_mobiledata,
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialLoginButton(
                                    icon: Icons.facebook,
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _SocialLoginButton(
                                    icon: Icons.apple,
                                    onTap: () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isDark 
              ? AppTheme.backgroundDark 
              : AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark 
                ? Colors.grey.shade700 
                : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
        ),
      ),
    );
  }
}

