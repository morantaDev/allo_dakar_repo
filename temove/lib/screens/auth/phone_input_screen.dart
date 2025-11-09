import 'package:flutter/material.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/theme/app_theme.dart';
import 'otp_verification_screen.dart';

/// Écran de saisie du numéro de téléphone pour connexion OTP
class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedMethod = 'SMS'; // 'SMS' ou 'WHATSAPP'

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Normalise le numéro de téléphone
  String _normalizePhone(String phone) {
    // Enlever les espaces et caractères spéciaux
    phone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Si le numéro commence par 0, le remplacer par +221
    if (phone.startsWith('0') && phone.length == 10) {
      phone = '+221${phone.substring(1)}';
    }
    // Si le numéro commence par 77, 78, 76, 70, ajouter +221
    else if ((phone.startsWith('77') || 
              phone.startsWith('78') || 
              phone.startsWith('76') || 
              phone.startsWith('70')) && 
              !phone.startsWith('+221')) {
      phone = '+221$phone';
    }
    // Si le numéro ne commence pas par +, ajouter +221
    else if (!phone.startsWith('+')) {
      phone = '+221$phone';
    }
    
    return phone;
  }

  /// Valide le format du numéro de téléphone
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }
    
    // Normaliser le numéro
    final normalized = _normalizePhone(value);
    
    // Vérifier le format (doit être +221XXXXXXXXX)
    if (!RegExp(r'^\+221[0-9]{9}$').hasMatch(normalized)) {
      return 'Format invalide. Ex: +221771234567 ou 0771234567';
    }
    
    return null;
  }

  /// Envoie le code OTP
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final normalizedPhone = _normalizePhone(_phoneController.text);
      
      final result = await ApiService.sendOtp(
        phone: normalizedPhone,
        method: _selectedMethod,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Afficher le code de debug si disponible (en développement)
          if (result['debug_code'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Code OTP (développement):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result['debug_code'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 15),
                action: SnackBarAction(
                  label: 'OK',
                  textColor: AppTheme.secondaryColor,
                  onPressed: () {},
                ),
              ),
            );
          } else {
            // Message de succès normal
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Code OTP envoyé par ${_selectedMethod}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.successColor,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          // Attendre un peu avant de naviguer
          await Future.delayed(const Duration(milliseconds: 300));

          // Naviguer vers l'écran de vérification OTP
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  phone: normalizedPhone,
                  method: _selectedMethod,
                  expiresIn: result['expires_in'] ?? 300,
                  isTotpMode: result['totp_mode'] ?? false,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Erreur lors de l\'envoi du code'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: AppTheme.surfaceDark,
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
        iconTheme: const IconThemeData(
          color: AppTheme.textPrimary,
        ),
        titleTextStyle: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
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
                const SizedBox(height: 40),
                
                // Logo et titre
                Icon(
                  Icons.phone_android,
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 24),
                
                Text(
                  'Entrez votre numéro',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Nous vous enverrons un code de vérification',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Champ de saisie du numéro
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: '+221771234567 ou 0771234567',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                  ),
                  validator: _validatePhone,
                  onChanged: (value) {
                    // Format automatique du numéro
                    if (value.length > 0 && !value.startsWith('+') && !value.startsWith('0')) {
                      if (value.startsWith('77') || 
                          value.startsWith('78') || 
                          value.startsWith('76') || 
                          value.startsWith('70')) {
                        _phoneController.value = TextEditingValue(
                          text: value,
                          selection: TextSelection.collapsed(offset: value.length),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 24),
                
                // Sélection de la méthode (SMS/WhatsApp)
                Text(
                  'Méthode d\'envoi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildMethodButton(
                        'SMS',
                        Icons.sms,
                        _selectedMethod == 'SMS',
                        () => setState(() => _selectedMethod = 'SMS'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMethodButton(
                        'WhatsApp',
                        Icons.chat,
                        _selectedMethod == 'WHATSAPP',
                        () => setState(() => _selectedMethod = 'WHATSAPP'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // Bouton d'envoi
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
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
                          'Envoyer le code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                
                // Informations
                Text(
                  'En continuant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textPrimary.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construit un bouton de méthode d'envoi
  Widget _buildMethodButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.surfaceDark,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

