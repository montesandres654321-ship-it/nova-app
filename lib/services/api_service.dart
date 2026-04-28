// lib/services/api_service.dart
// ============================================================
// SERVICIO API CENTRALIZADO — Nova App Móvil
// ============================================================
// Mejoras de producción aplicadas:
//  • Motor HTTP unificado (_request) con retry inteligente
//  • Retry solo en fallas de red / timeout (nunca en 4xx/5xx)
//  • _handle401 con flag anti-duplicado, preparado para refresh
//  • userId eliminado del body de /scans (JWT identifica al usuario)
//  • Logging controlado: solo en kDebugMode
//  • changePassword: fix bug silencioso (verificaba status pero no success)
//  • _connectionError: type-safe (SocketException, TimeoutException)
// ============================================================

import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/place_model.dart';
import '../models/scan_record.dart';
import '../utils/constants.dart';
import 'navigation_service.dart';

class ApiService {
  ApiService._();

  // ═══════════════════════════════════════════════════════
  // INFRAESTRUCTURA HTTP
  // ═══════════════════════════════════════════════════════

  /// Máximo de reintentos automáticos.
  /// Solo aplica a SocketException y TimeoutException — nunca a 4xx/5xx.
  static const int _maxRetries = 2;

  /// Evita múltiples logout/redirect simultáneos cuando varios requests
  /// reciben 401 al mismo tiempo (e.g. token expirado con llamadas paralelas).
  static bool _isRefreshing = false;

  // ─── Motor HTTP unificado ────────────────────────────────

  /// Ejecuta un request HTTP con:
  ///  - Headers de autenticación si [requiresAuth] es true
  ///  - Timeout configurable (default: AppConstants.timeoutNormal)
  ///  - Retry automático en [SocketException] y [TimeoutException]
  ///  - Detección y manejo de 401 en rutas protegidas
  ///
  /// No reintenta en respuestas 4xx ni 5xx (errores de lógica/servidor).
  static Future<http.Response> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Duration? timeout,
  }) async {
    // Build headers — auth check local evita request innecesaria sin token
    final Map<String, String> headers;
    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyToken);
      if (token == null) {
        // Sin token local → tratar como 401 inmediatamente
        await _handle401();
        return http.Response('{"error":"Sin sesión activa"}', 401);
      }
      headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } else {
      headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }

    final uri          = Uri.parse(AppConstants.buildUrl(endpoint));
    final effectiveTO  = timeout ?? AppConstants.timeoutNormal;
    final encodedBody  = body != null ? jsonEncode(body) : null;

    _log('→ $method $endpoint');

    // ─── Retry loop ───────────────────────────────────────
    int attempt = 0;
    while (true) {
      try {
        final response = await _execute(method, uri, headers, encodedBody)
            .timeout(effectiveTO);

        _log('← ${response.statusCode} $endpoint');

        // 401 en ruta protegida → handle central (redirect a login)
        if (response.statusCode == 401 && requiresAuth) {
          await _handle401();
        }

        return response;

      } on SocketException {
        // Red caída — reintentar con backoff exponencial simple
        if (++attempt > _maxRetries) {
          _log('✗ $method $endpoint [sin red tras $attempt intentos]');
          rethrow;
        }
        _log('↻ Reintento $attempt/$_maxRetries $method $endpoint [sin red]');
        await Future.delayed(Duration(seconds: attempt));

      } on TimeoutException {
        // Request superó el timeout — reintentar
        if (++attempt > _maxRetries) {
          _log('✗ $method $endpoint [timeout tras $attempt intentos]');
          rethrow;
        }
        _log('↻ Reintento $attempt/$_maxRetries $method $endpoint [timeout]');
        await Future.delayed(Duration(seconds: attempt));
      }
      // Cualquier otra excepción (FormatException, etc.) propaga inmediatamente
    }
  }

  /// Despacha al método HTTP correspondiente.
  static Future<http.Response> _execute(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(uri, headers: headers, body: body);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: body);
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw ArgumentError('Método HTTP no soportado: $method');
    }
  }

  // ─── 401 Handler ─────────────────────────────────────────

  /// Maneja una sesión expirada o token inválido.
  ///
  /// El flag [_isRefreshing] previene múltiples redirects simultáneos.
  /// Estructura preparada para implementar refresh token en el futuro:
  ///   1. Intentar refrescar el token
  ///   2. Si falla → logout + redirect a login
  static Future<void> _handle401() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      // FUTURE: intentar refresh token aquí antes de desloguear
      // final refreshed = await _tryRefreshToken();
      // if (refreshed) return;
      await logout();
      NavigationService.goToLogin();
    } finally {
      _isRefreshing = false;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────

  /// Log solo en modo debug. No imprime nada en release.
  static void _log(String message) {
    if (kDebugMode) debugPrint('[ApiService] $message');
  }

  /// Mensaje de error amigable según código HTTP.
  static String _statusMessage(int code, String fallback) {
    switch (code) {
      case 400: return 'Solicitud inválida.';
      case 401: return 'Sesión expirada. Por favor, inicia sesión de nuevo.';
      case 403: return 'Acceso denegado.';
      case 404: return 'Recurso no encontrado.';
      case 409: return 'Conflicto con datos existentes.';
      case 422: return 'Datos inválidos.';
      case 500:
      case 502:
      case 503: return 'Error en el servidor. Intenta más tarde.';
      default:  return fallback;
    }
  }

  /// Traduce excepciones de red/timeout a mensajes legibles.
  /// Usa type-safe matching (no string.contains).
  static String _connectionError(Object e) {
    if (e is SocketException)  return 'Sin conexión. Verifica tu red.';
    if (e is TimeoutException) return 'Tiempo de espera agotado. Intenta de nuevo.';
    if (e is FormatException)  return 'Respuesta inesperada del servidor.';
    return 'Error de conexión.';
  }

  // ═══════════════════════════════════════════════════════
  // AUTH — Login / Registro
  // ═══════════════════════════════════════════════════════

  /// POST /login → { success, token, user }
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _request(
        method: 'POST',
        endpoint: AppConstants.loginEndpoint,
        body: {'email': email, 'password': password},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final inner = data['data'] ?? data;
        await _saveAuthData(inner);
        return {
          'success': true,
          'token': inner['token'],
          'user':  inner['user'],
        };
      }
      return {
        'success': false,
        'error': data['error'] ?? _statusMessage(response.statusCode, 'Error en login'),
      };
    } catch (e) {
      _log('✗ login: $e');
      return {'success': false, 'error': _connectionError(e)};
    }
  }

  /// POST /users/register
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
      final response = await _request(
        method: 'POST',
        endpoint: AppConstants.registerEndpoint,
        body: {
          'firstName':      firstName,
          'lastName':       lastName,
          'username':       username,
          'email':          email,
          'password':       password,
          'phone':          phone,
          'dob':            dob,
          'gender':         gender,
          'accepted_terms': acceptedTerms ? 1 : 0,
        },
      );

      final data = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        final inner = data['data'] ?? data;
        await _saveAuthData(inner);
        return {'success': true, 'token': inner['token'], 'user': inner['user']};
      }
      return {
        'success': false,
        'error': data['error'] ?? _statusMessage(response.statusCode, 'Error en registro'),
      };
    } catch (e) {
      _log('✗ register: $e');
      return {'success': false, 'error': _connectionError(e)};
    }
  }

  static Future<void> _saveAuthData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = data['token'];
    final user  = data['user'];

    if (token != null) await prefs.setString(AppConstants.keyToken, token);
    if (user != null) {
      await prefs.setString(AppConstants.keyUser, jsonEncode(user));
      if (user['id']         != null) await prefs.setInt(AppConstants.keyUserId, user['id']);
      if (user['username']   != null) await prefs.setString(AppConstants.keyUsername, user['username']);
      if (user['email']      != null) await prefs.setString(AppConstants.keyEmail, user['email']);
      if (user['first_name'] != null) await prefs.setString(AppConstants.keyFirstName, user['first_name']);
    }
  }

  /// Limpia token y datos de sesión locales.
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ═══════════════════════════════════════════════════════
  // PLACES — GET /places  (públicos, sin auth)
  // ═══════════════════════════════════════════════════════

  /// GET /places → lista completa de lugares activos
  static Future<List<Place>> getAllPlaces() async {
    try {
      final response = await _request(
        method: 'GET',
        endpoint: AppConstants.placesEndpoint,
        timeout: AppConstants.timeoutLong,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((j) => Place.fromJson(j)).toList();
        }
      }
      throw Exception(_statusMessage(response.statusCode, 'Error al cargar lugares'));
    } catch (e) {
      _log('✗ getAllPlaces: $e');
      rethrow;
    }
  }

  /// Alias explícito — mismo contrato que getAllPlaces
  static Future<List<Place>> getPlaces() => getAllPlaces();

  /// GET /places/type/:type
  static Future<List<Place>> getPlacesByType(String type) async {
    try {
      final response = await _request(
        method: 'GET',
        endpoint: '${AppConstants.placesByTypeEndpoint}/$type',
        timeout: AppConstants.timeoutLong,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          return list.map((j) => Place.fromJson(j)).toList();
        }
      }
      throw Exception(_statusMessage(response.statusCode, 'Error al cargar $type'));
    } catch (e) {
      _log('✗ getPlacesByType($type): $e');
      rethrow;
    }
  }

  /// GET /places/:id
  static Future<Place> getPlaceById(int id) async {
    try {
      final response = await _request(
        method: 'GET',
        endpoint: '${AppConstants.placeByIdEndpoint}/$id',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) return Place.fromJson(data['data']);
      }
      throw Exception(_statusMessage(response.statusCode, 'Lugar no encontrado'));
    } catch (e) {
      _log('✗ getPlaceById($id): $e');
      rethrow;
    }
  }

  // Shortcuts por tipo
  static Future<List<Place>> getHotels()      => getPlacesByType('hotel');
  static Future<List<Place>> getRestaurants() => getPlacesByType('restaurant');
  static Future<List<Place>> getBars()        => getPlacesByType('bar');

  // ═══════════════════════════════════════════════════════
  // SCAN — POST /scans  (protegido con JWT)
  // ═══════════════════════════════════════════════════════

  /// POST /scans — registra el escaneo.
  /// El backend obtiene userId del JWT — NO se incluye en el body.
  static Future<Map<String, dynamic>> registerScan(String qrCode) async {
    try {
      // Validación local del formato antes de hacer el request
      final parts = qrCode.split(':');
      if (parts.length != 2 || parts[0] != 'PLACE') {
        return {'success': false, 'error': 'Formato QR inválido: $qrCode'};
      }
      final placeId = int.tryParse(parts[1]);
      if (placeId == null) {
        return {'success': false, 'error': 'ID de lugar inválido: ${parts[1]}'};
      }

      final response = await _request(
        method: 'POST',
        endpoint: AppConstants.scanEndpoint,
        body: {
          'placeId': placeId,
          'qrCode':  qrCode,
          // userId viene del JWT — no se envía explícitamente
        },
        requiresAuth: true,
      );

      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesión expirada'};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final inner = data['data'] ?? {};
        return {
          'success':     true,
          'place':       inner['place'],
          'reward':      inner['reward'],
          'visit_count': inner['visit_count'],
          'message':     inner['message'] ?? data['message'],
        };
      }
      return {
        'success': false,
        'error': data['error'] ??
            _statusMessage(response.statusCode, 'Error al registrar escaneo'),
      };
    } catch (e) {
      _log('✗ registerScan: $e');
      return {'success': false, 'error': _connectionError(e)};
    }
  }

  /// Alias explícito requerido por el contrato
  static Future<Map<String, dynamic>> scanQR(String qrData) =>
      registerScan(qrData);

  /// POST /qr/validate — valida formato sin registrar
  static Future<Map<String, dynamic>> validateQR(String qrData) async {
    try {
      if (!qrData.startsWith('PLACE:')) {
        return {'valid': false, 'error': 'Formato QR inválido'};
      }
      final response = await _request(
        method: 'POST',
        endpoint: AppConstants.qrValidateEndpoint,
        body: {'qrData': qrData},
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(_statusMessage(response.statusCode, 'Error validando QR'));
    } catch (e) {
      _log('✗ validateQR: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // HISTORY — GET /scans/my-history  (protegido con JWT)
  // ═══════════════════════════════════════════════════════

  /// GET /scans/my-history — historial del usuario autenticado.
  /// El backend identifica al usuario por JWT (sin userId en la URL).
  static Future<List<ScanRecord>> getScanHistory() async {
    try {
      final response = await _request(
        method: 'GET',
        endpoint: AppConstants.myHistoryEndpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 401) throw Exception('Sesión expirada');
      if (response.statusCode != 200) {
        throw Exception(
            _statusMessage(response.statusCode, 'Error al obtener historial'));
      }

      final data = jsonDecode(response.body);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Error al obtener historial');
      }

      final List<dynamic> scansData = data['scans'] ?? data['data'] ?? [];
      return scansData.map((scan) => ScanRecord.fromMap(scan)).toList();
    } catch (e) {
      _log('✗ getScanHistory: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════
  // REWARDS — protegido con JWT
  // ═══════════════════════════════════════════════════════

  /// GET /rewards/my-rewards — recompensas del usuario autenticado
  static Future<Map<String, dynamic>> getMyRewards() async {
    try {
      final response = await _request(
        method: 'GET',
        endpoint: AppConstants.myRewardsEndpoint,
        requiresAuth: true,
      );

      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesión expirada'};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data; // { success, data: [...rewards] }
      }
      return {
        'success': false,
        'error': data['error'] ??
            _statusMessage(response.statusCode, 'Error al obtener recompensas'),
      };
    } catch (e) {
      _log('✗ getMyRewards: $e');
      return {'success': false, 'error': _connectionError(e)};
    }
  }

  /// PATCH /rewards/:id/redeem — confirmar recepción de recompensa
  static Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    try {
      final response = await _request(
        method: 'PATCH',
        endpoint: '/rewards/$rewardId/redeem',
        requiresAuth: true,
      );

      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesión expirada'};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {
        'success': false,
        'error': data['error'] ??
            _statusMessage(response.statusCode, 'Error al confirmar recompensa'),
      };
    } catch (e) {
      _log('✗ redeemReward($rewardId): $e');
      return {'success': false, 'error': _connectionError(e)};
    }
  }

  // ═══════════════════════════════════════════════════════
  // PROFILE — protegido con JWT
  // ═══════════════════════════════════════════════════════

  /// PATCH /users/me/profile
  static Future<Map<String, dynamic>> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await _request(
        method: 'PATCH',
        endpoint: AppConstants.userProfileEndpoint,
        body: {
          'first_name': firstName,
          'last_name':  lastName,
          'username':   username,
          'email':      email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesión expirada'};
      }

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        // Actualizar caché local
        final prefs    = await SharedPreferences.getInstance();
        final userData = data['data'] ?? data['user'];
        if (userData != null) {
          await prefs.setString(AppConstants.keyUser, jsonEncode(userData));
          await prefs.setString(AppConstants.keyFirstName, firstName);
          await prefs.setString(AppConstants.keyEmail, email);
        }
        return data;
      }
      return {
        'success': false,
        'error': data['error'] ??
            _statusMessage(response.statusCode, 'Error al actualizar perfil'),
      };
    } catch (e) {
      _log('✗ updateProfile: $e');
      return {'success': false, 'error': _connectionError(e)};
    }
  }

  /// POST /users/me/password
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _request(
        method: 'POST',
        endpoint: AppConstants.userPasswordEndpoint,
        body: {
          'current_password': currentPassword,
          'new_password':     newPassword,
        },
        requiresAuth: true,
      );

      if (response.statusCode == 401) {
        return {'success': false, 'error': 'Sesión expirada'};
      }

      final data = jsonDecode(response.body);
      // FIX: verificar data['success'] además del statusCode.
      // Antes solo chequeaba statusCode 200, ignorando { success: false } con 200.
      if (response.statusCode == 200 && data['success'] == true) return data;
      return {
        'success': false,
        'error': data['error'] ??
            _statusMessage(response.statusCode, 'Error al cambiar contraseña'),
      };
    } catch (e) {
      _log('✗ changePassword: $e');
      return {'success': false, 'error': _connectionError(e)};
    }
  }

  // ═══════════════════════════════════════════════════════
  // UTILS
  // ═══════════════════════════════════════════════════════

  /// GET /health — ping rápido sin retry (falla rápido si servidor caído).
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse(AppConstants.buildUrl(AppConstants.healthEndpoint)),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(AppConstants.timeoutShort);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
