// lib/pages/places/list_tab.dart
// ============================================================
// REDESIGN: SaaS-style cards · context menu · premium filters
// Lógica, servicios y navegación sin cambios
// ============================================================
import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../../services/place_service.dart';
import 'form_page.dart';
import 'qr_dialog.dart';
import '../place_details_page.dart';

// ── Design tokens (consistentes con stats_dashboard_page) ─────
const _kPrimary   = Color(0xFF06B6A4);
const _kBgPage    = Color(0xFFF1F5F9);
const _kTextHead  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kTextSub   = Color(0xFF94A3B8);
const _kBorder    = Color(0xFFE2E8F0);
const _kBlue      = Color(0xFF3B82F6);
const _kGreen     = Color(0xFF10B981);
const _kAmber     = Color(0xFFF59E0B);
const _kRed       = Color(0xFFEF4444);

// ─────────────────────────────────────────────────────────────
class PlacesListTab extends StatefulWidget {
  final String? initialFilter;
  final bool    canEdit;
  final bool    canViewInfo;

  const PlacesListTab({
    super.key,
    this.initialFilter,
    this.canEdit     = true,
    this.canViewInfo = true,
  });

  @override
  State<PlacesListTab> createState() => _PlacesListTabState();
}

class _PlacesListTabState extends State<PlacesListTab> {

  // ── State — SIN CAMBIOS ───────────────────────────────────
  List<Place> _places         = [];
  List<Place> _filteredPlaces = [];
  bool   _loading       = true;
  late String _selectedFilter;
  String _searchQuery   = '';

  // Filtro de estado (UI-only, no toca servicios)
  String _statusFilter  = 'all'; // 'all' | 'active' | 'inactive'

  final List<Map<String, dynamic>> _filters = [
    {'value': 'all',        'label': '🗺️ Todos'},
    {'value': 'hotel',      'label': '🏨 Hoteles'},
    {'value': 'restaurant', 'label': '🍽️ Restaurantes'},
    {'value': 'bar',        'label': '🍹 Bares'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'all';
    _loadPlaces();
  }

  // ── LÓGICA — SIN CAMBIOS ─────────────────────────────────
  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    try {
      final places = _selectedFilter == 'all'
          ? await PlaceService.getPlaces()
          : await PlaceService.getPlacesByType(_selectedFilter);
      setState(() { _places = places; _filterPlaces(); });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error cargando lugares: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterPlaces() {
    var list = _places;
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) =>
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.lugar.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    if (_statusFilter == 'active')   { list = list.where((p) =>  p.isActive).toList(); }
    if (_statusFilter == 'inactive') { list = list.where((p) => !p.isActive).toList(); }
    setState(() => _filteredPlaces = list);
  }

  void _showDeleteDialog(Place place) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text('¿Eliminar "${place.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(
            onPressed: () { Navigator.pop(context); _deletePlace(place.id); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar')),
      ],
    ));
  }

  Future<void> _deletePlace(int id) async {
    final result = await PlaceService.deletePlace(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['success'] == true
            ? 'Lugar desactivado' : result['error'] ?? 'Error'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red));
    if (result['success'] == true) _loadPlaces();
  }

  void _showQRDialog(Place place) {
    showDialog(context: context, builder: (_) => QRDialog(place: place));
  }

  void _handleAction(String action, Place place) {
    switch (action) {
      case 'view':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: place)));
        break;
      case 'qr':
        _showQRDialog(place);
        break;
      case 'edit':
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => PlaceFormPage(place: place)))
            .then((_) => _loadPlaces());
        break;
      case 'delete':
        _showDeleteDialog(place);
        break;
    }
  }

  static Color _typeColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'hotel':      return _kBlue;
      case 'restaurant': return _kGreen;
      case 'bar':        return _kAmber;
      default:           return _kTextSub;
    }
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

        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _kPrimary))
              : _filteredPlaces.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPlaces,
                      color: _kPrimary,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                        itemCount: _filteredPlaces.length,
                        itemBuilder: (_, i) =>
                            _buildPlaceCard(_filteredPlaces[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Búsqueda + botón ─────────────────────────────
        Row(children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _kBgPage,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _kBorder),
              ),
              child: TextField(
                style: const TextStyle(fontSize: 13, color: _kTextHead),
                decoration: const InputDecoration(
                  hintText: 'Buscar lugares...',
                  hintStyle: TextStyle(fontSize: 13, color: _kTextSub),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: _kTextSub),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 11),
                ),
                onChanged: (v) {
                  setState(() => _searchQuery = v);
                  _filterPlaces();
                },
              ),
            ),
          ),
          if (widget.canEdit) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PlaceFormPage()))
                  .then((_) => _loadPlaces()),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Nuevo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ]),

        const SizedBox(height: 12),

        // ── Pills de filtros ─────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [

            // Tipo
            ..._filters.map((f) => _filterPill(
              f['value'] as String,
              f['label'] as String,
              _selectedFilter == f['value'],
              () {
                setState(() => _selectedFilter = f['value'] as String);
                _loadPlaces();
              },
              activeColor: _kPrimary,
              activeTextColor: Colors.white,
            )),

            // Separador
            Container(width: 1, height: 22, color: _kBorder,
                margin: const EdgeInsets.symmetric(horizontal: 8)),

            // Estado
            _filterPill('all', 'Todos', _statusFilter == 'all',
                () { setState(() => _statusFilter = 'all'); _filterPlaces(); },
                activeColor: _kTextHead.withOpacity(0.08),
                activeTextColor: _kTextHead,
                activeBorderColor: _kTextHead.withOpacity(0.3)),

            _filterPill('active', 'Activos', _statusFilter == 'active',
                () { setState(() => _statusFilter = 'active'); _filterPlaces(); },
                activeColor: _kGreen.withOpacity(0.1),
                activeTextColor: _kGreen,
                activeBorderColor: _kGreen.withOpacity(0.35)),

            _filterPill('inactive', 'Inactivos', _statusFilter == 'inactive',
                () { setState(() => _statusFilter = 'inactive'); _filterPlaces(); },
                activeColor: _kRed.withOpacity(0.08),
                activeTextColor: _kRed,
                activeBorderColor: _kRed.withOpacity(0.3)),
          ]),
        ),

        const SizedBox(height: 10),

        // ── Contador ─────────────────────────────────────
        Text(
          '${_filteredPlaces.length} lugar${_filteredPlaces.length != 1 ? 'es' : ''}',
          style: const TextStyle(fontSize: 12, color: _kTextSub,
              fontWeight: FontWeight.w500),
        ),
      ]),
    );
  }

  Widget _filterPill(
    String value, String label, bool selected, VoidCallback onTap, {
    required Color activeColor,
    required Color activeTextColor,
    Color? activeBorderColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? (activeBorderColor ?? activeColor)
                  : _kBorder,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: selected ? activeTextColor : _kTextMuted,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400)),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // PLACE CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildPlaceCard(Place place) {
    final typeColor  = _typeColor(place.tipo);
    final isInactive = !place.isActive;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isInactive ? const Color(0xFFEEF2F7) : _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isInactive ? 0.02 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // Franja de color por tipo
            Container(
              width: 4,
              color: typeColor.withOpacity(isInactive ? 0.2 : 1.0),
            ),

            // Contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                  // Icono de tipo
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(isInactive ? 0.05 : 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(place.tipoEmoji,
                          style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 13),

                  // Texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Nombre + badge estado
                        Row(crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                          Expanded(
                            child: Text(place.name,
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isInactive
                                        ? _kTextSub
                                        : _kTextHead,
                                    height: 1.2),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(isActive: place.isActive),
                        ]),

                        const SizedBox(height: 6),

                        // Tipo chip + ubicación
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: typeColor.withOpacity(0.28)),
                            ),
                            child: Text(place.tipoLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: typeColor,
                                    fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on_outlined,
                              size: 12, color: _kTextSub),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(place.lugar,
                                style: const TextStyle(
                                    fontSize: 12, color: _kTextMuted),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),

                        // Propietario
                        if (place.ownerFirstName != null) ...[
                          const SizedBox(height: 5),
                          Row(children: [
                            const Icon(Icons.person_outline_rounded,
                                size: 12, color: _kTextSub),
                            const SizedBox(width: 4),
                            Text(
                              '${place.ownerFirstName}'
                              '${place.ownerLastName != null ? ' ${place.ownerLastName}' : ''}',
                              style: const TextStyle(
                                  fontSize: 11, color: _kTextSub),
                            ),
                          ]),
                        ],

                        // Recompensa
                        if (place.hasReward &&
                            place.rewardName != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kAmber.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kAmber.withOpacity(0.2)),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min,
                                children: [
                              const Icon(Icons.card_giftcard_rounded,
                                  size: 11, color: _kAmber),
                              const SizedBox(width: 4),
                              Text(place.rewardName!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _kAmber,
                                      fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Menú contextual ⋯
                  SizedBox(
                    width: 36,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          size: 18, color: _kTextSub),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      offset: const Offset(0, 6),
                      onSelected: (a) => _handleAction(a, place),
                      itemBuilder: (_) => [
                        if (widget.canViewInfo)
                          _menuItem('view',
                              Icons.visibility_outlined, 'Ver detalle',
                              _kTextHead),
                        _menuItem('qr',
                            Icons.qr_code_rounded, 'Ver QR', _kPrimary),
                        if (widget.canEdit) ...[
                          _menuItem('edit',
                              Icons.edit_outlined, 'Editar', _kTextHead),
                          const PopupMenuDivider(height: 1),
                          _menuItem('delete',
                              Icons.delete_outline_rounded, 'Eliminar',
                              _kRed),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) =>
    PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500)),
      ]),
    );

  // ─────────────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isFiltered =
        _searchQuery.isNotEmpty || _statusFilter != 'all';
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _kBorder,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isFiltered
                ? Icons.search_off_rounded
                : Icons.store_mall_directory_outlined,
            size: 30, color: _kTextSub),
        ),
        const SizedBox(height: 16),
        Text(
          isFiltered ? 'Sin resultados' : 'No hay lugares aún',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
              color: _kTextHead),
        ),
        const SizedBox(height: 6),
        Text(
          isFiltered
              ? 'Prueba con otros filtros o búsqueda'
              : 'Agrega el primer lugar para comenzar',
          style: const TextStyle(fontSize: 13, color: _kTextMuted),
          textAlign: TextAlign.center,
        ),
        if (!isFiltered && widget.canEdit) ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PlaceFormPage()))
                .then((_) => _loadPlaces()),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Agregar lugar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _kGreen : _kTextSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          isActive ? 'Activo' : 'Inactivo',
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2),
        ),
      ]),
    );
  }
}
