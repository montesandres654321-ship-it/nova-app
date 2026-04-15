// lib/models/place_model.dart
import 'dart:convert';
class Place {
  final int id;
  final String name;
  final String tipo;
  final String lugar;
  final String description;
  final String? imageUrl;
  final double rating;
  final String? address;
  final String? phone;
  final String? priceRange;
  final List<String> amenities;
  final bool isActive;

  Place({
    required this.id,
    required this.name,
    required this.tipo,
    required this.lugar,
    required this.description,
    this.imageUrl,
    this.rating = 0.0,
    this.address,
    this.phone,
    this.priceRange,
    required this.amenities,
    required this.isActive,
  });

  // ✅ FACTORY COMPATIBLE CON AMBOS SISTEMAS
  factory Place.fromJson(Map<String, dynamic> json) {
    // Manejar amenities de ambas fuentes
    List<String> amenitiesList = [];
    if (json['amenities'] != null) {
      if (json['amenities'] is String) {
        try {
          final amenitiesJson = jsonDecode(json['amenities']);
          if (amenitiesJson is List) {
            amenitiesList = List<String>.from(amenitiesJson);
          }
        } catch (e) {
          amenitiesList = (json['amenities'] as String).split(',').map((e) => e.trim()).toList();
        }
      } else if (json['amenities'] is List) {
        amenitiesList = List<String>.from(json['amenities']);
      }
    }

    return Place(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Sin nombre',
      tipo: json['tipo'] ?? 'hotel',
      lugar: json['lugar'] ?? 'Ubicación desconocida',
      description: json['description'] ?? 'Descripción no disponible',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      address: json['address'],
      phone: json['phone'],
      priceRange: json['price_range'] ?? json['priceRange'],
      amenities: amenitiesList,
      isActive: (json['is_active'] ?? json['isActive'] ?? 1) == 1,
    );
  }

  // ✅ MÉTODOS DE CONVENIENCIA PARA COMPATIBILIDAD
  String get city => lugar;
  String get type => tipo;

  String get typeEmoji {
    switch (tipo) {
      case 'hotel': return '🏨';
      case 'restaurant': return '🍽️';
      case 'bar': return '🍹';
      default: return '📍';
    }
  }

  String get displayName => '$typeEmoji $name';

  // ✅ PARA DEBUG
  @override
  String toString() {
    return 'Place{id: $id, name: $name, tipo: $tipo, lugar: $lugar, rating: $rating}';
  }
}