// lib/pages/restaurants_page.dart
import 'package:flutter/material.dart';
import 'restaurant_detail_page.dart';

class RestaurantsPage extends StatelessWidget {
  const RestaurantsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> restaurants = [
      {
        "name": "Restaurante La Costa",
        "image": "assets/images/restaurante_02.jpg",
        "location": ", Coveñas ",
        "description": "Restaurante especializado en mariscos frescos y comida costeña. Vista panorámica al mar Caribe con terraza al aire libre.",
        "cuisine": "Mariscos y comida costeña",
        "hours": "12:00 PM - 10:00 PM",
        "rating": 4.5,
        "priceRange": "Medio-Alto",
        "specialties": ["Ceviche mixto", "Arroz de mariscos", "Pargo rojo frito"],
        "features": ["Terraza", "Vista al mar", "Reservas"]
      },
      {
        "name": "Restaurante Gourmet",
        "image": "assets/images/restaurante_03.jpg",
        "location": "Centro Histórico, tolu",
        "description": "Cocina de autor con ingredientes locales. Menú degustación disponible con reserva previa. Ambiente elegante y sofisticado.",
        "cuisine": "Fusión internacional",
        "hours": "6:00 PM - 11:00 PM",
        "rating": 4.8,
        "priceRange": "Alto",
        "specialties": ["Menú degustación", "Platos de autor", "Maridaje"],
        "features": ["Elegante", "Cocina abierta", "Sommelier"]
      },
      {
        "name": "Restaurante Mar y Tierra",
        "image": "assets/images/restaurante_04.jpg",
        "location": "Zona Gastronómica, san Bernardo",
        "description": "Especialistas en carnes premium y pescados. Parrilla a la vista y ambiente rústico elegante. Perfecto para carnes a la parrilla.",
        "cuisine": "Carnes y mariscos",
        "hours": "12:00 PM - 11:00 PM",
        "rating": 4.4,
        "priceRange": "Medio",
        "specialties": ["Parrillada mixta", "Corte Angus", "Pescado a la talla"],
        "features": ["Parrilla", "Rústico", "Amplio"]
      },
      {
        "name": "Restaurante El Sabor",
        "image": "assets/images/restaurante_01.jpg",
        "location": "Getsemaní, Coveñas ",
        "description": "Comida típica colombiana en un ambiente familiar y acogedor. Platos generosos y auténticos que representan la gastronomía local.",
        "cuisine": "Comida colombiana tradicional",
        "hours": "11:00 AM - 9:00 PM",
        "rating": 4.2,
        "priceRange": "Económico-Medio",
        "specialties": ["Bandeja paisa", "Sancocho de gallina", "Ajiaco santafereño"],
        "features": ["Familiar", "Típico", "Económico"]
      }
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
                    builder: (_) => RestaurantDetailPage(restaurant: restaurant),
                  ),
                );
              },
              child: _buildRestaurantCard(restaurant),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
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
              restaurant["image"],
              height: 170,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 170,
                  color: Colors.grey[300],
                  child: Icon(Icons.restaurant, size: 50, color: Colors.grey[500]),
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
                  restaurant["name"],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant["location"],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${restaurant["rating"]}"),
                    const Spacer(),
                    Text(
                      restaurant["priceRange"],
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  restaurant["cuisine"],
                  style: TextStyle(fontSize: 14, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: (restaurant["features"] as List<String>).take(2).map((feature) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6A4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        feature,
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