// lib/pages/bars_page.dart
import 'package:flutter/material.dart';
import 'bar_detail_page.dart';

class BarsPage extends StatelessWidget {
  const BarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> bars = [
      {
        "name": "Bar El Rincón",
        "image": "assets/images/bares_02.jpg",
        "location": "Toli,Centro Histórico",
        "description": "Bar tradicional con más de 20 años de historia. Especialistas en cócteles clásicos y música en vivo los fines de semana.",
        "hours": "5:00 PM - 2:00 AM",
        "specialty": "Mojitos y Daiquiris",
        "rating": 4.3,
        "priceRange": "Medio"
      },
      {
        "name": "Bar La Noche",
        "image": "assets/images/bares_01.jpg",
        "location": "Coveñas,Zona Rosa",
        "description": "Lounge bar moderno con terraza exterior, ideal para reuniones sociales. Amplia carta de vinos y licores premium.",
        "hours": "6:00 PM - 3:00 AM",
        "specialty": "Coctelería de autor",
        "rating": 4.6,
        "priceRange": "Alto"
      },
      {
        "name": "Bar Mojitos",
        "image": "assets/images/bares_03.jpg",
        "location": "Playa Norte",
        "description": "Ambiente caribeño con vista al mar. Especialistas en cócteles tropicales y mariscos. Happy hour de 5pm a 7pm.",
        "hours": "4:00 PM - 1:00 AM",
        "specialty": "Mojitos tropicales",
        "rating": 4.4,
        "priceRange": "Medio"
      },
      {
        "name": "Bar Tropical",
        "image": "assets/images/bares_06.jpg",
        "location": "San BernardoMalecón",
        "description": "Bar temático con decoración tropical y música latina. Ideal para bailar y disfrutar de bebidas exóticas.",
        "hours": "5:00 PM - 2:00 AM",
        "specialty": "Piña colada y cuba libre",
        "rating": 4.1,
        "priceRange": "Económico"
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bares"),
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
    );
  }

  Widget _buildBarCard(Map<String, dynamic> bar) {
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
              bar["image"],
              height: 170,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 170,
                  color: Colors.grey[300],
                  child: Icon(Icons.local_bar, size: 50, color: Colors.grey[500]),
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
                  bar["name"],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  bar["location"],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${bar["rating"]}"),
                    const Spacer(),
                    Text(
                      bar["priceRange"],
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}