// lib/models/place_model.dart
// ============================================================
// MODELO DE LUGAR — Nova App Móvil
// ============================================================
// Compatible con backend v6.0
// Incluye campos de recompensa para mostrar en detalle
// ============================================================

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

  // Campos de recompensa (nuevos)
  final bool hasReward;
  final String? rewardName;
  final String? rewardIcon;
  final String? rewardDescription;
  final int? rewardStock;

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
    this.isActive = true,
    this.hasReward = false,
    this.rewardName,
    this.rewardIcon,
    this.rewardDescription,
    this.rewardStock,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    // Parsear amenities robustamente
    List<String> amenitiesList = [];
    if (json['amenities'] != null) {
      if (json['amenities'] is String) {
        try {
          final parsed = jsonDecode(json['amenities']);
          if (parsed is List) amenitiesList = List<String>.from(parsed);
        } catch (_) {
          amenitiesList = (json['amenities'] as String)
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
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
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? json['imageUrl'],
      rating: (json['rating'] ?? 0).toDouble(),
      address: json['address'],
      phone: json['phone'],
      priceRange: json['price_range'] ?? json['priceRange'],
      amenities: amenitiesList,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      // Campos de recompensa
      hasReward: json['has_reward'] == true || json['has_reward'] == 1,
      rewardName: json['reward_name'],
      rewardIcon: json['reward_icon'],
      rewardDescription: json['reward_description'],
      rewardStock: json['reward_stock'],
    );
  }

  // Helpers de conveniencia
  String get tipoEmoji {
    switch (tipo) {
      case 'hotel': return '🏨';
      case 'restaurant': return '🍽️';
      case 'bar': return '🍹';
      default: return '📍';
    }
  }

  String get tipoLabel {
    switch (tipo) {
      case 'hotel': return 'Hotel';
      case 'restaurant': return 'Restaurante';
      case 'bar': return 'Bar';
      default: return 'Lugar';
    }
  }

  String get displayName => '$tipoEmoji $name';

  @override
  String toString() => 'Place{id: $id, name: $name, tipo: $tipo, lugar: $lugar}';
}