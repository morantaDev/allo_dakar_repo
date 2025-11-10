import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/models/promo_code.dart';

class PromoCodeScreen extends StatefulWidget {
  final String? initialCode;

  const PromoCodeScreen({
    super.key,
    this.initialCode,
  });

  @override
  State<PromoCodeScreen> createState() => _PromoCodeScreenState();
}

class _PromoCodeScreenState extends State<PromoCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  PromoCode? _appliedCode;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCode != null) {
      _codeController.text = widget.initialCode!;
      _applyCode();
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _applyCode() {
    setState(() {
      _errorMessage = null;
      final code = _codeController.text.toUpperCase().trim();

      if (code.isEmpty) {
        _errorMessage = 'Veuillez entrer un code';
        _appliedCode = null;
        return;
      }

      final promo = PromoCode.sampleCodes.firstWhere(
        (p) => p.code == code,
        orElse: () => PromoCode(
          code: code,
          description: 'Code invalide',
          type: PromoType.percentage,
          value: 0,
        ),
      );

      if (promo.isValid && promo.code != code) {
        _errorMessage = 'Code promo non valide ou expiré';
        _appliedCode = null;
      } else {
        _appliedCode = promo.isValid ? promo : null;
        if (_appliedCode == null) {
          _errorMessage = 'Code promo non valide ou expiré';
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _appliedCode),
        ),
        title: const Text('Code Promo'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Input field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Code Promo',
                hintText: 'Entrez votre code',
                prefixIcon: const Icon(Icons.local_offer),
                suffixIcon: _codeController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _codeController.clear();
                          setState(() {
                            _appliedCode = null;
                            _errorMessage = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? AppTheme.backgroundColor.withOpacity(0.3)
                    : Colors.white,
              ),
              textCapitalization: TextCapitalization.characters,
              onChanged: (value) {
                setState(() {
                  _errorMessage = null;
                });
              },
            ),
            const SizedBox(height: 16),
            // Apply button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _applyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Appliquer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_appliedCode != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Code appliqué !',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _appliedCode!.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.textMuted
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            // Available codes
            Text(
              'Codes disponibles',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...PromoCode.sampleCodes.map((code) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.secondaryColor.withOpacity(0.2)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        code.code,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        code.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.textMuted
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

