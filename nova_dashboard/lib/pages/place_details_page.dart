// lib/pages/place_details_page.dart
// ============================================================
// REDISEÑO: Layout 2 columnas — todo visible sin scroll
// CAMBIOS:
//   1. Imagen a la izquierda (fija, 360px ancho)
//   2. Info + contacto + descripción + servicios + recompensa a la derecha (scroll propio)
//   3. Sin imagen gigante de 250px arriba
//   4. Compacto y profesional
// ============================================================
import 'package:flutter/material.dart';
import '../models/place.dart';
import 'places/form_page.dart';

class PlaceDetailsPage extends StatelessWidget {
  final Place place;
  const PlaceDetailsPage({super.key, required this.place});

  static const _teal  = Color(0xFF06B6A4);
  static const _amber = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        title: Text(place.name),
        backgroundColor: _teal,
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Columna izquierda: Imagen + Info básica ───
            SizedBox(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Imagen
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (place.imageUrl != null && place.imageUrl!.isNotEmpty)
                        ? Image.network(
                      place.imageUrl!,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                        : _imagePlaceholder(),
                  ),
                  const SizedBox(height: 14),

                  // Info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre + Tipo
                        Row(children: [
                          Text(place.typeEmoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(place.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text(place.tipoLabel,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: place.isActive ? Colors.green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(place.isActive ? 'Activo' : 'Inactivo',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: place.isActive ? Colors.green : Colors.red)),
                          ),
                        ]),
                        const SizedBox(height: 12),

                        // Rating
                        Row(children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(place.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(' / 5.0', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ]),
                        const SizedBox(height: 12),

                        // Contacto compacto
                        _infoChip(Icons.location_on_rounded, place.lugar),
                        if (place.address != null && place.address!.isNotEmpty)
                          _infoChip(Icons.home_rounded, place.address!),
                        if (place.phone != null && place.phone!.isNotEmpty)
                          _infoChip(Icons.phone_rounded, place.phone!),
                        if (place.priceRange != null && place.priceRange!.isNotEmpty)
                          _infoChip(Icons.attach_money_rounded, place.priceRange!),

                        // Sistema
                        const SizedBox(height: 8),
                        Text('ID: ${place.id}',
                            style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                        if (place.createdAt != null)
                          Text('Creado: ${_fmt(place.createdAt!)}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),

            // ── Columna derecha: Descripción + Servicios + Recompensa ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Descripción
                    _sectionCard('Descripción', [
                      Text(place.description,
                          style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.6)),
                    ]),
                    const SizedBox(height: 14),

                    // Servicios
                    if (place.amenities.isNotEmpty) ...[
                      _sectionCard('Servicios', [
                        Wrap(spacing: 6, runSpacing: 6,
                            children: place.amenities.map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                  color: _teal.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text(a, style: const TextStyle(
                                  fontSize: 12, color: _teal, fontWeight: FontWeight.w500)),
                            )).toList()),
                      ]),
                      const SizedBox(height: 14),
                    ],

                    // Recompensa
                    if (place.hasReward)
                      _sectionCard('Recompensa', [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: _amber.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _amber.withOpacity(0.2))),
                          child: Row(children: [
                            Text(place.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 36)),
                            const SizedBox(width: 14),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(place.rewardName ?? 'Recompensa',
                                    style: TextStyle(fontSize: 15,
                                        fontWeight: FontWeight.bold, color: _amber)),
                                if (place.rewardDescription != null && place.rewardDescription!.isNotEmpty)
                                  Padding(padding: const EdgeInsets.only(top: 3),
                                      child: Text(place.rewardDescription!,
                                          style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                                if (place.rewardStock != null)
                                  Padding(padding: const EdgeInsets.only(top: 4),
                                      child: Text('Stock: ${place.rewardStock} disponibles',
                                          style: TextStyle(fontSize: 11, color: _amber,
                                              fontWeight: FontWeight.w500))),
                              ],
                            )),
                          ]),
                        ),
                      ]),

                    // Propietario
                    if (place.hasOwner) ...[
                      const SizedBox(height: 14),
                      _sectionCard('Propietario', [
                        Row(children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: _teal.withOpacity(0.1),
                            child: Text(place.ownerInitials,
                                style: const TextStyle(
                                    color: _teal, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(place.ownerDisplay,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              if (place.ownerEmail != null)
                                Text(place.ownerEmail!,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          )),
                        ]),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: _teal, width: 4)),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12))),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: _teal)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children),
        ),
      ]),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 15, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
      ]),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [BoxShadow(
        color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
  );

  Widget _imagePlaceholder() => Container(
    height: 200,
    decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12)),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(_iconForType(place.tipo), size: 60, color: Colors.grey[400]),
      const SizedBox(height: 8),
      Text('Sin imagen', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
    ]),
  );

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