// lib/services/places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';

class PlacesService {
  static const String baseUrl = "http://192.168.2.178:3000"; // Misma IP de tu api_service.dart

  // Headers comunes para todas las peticiones
  static Map<String, String> get headers {
    return {
      'Content-Type': 'application/json',
    };
  }

  // ✅ Obtener todos los lugares con detalles completos
  static Future<List<Place>> getPlaces() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/places/detailed'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> placesData = data['places'];
          return placesData.map((json) => Place.fromJson(json)).toList();
        } else {
          throw Exception(data['error'] ?? 'Error al obtener lugares');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en PlacesService.getPlaces: $e');
      rethrow;
    }
  }

  // ✅ Obtener lugares por tipo (hotel, restaurant, bar)
  static Future<List<Place>> getPlacesByType(String type) async {
    try {
      // Validar tipo
      if (!['hotel', 'restaurant', 'bar'].contains(type.toLowerCase())) {
        throw Exception('Tipo de lugar no válido: $type');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/places/type/$type'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> placesData = data['places'];
          return placesData.map((json) => Place.fromJson(json)).toList();
        } else {
          throw Exception(data['error'] ?? 'Error al obtener lugares por tipo');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en PlacesService.getPlacesByType: $e');
      rethrow;
    }
  }

  // ✅ Obtener un lugar específico por ID
  static Future<Place> getPlaceById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/places/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          return Place.fromJson(data['place']);
        } else {
          throw Exception(data['error'] ?? 'Error al obtener el lugar');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Lugar no encontrado');
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en PlacesService.getPlaceById: $e');
      rethrow;
    }
  }

  // ✅ Obtener hoteles (convenience method)
  static Future<List<Place>> getHotels() async {
    return await getPlacesByType('hotel');
  }

  // ✅ Obtener restaurantes (convenience method)
  static Future<List<Place>> getRestaurants() async {
    return await getPlacesByType('restaurant');
  }

  // ✅ Obtener bares (convenience method)
  static Future<List<Place>> getBars() async {
    return await getPlacesByType('bar');
  }

  // ✅ Buscar lugares por término
  static Future<List<Place>> searchPlaces(String query) async {
    try {
      final allPlaces = await getPlaces();

      return allPlaces.where((place) {
        final searchTerm = query.toLowerCase();
        return place.name.toLowerCase().contains(searchTerm) ||
            place.lugar.toLowerCase().contains(searchTerm) ||
            place.description?.toLowerCase().contains(searchTerm) == true ||
            place.amenities.any((amenity) => amenity.toLowerCase().contains(searchTerm));
      }).toList();
    } catch (e) {
      print('❌ Error en PlacesService.searchPlaces: $e');
      rethrow;
    }
  }

  // ✅ Verificar salud del servicio
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: headers,
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }

  // ✅ MÉTODO ACTUALIZADO - Usa tus imágenes existentes
  static String getPlaceholderImage(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return 'assets/images/hotel_01.jpg'; // ← Tus imágenes reales
      case 'restaurant':
        return 'assets/images/restaurante_01.jpg';
      case 'bar':
        return 'assets/images/bares_01.jpg';
      default:
        return 'assets/images/hotel_01.jpg'; // ← Imagen por defecto existente
    }
  }
}