import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:temove/services/api_service.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/map_screen.dart';
import 'user_info_screen.dart';

/// Écran de vérification du code OTP
class OtpVerificationScreen extends StatefulWidget {
  final String phone;
  final String method;
  final int expiresIn; // en secondes
  final bool isTotpMode; // Mode TOTP activé

  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.method,
    this.expiresIn = 300,
    this.isTotpMode = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  int _remainingSeconds = 300; // 5 minutes par défaut
  Timer? _timer;
  bool _isLoading = false;
  bool _canResend = false;
  String? _errorMessage;
  String? _currentTotpCode; // Code TOTP actuel (pour affichage)

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.expiresIn;
    _startTimer();
    
    // Ajouter des listeners sur les contrôleurs pour forcer la mise à jour
    for (var controller in _controllers) {
      controller.addListener(() {
        if (mounted) {
          setState(() {
            // Forcer la mise à jour de l'UI quand le texte change
          });
        }
      });
    }
    
    // Si mode TOTP, récupérer le code actuel
    if (widget.isTotpMode) {
      _fetchTotpCode();
      // Actualiser le code TOTP toutes les 30 secondes
      Timer.periodic(const Duration(seconds: 30), (timer) {
        if (mounted && widget.isTotpMode) {
          _fetchTotpCode();
        } else {
          timer.cancel();
        }
      });
    }
    
    // Focus sur le premier champ au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  /// Récupère le code TOTP actuel depuis le backend et le remplit automatiquement
  Future<void> _fetchTotpCode() async {
    try {
      final result = await ApiService.getTotpCode(phone: widget.phone);
      if (mounted && result['success'] == true) {
        final code = result['code'] as String?;
        if (code != null && code.length == 6) {
          setState(() {
            _currentTotpCode = code;
            // Remplir automatiquement les champs avec le code TOTP
            for (int i = 0; i < 6 && i < code.length; i++) {
              _controllers[i].text = code[i];
            }
          });
          // Vérifier automatiquement le code après un court délai
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _verifyOtp();
            }
          });
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération du code TOTP: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  /// Démarre le timer de compte à rebours
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  /// Formate le temps restant (MM:SS)
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Gère la saisie dans un champ OTP
  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Si un caractère est saisi, passer au champ suivant
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Si c'est le dernier champ, vérifier le code
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else {
      // Si le champ est vidé, revenir au champ précédent
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    // Vérifier si tous les champs sont remplis
    final allFilled = _controllers.every((controller) => controller.text.isNotEmpty);
    if (allFilled && index == 5) {
      _verifyOtp();
    }
  }

  /// Vérifie le code OTP
  Future<void> _verifyOtp({String? fullName}) async {
    final code = _controllers.map((controller) => controller.text).join();
    
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Veuillez entrer le code complet';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.verifyOtp(
        phone: widget.phone,
        code: code,
        fullName: fullName,
      );

      if (mounted) {
        if (result['success'] == true) {
          // Connexion réussie - Afficher message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result['is_new_user'] == true 
                          ? 'Bienvenue ! Votre compte a été créé avec succès.'
                          : 'Connexion réussie !',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Attendre un peu avant de rediriger pour montrer le message
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Aller à la carte
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
              (route) => false,
            );
          }
        } else {
          // Si le nom est requis, rediriger vers UserInfoScreen
          if (result['requires_name'] == true) {
            setState(() {
              _isLoading = false;
            });
            
            // Afficher un message informatif
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Veuillez compléter votre profil pour continuer',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 2),
              ),
            );
            
            // Sauvegarder le code OTP et rediriger vers UserInfoScreen
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UserInfoScreen(
                    phone: widget.phone,
                  ),
                  settings: RouteSettings(
                    arguments: {
                      'otp_code': code,
                      'phone': widget.phone,
                    },
                  ),
                ),
              );
            }
          } else {
            setState(() {
              _errorMessage = result['error'] ?? 'Code OTP invalide';
              _isLoading = false;
            });
            
            // Effacer les champs en cas d'erreur
            for (var controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }


  /// Renvoie un nouveau code OTP
  Future<void> _resendOtp() async {
    setState(() {
      _isLoading = true;
      _canResend = false;
      _remainingSeconds = widget.expiresIn;
      _errorMessage = null;
    });

    // Effacer les champs
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    try {
      final result = await ApiService.sendOtp(
        phone: widget.phone,
        method: widget.method,
      );

      if (mounted) {
        if (result['success'] == true) {
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Nouveau code envoyé par ${widget.method}'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
          
          // Afficher le code de debug si disponible
          if (result['debug_code'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Code de debug: ${result['debug_code']}'),
                backgroundColor: AppTheme.primaryColor,
                duration: const Duration(seconds: 10),
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
        title: const Text('Vérification'),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // Icône
              Icon(
                Icons.security,
                size: 80,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              
              Text(
                'Entrez le code de vérification',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              Text(
                widget.isTotpMode
                    ? 'Mode TOTP activé\nLe code change automatiquement toutes les 5 minutes'
                    : 'Code envoyé par ${widget.method} à\n${widget.phone}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.isTotpMode) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.vpn_key,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Code TOTP Actuel',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_currentTotpCode != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _currentTotpCode!,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ce code change automatiquement toutes les 5 minutes',
                          style: TextStyle(
                            color: AppTheme.textPrimary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chargement du code TOTP...',
                          style: TextStyle(
                            color: AppTheme.textPrimary.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              
              // Champs OTP
              Builder(
                builder: (context) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  // Utiliser des couleurs très contrastées pour garantir la visibilité
                  final textColor = isDark 
                      ? Colors.white  // Blanc sur fond sombre
                      : Colors.black87; // Noir sur fond clair
                  final fillColor = isDark 
                      ? AppTheme.surfaceDark.withOpacity(0.8)  // Fond sombre
                      : Colors.white; // Fond blanc
                  final borderColor = isDark 
                      ? AppTheme.grayMedium 
                      : AppTheme.grayLightest;
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return _OtpInputField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        enabled: !_isLoading,
                        isFocused: _focusNodes[index].hasFocus,
                        textColor: textColor,
                        fillColor: fillColor,
                        borderColor: borderColor,
                        errorMessage: _errorMessage != null && index == 5 ? _errorMessage : null,
                        onChanged: (value) => _onCodeChanged(index, value),
                        autofocus: index == 0,
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Timer et bouton de renvoi
              if (_remainingSeconds > 0)
                Text(
                  'Le code expire dans ${_formatTime(_remainingSeconds)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                )
              else
                TextButton(
                  onPressed: _canResend && !_isLoading ? _resendOtp : null,
                  child: const Text('Renvoyer le code'),
                ),
              const SizedBox(height: 24),
              
              // Bouton de vérification
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
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
                        'Vérifier',
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
    );
  }
}

/// Widget personnalisé pour les champs OTP avec affichage garanti
class _OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isFocused;
  final Color textColor;
  final Color fillColor;
  final Color borderColor;
  final String? errorMessage;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _OtpInputField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isFocused,
    required this.textColor,
    required this.fillColor,
    required this.borderColor,
    this.errorMessage,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  State<_OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<_OtpInputField> {
  @override
  void initState() {
    super.initState();
    // Écouter les changements du contrôleur pour forcer la mise à jour
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final isFocused = widget.focusNode.hasFocus;
    
    return SizedBox(
      width: 50,
      height: 60,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        enabled: widget.enabled,
        obscureText: false,
        textInputAction: TextInputAction.next,
        autofocus: widget.autofocus,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: widget.textColor,
          letterSpacing: 0,
          height: 1.0,
          shadows: [
            // Ajouter une ombre pour garantir la visibilité
            Shadow(
              offset: Offset(0, 0),
              blurRadius: 2,
              color: widget.fillColor.withOpacity(0.8),
            ),
          ],
        ),
        cursorColor: AppTheme.primaryColor,
        cursorWidth: 3,
        showCursor: isFocused,
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 16),
          isDense: false,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isFocused ? AppTheme.primaryColor : widget.borderColor,
              width: isFocused ? 3 : 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isFocused ? AppTheme.primaryColor : widget.borderColor,
              width: isFocused ? 3 : 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.primaryColor,
              width: 3,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: widget.borderColor.withOpacity(0.5),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: widget.fillColor,
          errorText: widget.errorMessage,
          errorMaxLines: 2,
          errorStyle: TextStyle(
            color: AppTheme.errorColor,
            fontSize: 10,
            height: 1.0,
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

