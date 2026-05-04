// lib/pages/users_page.dart
// CAMBIOS:
//  1. Import UserDetailPage descomentado
//  2. Navegación real a UserDetailPage en onTap y case 'detail'
//  3. Case 'edit' implementado — diálogo nombre/apellido/teléfono
//     llama PATCH /admin/users/:id (nuevo endpoint backend)
//  4. PopupMenuItem 'change-role' y _showChangeRoleDialog() eliminados
//  5. Texto del diálogo de desactivar corregido — menciona "app Nova"

import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import 'user_detail_page.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});
  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<UserModel> _users         = [];
  List<UserModel> _filteredUsers = [];
  bool   _loading      = true;
  String _error        = '';
  String _searchQuery  = '';
  String? _currentRole;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadCurrentRole();
  }

  Future<void> _loadCurrentRole() async {
    final role = await AdminService.getCurrentRole();
    if (mounted) setState(() => _currentRole = role);
  }

  Future<void> _loadUsers() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final response = await AdminService.getAllUsers();
      if (response['success'] == true) {
        final usersData = response['users'] as List? ?? [];
        final users = usersData
            .whereType<Map<String, dynamic>>()
            .map((j) => UserModel.fromJson(j))
            .toList();
        if (mounted) setState(() {
          _users         = users;
          _filteredUsers = users;
          _loading       = false;
        });
      } else {
        throw Exception(response['error'] ?? 'Error al cargar');
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        final q = query.toLowerCase();
        _filteredUsers = _users.where((u) =>
        u.email.toLowerCase().contains(q)        ||
            u.username.toLowerCase().contains(q)     ||
            (u.firstName ?? '').toLowerCase().contains(q) ||
            (u.lastName  ?? '').toLowerCase().contains(q)).toList();
      }
    });
  }

  // ── Desactivar / Activar ──────────────────────────────
  Future<void> _toggleUserStatus(UserModel user) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text(user.isActive ? 'Desactivar Turista' : 'Activar Turista'),
            content: Text(user.isActive
            // ← texto mejorado: menciona "app Nova" no "sistema"
                ? '¿Desactivar a ${user.displayName}?\n\n'
                'No podrá iniciar sesión en la app Nova.\n'
                'Su historial de escaneos y recompensas se conserva.\n'
                'Esta acción se puede revertir.'
                : '¿Activar a ${user.displayName}?\n\n'
                'Podrá volver a usar la app Nova.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: user.isActive ? Colors.red : Colors.green),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(user.isActive ? 'Desactivar' : 'Activar',
                      style: const TextStyle(color: Colors.white))),
            ]));

    if (confirm != true) return;

    try {
      final result = await AdminService.toggleUserStatus(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['success'] == true
              ? result['message'] ?? 'Estado actualizado'
              : result['error']   ?? 'Error'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red));
      if (result['success'] == true) { _loadUsers(); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Editar turista ─────────────────────────────────────
  // Campos editables: nombre, apellido, teléfono
  // NO: email, username, rol
  void _editUser(UserModel user) {
    final firstCtrl = TextEditingController(text: user.firstName ?? '');
    final lastCtrl  = TextEditingController(text: user.lastName  ?? '');
    final phoneCtrl = TextEditingController(text: user.phone     ?? '');

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Row(children: [
              const Icon(Icons.edit, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text('Editar — ${user.displayName}',
                  style: const TextStyle(fontSize: 16))),
            ]),
            content: SizedBox(width: 380, child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: TextField(
                        controller: firstCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            isDense: true))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                        controller: lastCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Apellido',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                            isDense: true))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          isDense: true)),
                ])),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // Usar el nuevo endpoint PATCH /admin/users/:id
                    final result = await AdminService.updateUser(
                      userId:    user.id,
                      firstName: firstCtrl.text.trim(),
                      lastName:  lastCtrl.text.trim(),
                      phone:     phoneCtrl.text.trim().isEmpty
                          ? null : phoneCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result['success'] == true
                            ? 'Turista actualizado correctamente'
                            : result['error'] ?? 'Error al actualizar'),
                        backgroundColor: result['success'] == true
                            ? Colors.green : Colors.red));
                    if (result['success'] == true) { _loadUsers(); }
                  },
                  child: const Text('Guardar')),
            ]));
  }

  Widget _buildPageHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Turistas',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Gestión de usuarios registrados',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ]),
        const Spacer(),
        _buildIconButton(icon: Icons.refresh_rounded, tooltip: 'Actualizar', onTap: _loadUsers),
      ]),
    );
  }

  // Botón icono reutilizable
  Widget _buildIconButton({required IconData icon, required String tooltip, required VoidCallback onTap}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF64748B)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
          _buildPageHeader(),
          // Barra de búsqueda
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                        hintText: 'Buscar turista...',
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11)),
                    onChanged: _filterUsers),
              )),

          // Contador
          if (!_loading && _error.isEmpty)
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                child: Row(children: [
                  Text('${_filteredUsers.length} turistas',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500)),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Text('· filtrando por "$_searchQuery"',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ])),

          // Lista
          Expanded(child: _loading
              ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Cargando turistas...'),
              ]))
              : _error.isNotEmpty
              ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.red),
                const SizedBox(height: 12),
                Text(_error, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                    onPressed: _loadUsers,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6A4)),
                    child: const Text('Reintentar',
                        style: TextStyle(color: Colors.white))),
              ]))
              : _filteredUsers.isEmpty
              ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 56, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(_searchQuery.isNotEmpty
                    ? 'Sin resultados para "$_searchQuery"'
                    : 'No hay turistas registrados',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ]))
              : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: _filteredUsers.length,
                itemBuilder: (_, i) => _buildUserCard(_filteredUsers[i]),
              ))),
        ]);
  }

  Widget _buildUserCard(UserModel user) {
    return _UserCardItem(
      user: user,
      currentRole: _currentRole,
      // ← Tap abre UserDetailPage
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => UserDetailPage(userId: user.id))),
      // ← Editar solo admin_general
      onEdit: () { if (_currentRole == 'admin_general') _editUser(user); },
      onToggle: () => _toggleUserStatus(user),
    );
  }
}

// ── Card item con hover effect para desktop ───────────────
class _UserCardItem extends StatefulWidget {
  final UserModel user;
  final String? currentRole;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const _UserCardItem({
    required this.user,
    required this.currentRole,
    required this.onTap,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  State<_UserCardItem> createState() => _UserCardItemState();
}

class _UserCardItemState extends State<_UserCardItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF0FDFA) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFF06B6A4).withOpacity(0.35)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hovered ? 0.08 : 0.04),
                blurRadius: _hovered ? 14 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: user.isActive
                    ? const Color(0xFF06B6A4).withOpacity(0.12)
                    : Colors.grey.shade200,
                child: Icon(
                    user.isGoogleUser ? Icons.g_mobiledata : Icons.person,
                    color: user.isActive ? const Color(0xFF06B6A4) : Colors.grey,
                    size: 22),
              ),
              const SizedBox(width: 14),

              // Info principal
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.displayName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15,
                            color: Color(0xFF111827))),
                    const SizedBox(height: 3),
                    Text(user.email,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 7),
                    Row(children: [
                      // Badge estado
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: user.isActive
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(
                              user.isActive ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: user.isActive
                                      ? const Color(0xFF059669)
                                      : Colors.red))),
                      const SizedBox(width: 8),
                      Text('${user.scansCount} escaneos',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9CA3AF))),
                      if (user.isGoogleUser) ...[
                        const SizedBox(width: 8),
                        const Text('Google',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF9CA3AF))),
                      ],
                    ]),
                  ])),

              // Menú de acciones
              PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    switch (value) {
                    // ← Activado: navega a UserDetailPage
                      case 'detail': widget.onTap(); break;
                    // ← Implementado: abre diálogo de edición
                      case 'edit':   widget.onEdit(); break;
                      case 'toggle': widget.onToggle(); break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    // Ver detalle — siempre visible
                    const PopupMenuItem(
                        value: 'detail',
                        child: Row(children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Text('Ver detalle'),
                        ])),

                    // Editar — solo admin_general
                    if (widget.currentRole == 'admin_general')
                      const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ])),

                    // ← 'change-role' ELIMINADO — turistas no cambian de rol

                    // Desactivar / Activar
                    PopupMenuItem(
                        value: 'toggle',
                        child: Row(children: [
                          Icon(
                              user.isActive ? Icons.block : Icons.check_circle,
                              size: 20,
                              color: user.isActive ? Colors.red : Colors.green),
                          const SizedBox(width: 8),
                          Text(user.isActive ? 'Desactivar' : 'Activar'),
                        ])),
                  ]),
            ]),
          ),
        ),
      ),
    );
  }
}
