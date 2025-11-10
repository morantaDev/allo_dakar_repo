import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';

/// Écran de paramètres administratifs
/// 
/// Permet de configurer les paramètres globaux de l'application
/// (taux de commission, zones, horaires, etc.)
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  Map<String, dynamic>? _settings;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Contrôleurs pour les champs
  final TextEditingController _commissionRateController = TextEditingController();
  final TextEditingController _serviceFeeController = TextEditingController();
  final TextEditingController _minRidePriceController = TextEditingController();
  final TextEditingController _maxRidePriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _commissionRateController.dispose();
    _serviceFeeController.dispose();
    _minRidePriceController.dispose();
    _maxRidePriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminApiService.getSettings();

      if (result['success'] == true) {
        setState(() {
          _settings = result['settings'];
          
          // Initialiser les contrôleurs avec les valeurs récupérées
          _commissionRateController.text = (_settings?['commission_rate'] ?? 10.0).toString();
          _serviceFeeController.text = (_settings?['service_fee'] ?? 0).toString();
          _minRidePriceController.text = (_settings?['min_ride_price'] ?? 500).toString();
          _maxRidePriceController.text = (_settings?['max_ride_price'] ?? 50000).toString();
          
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final settingsToSave = {
        'commission_rate': double.tryParse(_commissionRateController.text) ?? 10.0,
        'service_fee': int.tryParse(_serviceFeeController.text) ?? 0,
        'min_ride_price': int.tryParse(_minRidePriceController.text) ?? 500,
        'max_ride_price': int.tryParse(_maxRidePriceController.text) ?? 50000,
      };

      final result = await AdminApiService.updateSettings(settingsToSave);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres sauvegardés avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadSettings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la sauvegarde'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Paramètres Administrateur'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveSettings,
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadSettings,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Commissions
                      _buildSectionTitle('Commissions', Icons.account_balance_wallet, isDark),
                      const SizedBox(height: 16),
                      _buildSettingCard(
                        title: 'Taux de commission',
                        subtitle: 'Pourcentage de commission sur chaque course (par défaut: 10%)',
                        child: TextField(
                          controller: _commissionRateController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Taux (%)',
                            suffixText: '%',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        title: 'Frais de service',
                        subtitle: 'Frais fixes par course (XOF)',
                        child: TextField(
                          controller: _serviceFeeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Frais (XOF)',
                            suffixText: 'XOF',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      
                      // Section Tarifs
                      _buildSectionTitle('Tarifs', Icons.attach_money, isDark),
                      const SizedBox(height: 16),
                      _buildSettingCard(
                        title: 'Prix minimum',
                        subtitle: 'Prix minimum d\'une course (XOF)',
                        child: TextField(
                          controller: _minRidePriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Prix minimum (XOF)',
                            suffixText: 'XOF',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildSettingCard(
                        title: 'Prix maximum',
                        subtitle: 'Prix maximum d\'une course (XOF)',
                        child: TextField(
                          controller: _maxRidePriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Prix maximum (XOF)',
                            suffixText: 'XOF',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: 24),
                      
                      // Bouton de sauvegarde
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveSettings,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label: Text(_isSaving ? 'Sauvegarde en cours...' : 'Sauvegarder les paramètres'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Section Informations
                      _buildInfoCard(isDark),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required Widget child,
    required bool isDark,
  }) {
    return Card(
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Informations',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Les modifications des paramètres prennent effet immédiatement pour toutes les nouvelles courses.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les commissions existantes ne sont pas affectées par les changements de taux.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

