// lib/pages/places/list_tab.dart
// CORRECCIÓN: canViewInfo oculta botón ⓘ (info) para user_general
// Secretaría solo ve QR — no puede ver detalle del lugar
import 'package:flutter/material.dart';
import '../../models/place.dart';
import '../../services/place_service.dart';
import 'form_page.dart';
import 'qr_dialog.dart';
import '../place_details_page.dart';

class PlacesListTab extends StatefulWidget {
  final String? initialFilter;
  final bool    canEdit;
  final bool    canViewInfo; // false = oculta botón ⓘ (secretaría)

  const PlacesListTab({
    super.key,
    this.initialFilter,
    this.canEdit    = true,
    this.canViewInfo = true,
  });

  @override
  State<PlacesListTab> createState() => _PlacesListTabState();
}

class _PlacesListTabState extends State<PlacesListTab> {
  List<Place> _places         = [];
  List<Place> _filteredPlaces = [];
  bool   _loading        = true;
  late String _selectedFilter;
  String _searchQuery    = '';

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

  Future<void> _loadPlaces() async {
    setState(() => _loading = true);
    try {
      final places = _selectedFilter == 'all'
          ? await PlaceService.getPlaces()
          : await PlaceService.getPlacesByType(_selectedFilter);
      setState(() { _places = places; _filterPlaces(); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error cargando lugares: $e'),
          backgroundColor: Colors.red));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filterPlaces() {
    if (_searchQuery.isEmpty) {
      setState(() => _filteredPlaces = _places);
    } else {
      setState(() => _filteredPlaces = _places.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.lugar.toLowerCase().contains(_searchQuery.toLowerCase())).toList());
    }
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

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── FILTROS envueltos en Material ────────────────
      Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: _filters.map((f) {
                final isSelected = _selectedFilter == f['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f['label']),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = f['value']);
                      _loadPlaces();
                    },
                    selectedColor: const Color(0xFF06B6A4).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF06B6A4),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                  hintText: 'Buscar lugar...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Colors.grey.shade100),
              onChanged: (v) { setState(() => _searchQuery = v); _filterPlaces(); },
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text('${_filteredPlaces.length} lugar${_filteredPlaces.length != 1 ? 'es' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              if (widget.canEdit)
                ElevatedButton.icon(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const PlaceFormPage()))
                        .then((_) => _loadPlaces()),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nuevo lugar'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6A4),
                        foregroundColor: Colors.white)),
            ]),
          ]),
        ),
      ),

      const SizedBox(height: 8),

      // ── LISTA ────────────────────────────────────────
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _filteredPlaces.isEmpty
            ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_searchQuery.isNotEmpty ? Icons.search_off : Icons.place_outlined,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_searchQuery.isNotEmpty
                ? 'No se encontraron lugares'
                : 'No hay lugares de este tipo',
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            if (_searchQuery.isEmpty && widget.canEdit) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PlaceFormPage()))
                      .then((_) => _loadPlaces()),
                  icon: const Icon(Icons.add), label: const Text('Agregar lugar')),
            ],
          ],
        ))
            : RefreshIndicator(
          onRefresh: _loadPlaces,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _filteredPlaces.length,
            itemBuilder: (_, i) => _buildPlaceCard(_filteredPlaces[i]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildPlaceCard(Place place) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: place.isActive ? null : Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(place.typeEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(place.name, style: TextStyle(fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: place.isActive ? null : Colors.grey)),
              if (!place.isActive)
                const Text('INACTIVO', style: TextStyle(fontSize: 10,
                    color: Colors.red, fontWeight: FontWeight.bold)),
            ])),
            _buildActionButtons(place),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(place.lugar, style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 16),
            const Icon(Icons.star, size: 16, color: Colors.amber),
            const SizedBox(width: 4),
            Text('${place.rating}', style: const TextStyle(color: Colors.grey)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildActionButtons(Place place) {
    return Row(mainAxisSize: MainAxisSize.min, children: [

      // ⓘ Info — solo si canViewInfo (admin_general)
      if (widget.canViewInfo)
        IconButton(
            icon: const Icon(Icons.info_outline, size: 20),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: place))),
            tooltip: 'Ver detalle'),

      // QR — siempre visible (secretaría también puede descargar)
      IconButton(
          icon: const Icon(Icons.qr_code, size: 20),
          onPressed: () => _showQRDialog(place),
          tooltip: 'Ver QR',
          color: const Color(0xFF06B6A4)),

      // Editar y Eliminar — solo si canEdit (admin_general)
      if (widget.canEdit) ...[
        IconButton(
            icon: const Icon(Icons.edit, size: 20),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PlaceFormPage(place: place)))
                .then((_) => _loadPlaces()),
            tooltip: 'Editar'),
        IconButton(
            icon: const Icon(Icons.delete, size: 20),
            onPressed: () => _showDeleteDialog(place),
            tooltip: 'Eliminar', color: Colors.red),
      ],
    ]);
  }
}