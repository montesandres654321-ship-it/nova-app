//restaurants_page.dart
import 'package:flutter/material.dart';
import 'restaurant_detail_page.dart';

class RestaurantsPage extends StatelessWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> restaurants = [
      {"name": "Restaurante La Costa", "image": "assets/images/restaurante_02.jpg"},
      {"name": "Restaurante Gourmet", "image": "assets/images/restaurante_03.jpg"},
      {"name": "Restaurante Mar y Tierra", "image": "assets/images/restaurante_04.jpg"},
      {"name": "Restaurante El Sabor", "image": "assets/images/restaurante_01.jpg"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurantes"),
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
          itemCount: restaurants.length,
          itemBuilder: (context, index) {
            final restaurant = restaurants[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantDetailPage(
                      name: restaurant["name"]!,
                      image: restaurant["image"]!,
                    ),
                  ),
                );
              },
              child: _buildCard(restaurant["name"]!, restaurant["image"]!),
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
