// lib/services/api_service.dart -
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'scan_record.dart';
import '../models/place_model.dart';

class ApiService {
  // ✅ IP CORRECTA - MISMA QUE DASHBOARD
  static const String backendUrl = "http://192.168.2.178:3000";

  // ==================== MÉTODOS MEJORADOS PARA LUGARES ====================

  // ✅ MEJORADO: Obtener bares con manejo de errores mejorado
  static Future<List<Place>> getBars() async {
    return _getPlacesByType('bar');
  }

  // ✅ MEJORADO: Obtener hoteles
  static Future<List<Place>> getHotels() async {
    return _getPlacesByType('hotel');
  }

  // ✅ MEJORADO: Obtener restaurantes
  static Future<List<Place>> getRestaurants() async {
    return _getPlacesByType('restaurant');
  }

  // ✅ MEJORADO: Método privado con mejor manejo de errores
  static Future<List<Place>> _getPlacesByType(String type) async {
    try {
      print('🔄 Cargando lugares de tipo: $type');

      final response = await http.get(
        Uri.parse('$backendUrl/places/type/$type'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      print('📡 Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> placesData = data['places'] ?? [];
          print('✅ Se encontraron ${placesData.length} lugares de tipo $type');

          final places = placesData.map((json) => Place.fromJson(json)).toList();
          return places;
        } else {
          throw Exception(data['error'] ?? 'Error al cargar $type');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en _getPlacesByType ($type): $e');
      // Fallback a datos mock para desarrollo
      return _getMockPlacesByType(type);
    }
  }

  // ✅ NUEVO: Obtener todos los lugares
  static Future<List<Place>> getAllPlaces() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/places'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> placesData = data['places'] ?? [];
          return placesData.map((json) => Place.fromJson(json)).toList();
        } else {
          throw Exception(data['error'] ?? 'Error al cargar lugares');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getAllPlaces: $e');
      return [];
    }
  }

  // ✅ MEJORADO: Validar código QR
  static Future<Map<String, dynamic>> validateQR(String qrData) async {
    try {
      print('🔍 Validando QR: $qrData');

      // Verificar formato básico primero
      if (!qrData.startsWith('PLACE:')) {
        return {
          'valid': false,
          'error': 'Formato QR inválido. Debe comenzar con "PLACE:"'
        };
      }

      final response = await http.post(
        Uri.parse('$backendUrl/qr/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qrData': qrData}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en validateQR: $e');
      rethrow;
    }
  }

  // ==================== MÉTODOS EXISTENTES MEJORADOS ====================

  // ✅ MEJORADO: Obtener historial con userId
  static Future<List<ScanRecord>> getScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      print('🔄 Cargando historial para usuario: $userId');

      final response = await http.get(
        Uri.parse('$backendUrl/scans/details/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> scansData = data['scans'] ?? [];
          print('✅ Historial cargado: ${scansData.length} escaneos');

          return scansData.map((scan) => ScanRecord.fromMap(scan)).toList();
        } else {
          throw Exception(data['error'] ?? 'Error al obtener historial');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en getScanHistory: $e');
      rethrow;
    }
  }

  // ✅ MEJORADO: Registrar escaneo
  static Future<Map<String, dynamic>> registerScan(String qrCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      print('📝 Registrando escaneo: $qrCode para usuario: $userId');

      // Extraer placeId del código QR
      final parts = qrCode.split(':');
      if (parts.length != 2) {
        throw Exception('Formato QR inválido: $qrCode');
      }

      final placeId = int.tryParse(parts[1]);
      if (placeId == null) {
        throw Exception('ID de lugar inválido: ${parts[1]}');
      }

      final response = await http.post(
        Uri.parse('$backendUrl/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'placeId': placeId,
          'qrCode': qrCode,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ Escaneo registrado exitosamente');
          return data;
        } else {
          throw Exception(data['error'] ?? 'Error al registrar escaneo');
        }
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en registerScan: $e');
      rethrow;
    }
  }

  // ✅ MANTENIDO: Login tradicional
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error en login: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  // ✅ MANTENIDO: Registro de usuario
  static Future<Map<String, dynamic>> register(
      String firstName, String lastName, String username,
      String email, String password, String phone,
      String dob, String gender, bool acceptedTerms) async {

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'username': username,
          'email': email,
          'password': password,
          'phone': phone,
          'dob': dob,
          'gender': gender,
          'accepted_terms': acceptedTerms ? 1 : 0,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error en registro: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en register: $e');
      rethrow;
    }
  }

  // ==================== MÉTODOS AUXILIARES MEJORADOS ====================

  // ✅ MEJORADO: Datos mock para desarrollo
  static List<Place> _getMockPlacesByType(String type) {
    print('🔄 Usando datos mock para tipo: $type');

    final allPlaces = [
      Place(
        id: 1,
        name: "Hotel Sol Caribe",
        tipo: "hotel",
        lugar: "Coveñas",
        description: "Hermoso hotel frente al mar con todas las comodidades y vista al océano",
        imageUrl: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop",
        rating: 4.5,
        address: "Av. Principal #123, Coveñas",
        phone: "+57 123 456 7890",
        priceRange: "\$100,000 - \$300,000",
        amenities: ["Wifi", "Piscina", "Aire Acondicionado", "Restaurante", "Spa"],
        isActive: true,
      ),
      Place(
        id: 2,
        name: "Restaurante Mar Azul",
        tipo: "restaurant",
        lugar: "Coveñas",
        description: "Comida típica del caribe colombiano con los mejores mariscos frescos",
        imageUrl: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop",
        rating: 4.7,
        address: "Av. del Mar #234, Coveñas",
        phone: "+57 123 456 7892",
        priceRange: "\$50,000 - \$150,000",
        amenities: ["Terraza", "Mariscos", "Comida Local", "Bar", "Vista al Mar"],
        isActive: true,
      ),
      Place(
        id: 3,
        name: "Bar Arena Dorada",
        tipo: "bar",
        lugar: "Coveñas",
        description: "Ambiente relajado con cocktails exclusivos y música en vivo los fines de semana",
        imageUrl: "https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=400&h=300&fit=crop",
        rating: 4.3,
        address: "Calle 8 #12-34, Coveñas",
        phone: "+57 123 456 7894",
        priceRange: "\$20,000 - \$80,000",
        amenities: ["Cócteles", "Música En Vivo", "Terraza", "Happy Hour", "Snacks"],
        isActive: true,
      ),
      Place(
        id: 4,
        name: "Hotel Playa Serena",
        tipo: "hotel",
        lugar: "Tolú",
        description: "Hotel familiar con piscina y jardines tropicales, ideal para descansar",
        imageUrl: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&h=300&fit=crop",
        rating: 4.2,
        address: "Carrera 5 #12-45, Tolú",
        phone: "+57 123 456 7891",
        priceRange: "\$80,000 - \$200,000",
        amenities: ["Piscina", "Jardín", "Desayuno Incluido", "Wifi", "Estacionamiento"],
        isActive: true,
      ),
      Place(
        id: 5,
        name: "Restaurante La Bahía",
        tipo: "restaurant",
        lugar: "Tolú",
        description: "Especialidad en pescados y mariscos con vista espectacular al mar",
        imageUrl: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400&h=300&fit=crop",
        rating: 4.6,
        address: "Malecón #56, Tolú",
        phone: "+57 123 456 7893",
        priceRange: "\$60,000 - \$180,000",
        amenities: ["Vista al Mar", "Mariscos Frescos", "Terraza", "Bar", "Postres Caseros"],
        isActive: true,
      ),
    ];

    final filteredPlaces = allPlaces.where((place) => place.tipo == type).toList();
    print('✅ Datos mock: ${filteredPlaces.length} lugares de tipo $type');

    return filteredPlaces;
  }

  // ✅ NUEVO: Verificar salud del servidor
  static Future<Map<String, dynamic>> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return {
        'available': response.statusCode == 200,
        'statusCode': response.statusCode,
        'message': response.statusCode == 200 ? 'Servidor disponible' : 'Servidor no disponible'
      };
    } catch (e) {
      print('❌ Servidor no disponible: $e');
      return {
        'available': false,
        'error': 'Error de conexión: $e'
      };
    }
  }

  // ✅ NUEVO: Obtener estadísticas del usuario
  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/users/$userId/stats'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': 'Error al obtener estadísticas'
        };
      }
    } catch (e) {
      print('❌ Error en getUserStats: $e');
      return {
        'success': false,
        'error': 'Error de conexión'
      };
    }
  }
}