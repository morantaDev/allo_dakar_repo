import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;
import 'dart:typed_data';

/// Écran de génération de rapports pour les administrateurs
/// 
/// Permet de générer et exporter différents types de rapports
/// (revenus, courses, conducteurs, utilisateurs, etc.)
class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  String _selectedReportType = 'revenue'; // revenue, rides, drivers, users, commissions
  DateTime? _startDate;
  DateTime? _endDate;
  String? _exportFormat; // 'excel', 'pdf'
  bool _isGenerating = false;

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _generateReport() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une période'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    if (_exportFormat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un format d\'export'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final result = await AdminApiService.generateReport(
        reportType: _selectedReportType,
        startDate: _startDate!,
        endDate: _endDate!,
        format: _exportFormat!,
      );

      if (result['success'] == true) {
        // Télécharger le fichier
        try {
          final fileData = result['file_data'] as Uint8List?;
          final filename = result['filename'] as String? ?? 'rapport.${_exportFormat == 'excel' ? 'xlsx' : 'pdf'}';
          
          if (fileData != null && fileData is Uint8List) {
            // Créer un blob et déclencher le téléchargement (Flutter Web)
            final blob = html.Blob([fileData as Uint8List]);
            final url = html.Url.createObjectUrlFromBlob(blob);
            final anchor = html.AnchorElement(href: url)
              ..setAttribute('download', filename)
              ..click();
            html.Url.revokeObjectUrl(url);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rapport généré et téléchargé: $filename'),
                  backgroundColor: AppTheme.successColor,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? 'Rapport généré avec succès'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            }
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rapport généré mais erreur lors du téléchargement: ${e.toString()}'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la génération du rapport'),
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
        _isGenerating = false;
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
        title: const Text('Rapports'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Type de rapport
            _buildSectionTitle('Type de rapport', Icons.description, isDark),
            const SizedBox(height: 12),
            _buildReportTypeSelector(isDark),
            const SizedBox(height: 24),
            
            // Section Période
            _buildSectionTitle('Période', Icons.calendar_today, isDark),
            const SizedBox(height: 12),
            _buildDateRangeSelector(isDark),
            const SizedBox(height: 24),
            
            // Section Format d'export
            _buildSectionTitle('Format d\'export', Icons.file_download, isDark),
            const SizedBox(height: 12),
            _buildExportFormatSelector(isDark),
            const SizedBox(height: 24),
            
            // Bouton de génération
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateReport,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download),
                label: Text(_isGenerating ? 'Génération en cours...' : 'Générer le rapport'),
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
            
            // Informations sur les rapports disponibles
            _buildReportInfo(isDark),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildReportTypeSelector(bool isDark) {
    final reportTypes = [
      {'value': 'revenue', 'label': 'Revenus', 'icon': Icons.attach_money},
      {'value': 'rides', 'label': 'Courses', 'icon': Icons.directions_car},
      {'value': 'drivers', 'label': 'Conducteurs', 'icon': Icons.local_taxi},
      {'value': 'users', 'label': 'Utilisateurs', 'icon': Icons.people},
      {'value': 'commissions', 'label': 'Commissions', 'icon': Icons.account_balance_wallet},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: reportTypes.map((type) {
        final isSelected = _selectedReportType == type['value'];
        return ChoiceChip(
          avatar: Icon(
            type['icon'] as IconData,
            size: 20,
            color: isSelected ? Colors.white : AppTheme.primaryColor,
          ),
          label: Text(type['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedReportType = type['value'] as String;
              });
            }
          },
          selectedColor: AppTheme.primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateRangeSelector(bool isDark) {
    return Card(
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate != null && _endDate != null
                          ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                          : 'Sélectionner une période',
                    ),
                    onPressed: _selectDateRange,
                  ),
                ),
                if (_startDate != null && _endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                      });
                    },
                    tooltip: 'Effacer',
                  ),
              ],
            ),
            if (_startDate != null && _endDate != null) ...[
              const SizedBox(height: 12),
              Text(
                'Durée: ${_endDate!.difference(_startDate!).inDays + 1} jour(s)',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExportFormatSelector(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Card(
            color: _exportFormat == 'excel'
                ? AppTheme.primaryColor.withOpacity(0.1)
                : (isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white),
            child: InkWell(
              onTap: () {
                setState(() {
                  _exportFormat = 'excel';
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.table_chart,
                      color: _exportFormat == 'excel' ? AppTheme.primaryColor : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Excel',
                      style: TextStyle(
                        fontWeight: _exportFormat == 'excel' ? FontWeight.bold : FontWeight.normal,
                        color: _exportFormat == 'excel'
                            ? AppTheme.primaryColor
                            : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            color: _exportFormat == 'pdf'
                ? AppTheme.primaryColor.withOpacity(0.1)
                : (isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white),
            child: InkWell(
              onTap: () {
                setState(() {
                  _exportFormat = 'pdf';
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: _exportFormat == 'pdf' ? AppTheme.errorColor : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'PDF',
                      style: TextStyle(
                        fontWeight: _exportFormat == 'pdf' ? FontWeight.bold : FontWeight.normal,
                        color: _exportFormat == 'pdf'
                            ? AppTheme.errorColor
                            : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReportInfo(bool isDark) {
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
            _buildInfoItem('Revenus', 'Rapport détaillé des revenus avec graphiques', isDark),
            _buildInfoItem('Courses', 'Liste complète des courses avec détails', isDark),
            _buildInfoItem('Conducteurs', 'Statistiques et performances des conducteurs', isDark),
            _buildInfoItem('Utilisateurs', 'Liste et activité des utilisateurs', isDark),
            _buildInfoItem('Commissions', 'Détails des commissions et paiements', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

