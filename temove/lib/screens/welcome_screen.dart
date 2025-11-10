import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/screens/auth_screen.dart';
import 'package:temove/screens/auth/phone_input_screen.dart';
import 'package:temove/widgets/temove_logo.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              flex: 2,
              child: SizedBox(),
            ),
            // Logo TeMove
            TeMoveLogoOutline(
              size: 150,
            ),
            const Expanded(
              flex: 2,
              child: SizedBox(),
            ),
            // Boutons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton Connexion par téléphone (OTP) - PRINCIPAL
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PhoneInputScreen(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_android, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Se connecter avec téléphone',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Séparateur
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppTheme.textPrimary.withOpacity(0.2),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ou',
                          style: TextStyle(
                            color: AppTheme.textPrimary.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppTheme.textPrimary.withOpacity(0.2),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Bouton Connexion par email (ancien système) - SECONDAIRE
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AuthScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: BorderSide(
                          color: AppTheme.textPrimary.withOpacity(0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.email, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Se connecter avec email',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
            const Expanded(
              flex: 1,
              child: SizedBox(),
            ),
          ],
        ),
      ),
    );
  }
}
