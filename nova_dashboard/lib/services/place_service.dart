// lib/services/place_service.dart
// ============================================================
// CORRECCIONES:
//  • getAllPlaces: elimina page/limit (backend no los usa)
//  • getPlacesByType: usa getAllPlaces(tipo:tipo) con ?tipo=hotel
//  • createPlace: campos en inglés (name, description, image_url)
//  • updatePlace: campos en inglés
// ============================================================

import 'api_client.dart';
import '../models/place.dart';

class PlaceService {

  // ── OBTENER TODOS LOS LUGARES ─────────────────────────
  // GET /places           → todos
  // GET /places?tipo=hotel → filtrados
  static Future<List<Place>> getAllPlaces({String? tipo}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (tipo != null) queryParams['tipo'] = tipo;

      final response = await ApiClient.get<dynamic>(
        '/places',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException('Formato inválido: esperaba List, recibió ${data.runtimeType}');
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => Place.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error en getAllPlaces: $e');
      rethrow;
    }
  }

  // ── ALIAS getPlaces ───────────────────────────────────
  static Future<List<Place>> getPlaces() async => getAllPlaces();

  // ── FILTRAR POR TIPO ──────────────────────────────────
  // Usa ?tipo= en lugar de /by-type/$tipo
  static Future<List<Place>> getPlacesByType(String tipo) async {
    return getAllPlaces(tipo: tipo);
  }

  // ── OBTENER POR ID ────────────────────────────────────
  static Future<Place> getPlaceById(int id) async {
    try {
      final response = await ApiClient.get<dynamic>('/places/$id');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido: esperaba Map');
      }
      return Place.fromJson(data);
    } catch (e) {
      print('❌ Error en getPlaceById: $e');
      rethrow;
    }
  }

  // ── CREAR LUGAR ───────────────────────────────────────
  // CORRECCIÓN: campos en inglés (name, description, image_url)
  static Future<Map<String, dynamic>> createPlace(Place place) async {
    try {
      final body = <String, dynamic>{
        'name':        place.name,
        'tipo':        place.tipo,
        'lugar':       place.lugar,
        'description': place.description,
        'rating':      place.rating,
        'is_active':   place.isActive ? 1 : 0,
        'has_reward':  place.hasReward ? 1 : 0,
      };

      if (place.imageUrl   != null && place.imageUrl!.isNotEmpty) body['image_url']           = place.imageUrl;
      if (place.address    != null) body['address']          = place.address;
      if (place.phone      != null) body['phone']            = place.phone;
      if (place.priceRange != null) body['price_range']      = place.priceRange;
      if (place.amenities.isNotEmpty)  body['amenities']     = place.amenities;
      if (place.rewardName != null) body['reward_name']       = place.rewardName;
      if (place.rewardDescription != null) body['reward_description'] = place.rewardDescription;
      if (place.rewardIcon != null) body['reward_icon']       = place.rewardIcon;
      if (place.ownerAdminId != null) body['owner_id']        = place.ownerAdminId;

      final response = await ApiClient.post<dynamic>('/places', body: body);
      return {'success': true, 'message': 'Lugar creado exitosamente', 'data': response.data};
    } catch (e) {
      print('❌ Error en createPlace: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── ACTUALIZAR LUGAR ──────────────────────────────────
  // CORRECCIÓN: campos en inglés
  static Future<Map<String, dynamic>> updatePlace(int id, Place place) async {
    try {
      final body = <String, dynamic>{
        'name':        place.name,
        'tipo':        place.tipo,
        'lugar':       place.lugar,
        'description': place.description,
        'rating':      place.rating,
        'is_active':   place.isActive ? 1 : 0,
        'has_reward':  place.hasReward ? 1 : 0,
        'amenities':   place.amenities,
      };

      if (place.imageUrl   != null) body['image_url']         = place.imageUrl;
      if (place.address    != null) body['address']           = place.address;
      if (place.phone      != null) body['phone']             = place.phone;
      if (place.priceRange != null) body['price_range']       = place.priceRange;
      if (place.rewardName != null) body['reward_name']       = place.rewardName;
      if (place.rewardDescription != null) body['reward_description'] = place.rewardDescription;
      if (place.rewardIcon != null) body['reward_icon']       = place.rewardIcon;
      body['owner_id'] = place.ownerAdminId;

      final response = await ApiClient.put<dynamic>('/places/$id', body: body);
      return {'success': true, 'message': 'Lugar actualizado exitosamente', 'data': response.data};
    } catch (e) {
      print('❌ Error en updatePlace: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── ELIMINAR / DESACTIVAR ─────────────────────────────
  static Future<Map<String, dynamic>> deletePlace(int id) async {
    try {
      final response = await ApiClient.delete<dynamic>('/places/$id');
      return {'success': response.success, 'message': 'Lugar desactivado'};
    } catch (e) {
      print('❌ Error en deletePlace: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ── ESTADÍSTICAS DEL LUGAR ────────────────────────────
  static Future<Map<String, dynamic>> getPlaceStats(int placeId) async {
    try {
      final response = await ApiClient.get<dynamic>('/my-place/stats?place_id=$placeId');
      final data = response.data;
      if (data is! Map<String, dynamic>) throw ApiException('Formato inválido');
      return data;
    } catch (e) {
      print('❌ Error en getPlaceStats: $e');
      rethrow;
    }
  }
}