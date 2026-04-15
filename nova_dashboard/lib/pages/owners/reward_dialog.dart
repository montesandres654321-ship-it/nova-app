// lib/pages/owners/reward_dialog.dart
// Diálogo para que el propietario edite la recompensa de su lugar
// Llama PATCH /places/my-place/reward (solo user_place)
// Campos: selector de ícono, nombre, descripción, stock disponible

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

class OwnerRewardDialog extends StatefulWidget {
  final String? currentIcon;
  final String? currentName;
  final String? currentDescription;
  final int?    currentStock;       // null = ilimitado
  final VoidCallback onSaved;       // recarga el dashboard al guardar

  const OwnerRewardDialog({
    super.key,
    this.currentIcon,
    this.currentName,
    this.currentDescription,
    this.currentStock,
    required this.onSaved,
  });

  @override
  State<OwnerRewardDialog> createState() => _OwnerRewardDialogState();
}

class _OwnerRewardDialogState extends State<OwnerRewardDialog> {
  static const _teal  = Color(0xFF06B6A4);
  static const _amber = Color(0xFFD97706);

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _stockCtrl;
  String _selectedIcon = '🎁';
  bool   _saving       = false;
  bool   _unlimited    = true;   // true = sin límite de stock

  final List<Map<String, String>> _icons = [
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
    _selectedIcon = widget.currentIcon ?? '🎁';
    _nameCtrl  = TextEditingController(text: widget.currentName ?? '');
    _descCtrl  = TextEditingController(text: widget.currentDescription ?? '');
    _unlimited = widget.currentStock == null;
    _stockCtrl = TextEditingController(
        text: widget.currentStock?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('El nombre de la recompensa es requerido');
      return;
    }

    int? stock;
    if (!_unlimited) {
      stock = int.tryParse(_stockCtrl.text.trim());
      if (stock == null || stock < 0) {
        _showError('El stock debe ser un número positivo');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken) ?? '';

      final body = <String, dynamic>{
        'reward_icon':        _selectedIcon,
        'reward_name':        name,
        'reward_description': _descCtrl.text.trim(),
        'reward_stock':       _unlimited ? null : stock,
      };

      final response = await http.patch(
        Uri.parse('${AppConstants.backendUrl}/places/my-place/reward'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('✅ Recompensa actualizada correctamente'),
            backgroundColor: Colors.green));
      } else {
        _showError(data['error']?.toString() ?? 'Error al actualizar');
      }
    } catch (e) {
      if (mounted) _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: _amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.card_giftcard_rounded,
                color: _amber, size: 20)),
        const SizedBox(width: 10),
        const Expanded(child: Text('Editar Recompensa',
            style: TextStyle(fontSize: 16))),
        IconButton(
            icon: const Icon(Icons.close),
            onPressed: _saving ? null : () => Navigator.pop(context)),
      ]),
      content: SizedBox(width: 420, child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          // ── Selector de ícono ─────────────────────────
          Align(alignment: Alignment.centerLeft,
              child: Text('Ícono',
                  style: TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700]))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8,
              children: _icons.map((item) {
                final sel = _selectedIcon == item['icon'];
                return InkWell(
                    onTap: () => setState(() => _selectedIcon = item['icon']!),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: sel ? _teal.withOpacity(0.12) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: sel ? _teal : Colors.transparent,
                                width: 2)),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(item['icon']!,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 2),
                          Text(item['label']!,
                              style: TextStyle(fontSize: 9,
                                  color: sel ? _teal : Colors.grey[600])),
                        ])));
              }).toList()),

          const SizedBox(height: 16),

          // ── Nombre ────────────────────────────────────
          TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                  labelText: 'Nombre de la recompensa *',
                  hintText: 'Ej: Café gratis',
                  border: const OutlineInputBorder(),
                  prefixIcon: Text(_selectedIcon,
                      style: const TextStyle(fontSize: 18)),
                  isDense: true)),
          const SizedBox(height: 12),

          // ── Descripción ───────────────────────────────
          TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Ej: 1 café americano mediano',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 16),

          // ── Stock ─────────────────────────────────────
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
                                _unlimited
                                    ? 'Sin límite — todos los turistas pueden ganar la recompensa'
                                    : 'Máximo de recompensas a otorgar en total',
                                style: TextStyle(fontSize: 10,
                                    color: Colors.grey[600])),
                          ])),
                      Switch(
                          value: _unlimited,
                          onChanged: (v) => setState(() {
                            _unlimited = v;
                            if (v) _stockCtrl.clear();
                          }),
                          activeColor: _teal),
                      Text(_unlimited ? 'Ilimitado' : 'Limitado',
                          style: TextStyle(fontSize: 11,
                              color: _unlimited ? _teal : _amber,
                              fontWeight: FontWeight.w600)),
                    ]),
                    if (!_unlimited) ...[
                      const SizedBox(height: 10),
                      TextField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: 'Cantidad máxima',
                              hintText: 'Ej: 50',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.inventory_2_outlined),
                              suffixText: 'recompensas',
                              isDense: true,
                              fillColor: Colors.white,
                              filled: true)),
                    ],
                  ])),
        ]),
      )),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(_saving ? 'Guardando...' : 'Guardar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: Colors.white)),
      ],
    );
  }
}