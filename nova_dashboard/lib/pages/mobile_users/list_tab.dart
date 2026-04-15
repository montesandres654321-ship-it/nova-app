// lib/pages/mobile_users/list_tab.dart

import 'package:flutter/material.dart';
import 'package:nova_dashboard/services/admin_service.dart';
import 'package:nova_dashboard/models/user_model.dart';
import 'package:nova_dashboard/utils/app_theme.dart';
import 'package:nova_dashboard/pages/user_detail_page.dart';

class MobileUsersListTab extends StatefulWidget {
  final bool canEdit;

  const MobileUsersListTab({
    super.key,
    required this.canEdit,
  });

  @override
  State<MobileUsersListTab> createState() => _MobileUsersListTabState();
}

class _MobileUsersListTabState extends State<MobileUsersListTab> {
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _loading = true;
  String _error = '';
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _loading = true;
        _error = '';
      });

      // ✅ CORRECCIÓN: Usar instancia en lugar de método estático
      final response = await AdminService.getAllUsers();

      if (response['success'] == true) {
        final usersData = response['users'];
        if (usersData != null && usersData is List) {
          final users = usersData
              .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
              .toList();

          if (mounted) {
            setState(() {
              _users = users;
              _applyFilters();
              _loading = false;
            });
          }
        } else {
          throw Exception('Formato de datos inválido');
        }
      } else {
        throw Exception(response['error']?.toString() ?? 'Error al cargar usuarios');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar usuarios: $e';
          _loading = false;
        });
      }
    }
  }

  void _applyFilters() {
    var filtered = _users;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user.email.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query) ||
            (user.firstName?.toLowerCase().contains(query) ?? false) ||
            (user.lastName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_filterStatus == 'active') {
      filtered = filtered.where((u) => u.isActive).toList();
    } else if (_filterStatus == 'inactive') {
      filtered = filtered.where((u) => !u.isActive).toList();
    }

    setState(() {
      _filteredUsers = filtered;
    });
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    if (!widget.canEdit) {
      _showError('No tienes permisos para editar usuarios');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.isActive ? 'Desactivar Usuario' : 'Activar Usuario'),
        content: Text(
          user.isActive
              ? '¿Desactivar a ${user.displayName}? No podrá acceder al sistema.'
              : '¿Activar a ${user.displayName}? Podrá acceder nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isActive ? AppTheme.error : AppTheme.success,
            ),
            child: Text(user.isActive ? 'Desactivar' : 'Activar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // ✅ CORRECCIÓN: Usar instancia en lugar de método estático
        final result = await AdminService.toggleUserStatus(user.id);

        if (result['success'] == true) {
          if (mounted) {
            _showSuccess(result['message'] ?? 'Estado actualizado');
            _loadUsers();
          }
        } else {
          throw Exception(result['error'] ?? 'Error al cambiar estado');
        }
      } catch (e) {
        if (mounted) {
          _showError('Error: $e');
        }
      }
    }
  }

  void _navigateToUserDetail(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserDetailPage(userId: user.id),
      ),
    ).then((_) {
      _loadUsers();
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.success),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceMD),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar usuarios...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                      _applyFilters();
                    },
                  )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applyFilters();
                },
              ),
              const SizedBox(height: AppTheme.spaceSM),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'all',
                          label: Text('Todos'),
                          icon: Icon(Icons.people, size: 16),
                        ),
                        ButtonSegment(
                          value: 'active',
                          label: Text('Activos'),
                          icon: Icon(Icons.check_circle, size: 16),
                        ),
                        ButtonSegment(
                          value: 'inactive',
                          label: Text('Inactivos'),
                          icon: Icon(Icons.block, size: 16),
                        ),
                      ],
                      selected: {_filterStatus},
                      onSelectionChanged: (Set<String> selected) {
                        setState(() => _filterStatus = selected.first);
                        _applyFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceSM),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadUsers,
                    tooltip: 'Actualizar',
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceSM),
              _buildStats(),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error.isNotEmpty
              ? _buildErrorView()
              : _filteredUsers.isEmpty
              ? _buildEmptyView()
              : _buildUsersList(),
        ),
      ],
    );
  }

  Widget _buildStats() {
    final total = _users.length;
    final active = _users.where((u) => u.isActive).length;
    final inactive = total - active;

    return Row(
      children: [
        Expanded(child: _buildStatCard('Total', total, AppTheme.info)),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(child: _buildStatCard('Activos', active, AppTheme.success)),
        const SizedBox(width: AppTheme.spaceSM),
        Expanded(child: _buildStatCard('Inactivos', inactive, AppTheme.warning)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceSM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: AppTheme.error),
          const SizedBox(height: AppTheme.spaceMD),
          Text(_error, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.spaceMD),
          ElevatedButton(
            onPressed: _loadUsers,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: AppTheme.gray400),
          const SizedBox(height: AppTheme.spaceMD),
          Text(
            _searchQuery.isNotEmpty
                ? 'No se encontraron usuarios'
                : 'No hay usuarios registrados',
            style: const TextStyle(fontSize: 16, color: AppTheme.gray600),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppTheme.spaceMD),
      itemCount: _filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spaceSM),
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];
        return _buildUserCard(user);
      },
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? AppTheme.success.withOpacity(0.2)
              : AppTheme.gray300,
          child: Icon(
            user.isGoogleUser ? Icons.g_mobiledata : Icons.person,
            color: user.isActive ? AppTheme.success : AppTheme.gray600,
          ),
        ),
        title: Text(
          user.displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: user.isActive ? AppTheme.gray900 : AppTheme.gray500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? AppTheme.success.withOpacity(0.1)
                        : AppTheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Text(
                    user.isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: user.isActive ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                ),
                if (user.isGoogleUser) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.info.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                    ),
                    child: const Text(
                      'Google',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.info,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: widget.canEdit
            ? PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle') {
              _toggleUserStatus(user);
            } else if (value == 'detail') {
              _navigateToUserDetail(user);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'detail',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Ver detalle'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle',
              child: Row(
                children: [
                  Icon(
                    user.isActive ? Icons.block : Icons.check_circle,
                    size: 20,
                    color: user.isActive ? AppTheme.error : AppTheme.success,
                  ),
                  const SizedBox(width: 8),
                  Text(user.isActive ? 'Desactivar' : 'Activar'),
                ],
              ),
            ),
          ],
        )
            : null,
        onTap: () => _navigateToUserDetail(user),
      ),
    );
  }
}