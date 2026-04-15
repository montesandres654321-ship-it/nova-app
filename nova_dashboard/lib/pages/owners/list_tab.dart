// lib/pages/owners/list_tab.dart
// CORRECCIÓN: OwnerService no existe — reemplazado por AdminService
// AdminService.getOwners()         → GET /api/admins/owners
// AdminService.toggleOwnerStatus() → PATCH /api/admins/:id/toggle

import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/admin_model.dart';

class OwnersListTab extends StatefulWidget {
  final bool canEdit;

  const OwnersListTab({
    super.key,
    required this.canEdit,
  });

  @override
  State<OwnersListTab> createState() => _OwnersListTabState();
}

class _OwnersListTabState extends State<OwnersListTab> {
  List<AdminModel> _owners         = [];
  List<AdminModel> _filteredOwners = [];
  bool   _loading      = true;
  String _error        = '';
  String _searchQuery  = '';
  String _filterRole   = 'all';

  @override
  void initState() {
    super.initState();
    _loadOwners();
  }

  Future<void> _loadOwners() async {
    setState(() { _loading = true; _error = ''; });
    try {
      // ← CORREGIDO: AdminService.getOwners() en lugar de OwnerService
      final owners = await AdminService.getOwners();
      if (mounted) {
        setState(() {
          _owners = owners;
          _applyFilters();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Error al cargar: $e'; _loading = false; });
    }
  }

  void _applyFilters() {
    var filtered = _owners;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((o) =>
      o.email.toLowerCase().contains(q)         ||
          o.username.toLowerCase().contains(q)      ||
          o.firstName.toLowerCase().contains(q)     ||
          o.lastName.toLowerCase().contains(q)).toList();
    }
    if (_filterRole != 'all') {
      filtered = filtered.where((o) => o.role == _filterRole).toList();
    }
    setState(() => _filteredOwners = filtered);
  }

  Future<void> _toggleOwnerStatus(AdminModel owner) async {
    if (!widget.canEdit) {
      _showError('No tienes permisos para editar administradores');
      return;
    }

    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Text(owner.isActive ? 'Desactivar Admin' : 'Activar Admin'),
            content: Text(owner.isActive
                ? '¿Desactivar a ${owner.displayName}? No podrá acceder al panel.'
                : '¿Activar a ${owner.displayName}? Podrá acceder nuevamente.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: owner.isActive ? Colors.red : Colors.green,
                      foregroundColor: Colors.white),
                  child: Text(owner.isActive ? 'Desactivar' : 'Activar')),
            ]));

    if (confirm != true || !mounted) return;

    try {
      // ← CORREGIDO: AdminService.toggleOwnerStatus() en lugar de OwnerService
      final result = await AdminService.toggleOwnerStatus(owner.id);
      if (mounted) {
        if (result['success'] == true) {
          _showSuccess(result['message'] ?? 'Estado actualizado');
          _loadOwners();
        } else {
          _showError(result['error'] ?? 'Error al cambiar estado');
        }
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green));

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Header + búsqueda ──────────────────────────────
      Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(children: [
            Row(children: [
              Expanded(child: TextField(
                  decoration: InputDecoration(
                      hintText: 'Buscar administradores...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () { setState(() => _searchQuery = ''); _applyFilters(); })
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); })),
              const SizedBox(width: 8),
              IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadOwners,
                  tooltip: 'Actualizar'),
            ]),
            const SizedBox(height: 12),

            // Filtro por rol
            DropdownButtonFormField<String>(
                value: _filterRole,
                decoration: const InputDecoration(
                    labelText: 'Filtrar por rol',
                    prefixIcon: Icon(Icons.filter_alt),
                    border: OutlineInputBorder(), isDense: true),
                items: const [
                  DropdownMenuItem(value: 'all',           child: Text('Todos')),
                  DropdownMenuItem(value: 'admin_general', child: Text('👑 Admin General')),
                  DropdownMenuItem(value: 'user_general',  child: Text('📋 Secretaría')),
                  DropdownMenuItem(value: 'user_place',    child: Text('🏪 Propietario')),
                ],
                onChanged: (v) { setState(() => _filterRole = v!); _applyFilters(); }),

            const SizedBox(height: 12),
            _buildStats(),
          ])),

      const Divider(height: 1),

      // ── Lista ──────────────────────────────────────────
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _buildError()
          : _filteredOwners.isEmpty
          ? _buildEmpty()
          : _buildList()),
    ]);
  }

  Widget _buildStats() {
    final total   = _owners.length;
    final admins  = _owners.where((o) => o.role == 'admin_general').length;
    final general = _owners.where((o) => o.role == 'user_general').length;
    final owners  = _owners.where((o) => o.role == 'user_place').length;

    return Row(children: [
      _statChip('Total',   total,   Colors.blue),
      const SizedBox(width: 6),
      _statChip('Admin',   admins,  Colors.purple),
      const SizedBox(width: 6),
      _statChip('General', general, Colors.teal),
      const SizedBox(width: 6),
      _statChip('Owners',  owners,  Colors.orange),
    ]);
  }

  Widget _statChip(String label, int value, Color color) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Text(value.toString(), style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: color)),
          ])));

  Widget _buildList() => ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOwners.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildCard(_filteredOwners[i]));

  Widget _buildCard(AdminModel owner) {
    final roleColors = {
      'admin_general': Colors.purple,
      'user_general':  Colors.teal,
      'user_place':    Colors.orange,
    };
    final color = roleColors[owner.role] ?? Colors.grey;

    return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
            leading: CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Text(owner.roleEmoji, style: const TextStyle(fontSize: 18))),
            title: Text(owner.displayName,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: owner.isActive ? Colors.black87 : Colors.grey)),
            subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(owner.email, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Row(children: [
                _badge(owner.roleLabel, color),
                const SizedBox(width: 6),
                _badge(owner.isActive ? 'Activo' : 'Inactivo',
                    owner.isActive ? Colors.green : Colors.red),
                if (owner.placeId != null) ...[
                  const SizedBox(width: 6),
                  _badge('Lugar #${owner.placeId}', Colors.blue),
                ],
              ]),
            ]),
            trailing: widget.canEdit
                ? PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'toggle') _toggleOwnerStatus(owner);
                  if (v == 'edit')   _showError('Función en desarrollo');
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Editar')])),
                  PopupMenuItem(value: 'toggle',
                      child: Row(children: [
                        Icon(owner.isActive ? Icons.block : Icons.check_circle,
                            size: 20,
                            color: owner.isActive ? Colors.red : Colors.green),
                        const SizedBox(width: 8),
                        Text(owner.isActive ? 'Desactivar' : 'Activar')])),
                ])
                : null));
  }

  Widget _badge(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600, color: color)));

  Widget _buildError() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadOwners, child: const Text('Reintentar')),
      ]));

  Widget _buildEmpty() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(_searchQuery.isNotEmpty
            ? 'No se encontraron administradores'
            : 'No hay administradores registrados',
            style: TextStyle(fontSize: 14, color: Colors.grey[500])),
      ]));
}