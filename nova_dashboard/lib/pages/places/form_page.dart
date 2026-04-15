// lib/pages/places/form_page.dart
// ============================================================
// CAMBIOS vs versión anterior:
//   1. _hasReward = true por defecto al crear nuevo lugar
//      (al editar, mantiene el valor del lugar existente)
//   2. Campos de recompensa siempre visibles cuando _hasReward=true
//      ya no están ocultos detrás del checkbox
// ============================================================
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/place.dart';
import '../../models/admin_model.dart';
import '../../services/place_service.dart';
import '../../services/admin_service.dart';
import '../../utils/constants.dart';

class PlaceFormPage extends StatefulWidget {
  final Place? place;
  const PlaceFormPage({super.key, this.place});
  @override
  State<PlaceFormPage> createState() => _PlaceFormPageState();
}

class _PlaceFormPageState extends State<PlaceFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _loading        = false;
  bool _uploadingImage = false;

  late TextEditingController _nameController;
  late TextEditingController _lugarController;
  late TextEditingController _descriptionController;
  late TextEditingController _imageUrlController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _amenitiesController;
  late TextEditingController _rewardNameController;
  late TextEditingController _rewardDescriptionController;
  late TextEditingController _rewardStockController;

  List<AdminModel> _availableOwners = [];
  int?    _selectedOwnerId;
  bool    _loadingOwners = false;
  PlatformFile? _selectedImageFile;

  String _selectedType      = 'hotel';
  bool   _isActive          = true;
  // CAMBIO: true por defecto al crear nuevo lugar
  bool   _hasReward         = true;
  String _selectedRewardIcon = '☕';

  final List<String> _types = ['hotel', 'restaurant', 'bar'];

  final List<Map<String, String>> _rewardIcons = [
    {'icon': '☕', 'label': 'Café'},
    {'icon': '🥤', 'label': 'Bebida'},
    {'icon': '🍔', 'label': 'Comida'},
    {'icon': '🍕', 'label': 'Pizza'},
    {'icon': '🍰', 'label': 'Postre'},
    {'icon': '🎁', 'label': 'Regalo'},
    {'icon': '💰', 'label': 'Descuento'},
    {'icon': '🎫', 'label': 'Cupón'},
  ];

  static const _teal = Color(0xFF06B6A4);

  @override
  void initState() {
    super.initState();
    _loadAvailableOwners();
    final p = widget.place;
    _nameController        = TextEditingController(text: p?.name ?? '');
    _lugarController       = TextEditingController(text: p?.lugar ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _imageUrlController    = TextEditingController(text: p?.imageUrl ?? '');
    _addressController     = TextEditingController(text: p?.address ?? '');
    _phoneController       = TextEditingController(text: p?.phone ?? '');
    _amenitiesController   = TextEditingController(
        text: p?.amenities.join(', ') ?? '');
    _rewardNameController        = TextEditingController(text: p?.rewardName ?? '');
    _rewardDescriptionController = TextEditingController(
        text: p?.rewardDescription ?? '');
    _rewardStockController = TextEditingController(
        text: p?.rewardStock?.toString() ?? '');
    if (p != null) {
      _selectedType      = p.tipo;
      _isActive          = p.isActive;
      _hasReward         = p.hasReward;
      _selectedRewardIcon = p.rewardIcon ?? '☕';
      _selectedOwnerId   = p.ownerAdminId;
    }
    // Si es nuevo lugar (place == null), _hasReward ya es true por defecto
  }

  @override
  void dispose() {
    _nameController.dispose();        _lugarController.dispose();
    _descriptionController.dispose(); _imageUrlController.dispose();
    _addressController.dispose();     _phoneController.dispose();
    _amenitiesController.dispose();
    _rewardNameController.dispose();  _rewardDescriptionController.dispose();
    _rewardStockController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableOwners() async {
    setState(() => _loadingOwners = true);
    try {
      final owners = await AdminService.getOwnersWithoutPlace();
      setState(() { _availableOwners = owners; _loadingOwners = false; });
    } catch (_) {
      setState(() => _loadingOwners = false);
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.image, allowMultiple: false, withData: true);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _selectedImageFile = result.files.first);
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null) return null;
    setState(() => _uploadingImage = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken) ?? '';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.backendUrl}${AppConstants.uploadImageEndpoint}'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      if (_selectedImageFile!.bytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
            'image', _selectedImageFile!.bytes!,
            filename: _selectedImageFile!.name));
      }
      final response = await request.send();
      final body     = await response.stream.bytesToString();
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(body);
        return data['imageUrl'] ?? data['image_url'];
      }
      throw Exception('Error al subir imagen');
    } catch (e) {
      _showError('Error al subir imagen: $e');
      return null;
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? imageUrl = _imageUrlController.text.trim();
      if (_selectedImageFile != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) { setState(() => _loading = false); return; }
      }
      final amenities = _amenitiesController.text
          .split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      final place = Place(
        id:          widget.place?.id ?? 0,
        name:        _nameController.text.trim(),
        tipo:        _selectedType,
        lugar:       _lugarController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl:    (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
        rating:      0.0,
        address:     _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        phone:       _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        priceRange:  null,
        amenities:   amenities,
        isActive:    _isActive,
        hasReward:   _hasReward,
        rewardName:  _hasReward ? _rewardNameController.text.trim() : null,
        rewardDescription: _hasReward ? _rewardDescriptionController.text.trim() : null,
        rewardIcon:  _hasReward ? _selectedRewardIcon : null,
        rewardStock: _hasReward ? int.tryParse(_rewardStockController.text.trim()) : null,
        ownerAdminId: _selectedOwnerId,
      );

      final result = widget.place == null
          ? await PlaceService.createPlace(place)
          : await PlaceService.updatePlace(widget.place!.id, place);

      if (!mounted) return;
      if (result['success'] == true) {
        _showSuccess(result['message']?.toString() ??
            (widget.place == null ? 'Lugar creado' : 'Lugar actualizado'));
        Navigator.pop(context, true);
      } else {
        _showError(result['error']?.toString() ?? 'Error al guardar');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deletePlace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar lugar'),
        content: Text('¿Eliminar "${widget.place!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    final result = await PlaceService.deletePlace(widget.place!.id);
    if (!mounted) return;
    if (result['success'] == true) {
      _showSuccess('Lugar eliminado');
      Navigator.pop(context, true);
    } else {
      _showError(result['error']?.toString() ?? 'Error al eliminar');
      setState(() => _loading = false);
    }
  }

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green,
          duration: const Duration(seconds: 3)));

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red,
          duration: const Duration(seconds: 4)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(widget.place == null ? 'Nuevo Lugar' : 'Editar Lugar'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        actions: [
          if (widget.place != null)
            IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _loading ? null : _deletePlace,
                tooltip: 'Eliminar'),
        ],
      ),
      body: (_loading || _uploadingImage)
          ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: _teal),
            const SizedBox(height: 16),
            Text(_uploadingImage ? 'Subiendo imagen...' : 'Guardando...',
                style: const TextStyle(fontSize: 16)),
          ]))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Sección 1: Información básica ──────────
                  _sectionCard('Información Básica', [
                    _row([
                      Expanded(flex: 2, child: _field(
                          controller: _nameController,
                          label: 'Nombre del lugar',
                          icon: Icons.business,
                          validator: (v) =>
                          v?.isEmpty ?? true ? 'Requerido' : null)),
                      const SizedBox(width: 16),
                      Expanded(child: _dropdown(
                          value: _selectedType,
                          label: 'Tipo',
                          icon: Icons.category,
                          items: _types,
                          onChanged: (v) =>
                              setState(() => _selectedType = v!))),
                    ]),
                    const SizedBox(height: 12),
                    _field(
                        controller: _lugarController,
                        label: 'Municipio / Lugar',
                        icon: Icons.location_on,
                        validator: (v) =>
                        v?.isEmpty ?? true ? 'Requerido' : null),
                    const SizedBox(height: 12),
                    _field(
                        controller: _descriptionController,
                        label: 'Descripción',
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (v) =>
                        v?.isEmpty ?? true ? 'Requerido' : null),
                  ]),

                  const SizedBox(height: 16),

                  // ── Sección 2: Imagen ──────────────────────
                  _sectionCard('Imagen del Lugar', [
                    _row([
                      Expanded(child: _field(
                          controller: _imageUrlController,
                          label: 'URL de imagen (opcional)',
                          icon: Icons.link,
                          hint: 'https://...')),
                      const SizedBox(width: 16),
                      Expanded(child: OutlinedButton.icon(
                          onPressed: _uploadingImage ? null : _pickImage,
                          icon: const Icon(Icons.upload_file),
                          label: Text(_selectedImageFile != null
                              ? _selectedImageFile!.name
                              : 'Subir desde archivo',
                              overflow: TextOverflow.ellipsis),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 12),
                              side: const BorderSide(color: _teal),
                              foregroundColor: _teal))),
                    ]),
                    if (_selectedImageFile != null) ...[
                      const SizedBox(height: 8),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green)),
                          child: Row(children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(
                                '${_selectedImageFile!.name} (${(_selectedImageFile!.size / 1024).toStringAsFixed(0)} KB)',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis)),
                            IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red, size: 18),
                                onPressed: () => setState(
                                        () => _selectedImageFile = null),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints()),
                          ])),
                    ],
                  ]),

                  const SizedBox(height: 16),

                  // ── Sección 3: Detalles ────────────────────
                  _sectionCard('Detalles', [
                    _row([
                      Expanded(child: _field(
                          controller: _addressController,
                          label: 'Dirección',
                          icon: Icons.home)),
                      const SizedBox(width: 16),
                      Expanded(child: _field(
                          controller: _phoneController,
                          label: 'Teléfono',
                          icon: Icons.phone)),
                    ]),
                    const SizedBox(height: 12),
                    _field(
                        controller: _amenitiesController,
                        label: 'Servicios (separados por coma)',
                        icon: Icons.list,
                        hint: 'Wifi, Piscina, A/C'),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Lugar activo',
                          style: TextStyle(fontSize: 13)),
                      subtitle: Text(
                          _isActive ? 'Visible en la app' : 'Oculto',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[600])),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      activeColor: _teal,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // ── Sección 4: Recompensa ──────────────────
                  // CAMBIO: campos siempre visibles, checkbox activado por defecto
                  _sectionCard('🎁 Recompensa para Turistas', [

                    // Toggle activar/desactivar recompensa
                    SwitchListTile(
                      title: const Text('Recompensa activa',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          _hasReward
                              ? 'Los turistas ganan al escanear el QR'
                              : 'No se otorga recompensa al escanear',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      value: _hasReward,
                      onChanged: (v) => setState(() => _hasReward = v),
                      activeColor: _teal,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Campos de recompensa — siempre visibles cuando activo
                    if (_hasReward) ...[
                      const SizedBox(height: 12),

                      // Selector de ícono
                      const Text('Ícono de la recompensa:',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, runSpacing: 8,
                          children: _rewardIcons.map((item) {
                            final sel = _selectedRewardIcon == item['icon'];
                            return InkWell(
                                onTap: () => setState(
                                        () => _selectedRewardIcon = item['icon']!),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: sel
                                            ? _teal.withOpacity(0.15)
                                            : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: sel ? _teal : Colors.transparent,
                                            width: 2)),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(item['icon']!,
                                              style: const TextStyle(fontSize: 24)),
                                          const SizedBox(height: 2),
                                          Text(item['label']!,
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  color: sel
                                                      ? _teal : Colors.grey[700])),
                                        ])));
                          }).toList()),
                      const SizedBox(height: 14),

                      // Nombre + Descripción en fila
                      _row([
                        Expanded(child: _field(
                            controller: _rewardNameController,
                            label: 'Nombre de la recompensa',
                            icon: Icons.card_giftcard,
                            hint: 'Ej: Café gratis',
                            validator: _hasReward
                                ? (v) => v?.isEmpty ?? true
                                ? 'Requerido' : null
                                : null)),
                        const SizedBox(width: 16),
                        Expanded(child: _field(
                            controller: _rewardDescriptionController,
                            label: 'Descripción',
                            icon: Icons.info_outline,
                            hint: 'Ej: 1 café americano mediano')),
                      ]),
                      const SizedBox(height: 12),

                      // Stock
                      TextFormField(
                        controller: _rewardStockController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 13),
                        decoration: _inputDecoration(
                          'Stock disponible (vacío = ilimitado)',
                          Icons.inventory_2_outlined,
                          hint: 'Ej: 50 — dejar vacío para sin límite',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (int.tryParse(v.trim()) == null) return 'Debe ser un número';
                          if (int.parse(v.trim()) < 0) return 'Debe ser positivo';
                          return null;
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vacío o 0 = sin límite de recompensas',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                    ] else ...[
                      // Mensaje cuando está desactivada
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'Activa la recompensa para que los turistas reciban un premio al escanear el código QR del establecimiento.',
                            style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                          )),
                        ]),
                      ),
                    ],
                  ]),

                  const SizedBox(height: 16),

                  // ── Sección 5: Propietario ─────────────────
                  _sectionCard('Propietario (Opcional)', [
                    _loadingOwners
                        ? const Center(child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(color: _teal)))
                        : DropdownButtonFormField<int>(
                        value: _selectedOwnerId,
                        decoration: _inputDecoration(
                            'Asignar propietario',
                            Icons.person,
                            hint: 'Sin propietario (opcional)'),
                        items: [
                          const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Sin propietario')),
                          ..._availableOwners.map((o) =>
                              DropdownMenuItem<int>(
                                  value: o.id,
                                  child: Text(
                                      '${o.displayName} — ${o.email}',
                                      overflow: TextOverflow.ellipsis))),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedOwnerId = v)),
                  ]),

                  const SizedBox(height: 28),

                  // ── Botón guardar ──────────────────────────
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      onPressed: (_loading || _uploadingImage)
                          ? null : _savePlace,
                      icon: (_loading || _uploadingImage)
                          ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(
                          (_loading || _uploadingImage)
                              ? (_uploadingImage
                              ? 'Subiendo imagen...'
                              : 'Guardando...')
                              : (widget.place == null
                              ? 'Crear Lugar'
                              : 'Actualizar Lugar'),
                          style: const TextStyle(fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _teal,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Widgets de ayuda ──────────────────────────────────────

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.07), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: _teal, width: 4)),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12), topRight: Radius.circular(12))),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold, color: _teal))),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children)),
      ]),
    );
  }

  Widget _row(List<Widget> children) => Row(
      crossAxisAlignment: CrossAxisAlignment.start, children: children);

  InputDecoration _inputDecoration(String label, IconData icon,
      {String? hint}) {
    return InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _teal, width: 1.5)),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: _inputDecoration(label, icon, hint: hint),
      validator: validator,
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _dropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final labels = {'hotel': 'Hotel', 'restaurant': 'Restaurante', 'bar': 'Bar'};
    return DropdownButtonFormField<String>(
      value: value,
      decoration: _inputDecoration(label, icon),
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      items: items.map((t) => DropdownMenuItem(
          value: t,
          child: Text(labels[t] ?? t))).toList(),
      onChanged: onChanged,
    );
  }
}