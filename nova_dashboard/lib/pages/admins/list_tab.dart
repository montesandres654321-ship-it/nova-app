// lib/pages/admins/list_tab.dart
// CAMBIOS:
//  1. Botón "Desactivar" agregado en AdminCard — soft delete
//     llama DELETE /admin/users/:id (nuevo endpoint backend)
//  2. _editAdmin usa PATCH /admin/users/:id (nuevo endpoint)
//     — antes llamaba PUT /users/update/:id que no existía
//  3. Diálogo de desactivación con 2 advertencias claras

import 'package:flutter/material.dart';
import '../../models/admin_stats_model.dart';
import '../../services/admin_service.dart';
import '../../services/place_service.dart';
import '../../models/place.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_widget.dart';
import 'admin_card.dart';
import 'admin_detail_dialog.dart';

class AdminsListTab extends StatefulWidget {
  // canEdit: true = admin_general, false = user_general (solo lectura)
  final bool canEdit;
  const AdminsListTab({Key? key, this.canEdit = true}) : super(key: key);
  @override
  State<AdminsListTab> createState() => _AdminsListTabState();
}

class _AdminsListTabState extends State<AdminsListTab> {
  List<AdminStats> _allAdmins      = [];
  List<AdminStats> _filteredAdmins = [];
  bool    _isLoading  = true;
  String? _error;
  String  _filterRole  = 'all';
  String  _searchQuery = '';

  @override
  void initState() { super.initState(); _loadAdmins(); }

  Future<void> _loadAdmins() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final admins = await AdminService.getUsersWithDetails();
      setState(() { _allAdmins = admins; _applyFilters(); _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _applyFilters() {
    var filtered = _allAdmins;
    if (_filterRole != 'all') {
      filtered = filtered.where((a) => a.admin.role == _filterRole).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((a) =>
      a.admin.displayName.toLowerCase().contains(q) ||
          a.admin.email.toLowerCase().contains(q)       ||
          (a.admin.placeName?.toLowerCase().contains(q) ?? false)).toList();
    }
    setState(() => _filteredAdmins = filtered);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildHeader(),
      _buildFilters(),
      _buildCounters(),
      const SizedBox(height: 16),
      Expanded(child: _buildContent()),
    ]);
  }

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(
                color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)]),
        child: Row(children: [
          const Icon(Icons.admin_panel_settings, size: 28, color: Colors.teal),
          const SizedBox(width: 12),
          const Text('Administradores',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          if (widget.canEdit)
            ElevatedButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Crear usuario'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAdmins),
        ]));
  }

  // ── Filtros ────────────────────────────────────────────
  Widget _buildFilters() {
    return Container(
        padding: const EdgeInsets.all(16), color: Colors.grey[50],
        child: Row(children: [
          Expanded(child: TextField(
              decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, email o lugar...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  filled: true, fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onChanged: (v) { _searchQuery = v; _applyFilters(); })),
          const SizedBox(width: 16),
          DropdownButton<String>(
              value: _filterRole,
              items: const [
                DropdownMenuItem(value: 'all',           child: Text('Todos los roles')),
                DropdownMenuItem(value: 'admin_general', child: Text('👑 Admin General')),
                DropdownMenuItem(value: 'user_general',  child: Text('📋 Secretaría')),
                DropdownMenuItem(value: 'user_place',    child: Text('🏪 Propietarios')),
              ],
              onChanged: (v) {
                if (v != null) setState(() { _filterRole = v; _applyFilters(); });
              }),
        ]));
  }

  // ── Contadores ──────────────────────────────────────────
  Widget _buildCounters() {
    final total    = _allAdmins.length;
    final admins   = _allAdmins.where((a) => a.admin.role == 'admin_general').length;
    final generals = _allAdmins.where((a) => a.admin.role == 'user_general').length;
    final owners   = _allAdmins.where((a) => a.admin.role == 'user_place').length;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _counter('Total',        total,    Colors.blue),    const SizedBox(width: 12),
          _counter('Admins',       admins,   Colors.purple),  const SizedBox(width: 12),
          _counter('Secretaría',   generals, Colors.teal),    const SizedBox(width: 12),
          _counter('Propietarios', owners,   Colors.orange),
        ]));
  }

  Widget _counter(String label, int value, Color color) => Expanded(
      child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.3))),
          child: Column(children: [
            Text(value.toString(), style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])));

  // ── Lista ──────────────────────────────────────────────
  Widget _buildContent() {
    if (_isLoading) return const LoadingIndicator(message: 'Cargando...');
    if (_error != null) return ErrorDisplay(message: _error!, onRetry: _loadAdmins);
    if (_filteredAdmins.isEmpty) {
      return EmptyState(
          icon:    Icons.person_off,
          title:   'No hay administradores',
          message: _searchQuery.isNotEmpty
              ? 'Sin resultados para "$_searchQuery"'
              : 'No hay administradores registrados');
    }
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredAdmins.length,
        itemBuilder: (_, i) => AdminCard(
          adminStats:     _filteredAdmins[i],
          onTapDetail:    widget.canEdit ? () => _showDetail(_filteredAdmins[i]) : null,
          onTapEdit:      widget.canEdit ? () => _editAdmin(_filteredAdmins[i])  : null,
          onTapReassign:  widget.canEdit ? () => _reassignPlace(_filteredAdmins[i]) : null,
          onTapDashboard: () => _viewDashboard(_filteredAdmins[i]),
          // ← NUEVO: botón desactivar solo si canEdit
          onTapDeactivate: widget.canEdit ? () => _deactivateAdmin(_filteredAdmins[i]) : null,
        ));
  }

  // ── Acciones ───────────────────────────────────────────

  void _showDetail(AdminStats a) {
    showDialog(context: context,
        builder: (_) => AdminDetailDialog(adminStats: a));
  }

  void _viewDashboard(AdminStats a) {
    final placeId = a.admin.placeId;
    if (placeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Este usuario no tiene un lugar asignado'),
          backgroundColor: Colors.orange));
      return;
    }
    Navigator.of(context).pushNamed('/owner-dashboard', arguments: {
      'placeId': placeId, 'userName': a.admin.displayName,
      'userEmail': a.admin.email,
    });
  }

  // ── Editar admin — CORREGIDO: usa PATCH /admin/users/:id ──
  void _editAdmin(AdminStats a) {
    final firstCtrl = TextEditingController(text: a.admin.firstName);
    final lastCtrl  = TextEditingController(text: a.admin.lastName);
    final phoneCtrl = TextEditingController(text: a.admin.phone ?? '');

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Row(children: [
              const Icon(Icons.edit, color: Colors.teal),
              const SizedBox(width: 10),
              Expanded(child: Text('Editar — ${a.admin.displayName}',
                  style: const TextStyle(fontSize: 16))),
            ]),
            content: SizedBox(width: 400, child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(child: TextField(
                        controller: firstCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nombre',
                            border: OutlineInputBorder(),
                            isDense: true))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                        controller: lastCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Apellido',
                            border: OutlineInputBorder(),
                            isDense: true))),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                          isDense: true)),
                ])),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              ElevatedButton(
                // ← CORREGIDO: ahora sí guarda en el backend
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final result = await AdminService.updateUser(
                      userId:    a.admin.id,
                      firstName: firstCtrl.text.trim(),
                      lastName:  lastCtrl.text.trim(),
                      phone:     phoneCtrl.text.trim().isEmpty
                          ? null : phoneCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(result['success'] == true
                            ? 'Usuario actualizado correctamente'
                            : result['error'] ?? 'Error al actualizar'),
                        backgroundColor: result['success'] == true
                            ? Colors.green : Colors.red));
                    if (result['success'] == true) _loadAdmins();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  child: const Text('Guardar')),
            ]));
  }

  // ── Reasignar lugar ─────────────────────────────────────
  void _reassignPlace(AdminStats a) async {
    if (a.admin.role != 'user_place') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Solo se puede asignar lugar a propietarios')));
      return;
    }
    List<Place> places = [];
    try { places = await PlaceService.getAllPlaces(); } catch (_) {}
    if (!mounted) return;

    Place? selectedPlace = a.admin.placeId != null
        ? places.where((p) => p.id == a.admin.placeId).firstOrNull
        : null;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setD) => AlertDialog(
                title: Text('Asignar lugar a ${a.admin.displayName}'),
                content: SizedBox(width: 400, child: places.isEmpty
                    ? const Text('No hay lugares disponibles')
                    : DropdownButtonFormField<Place>(
                    value: selectedPlace,
                    hint: const Text('Selecciona un lugar'),
                    items: places.map((p) => DropdownMenuItem(
                        value: p,
                        child: Text('${p.tipoEmoji} ${p.name} — ${p.lugar}',
                            overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (p) => setD(() => selectedPlace = p))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  ElevatedButton(
                      onPressed: selectedPlace == null ? null : () async {
                        Navigator.pop(ctx);
                        final result = await AdminService.changeUserRole(
                            a.admin.id, 'user_place', placeId: selectedPlace!.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(result['success'] == true
                                ? 'Lugar asignado correctamente'
                                : result['error'] ?? 'Error'),
                            backgroundColor: result['success'] == true
                                ? Colors.green : Colors.red));
                        if (result['success'] == true) _loadAdmins();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      child: const Text('Asignar')),
                ])));
  }

  // ── Desactivar admin — NUEVO ───────────────────────────
  // Soft delete: preserva historial. Con 2 advertencias claras.
  void _deactivateAdmin(AdminStats a) async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Desactivar usuario'),
            ]),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Desactivar a ${a.admin.displayName}?',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.withOpacity(0.3))),
                      child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• Ya no podrá acceder al panel web.',
                                style: TextStyle(fontSize: 13)),
                            SizedBox(height: 4),
                            Text('• Su historial y datos se conservan.',
                                style: TextStyle(fontSize: 13)),
                            SizedBox(height: 4),
                            Text('• Esta acción se puede revertir desde el panel.',
                                style: TextStyle(fontSize: 13)),
                          ])),
                ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar')),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Desactivar')),
            ]));

    if (confirm != true || !mounted) return;

    try {
      // Llama DELETE /admin/users/:id (soft delete en backend)
      final result = await AdminService.deactivateUser(a.admin.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['success'] == true
              ? result['message'] ?? '${a.admin.displayName} desactivado'
              : result['error'] ?? 'Error al desactivar'),
          backgroundColor: result['success'] == true ? Colors.green : Colors.red));
      if (result['success'] == true) _loadAdmins();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  // ── Crear usuario ──────────────────────────────────────
  void _showCreateUserDialog() async {
    final formKey      = GlobalKey<FormState>();
    final firstCtrl    = TextEditingController();
    final lastCtrl     = TextEditingController();
    final emailCtrl    = TextEditingController();
    final userCtrl     = TextEditingController();
    final passCtrl     = TextEditingController();
    String selectedRole = 'user_place';
    Place? selectedPlace;
    bool   obscure     = true;
    bool   isCreating  = false;

    List<Place> places = [];
    try { places = await PlaceService.getAllPlaces(); } catch (_) {}
    if (!mounted) return;

    showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setD) => AlertDialog(
                title: Row(children: [
                  const Icon(Icons.person_add, color: Colors.teal),
                  const SizedBox(width: 12),
                  const Text('Crear usuario del panel'),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: isCreating ? null : () => Navigator.pop(ctx)),
                ]),
                content: SizedBox(width: 500, child: Form(
                    key: formKey,
                    child: SingleChildScrollView(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Expanded(child: TextFormField(
                                controller: firstCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Nombre *', border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person)),
                                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null)),
                            const SizedBox(width: 12),
                            Expanded(child: TextFormField(
                                controller: lastCtrl,
                                decoration: const InputDecoration(
                                    labelText: 'Apellido *', border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person_outline)),
                                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null)),
                          ]),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                  labelText: 'Email *', border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.email)),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (!v.contains('@')) return 'Email inválido';
                                return null;
                              }),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: userCtrl,
                              decoration: const InputDecoration(
                                  labelText: 'Usuario *', border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.alternate_email)),
                              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                          const SizedBox(height: 16),
                          TextFormField(
                              controller: passCtrl, obscureText: obscure,
                              decoration: InputDecoration(
                                  labelText: 'Contraseña *', border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock),
                                  helperText: 'Mínimo 6 caracteres',
                                  suffixIcon: IconButton(
                                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                                      onPressed: () => setD(() => obscure = !obscure))),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              }),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: const InputDecoration(
                                  labelText: 'Rol *', border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge)),
                              items: const [
                                DropdownMenuItem(value: 'admin_general', child: Text('👑 Administrador General')),
                                DropdownMenuItem(value: 'user_general',  child: Text('📋 Secretaría de Turismo')),
                                DropdownMenuItem(value: 'user_place',    child: Text('🏪 Propietario de Lugar')),
                              ],
                              onChanged: (v) {
                                if (v != null) setD(() { selectedRole = v; selectedPlace = null; });
                              }),
                          if (selectedRole == 'user_place') ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<Place>(
                                value: selectedPlace,
                                decoration: const InputDecoration(
                                    labelText: 'Lugar asignado *', border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.place)),
                                hint: const Text('Selecciona el establecimiento'),
                                items: places.map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('${p.tipoEmoji} ${p.name} — ${p.lugar}',
                                        overflow: TextOverflow.ellipsis))).toList(),
                                onChanged: (p) => setD(() => selectedPlace = p),
                                validator: (v) => v == null ? 'Selecciona un lugar' : null),
                          ],
                        ])))),
                actions: [
                  TextButton(
                      onPressed: isCreating ? null : () => Navigator.pop(ctx),
                      child: const Text('Cancelar')),
                  ElevatedButton(
                      onPressed: isCreating ? null : () async {
                        if (!formKey.currentState!.validate()) return;
                        setD(() => isCreating = true);
                        final result = await AdminService.createUser(
                          firstName: firstCtrl.text.trim(),
                          lastName:  lastCtrl.text.trim(),
                          email:     emailCtrl.text.trim(),
                          password:  passCtrl.text,
                          username:  userCtrl.text.trim(),
                          role:      selectedRole,
                          placeId:   selectedRole == 'user_place' ? selectedPlace?.id : null,
                        );
                        setD(() => isCreating = false);
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(result['success'] == true
                                ? '✅ Usuario creado exitosamente'
                                : result['error'] ?? 'Error al crear usuario'),
                            backgroundColor: result['success'] == true ? Colors.green : Colors.red,
                            duration: const Duration(seconds: 3)));
                        if (result['success'] == true) _loadAdmins();
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                      child: isCreating
                          ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Crear usuario')),
                ])));
  }
}