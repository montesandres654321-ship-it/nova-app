// lib/pages/place_details_page.dart
// CORRECCIÓN: leading: const BackButton() explícito
// Flutter Web no agrega ← automáticamente en todos los contextos
import 'package:flutter/material.dart';
import '../models/place.dart';
import 'places/form_page.dart';

class PlaceDetailsPage extends StatelessWidget {
  final Place place;
  const PlaceDetailsPage({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // ← explícito para Flutter Web
        leading: const BackButton(color: Colors.white),
        title: Text(place.name),
        backgroundColor: const Color(0xFF06B6A4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PlaceFormPage(place: place)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🖼️ IMAGEN
            if (place.imageUrl != null && place.imageUrl!.isNotEmpty)
              Container(width: double.infinity, height: 250,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(place.imageUrl!), fit: BoxFit.cover)))
            else
              Container(width: double.infinity, height: 250,
                  color: Colors.grey[300],
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_iconForType(place.tipo), size: 80, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    Text('Sin imagen', style: TextStyle(color: Colors.grey[600])),
                  ])),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ENCABEZADO
                Row(children: [
                  Text(place.typeEmoji, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(place.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    // tipoLabel devuelve "Restaurante" (español)
                    Text(place.tipoLabel,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: place.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(place.isActive ? 'Activo' : 'Inactivo',
                        style: TextStyle(fontSize: 12,
                            color: place.isActive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                ]),

                const SizedBox(height: 24),

                // CALIFICACIÓN
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(place.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(' / 5.0', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ]),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // CONTACTO
                _sectionTitle('Información de Contacto'),
                const SizedBox(height: 16),
                _infoRow(icon: Icons.location_on, label: 'Ubicación', value: place.lugar),
                if (place.address != null && place.address!.isNotEmpty)
                  _infoRow(icon: Icons.home, label: 'Dirección', value: place.address!),
                if (place.phone != null && place.phone!.isNotEmpty)
                  _infoRow(icon: Icons.phone, label: 'Teléfono', value: place.phone!),
                if (place.priceRange != null && place.priceRange!.isNotEmpty)
                  _infoRow(icon: Icons.attach_money, label: 'Rango de precios', value: place.priceRange!),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // DESCRIPCIÓN
                _sectionTitle('Descripción'),
                const SizedBox(height: 12),
                Text(place.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.5)),

                // SERVICIOS
                if (place.amenities.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _sectionTitle('Servicios'),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8,
                      children: place.amenities.map((a) => Chip(
                        label: Text(a),
                        backgroundColor: const Color(0xFF06B6A4).withOpacity(0.1),
                        labelStyle: const TextStyle(
                            color: Color(0xFF06B6A4), fontWeight: FontWeight.w500),
                      )).toList()),
                ],

                // RECOMPENSA
                if (place.hasReward) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _sectionTitle('Recompensa'),
                  const SizedBox(height: 12),
                  Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 2)),
                      child: Row(children: [
                        Text(place.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 48)),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(place.rewardName ?? 'Recompensa',
                              style: const TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.bold, color: Colors.amber)),
                          if (place.rewardDescription != null && place.rewardDescription!.isNotEmpty)
                            Padding(padding: const EdgeInsets.only(top: 4),
                                child: Text(place.rewardDescription!,
                                    style: TextStyle(fontSize: 14, color: Colors.grey[700]))),
                        ])),
                      ])),
                ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),

                // SISTEMA
                _sectionTitle('Información del Sistema'),
                const SizedBox(height: 12),
                if (place.createdAt != null)
                  _infoRow(icon: Icons.calendar_today, label: 'Fecha de creación',
                      value: _fmt(place.createdAt!)),
                if (place.updatedAt != null)
                  _infoRow(icon: Icons.update, label: 'Última actualización',
                      value: _fmt(place.updatedAt!)),
                _infoRow(icon: Icons.tag, label: 'ID', value: place.id.toString()),

                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
          color: Color(0xFF06B6A4)));

  Widget _infoRow({required IconData icon, required String label, required String value}) =>
      Padding(padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ])),
          ]));

  IconData _iconForType(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'hotel':      return Icons.hotel;
      case 'restaurant': return Icons.restaurant;
      case 'bar':        return Icons.local_bar;
      default:           return Icons.place;
    }
  }

  String _fmt(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
}