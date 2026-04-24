// lib/pages/hotels_page.dart
// ============================================================
// HOTELES — Nova App Móvil
// ============================================================
// Import corregido: ApiService desde ../services/api_service.dart
// ============================================================

import 'package:flutter/material.dart';
import 'hotel_detail_page.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';

class HotelsPage extends StatefulWidget {
  const HotelsPage({super.key});

  @override
  State<HotelsPage> createState() => _HotelsPageState();
}

class _HotelsPageState extends State<HotelsPage> {
  List<Place> hotels = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final hotelsList = await ApiService.getHotels();
      setState(() => hotels = hotelsList);
      if (hotelsList.isEmpty) setState(() => _error = 'No hay hoteles disponibles');
    } catch (e) {
      setState(() => _error = 'Error al cargar hoteles: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hoteles"), backgroundColor: const Color(0xFF06B6A4),
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHotels, tooltip: 'Actualizar')]),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
            colors: [Color(0xFF06B6A4), Color(0xFF0EA5E9)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_error, style: const TextStyle(fontSize: 16, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadHotels,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF06B6A4)),
              child: const Text('Reintentar')),
        ]))
            : RefreshIndicator(onRefresh: _loadHotels,
            child: ListView.builder(itemCount: hotels.length, itemBuilder: (_, i) {
              final hotel = hotels[i];
              return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailPage(hotel: hotel))),
                  child: _buildHotelCard(hotel));
            })),
      ),
    );
  }

  Widget _buildHotelCard(Place hotel) {
    return Card(
      margin: const EdgeInsets.all(12), elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: Image.network(
            hotel.imageUrl ?? "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop",
            height: 170, fit: BoxFit.cover,
            loadingBuilder: (_, child, prog) {
              if (prog == null) return child;
              return Container(height: 170, color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6A4)))));
            },
            errorBuilder: (_, __, ___) => Container(height: 170, color: Colors.grey[300],
                child: const Icon(Icons.hotel, size: 50, color: Colors.grey)),
          ),
        ),
        Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hotel.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(hotel.lugar, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 16),
            Text(" ${hotel.rating}"),
            const Spacer(),
            Text(hotel.priceRange ?? 'Consultar',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF06B6A4))),
          ]),
          const SizedBox(height: 8),
          if (hotel.amenities.isNotEmpty)
            Wrap(spacing: 6, runSpacing: 4, children: hotel.amenities.take(3).map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF06B6A4).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(a, style: const TextStyle(fontSize: 10, color: Color(0xFF06B6A4))),
            )).toList()),
          // Mostrar recompensa si existe
          if (hotel.hasReward) ...[
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(hotel.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Flexible(child: Text(hotel.rewardName ?? 'Recompensa disponible',
                      style: TextStyle(fontSize: 11, color: Colors.amber[800], fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis)),
                ])),
          ],
        ])),
      ]),
    );
  }
}