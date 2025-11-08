import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/models/local_landmarks.dart';

class LandmarksScreen extends StatefulWidget {
  final Function(LocalLandmark)? onLandmarkSelected;

  const LandmarksScreen({
    super.key,
    this.onLandmarkSelected,
  });

  @override
  State<LandmarksScreen> createState() => _LandmarksScreenState();
}

class _LandmarksScreenState extends State<LandmarksScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LocalLandmark> _filteredLandmarks = LocalLandmark.dakarLandmarks;
  LandmarkType? _selectedType;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredLandmarks = LocalLandmark.search(_searchController.text);
    });
  }

  void _filterByType(LandmarkType? type) {
    setState(() {
      _selectedType = type;
      if (type == null) {
        _filteredLandmarks = LocalLandmark.dakarLandmarks;
      } else {
        _filteredLandmarks = LocalLandmark.getByType(type);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Destinations populaires'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher... (ex: Sandaga, Yoff)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: isDark
                    ? AppTheme.backgroundColor.withOpacity(0.3)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Type Filters
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _TypeChip(
                  label: 'Tout',
                  isSelected: _selectedType == null,
                  onTap: () => _filterByType(null),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Marchés',
                  isSelected: _selectedType == LandmarkType.market,
                  onTap: () => _filterByType(LandmarkType.market),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Plages',
                  isSelected: _selectedType == LandmarkType.beach,
                  onTap: () => _filterByType(LandmarkType.beach),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Quartiers',
                  isSelected: _selectedType == LandmarkType.neighborhood,
                  onTap: () => _filterByType(LandmarkType.neighborhood),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: 'Monuments',
                  isSelected: _selectedType == LandmarkType.monument,
                  onTap: () => _filterByType(LandmarkType.monument),
                  isDark: isDark,
                ),
              ],
            ),
          ),
          // Landmarks List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredLandmarks.length,
              itemBuilder: (context, index) {
                final landmark = _filteredLandmarks[index];
                return _LandmarkCard(
                  landmark: landmark,
                  isDark: isDark,
                  onTap: () {
                    if (widget.onLandmarkSelected != null) {
                      widget.onLandmarkSelected!(landmark);
                    }
                    Navigator.pop(context, landmark);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : (isDark
                  ? AppTheme.backgroundColor.withOpacity(0.3)
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? AppTheme.secondaryColor
                : (isDark ? AppTheme.textPrimary : AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _LandmarkCard extends StatelessWidget {
  final LocalLandmark landmark;
  final bool isDark;
  final VoidCallback onTap;

  const _LandmarkCard({
    required this.landmark,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.secondaryColor.withOpacity(0.2)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (landmark.icon != null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      landmark.icon!,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              if (landmark.icon != null) const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landmark.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      landmark.nameWolof,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      landmark.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textMuted
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

