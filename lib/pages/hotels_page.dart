//hotels_page.dart
import 'package:flutter/material.dart';
import 'hotel_detail_page.dart';

class HotelsPage extends StatelessWidget {
  const HotelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> hotels = [
      {"name": "Hotel Sol Caribe", "image": "assets/images/hotel_02.jpg"},
      {"name": "Hotel Paraíso", "image": "assets/images/hotel_03.jpg"},
      {"name": "Hotel Playa", "image": "assets/images/hotel_01.jpg"},
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
                    builder: (_) => HotelDetailPage(
                      name: hotel["name"]!,
                      image: hotel["image"]!,
                    ),
                  ),
                );
              },
              child: _buildCard(hotel["name"]!, hotel["image"]!),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(String title, String imagePath) {
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
              imagePath,
              height: 170,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}


