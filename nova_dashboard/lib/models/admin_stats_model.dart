// lib/models/admin_stats_model.dart
import 'admin_model.dart';

/// Modelo que combina datos de admin con estadísticas de su lugar
class AdminStats {
  final AdminModel admin;
  final PlaceStats? placeStats;

  AdminStats({
    required this.admin,
    this.placeStats,
  });

  // ============================================
  // FACTORY FROM JSON
  // ============================================
  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      admin: AdminModel.fromJson(json),
      placeStats: json['place_id'] != null && json['place_name'] != null
          ? PlaceStats.fromJson(json)
          : null,
    );
  }

  // ============================================
  // TO JSON
  // ============================================
  Map<String, dynamic> toJson() {
    return {
      ...admin.toJson(),
      if (placeStats != null) ...placeStats!.toJson(),
    };
  }

  // ============================================
  // GETTERS
  // ============================================

  /// Verifica si tiene lugar asignado
  bool get hasPlace => placeStats != null && admin.placeId != null;

  /// Información resumida para mostrar
  String get displayInfo {
    if (hasPlace && placeStats != null) {
      return '${admin.placeName} • ${placeStats!.totalScans} escaneos';
    }
    return 'Sin lugar asignado';
  }

  /// Información detallada para tooltip
  String get detailedInfo {
    if (!hasPlace || placeStats == null) {
      return 'Usuario sin lugar asignado';
    }

    return '''
${admin.placeName}
Tipo: ${placeStats!.placeType}
Ubicación: ${placeStats!.placeLocation}
Rating: ${placeStats!.placeRating}/5
Escaneos: ${placeStats!.totalScans}
Visitantes únicos: ${placeStats!.uniqueVisitors}
Recompensas: ${placeStats!.totalRewards}
''';
  }

  /// Estadísticas resumidas
  String get statsResume {
    if (!hasPlace || placeStats == null) return 'N/A';
    return '${placeStats!.totalScans} escaneos • ${placeStats!.totalRewards} recompensas';
  }
}

/// Estadísticas del lugar asignado al propietario
class PlaceStats {
  final String placeName;
  final String placeType;
  final String placeLocation;
  final double placeRating;
  final int totalScans;
  final int uniqueVisitors;
  final int totalRewards;

  PlaceStats({
    required this.placeName,
    required this.placeType,
    required this.placeLocation,
    required this.placeRating,
    required this.totalScans,
    required this.uniqueVisitors,
    required this.totalRewards,
  });

  // ============================================
  // FACTORY FROM JSON
  // ============================================
  factory PlaceStats.fromJson(Map<String, dynamic> json) {
    return PlaceStats(
      placeName: json['place_name'] ?? '',
      placeType: json['place_type'] ?? '',
      placeLocation: json['place_location'] ?? json['lugar'] ?? '',
      placeRating: (json['place_rating'] ?? 0.0).toDouble(),
      totalScans: json['total_scans'] ?? 0,
      uniqueVisitors: json['unique_visitors'] ?? 0,
      totalRewards: json['total_rewards'] ?? 0,
    );
  }

  // ============================================
  // TO JSON
  // ============================================
  Map<String, dynamic> toJson() {
    return {
      'place_name': placeName,
      'place_type': placeType,
      'place_location': placeLocation,
      'place_rating': placeRating,
      'total_scans': totalScans,
      'unique_visitors': uniqueVisitors,
      'total_rewards': totalRewards,
    };
  }

  // ============================================
  // GETTERS
  // ============================================

  /// Promedio de escaneos por visitante
  double get avgScansPerVisitor {
    if (uniqueVisitors == 0) return 0;
    return totalScans / uniqueVisitors;
  }

  /// Porcentaje de conversión a recompensas
  double get rewardConversionRate {
    if (totalScans == 0) return 0;
    return (totalRewards / totalScans) * 100;
  }

  /// Rating formateado
  String get ratingFormatted {
    return placeRating.toStringAsFixed(1);
  }

  /// Tipo formateado con emoji
  String get typeWithEmoji {
    switch (placeType.toLowerCase()) {
      case 'hotel':
        return '🏨 Hotel';
      case 'restaurant':
        return '🍽️ Restaurante';
      case 'bar':
        return '🍹 Bar';
      default:
        return '📍 $placeType';
    }
  }

  /// Resumen de estadísticas
  String get summary {
    return '$totalScans escaneos ($uniqueVisitors únicos) • $totalRewards recompensas';
  }
}