// lib/pages/hotels_page.dart
import 'package:flutter/material.dart';
import 'hotel_detail_page.dart';

class HotelsPage extends StatelessWidget {
  const HotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> hotels = [
      {
        "name": "Hotel Sol Caribe",
        "image": "assets/images/hotel_02.jpg",
        "location": "Coveñas, Sucre",
        "description": "Hotel frente al mar con piscina infinita, restaurante gourmet y spa. Ideal para familias y parejas.",
        "price": "\$250.000/noche",
        "rating": 4.5,
        "amenities": ["Wifi", "Piscina", "Spa", "Restaurante", "Estacionamiento"],
        "checkIn": "3:00 PM",
        "checkOut": "12:00 PM"
      },
      {
        "name": "Hotel Paraíso Tropical",
        "image": "assets/images/hotel_03.jpg",
        "location": "Tolú, Sucre",
        "description": "Eco-hotel sostenible con cabañas privadas, tours ecológicos y comida orgánica.",
        "price": "\$180.000/noche",
        "rating": 4.2,
        "amenities": ["Wifi", "Tours", "Restaurante", "Ecológico", "Playa privada"],
        "checkIn": "2:00 PM",
        "checkOut": "11:00 AM"
      },
      {
        "name": "Hotel Playa Azul",
        "image": "assets/images/hotel_01.jpg",
        "location": "San Antero, Córdoba",
        "description": "Hotel boutique con diseño moderno, bar en la terraza y vista panorámica al mar.",
        "price": "\$320.000/noche",
        "rating": 4.7,
        "amenities": ["Wifi", "Bar", "Terraza", "Vista al mar", "Desayuno incluido"],
        "checkIn": "3:00 PM",
        "checkOut": "1:00 PM"
      },
      {
        "name": "Hotel Costa Verde",
        "image": "assets/images/hotel_02.jpg",
        "location": "Moñitos, Córdoba",
        "description": "Hotel familiar con amplias habitaciones, zona de juegos infantiles y piscina climatizada.",
        "price": "\$200.000/noche",
        "rating": 4.0,
        "amenities": ["Wifi", "Piscina", "Familiar", "Juegos infantiles", "Restaurante"],
        "checkIn": "2:00 PM",
        "checkOut": "12:00 PM"
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hoteles"),
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
        child: ListView.builder(
          itemCount: hotels.length,
          itemBuilder: (context, index) {
            final hotel = hotels[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HotelDetailPage(hotel: hotel),
                  ),
                );
              },
              child: _buildHotelCard(hotel),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              hotel["image"],
              height: 170,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 170,
                  color: Colors.grey[300],
                  child: Icon(Icons.hotel, size: 50, color: Colors.grey[500]),
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
                  hotel["name"],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  hotel["location"],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${hotel["rating"]}"),
                    const Spacer(),
                    Text(
                      hotel["price"],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF06B6A4)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (hotel["amenities"] as List<String>).take(3).map((amenity) {
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}