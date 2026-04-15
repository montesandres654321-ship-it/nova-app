// lib/pages/owners/place_edit_page.dart
// ============================================================
// CAMBIOS vs versión anterior:
//   1. Nueva sección "🎁 Recompensa" con selector de ícono,
//      nombre, descripción, stock (ilimitado/limitado)
//   2. Al guardar, envía datos de recompensa junto con el resto
//      en una sola petición PATCH /places/my-place
//   3. Si el lugar ya tiene recompensa, los campos vienen prellenados
// ============================================================
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/place.dart';
import '../../utils/constants.dart';

class OwnerPlaceEditPage extends StatefulWidget {
  final Place place;
  final VoidCallback onSaved;

  const OwnerPlaceEditPage({
    super.key,
    required this.place,
    required this.onSaved,
  });

  @override
  State<OwnerPlaceEditPage> createState() => _OwnerPlaceEditPageState();
}

class _OwnerPlaceEditPageState extends State<OwnerPlaceEditPage> {
  static const _teal  = Color(0xFF06B6A4);
  static const _amber = Color(0xFFD97706);

  final _formKey = GlobalKey<FormState>();
  bool _loading        = false;
  bool _uploadingImage = false;

  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _imageUrlController;

  // Controladores de recompensa
  late TextEditingController _rewardNameController;
  late TextEditingController _rewardDescriptionController;
  late TextEditingController _rewardStockController;
  late bool   _hasReward;
  late String  _selectedRewardIcon;
  bool _unlimitedStock = true;

  PlatformFile? _selectedImageFile;

  final List<Map<String, String>> _rewardIcons = [
    {'icon': '☕', 'label': 'Café'},
    {'icon': '🥤', 'label': 'Bebida'},
    {'icon': '🍔', 'label': 'Comida'},
    {'icon': '🍕', 'label': 'Pizza'},
    {'icon': '🍰', 'label': 'Postre'},
    {'icon': '🎁', 'label': 'Regalo'},
    {'icon': '💰', 'label': 'Descuento'},
    {'icon': '🎫', 'label': 'Cupón'},
    {'icon': '🍹', 'label': 'Coctel'},
    {'icon': '⛵', 'label': 'Tour'},
    {'icon': '💆', 'label': 'Spa'},
    {'icon': '🦐', 'label': 'Mariscos'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _descriptionController = TextEditingController(text: p.description);
    _phoneController       = TextEditingController(text: p.phone ?? '');
    _addressController     = TextEditingController(text: p.address ?? '');
    _imageUrlController    = TextEditingController(text: p.imageUrl ?? '');

    // Recompensa
    _hasReward             = p.hasReward;
    _selectedRewardIcon    = p.rewardIcon ?? '🎁';
    _rewardNameController  = TextEditingController(text: p.rewardName ?? '');
    _rewardDescriptionController = TextEditingController(text: p.rewardDescription ?? '');
    _unlimitedStock        = p.rewardStock == null;
    _rewardStockController = TextEditingController(
        text: p.rewardStock?.toString() ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _imageUrlController.dispose();
    _rewardNameController.dispose();
    _rewardDescriptionController.dispose();
    _rewardStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.image, allowMultiple: false, withData: true);
      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedImageFile = result.files.first);
      }
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImageFile == null) return _imageUrlController.text.trim();
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
      throw Exception('Error al subir imagen (${response.statusCode})');
    } catch (e) {
      _showError('Error al subir imagen: $e');
      return null;
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? imageUrl = _imageUrlController.text.trim();
      if (_selectedImageFile != null) {
        imageUrl = await _uploadImage();
        if (imageUrl == null) { setState(() => _loading = false); return; }
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken) ?? '';

      // Stock
      int? stock;
      if (_hasReward && !_unlimitedStock) {
        stock = int.tryParse(_rewardStockController.text.trim());
      }

      final body = <String, dynamic>{
        'description': _descriptionController.text.trim(),
        'phone':       _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'address':     _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'image_url':   imageUrl?.isEmpty == true ? null : imageUrl,
        // Datos de recompensa
        'has_reward':         _hasReward,
        'reward_icon':        _hasReward ? _selectedRewardIcon : null,
        'reward_name':        _hasReward ? _rewardNameController.text.trim() : null,
        'reward_description': _hasReward ? _rewardDescriptionController.text.trim() : null,
        'reward_stock':       _hasReward ? (_unlimitedStock ? null : stock) : null,
      };

      final response = await http.patch(
        Uri.parse('${AppConstants.backendUrl}/places/my-place'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Información actualizada correctamente'),
            backgroundColor: Colors.green));
        widget.onSaved();
        Navigator.pop(context, true);
      } else {
        _showError(data['error']?.toString() ?? 'Error al guardar');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red,
          duration: const Duration(seconds: 4)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: const BackButton(color: Colors.white),
            title: const Text('Editar mi Lugar'),
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            actions: [
              if (!_loading && !_uploadingImage)
                TextButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded, color: Colors.white, size: 18),
                  label: const Text('Guardar',
                      style: TextStyle(color: Colors.white, fontSize: 13)),
                ),
              const SizedBox(width: 8),
            ]),
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
            padding: const EdgeInsets.all(20),
            child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(key: _formKey, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Info de solo lectura ──────────────
                      _sectionCard('📍 Información del Lugar', [
                        _readOnlyField('Nombre', widget.place.name,
                            Icons.business_rounded),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _readOnlyField(
                              'Tipo', '${widget.place.tipoEmoji} ${widget.place.tipoLabel}',
                              Icons.category_rounded)),
                          const SizedBox(width: 12),
                          Expanded(child: _readOnlyField(
                              'Ubicación', widget.place.lugar,
                              Icons.location_on_rounded)),
                        ]),
                        const SizedBox(height: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.blue[200]!)),
                            child: Row(children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: Colors.blue[600]),
                              const SizedBox(width: 6),
                              Expanded(child: Text(
                                  'El nombre, tipo y ubicación solo puede cambiarlos el administrador.',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.blue[700]))),
                            ])),
                      ]),

                      const SizedBox(height: 16),

                      // ── Descripción ───────────────────────
                      _sectionCard('📝 Descripción', [
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 13),
                          decoration: _dec(
                              'Descripción del lugar *',
                              Icons.description_rounded),
                          validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'La descripción es requerida' : null,
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // ── Contacto ──────────────────────────
                      _sectionCard('📞 Contacto y Dirección', [
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 13),
                          decoration: _dec('Teléfono', Icons.phone_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          style: const TextStyle(fontSize: 13),
                          decoration: _dec('Dirección', Icons.home_rounded),
                        ),
                      ]),

                      const SizedBox(height: 16),

                      // ── Imagen ────────────────────────────
                      _sectionCard('🖼️ Imagen del Lugar', [
                        if (widget.place.imageUrl != null &&
                            _selectedImageFile == null) ...[
                          ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.place.imageUrl!,
                                height: 140, width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    height: 80, color: Colors.grey[100],
                                    child: const Center(
                                        child: Icon(Icons.image_not_supported,
                                            color: Colors.grey))),
                              )),
                          const SizedBox(height: 10),
                        ],
                        TextFormField(
                          controller: _imageUrlController,
                          style: const TextStyle(fontSize: 13),
                          decoration: _dec(
                              'URL de imagen (opcional)',
                              Icons.link_rounded,
                              hint: 'https://...'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                            onPressed: _uploadingImage ? null : _pickImage,
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: Text(
                                _selectedImageFile != null
                                    ? _selectedImageFile!.name
                                    : 'Subir nueva imagen desde archivo',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 14),
                                side: const BorderSide(color: _teal),
                                foregroundColor: _teal)),
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
                                    onPressed: () =>
                                        setState(() => _selectedImageFile = null),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints()),
                              ])),
                        ],
                      ]),

                      const SizedBox(height: 16),

                      // ── NUEVA SECCIÓN: Recompensa ─────────
                      _sectionCard('🎁 Recompensa', [

                        // Toggle activar/desactivar
                        SwitchListTile(
                          title: const Text('Recompensa activa',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              _hasReward
                                  ? 'Los turistas ganan al escanear tu QR'
                                  : 'No se otorga recompensa',
                              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          value: _hasReward,
                          onChanged: (v) => setState(() => _hasReward = v),
                          activeColor: _teal,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                        ),

                        if (_hasReward) ...[
                          const Divider(height: 20),

                          // Selector de ícono
                          const Text('Ícono:',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8,
                              children: _rewardIcons.map((item) {
                                final sel = _selectedRewardIcon == item['icon'];
                                return InkWell(
                                    onTap: () => setState(
                                            () => _selectedRewardIcon = item['icon']!),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                            color: sel ? _amber.withOpacity(0.12) : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: sel ? _amber : Colors.transparent,
                                                width: 2)),
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(item['icon']!,
                                                  style: const TextStyle(fontSize: 20)),
                                              const SizedBox(height: 2),
                                              Text(item['label']!,
                                                  style: TextStyle(fontSize: 9,
                                                      color: sel ? _amber : Colors.grey[600])),
                                            ])));
                              }).toList()),
                          const SizedBox(height: 14),

                          // Nombre
                          TextFormField(
                            controller: _rewardNameController,
                            style: const TextStyle(fontSize: 13),
                            decoration: _dec('Nombre de la recompensa *',
                                Icons.card_giftcard_rounded,
                                hint: 'Ej: Café gratis'),
                            validator: _hasReward
                                ? (v) => v?.trim().isEmpty ?? true
                                ? 'El nombre es requerido' : null
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Descripción
                          TextFormField(
                            controller: _rewardDescriptionController,
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            decoration: _dec('Descripción',
                                Icons.info_outline_rounded,
                                hint: 'Ej: 1 café americano mediano'),
                          ),
                          const SizedBox(height: 14),

                          // Stock
                          Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!)),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Stock disponible',
                                                style: TextStyle(
                                                    fontSize: 12, fontWeight: FontWeight.w600)),
                                            Text(
                                                _unlimitedStock
                                                    ? 'Sin límite — todos pueden ganar'
                                                    : 'Cantidad máxima de recompensas',
                                                style: TextStyle(fontSize: 10,
                                                    color: Colors.grey[600])),
                                          ])),
                                      Switch(
                                          value: _unlimitedStock,
                                          onChanged: (v) => setState(() {
                                            _unlimitedStock = v;
                                            if (v) _rewardStockController.clear();
                                          }),
                                          activeColor: _teal),
                                      Text(_unlimitedStock ? 'Ilimitado' : 'Limitado',
                                          style: TextStyle(fontSize: 11,
                                              color: _unlimitedStock ? _teal : _amber,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                                    if (!_unlimitedStock) ...[
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _rewardStockController,
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                            labelText: 'Cantidad máxima',
                                            hintText: 'Ej: 50',
                                            border: const OutlineInputBorder(),
                                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                                            suffixText: 'recompensas',
                                            isDense: true,
                                            fillColor: Colors.white,
                                            filled: true),
                                        validator: (v) {
                                          if (_unlimitedStock) return null;
                                          if (v == null || v.trim().isEmpty) return 'Requerido';
                                          if (int.tryParse(v.trim()) == null) return 'Debe ser número';
                                          if (int.parse(v.trim()) < 0) return 'Debe ser positivo';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ])),
                        ] else ...[
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
                                'Activa la recompensa para premiar a los turistas que escanean tu código QR.',
                                style: TextStyle(fontSize: 11, color: Colors.orange[800]),
                              )),
                            ]),
                          ),
                        ],
                      ]),

                      const SizedBox(height: 28),

                      // ── Botón guardar ─────────────────────
                      SizedBox(
                          width: double.infinity, height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _loading || _uploadingImage ? null : _save,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('Guardar Cambios',
                                style: TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: _teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12))),
                          )),
                      const SizedBox(height: 24),
                    ])))))
    );
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500],
              fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!)),
          child: Row(children: [
            Icon(icon, size: 16, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Expanded(child: Text(value,
                style: const TextStyle(fontSize: 13, color: Colors.black87))),
          ])),
    ]);
  }

  InputDecoration _dec(String label, IconData icon, {String? hint}) =>
      InputDecoration(
          labelText: label, hintText: hint,
          prefixIcon: Icon(icon, size: 18),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _teal, width: 1.5)));

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
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12))),
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold,
                      color: _teal))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children)),
        ]));
  }
}