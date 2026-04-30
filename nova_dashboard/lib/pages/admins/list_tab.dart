// lib/pages/admins/list_tab.dart
// CAMBIOS:
//  1. Botón "Desactivar" agregado en AdminCard — soft delete
//     llama DELETE /admin/users/:id (nuevo endpoint backend)
//  2. _editAdmin usa PATCH /admin/users/:id (nuevo endpoint)
//     — antes llamaba PUT /users/update/:id que no existía
//  3. Diálogo de desactivación con 2 advertencias claras
//  4. REDESIGN: header compacto · KPI chips · modal SaaS premium

import 'package:flutter/material.dart';
import '../../models/admin_stats_model.dart';
import '../../services/admin_service.dart';
import '../../services/place_service.dart';
import '../../models/place.dart';
import '../../utils/app_theme.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_widget.dart';
import 'admin_card.dart';
import 'admin_detail_dialog.dart';

// ── Design tokens ─────────────────────────────────────────────
const _kPrimary   = Color(0xFF06B6A4);
const _kBgPage    = Color(0xFFF1F5F9);
const _kTextHead  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kTextSub   = Color(0xFF94A3B8);
const _kBorder    = Color(0xFFE2E8F0);
const _kBlue      = Color(0xFF3B82F6);
const _kAmber     = Color(0xFFF59E0B);
const _kRed       = Color(0xFFEF4444);
const _kPurple    = Color(0xFF8B5CF6);

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

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _kBgPage,
      child: Column(children: [
        _buildHeader(),
        const Divider(height: 1, thickness: 0.5, color: _kBorder),
        Expanded(child: _buildContent()),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HEADER COMPACTO
  // ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final total    = _allAdmins.length;
    final admins   = _allAdmins.where((a) => a.admin.role == 'admin_general').length;
    final generals = _allAdmins.where((a) => a.admin.role == 'user_general').length;
    final owners   = _allAdmins.where((a) => a.admin.role == 'user_place').length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Fila 1: Título + botón + refresh ─────────
        Row(children: [
          const Text('Administradores',
              style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.w700, color: _kTextHead)),
          const Spacer(),
          if (widget.canEdit) ...[
            ElevatedButton.icon(
              onPressed: _showCreateUserDialog,
              icon: const Icon(Icons.person_add_rounded, size: 15),
              label: const Text('Crear usuario',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 9),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 6),
          ],
          SizedBox(
            width: 32, height: 32,
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  size: 18, color: _kTextMuted),
              onPressed: _loadAdmins,
              tooltip: 'Actualizar',
              padding: EdgeInsets.zero,
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Fila 2: Búsqueda + filtro rol ────────────
        Row(children: [
          Expanded(
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: _kBgPage,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 13, color: _kTextHead),
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, email o lugar...',
                  hintStyle: TextStyle(fontSize: 13, color: _kTextSub),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 17, color: _kTextSub),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) { _searchQuery = v; _applyFilters(); },
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _kBgPage,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterRole,
                isDense: true,
                icon: const Icon(Icons.expand_more_rounded,
                    size: 16, color: _kTextMuted),
                style: const TextStyle(
                    fontSize: 12, color: _kTextHead),
                items: const [
                  DropdownMenuItem(
                      value: 'all',
                      child: Text('Todos los roles')),
                  DropdownMenuItem(
                      value: 'admin_general',
                      child: Text('👑 Admin General')),
                  DropdownMenuItem(
                      value: 'user_general',
                      child: Text('📋 Secretaría')),
                  DropdownMenuItem(
                      value: 'user_place',
                      child: Text('🏪 Propietarios')),
                ],
                onChanged: (v) {
                  if (v != null) {
                    setState(() { _filterRole = v; _applyFilters(); });
                  }
                },
              ),
            ),
          ),
        ]),

        const SizedBox(height: 10),

        // ── Fila 3: KPI chips compactos ───────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _kpiChip('Total', total, _kBlue),
            _kpiSep(),
            _kpiChip('Admins', admins, _kPurple),
            _kpiSep(),
            _kpiChip('Secretaría', generals, _kPrimary),
            _kpiSep(),
            _kpiChip('Propietarios', owners, _kAmber),
            if (_filteredAdmins.length != total) ...[
              _kpiSep(),
              _kpiChip('Filtrados', _filteredAdmins.length, _kTextMuted),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _kpiChip(String label, int value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text('$value ',
          style: TextStyle(fontSize: 13,
              fontWeight: FontWeight.w700, color: color)),
      Text(label,
          style: TextStyle(fontSize: 12,
              color: color.withOpacity(0.85))),
    ]),
  );

  Widget _kpiSep() => Container(
    width: 1, height: 16, color: _kBorder,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );

  // ─────────────────────────────────────────────────────────
  // LISTA
  // ─────────────────────────────────────────────────────────
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
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        itemCount: _filteredAdmins.length,
        itemBuilder: (_, i) => AdminCard(
          adminStats:      _filteredAdmins[i],
          onTapDetail:     widget.canEdit ? () => _showDetail(_filteredAdmins[i]) : null,
          onTapEdit:       widget.canEdit ? () => _editAdmin(_filteredAdmins[i])  : null,
          onTapReassign:   widget.canEdit ? () => _reassignPlace(_filteredAdmins[i]) : null,
          onTapDashboard:  () => _viewDashboard(_filteredAdmins[i]),
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
              const Icon(Icons.edit, color: AppTheme.primary),
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
                      backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
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
                          backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
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

  // ─────────────────────────────────────────────────────────
  // CREAR USUARIO — MODAL SaaS
  // ─────────────────────────────────────────────────────────
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

    // ── Decoration base para todos los inputs ──────
    InputDecoration inputDec() => InputDecoration(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 13),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRed)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRed, width: 1.5)),
    );

    showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setD) {

              // ── Helper: campo con label encima ─────
              Widget field({
                required String label,
                required TextEditingController ctrl,
                bool obscureText = false,
                Widget? suffix,
                TextInputType? keyboard,
                String? Function(String?)? validator,
              }) {
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kTextMuted)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: ctrl,
                    obscureText: obscureText,
                    keyboardType: keyboard,
                    style: const TextStyle(
                        fontSize: 14, color: _kTextHead),
                    decoration: inputDec().copyWith(suffixIcon: suffix),
                    validator: validator,
                  ),
                ]);
              }

              // ── Helper: etiqueta de sección ────────
              Widget sectionLabel(String text) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Container(
                    width: 3, height: 14,
                    decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  Text(text,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _kTextMuted,
                          letterSpacing: 0.6)),
                ]),
              );

              return Dialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                      maxWidth: 540, maxHeight: 720),
                  child: Form(
                    key: formKey,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [

                      // ── Header del modal ───────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 18, 14, 18),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(
                              color: _kBorder, width: 0.5)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _kPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.person_add_rounded,
                                size: 18, color: _kPrimary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Crear usuario',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _kTextHead)),
                                SizedBox(height: 2),
                                Text(
                                    'Nuevo acceso al panel de administración',
                                    style: TextStyle(
                                        fontSize: 12, color: _kTextSub)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 20, color: _kTextMuted),
                            onPressed: isCreating
                                ? null : () => Navigator.pop(ctx),
                            padding: EdgeInsets.zero,
                          ),
                        ]),
                      ),

                      // ── Cuerpo del formulario ──────
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              // Sección: Información personal
                              sectionLabel('INFORMACIÓN PERSONAL'),
                              Row(children: [
                                Expanded(child: field(
                                  label: 'Nombre *',
                                  ctrl: firstCtrl,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Requerido' : null,
                                )),
                                const SizedBox(width: 12),
                                Expanded(child: field(
                                  label: 'Apellido *',
                                  ctrl: lastCtrl,
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Requerido' : null,
                                )),
                              ]),
                              const SizedBox(height: 12),
                              field(
                                label: 'Email *',
                                ctrl: emailCtrl,
                                keyboard: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requerido';
                                  if (!v.contains('@')) return 'Email inválido';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Sección: Acceso
                              sectionLabel('ACCESO'),
                              field(
                                label: 'Usuario *',
                                ctrl: userCtrl,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Requerido' : null,
                              ),
                              const SizedBox(height: 12),
                              field(
                                label: 'Contraseña *',
                                ctrl: passCtrl,
                                obscureText: obscure,
                                suffix: IconButton(
                                  icon: Icon(
                                    obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 18, color: _kTextSub,
                                  ),
                                  onPressed: () =>
                                      setD(() => obscure = !obscure),
                                  padding: const EdgeInsets.only(right: 4),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Requerido';
                                  if (v.length < 6) return 'Mínimo 6 caracteres';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Sección: Configuración
                              sectionLabel('CONFIGURACIÓN'),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Rol *',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: _kTextMuted)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: selectedRole,
                                    style: const TextStyle(
                                        fontSize: 14, color: _kTextHead),
                                    decoration: inputDec(),
                                    items: const [
                                      DropdownMenuItem(
                                          value: 'admin_general',
                                          child: Text('👑 Administrador General')),
                                      DropdownMenuItem(
                                          value: 'user_general',
                                          child: Text('📋 Secretaría de Turismo')),
                                      DropdownMenuItem(
                                          value: 'user_place',
                                          child: Text('🏪 Propietario de Lugar')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setD(() {
                                          selectedRole  = v;
                                          selectedPlace = null;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),

                              if (selectedRole == 'user_place') ...[
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Lugar asignado *',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _kTextMuted)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<Place>(
                                      value: selectedPlace,
                                      style: const TextStyle(
                                          fontSize: 14, color: _kTextHead),
                                      decoration: inputDec(),
                                      hint: const Text(
                                          'Selecciona el establecimiento',
                                          style: TextStyle(
                                              fontSize: 13, color: _kTextSub)),
                                      items: places
                                          .map((p) => DropdownMenuItem(
                                              value: p,
                                              child: Text(
                                                '${p.tipoEmoji} ${p.name} — ${p.lugar}',
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 13),
                                              )))
                                          .toList(),
                                      onChanged: (p) =>
                                          setD(() => selectedPlace = p),
                                      validator: (v) =>
                                          v == null ? 'Selecciona un lugar' : null,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // ── Footer con botones ─────────
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(
                              color: _kBorder, width: 0.5)),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                          TextButton(
                            onPressed: isCreating
                                ? null : () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: _kTextMuted,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                            ),
                            child: const Text('Cancelar',
                                style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 10),
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
                                placeId:   selectedRole == 'user_place'
                                    ? selectedPlace?.id : null,
                              );
                              setD(() => isCreating = false);
                              if (!mounted) return;
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(result['success'] == true
                                      ? '✅ Usuario creado exitosamente'
                                      : result['error'] ?? 'Error al crear usuario'),
                                  backgroundColor: result['success'] == true
                                      ? Colors.green : Colors.red,
                                  duration: const Duration(seconds: 3)));
                              if (result['success'] == true) _loadAdmins();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kPrimary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                            ),
                            child: isCreating
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.person_add_rounded, size: 15),
                                      SizedBox(width: 8),
                                      Text('Crear usuario',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                          ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              );
            }));
  }
}
