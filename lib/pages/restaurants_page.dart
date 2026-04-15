// lib/services/restaurants_page.dart
import 'package:flutter/material.dart';
import 'restaurant_detail_page.dart';
import '../models/place_model.dart';
import 'api_service.dart'; //

class RestaurantsPage extends StatefulWidget {
  const RestaurantsPage({super.key});

  @override
  State<RestaurantsPage> createState() => _RestaurantsPageState();
}

class _RestaurantsPageState extends State<RestaurantsPage> {
  List<Place> restaurants = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final restaurantsList = await ApiService.getRestaurants(); // ✅ CORREGIDO: ApiService.getRestaurants()
      setState(() => restaurants = restaurantsList);

      if (restaurantsList.isEmpty) {
        setState(() => _error = 'No hay restaurantes disponibles');
      }
    } catch (e) {
      setState(() => _error = 'Error al cargar restaurantes: $e');
      print('❌ Error en _loadRestaurants: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshRestaurants() async {
    await _loadRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurantes"),
        backgroundColor: const Color(0xFF06B6A4),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshRestaurants,
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
                onPressed: _loadRestaurants,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF06B6A4),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        )
            : restaurants.isEmpty
            ? const Center(
          child: Text(
            "No hay restaurantes disponibles",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        )
            : RefreshIndicator(
          onRefresh: _refreshRestaurants,
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
      ),
    );
  }

  Widget _buildRestaurantCard(Place restaurant) {
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
              restaurant.imageUrl ?? _getPlaceholderImage('restaurant'), // ✅ CORREGIDO: Método local
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
                  child: const Icon(Icons.restaurant, size: 50, color: Colors.grey),
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
                  restaurant.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  restaurant.lugar,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(" ${restaurant.rating}"),
                    const Spacer(),
                    Text(
                      restaurant.priceRange ?? 'Consultar',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (restaurant.description != null && restaurant.description!.isNotEmpty) ...{
                  Text(
                    restaurant.description!.length > 100
                        ? '${restaurant.description!.substring(0, 100)}...'
                        : restaurant.description!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                },
                if (restaurant.amenities.isNotEmpty) ...{
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: restaurant.amenities.take(3).map((feature) {
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