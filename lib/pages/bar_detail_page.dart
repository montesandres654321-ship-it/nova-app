// lib/services/bar_detail_page.dart
import 'package:flutter/material.dart';
import 'scan_page.dart';
import '../models/place_model.dart';

class BarDetailPage extends StatelessWidget {
  final Place bar;

  const BarDetailPage({
    super.key,
    required this.bar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(bar.name),
        backgroundColor: const Color(0xFF06B6A4),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF06B6A4), Color(0xFF0EA5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.network(
                bar.imageUrl ?? _getPlaceholderImage('bar'), // ✅ CORREGIDO: Método local
                height: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
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
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_bar, size: 60, color: Colors.grey),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bar.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        bar.lugar,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(" ${bar.rating}"),
                      const Spacer(),
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 4),
                      const Text(
                        "5:00 PM - 2:00 AM",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Descripción:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bar.description ?? 'Descripción no disponible',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  if (bar.amenities.isNotEmpty) ...{
                    const SizedBox(height: 16),
                    const Text(
                      "Especialidades:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: bar.amenities.map((specialty) {
                        return Chip(
                          label: Text(specialty),
                          backgroundColor: const Color(0xFF06B6A4).withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  },

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        "Precios: ",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        bar.priceRange ?? 'Consultar',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),

                  if (bar.phone != null && bar.phone!.isNotEmpty) ...{
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          "Tel: ${bar.phone!}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  },

                  if (bar.address != null && bar.address!.isNotEmpty) ...{
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Dirección: ${bar.address!}",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  },

                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanPage()),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text("Escanear QR del Bar"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6A4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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