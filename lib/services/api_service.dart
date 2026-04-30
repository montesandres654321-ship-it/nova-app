// lib/services/api_service.dart
// ============================================================
// SERVICIO API CENTRALIZADO — Nova App Móvil
// ============================================================
// • Usa AppConstants para IP y endpoints
// • Envía token JWT en peticiones autenticadas
// • Parsea data['data'] (formato backend v6.0)
// • Sin datos mock — muestra errores reales
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/place_model.dart';
import '../models/scan_record.dart';

class ApiService {
  ApiService._(); // No instanciable — todos los métodos son static

  // ─── Headers ────────────────────────────────────────────

  /// Headers básicos sin autenticación
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  /// Headers con token JWT para peticiones autenticadas
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken);
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Obtener userId guardado
  static Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(AppConstants.keyUserId);
  }

  // ═══════════════════════════════════════════════════════
  // AUTH — Login, Registro, Google
  // ═══════════════════════════════════════════════════════

  /// Login con email y contraseña
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.buildUrl(AppConstants.loginEndpoint)),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(AppConstants.timeoutNormal);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Backend devuelve: { success, data: { token, user } }
        final inner = data['data'] ?? data;
        await _saveAuthData(inner);
        // Retornar aplanado para que login_page lea data['user'] y data['token'] fácil
        return {
          'success': true,
          'token': inner['token'],
          'user': inner['user'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error en login (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Registro de nuevo usuario
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String phone,
    required String dob,
    required String gender,
    required bool acceptedTerms,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.buildUrl(AppConstants.registerEndpoint)),
        headers: _headers,
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
      ).timeout(AppConstants.timeoutNormal);

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        // Backend devuelve: { success, data: { token, user } }
        final inner = data['data'] ?? data;
        await _saveAuthData(inner);
        return {'success': true, 'token': inner['token'], 'user': inner['user']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error en registro (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('❌ Error en register: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Guardar token y datos del usuario tras login exitoso
  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'];
    final user = data['user'];

    if (token != null) {
      await prefs.setString(AppConstants.keyToken, token);
    }
    if (user != null) {
      await prefs.setString(AppConstants.keyUser, jsonEncode(user));
      if (user['id'] != null) await prefs.setInt(AppConstants.keyUserId, user['id']);
      if (user['username'] != null) await prefs.setString(AppConstants.keyUsername, user['username']);
      if (user['email'] != null) await prefs.setString(AppConstants.keyEmail, user['email']);
      if (user['first_name'] != null) await prefs.setString(AppConstants.keyFirstName, user['first_name']);
    }
  }

  // ═══════════════════════════════════════════════════════
  // PLACES — Obtener lugares
  // ═══════════════════════════════════════════════════════

  /// Obtener todos los lugares activos
  static Future<List<Place>> getAllPlaces() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.buildUrl(AppConstants.placesEndpoint)),
        headers: _headers,
      ).timeout(AppConstants.timeoutLong);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((json) => Place.fromJson(json)).toList();
        }
      }
      throw Exception('Error al cargar lugares (${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Error en getAllPlaces: $e');
      rethrow;
    }
  }

  /// Obtener lugares por tipo (hotel, restaurant, bar)
  static Future<List<Place>> getPlacesByType(String type) async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.buildUrl('${AppConstants.placesByTypeEndpoint}/$type')),
        headers: _headers,
      ).timeout(AppConstants.timeoutLong);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((json) => Place.fromJson(json)).toList();
        }
      }
      throw Exception('Error al cargar $type (${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Error en getPlacesByType ($type): $e');
      rethrow;
    }
  }

  /// Obtener lugar por ID
  static Future<Place> getPlaceById(int id) async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.buildUrl('${AppConstants.placeByIdEndpoint}/$id')),
        headers: _headers,
      ).timeout(AppConstants.timeoutNormal);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return Place.fromJson(data['data']);
        }
      }
      throw Exception('Lugar no encontrado');
    } catch (e) {
      debugPrint('❌ Error en getPlaceById: $e');
      rethrow;
    }
  }

  // Shortcuts
  static Future<List<Place>> getHotels() => getPlacesByType('hotel');
  static Future<List<Place>> getRestaurants() => getPlacesByType('restaurant');
  static Future<List<Place>> getBars() => getPlacesByType('bar');

  // ═══════════════════════════════════════════════════════
  // SCAN — Escaneo QR
  // ═══════════════════════════════════════════════════════

  /// Registrar escaneo de código QR
  static Future<Map<String, dynamic>> registerScan(String qrCode) async {
    try {
      final headers = await _authHeaders();
      final userId = await _getUserId();

      if (userId == null) {
        return {'success': false, 'error': 'Usuario no autenticado'};
      }

      // Extraer placeId del QR (formato: PLACE:1)
      final parts = qrCode.split(':');
      if (parts.length != 2) {
        return {'success': false, 'error': 'Formato QR inválido: $qrCode'};
      }
      final placeId = int.tryParse(parts[1]);
      if (placeId == null) {
        return {'success': false, 'error': 'ID de lugar inválido: ${parts[1]}'};
      }

      final response = await http.post(
        Uri.parse(AppConstants.buildUrl(AppConstants.scanEndpoint)),
        headers: headers,
        body: jsonEncode({
          'userId': userId,
          'placeId': placeId,
          'qrCode': qrCode,
        }),
      ).timeout(AppConstants.timeoutNormal);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Backend devuelve: { success, data: { scan_id, place, reward, ... } }
        // success_page.dart lee backendData['place'] y backendData['reward']
        final inner = data['data'] ?? {};
        return {
          'success': true,
          'place': inner['place'],
          'reward': inner['reward'],
          'visit_count': inner['visit_count'],
          'message': inner['message'] ?? data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al registrar escaneo (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('❌ Error en registerScan: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Validar código QR sin registrar
  static Future<Map<String, dynamic>> validateQR(String qrData) async {
    try {
      if (!qrData.startsWith('PLACE:')) {
        return {'valid': false, 'error': 'Formato QR inválido'};
      }

      final response = await http.post(
        Uri.parse(AppConstants.buildUrl(AppConstants.qrValidateEndpoint)),
        headers: _headers,
        body: jsonEncode({'qrData': qrData}),
      ).timeout(AppConstants.timeoutNormal);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception('Error validando QR (${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Error en validateQR: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // HISTORY — Historial de escaneos
  // ═══════════════════════════════════════════════════════

  /// Obtener historial de escaneos del usuario
  static Future<List<ScanRecord>> getScanHistory() async {
    try {
      final headers = await _authHeaders();
      final userId = await _getUserId();

      if (userId == null) throw Exception('Usuario no autenticado');

      final response = await http.get(
        Uri.parse(AppConstants.buildUrl('${AppConstants.scanDetailsEndpoint}/$userId')),
        headers: headers,
      ).timeout(AppConstants.timeoutNormal);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> scansData = data['scans'] ?? data['data'] ?? [];
          return scansData.map((scan) => ScanRecord.fromMap(scan)).toList();
        }
      }
      throw Exception('Error al obtener historial (${response.statusCode})');
    } catch (e) {
      debugPrint('❌ Error en getScanHistory: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // PROFILE — Perfil del usuario
  // ═══════════════════════════════════════════════════════

  /// Actualizar perfil del usuario autenticado
  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    String? phone,
  }) async {
    try {
      final headers = await _authHeaders();

      final response = await http.patch(
        Uri.parse(AppConstants.buildUrl(AppConstants.userProfileEndpoint)),
        headers: headers,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'username': username,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }),
      ).timeout(AppConstants.timeoutNormal);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        // Actualizar datos locales
        final prefs = await SharedPreferences.getInstance();
        final userData = data['data'] ?? data['user'];
        if (userData != null) {
          await prefs.setString(AppConstants.keyUser, jsonEncode(userData));
          await prefs.setString(AppConstants.keyFirstName, firstName);
          await prefs.setString(AppConstants.keyEmail, email);
        }
        return data;
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al actualizar perfil',
        };
      }
    } catch (e) {
      debugPrint('❌ Error en updateProfile: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Cambiar contraseña
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _authHeaders();

      final response = await http.post(
        Uri.parse(AppConstants.buildUrl(AppConstants.userPasswordEndpoint)),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ).timeout(AppConstants.timeoutNormal);

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      debugPrint('❌ Error en changePassword: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════
  // REWARDS — Recompensas
  // ═══════════════════════════════════════════════════════

  /// Confirmar recepción de recompensa (canjear)
  static Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    try {
      final headers = await _authHeaders();

      final response = await http.patch(
        Uri.parse(AppConstants.buildUrl('${AppConstants.redeemRewardEndpoint}/$rewardId/redeem')),
        headers: headers,
      ).timeout(AppConstants.timeoutNormal);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error al confirmar recompensa',
        };
      }
    } catch (e) {
      debugPrint('❌ Error en redeemReward: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ═══════════════════════════════════════════════════════
  // UTILS
  // ═══════════════════════════════════════════════════════

  /// Verificar salud del servidor
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse(AppConstants.buildUrl(AppConstants.healthEndpoint)),
        headers: _headers,
      ).timeout(AppConstants.timeoutShort);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Cerrar sesión — limpiar datos locales
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}