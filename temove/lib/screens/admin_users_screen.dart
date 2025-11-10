import 'package:flutter/material.dart';
import 'package:temove/theme/app_theme.dart';
import 'package:temove/widgets/admin_drawer.dart';
import 'package:temove/services/admin_api_service.dart';

/// Écran de gestion des utilisateurs (clients) pour les administrateurs
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatus; // 'active', 'inactive', null pour tous

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({bool resetPage = false}) async {
    if (resetPage) {
      setState(() {
        _currentPage = 1;
      });
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AdminApiService.getUsers(
        page: _currentPage,
        perPage: 20,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        status: _selectedStatus,
      );

      if (result['success'] == true) {
        setState(() {
          _users = result['users'] ?? [];
          final pagination = result['pagination'] ?? {};
          _totalPages = pagination['pages'] ?? 1;
          _totalUsers = pagination['total'] ?? 0;
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

  Future<void> _toggleUserStatus(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le statut'),
        content: const Text('Êtes-vous sûr de vouloir modifier le statut de cet utilisateur ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await AdminApiService.toggleUserStatus(userId);

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Statut modifié avec succès'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadUsers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur lors de la modification'),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Gestion des Utilisateurs'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadUsers(resetPage: true),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                ),
              ),
            ),
            child: Column(
              children: [
                // Recherche
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, email, téléphone...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadUsers(resetPage: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                  ),
                  onSubmitted: (_) => _loadUsers(resetPage: true),
                ),
                const SizedBox(height: 12),
                // Filtres de statut
                Row(
                  children: [
                    const Text('Statut: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Tous'),
                      selected: _selectedStatus == null,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _loadUsers(resetPage: true);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Actifs'),
                      selected: _selectedStatus == 'active',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = 'active';
                          });
                          _loadUsers(resetPage: true);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Inactifs'),
                      selected: _selectedStatus == 'inactive',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedStatus = 'inactive';
                          });
                          _loadUsers(resetPage: true);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des utilisateurs
          Expanded(
            child: _isLoading
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
                              onPressed: () => _loadUsers(),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      )
                    : _users.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 64,
                                  color: isDark ? AppTheme.textMuted : Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Aucun utilisateur trouvé',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark ? AppTheme.textMuted : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _loadUsers(),
                            child: Column(
                              children: [
                                // En-tête avec total
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Total: $_totalUsers utilisateur${_totalUsers > 1 ? 's' : ''}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Liste
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _users.length,
                                    itemBuilder: (context, index) {
                                      final user = _users[index] as Map<String, dynamic>;
                                      return _UserCard(
                                        user: user,
                                        isDark: isDark,
                                        onToggleStatus: () => _toggleUserStatus(user['id'] as int),
                                        onTap: () {
                                          // TODO: Naviguer vers les détails de l'utilisateur
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Détails de ${user['full_name'] ?? user['name'] ?? 'Utilisateur'}'),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                                // Pagination
                                if (_totalPages > 1)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.chevron_left),
                                          onPressed: _currentPage > 1
                                              ? () {
                                                  setState(() {
                                                    _currentPage--;
                                                  });
                                                  _loadUsers();
                                                }
                                              : null,
                                        ),
                                        Text(
                                          'Page $_currentPage sur $_totalPages',
                                          style: TextStyle(
                                            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chevron_right),
                                          onPressed: _currentPage < _totalPages
                                              ? () {
                                                  setState(() {
                                                    _currentPage++;
                                                  });
                                                  _loadUsers();
                                                }
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onToggleStatus;
  final VoidCallback onTap;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.onToggleStatus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = user['is_active'] == true || user['is_active'] == 1;
    final fullName = user['full_name'] ?? user['name'] ?? 'Utilisateur';
    final email = user['email'] ?? '';
    final phone = user['phone'] ?? '';
    final totalRides = user['total_rides'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppTheme.secondaryColor.withOpacity(0.3) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive ? AppTheme.successColor : AppTheme.errorColor,
          child: Text(
            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          fullName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.textPrimary : AppTheme.textSecondary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email),
            if (phone.isNotEmpty) Text(phone),
            Text('$totalRides course${totalRides > 1 ? 's' : ''}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(isActive ? 'Actif' : 'Inactif'),
              backgroundColor: isActive
                  ? AppTheme.successColor.withOpacity(0.2)
                  : AppTheme.errorColor.withOpacity(0.2),
              labelStyle: TextStyle(
                color: isActive ? AppTheme.successColor : AppTheme.errorColor,
                fontSize: 12,
              ),
            ),
            IconButton(
              icon: Icon(isActive ? Icons.block : Icons.check_circle),
              onPressed: onToggleStatus,
              tooltip: isActive ? 'Désactiver' : 'Activer',
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

