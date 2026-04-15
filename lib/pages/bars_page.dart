// lib/services/bar_page.dart
import 'package:flutter/material.dart';
import 'bar_detail_page.dart';
import '../models/place_model.dart';
import 'api_service.dart'; // ✅ CORREGIDO: ApiService en lugar de PlacesService

class BarsPage extends StatefulWidget {
  const BarsPage({super.key});

  @override
  State<BarsPage> createState() => _BarsPageState();
}

class _BarsPageState extends State<BarsPage> {
  List<Place> bars = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadBars();
  }

  Future<void> _loadBars() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final barsList = await ApiService.getBars(); // ✅ CORREGIDO: ApiService.getBars()
      setState(() => bars = barsList);

      if (barsList.isEmpty) {
        setState(() => _error = 'No hay bares disponibles');
      }
    } catch (e) {
      setState(() => _error = 'Error al cargar bares: $e');
      print('❌ Error en _loadBars: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshBars() async {
    await _loadBars();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bares"),
        backgroundColor: const Color(0xFF06B6A4),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBars,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06B6A4), Color(0xFF0EA5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error.isNotEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadBars,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF06B6A4),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        )
            : bars.isEmpty
            ? const Center(
          child: Text(
            "No hay bares disponibles",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        )
            : RefreshIndicator(
          onRefresh: _refreshBars,
          child: ListView.builder(
            itemCount: bars.length,
            itemBuilder: (context, index) {
              final bar = bars[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BarDetailPage(bar: bar),
                    ),
                  );
                },
                child: _buildBarCard(bar),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBarCard(Place bar) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              bar.imageUrl ?? _getPlaceholderImage('bar'), // ✅ CORREGIDO: Método local
              height: 170,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 170,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6A4)),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 170,
                  color: Colors.grey[300],
                  child: const Icon(Icons.local_bar, size: 50, color: Colors.grey),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bar.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  bar.lugar,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${bar.rating}"),
                    const Spacer(),
                    Text(
                      bar.priceRange ?? 'Consultar',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                if (bar.amenities.isNotEmpty) ...{
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: bar.amenities.take(2).map((amenity) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6A4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          amenity,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF06B6A4)),
                        ),
                      );
                    }).toList(),
                  ),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NUEVO: Método local para imágenes placeholder
  String _getPlaceholderImage(String type) {
    switch (type) {
      case 'bar':
        return "https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=400&h=300&fit=crop";
      case 'hotel':
        return "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop";
      case 'restaurant':
        return "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop";
      default:
        return "https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400&h=300&fit=crop";
    }
  }
}