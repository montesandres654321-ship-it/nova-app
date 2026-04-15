// lib/models/place.dart
// CAMBIO: agregado rewardStock (int?) en campo, fromJson, toJson, copyWith
import 'dart:convert';

class Place {
  final int id;
  final String name;
  final String tipo;
  final String lugar;
  final String description;
  final String? imageUrl;
  final String? qrImageUrl;
  final double rating;
  final String? address;
  final String? phone;
  final String? priceRange;
  final List<String> amenities;
  final bool isActive;

  // 🎁 CAMPOS DE RECOMPENSA
  final bool hasReward;
  final String? rewardName;
  final String? rewardDescription;
  final String? rewardIcon;
  final int?    rewardStock;   // ← NUEVO: null = ilimitado

  // 🆕 CAMPOS DE PROPIETARIO
  final int?    ownerAdminId;
  final String? ownerFirstName;
  final String? ownerLastName;
  final String? ownerEmail;
  final String? ownerPhone;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Place({
    required this.id,
    required this.name,
    required this.tipo,
    required this.lugar,
    required this.description,
    this.imageUrl,
    this.qrImageUrl,
    this.rating = 0.0,
    this.address,
    this.phone,
    this.priceRange,
    required this.amenities,
    required this.isActive,
    this.hasReward = false,
    this.rewardName,
    this.rewardDescription,
    this.rewardIcon,
    this.rewardStock,        // ← NUEVO
    this.ownerAdminId,
    this.ownerFirstName,
    this.ownerLastName,
    this.ownerEmail,
    this.ownerPhone,
    this.createdAt,
    this.updatedAt,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    List<String> amenitiesList = [];
    if (json['amenities'] != null) {
      if (json['amenities'] is String) {
        try {
          final amenitiesJson = jsonDecode(json['amenities']);
          if (amenitiesJson is List) {
            amenitiesList = List<String>.from(amenitiesJson);
          }
        } catch (e) {
          amenitiesList = (json['amenities'] as String)
              .split(',')
              .map((e) => e.trim())
              .toList();
        }
      } else if (json['amenities'] is List) {
        amenitiesList = List<String>.from(json['amenities']);
      }
    }

    return Place(
      id:          json['id']          ?? 0,
      name:        json['name']        ?? '',
      tipo:        json['tipo']        ?? '',
      lugar:       json['lugar']       ?? '',
      description: json['description'] ?? '',
      imageUrl:    json['image_url'],
      qrImageUrl:  json['qr_image_url'],
      rating:      (json['rating'] ?? 0.0).toDouble(),
      address:     json['address'],
      phone:       json['phone'],
      priceRange:  json['price_range'],
      amenities:   amenitiesList,
      isActive:    (json['is_active']  ?? 1) == 1,
      hasReward:   (json['has_reward'] ?? 0) == 1,
      rewardName:        json['reward_name'],
      rewardDescription: json['reward_description'],
      rewardIcon:        json['reward_icon'],
      rewardStock:       json['reward_stock'] as int?,   // ← NUEVO
      ownerAdminId:  json['owner_admin_id'] ?? json['owner_id'],
      ownerFirstName: json['owner_first_name'],
      ownerLastName:  json['owner_last_name'],
      ownerEmail:     json['owner_email'],
      ownerPhone:     json['owner_phone'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id':          id,
      'name':        name,
      'tipo':        tipo,
      'lugar':       lugar,
      'description': description,
      'image_url':    imageUrl,
      'qr_image_url': qrImageUrl,
      'rating':      rating,
      'address':     address,
      'phone':       phone,
      'price_range': priceRange,
      'amenities':   jsonEncode(amenities),
      'is_active':   isActive  ? 1 : 0,
      'has_reward':  hasReward ? 1 : 0,
      'reward_name':        rewardName,
      'reward_description': rewardDescription,
      'reward_icon':        rewardIcon,
      'reward_stock':       rewardStock,   // ← NUEVO
      'owner_admin_id':     ownerAdminId,
    };
  }

  // ── Getters ──────────────────────────────────────────
  String get tipoEmoji {
    switch (tipo.toLowerCase()) {
      case 'hotel':      return '🏨';
      case 'restaurant': return '🍽️';
      case 'bar':        return '🍹';
      default:           return '📍';
    }
  }

  String get tipoLabel {
    switch (tipo.toLowerCase()) {
      case 'hotel':      return 'Hotel';
      case 'restaurant': return 'Restaurante';
      case 'bar':        return 'Bar';
      default:           return 'Lugar';
    }
  }

  String get typeEmoji  => tipoEmoji;
  String get displayName => '$tipoEmoji $name';
  bool   get hasOwner    => ownerAdminId != null;

  String? get ownerFullName {
    if (ownerFirstName == null && ownerLastName == null) return null;
    return '${ownerFirstName ?? ''} ${ownerLastName ?? ''}'.trim();
  }

  String get ownerInitials {
    if (ownerFirstName == null && ownerLastName == null) return '?';
    final f = ownerFirstName?.isNotEmpty == true ? ownerFirstName![0] : '';
    final l = ownerLastName?.isNotEmpty  == true ? ownerLastName![0]  : '';
    return '$f$l'.toUpperCase();
  }

  String get ownerDisplay {
    if (!hasOwner) return 'Sin propietario';
    return ownerFullName ?? ownerEmail ?? 'Propietario';
  }

  /// Texto legible del stock: "50 disponibles" o "Ilimitado"
  String get rewardStockLabel {
    if (rewardStock == null) return 'Ilimitado';
    return '$rewardStock disponibles';
  }

  // ── copyWith ─────────────────────────────────────────
  Place copyWith({
    int? id, String? name, String? tipo, String? lugar,
    String? description, String? imageUrl, String? qrImageUrl,
    double? rating, String? address, String? phone,
    String? priceRange, List<String>? amenities, bool? isActive,
    bool? hasReward, String? rewardName, String? rewardDescription,
    String? rewardIcon,
    int?    rewardStock,       // ← NUEVO
    int? ownerAdminId, String? ownerFirstName, String? ownerLastName,
    String? ownerEmail, String? ownerPhone,
    DateTime? createdAt, DateTime? updatedAt,
  }) {
    return Place(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      tipo:        tipo        ?? this.tipo,
      lugar:       lugar       ?? this.lugar,
      description: description ?? this.description,
      imageUrl:    imageUrl    ?? this.imageUrl,
      qrImageUrl:  qrImageUrl  ?? this.qrImageUrl,
      rating:      rating      ?? this.rating,
      address:     address     ?? this.address,
      phone:       phone       ?? this.phone,
      priceRange:  priceRange  ?? this.priceRange,
      amenities:   amenities   ?? this.amenities,
      isActive:    isActive    ?? this.isActive,
      hasReward:   hasReward   ?? this.hasReward,
      rewardName:        rewardName        ?? this.rewardName,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      rewardIcon:        rewardIcon        ?? this.rewardIcon,
      rewardStock:       rewardStock       ?? this.rewardStock,   // ← NUEVO
      ownerAdminId:  ownerAdminId  ?? this.ownerAdminId,
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName:  ownerLastName  ?? this.ownerLastName,
      ownerEmail:     ownerEmail     ?? this.ownerEmail,
      ownerPhone:     ownerPhone     ?? this.ownerPhone,
      createdAt:  createdAt  ?? this.createdAt,
      updatedAt:  updatedAt  ?? this.updatedAt,
    );
  }

  @override
  String toString() =>
      'Place{id: $id, name: $name, tipo: $tipo, hasOwner: $hasOwner, '
          'hasReward: $hasReward, rewardStock: $rewardStock}';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Place && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}