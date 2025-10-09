// lib/pages/passport_page.dart
import 'package:flutter/material.dart';
import 'hotels_page.dart';
import 'restaurants_page.dart';
import 'bars_page.dart';

class PassportPage extends StatelessWidget {
  const PassportPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pasaporte"),
        backgroundColor: tealStart,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [tealStart, tealEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🏨 Hoteles
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HotelsPage()),
                );
              },
              child: _buildCard("Hoteles", "assets/images/hotel_01.jpg"),
            ),
            const SizedBox(height: 16),

            // 🍽️ Restaurantes
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RestaurantsPage()),
                );
              },
              child: _buildCard("Restaurantes", "assets/images/restaurante_01.jpg"),
            ),
            const SizedBox(height: 16),

            // 🍹 Bares
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BarsPage()),
                );
              },
              child: _buildCard("bares", "assets/images/bares_01.jpg"),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Reutilizamos el mismo estilo para las tarjetas
  Widget _buildCard(String title, String imagePath) {
    return Card(
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
