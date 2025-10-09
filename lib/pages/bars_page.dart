
//bars_page.dart
import 'package:flutter/material.dart';
import 'bar_detail_page.dart';

class BarsPage extends StatelessWidget {
  const BarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> bars = [
      {"name": "Bar El Rincón", "image": "assets/images/bares_02.jpg"},
      {"name": "Bar La Noche", "image": "assets/images/bares_01.jpg"},
      {"name": "Bar Mojitos", "image": "assets/images/bares_03.jpg"},
      {"name": "Bar Tropical", "image": "assets/images/bares_06.jpg"},
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
                    builder: (_) => BarDetailPage(
                      name: bar["name"]!,
                      image: bar["image"]!,
                    ),
                  ),
                );
              },
              child: _buildCard(bar["name"]!, bar["image"]!),
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
