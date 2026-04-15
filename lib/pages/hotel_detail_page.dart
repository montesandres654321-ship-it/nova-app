// lib/services/hotel_detail_page.dart
import 'package:flutter/material.dart';
import 'scan_page.dart';
import '../models/place_model.dart';

class HotelDetailPage extends StatelessWidget {
  final Place hotel;

  const HotelDetailPage({
    super.key,
    required this.hotel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hotel.name),
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
                hotel.imageUrl ?? _getPlaceholderImage('hotel'), // ✅ CORREGIDO: Método local
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
                    child: const Icon(Icons.hotel, size: 60, color: Colors.grey),
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
                    hotel.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        hotel.lugar,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(" ${hotel.rating}"),
                      const Spacer(),
                      Text(
                        hotel.priceRange ?? 'Consultar',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF06B6A4)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildInfoItem("Check-in", "3:00 PM", Icons.login),
                      const SizedBox(width: 20),
                      _buildInfoItem("Check-out", "12:00 PM", Icons.logout),
                    ],
                  ),

                  if (hotel.description != null && hotel.description!.isNotEmpty) ...{
                    const SizedBox(height: 16),
                    const Text(
                      "Descripción:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hotel.description!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  },

                  if (hotel.amenities.isNotEmpty) ...{
                    const SizedBox(height: 16),
                    const Text(
                      "Servicios incluidos:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: hotel.amenities.map((amenity) {
                        return Chip(
                          label: Text(amenity),
                          backgroundColor: const Color(0xFF06B6A4).withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  },

                  if (hotel.phone != null && hotel.phone!.isNotEmpty) ...{
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          "Tel: ${hotel.phone!}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  },

                  if (hotel.address != null && hotel.address!.isNotEmpty) ...{
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Dirección: ${hotel.address!}",
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
                      label: const Text("Escanear QR del Hotel"),
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

  Widget _buildInfoItem(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
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