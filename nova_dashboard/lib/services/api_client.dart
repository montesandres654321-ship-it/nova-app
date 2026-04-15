// lib/services/api_client.dart
// ============================================================
// CLIENTE HTTP CENTRALIZADO — Nova Dashboard
// ============================================================
// CORRECCIONES:
//   • baseUrl: 'localhost:3000' → AppConstants.backendUrl
//   • token: prefs.getString('token') → AppConstants.keyToken
//   • _handleResponse: acepta tanto data:{} como campos directos
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// Cliente HTTP centralizado con manejo robusto de errores
class ApiClient {

  // URL base desde la fuente única de verdad
  static String get baseUrl => AppConstants.backendUrl;
  static const Duration timeout = Duration(seconds: 30);

  // ──────────────────────────────────────────────────────────
  // HEADERS
  // ──────────────────────────────────────────────────────────
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    // ⚠️ Usa AppConstants.keyToken — antes usaba 'token' (inconsistente)
    final token = prefs.getString(AppConstants.keyToken);

    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ──────────────────────────────────────────────────────────
  // MÉTODOS HTTP
  // ──────────────────────────────────────────────────────────

  /// GET request
  static Future<ApiResponse<T>> get<T>(
      String endpoint, {
        Map<String, dynamic>? queryParams,
      }) async {
    try {
      final uri     = _buildUri(endpoint, queryParams);
      final headers = await _getHeaders();
      print('🌐 GET: $uri');
      final response = await http.get(uri, headers: headers).timeout(timeout);
      return _handleResponse<T>(response);
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  /// POST request
  static Future<ApiResponse<T>> post<T>(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    try {
      final uri     = _buildUri(endpoint);
      final headers = await _getHeaders();
      print('🌐 POST: $uri');
      final response = await http
          .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _handleResponse<T>(response);
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  /// PUT request
  static Future<ApiResponse<T>> put<T>(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    try {
      final uri     = _buildUri(endpoint);
      final headers = await _getHeaders();
      print('🌐 PUT: $uri');
      final response = await http
          .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _handleResponse<T>(response);
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  /// PATCH request
  static Future<ApiResponse<T>> patch<T>(
      String endpoint, {
        Map<String, dynamic>? body,
      }) async {
    try {
      final uri     = _buildUri(endpoint);
      final headers = await _getHeaders();
      print('🌐 PATCH: $uri');
      final response = await http
          .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
          .timeout(timeout);
      return _handleResponse<T>(response);
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  /// DELETE request
  static Future<ApiResponse<T>> delete<T>(String endpoint) async {
    try {
      final uri     = _buildUri(endpoint);
      final headers = await _getHeaders();
      print('🌐 DELETE: $uri');
      final response = await http.delete(uri, headers: headers).timeout(timeout);
      return _handleResponse<T>(response);
    } on http.ClientException catch (e) {
      throw ApiException('Error de conexión: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Error inesperado: $e');
    }
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS PRIVADOS
  // ──────────────────────────────────────────────────────────

  /// Construir URI con query parameters
  static Uri _buildUri(String endpoint, [Map<String, dynamic>? queryParams]) {
    final cleanEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    if (queryParams != null && queryParams.isNotEmpty) {
      return Uri.parse('$baseUrl$cleanEndpoint').replace(
        queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())),
      );
    }
    return Uri.parse('$baseUrl$cleanEndpoint');
  }

  /// Procesar respuesta HTTP
  /// ⚠️  CORRECCIÓN CRÍTICA: el backend devuelve { success, data: {...} }
  /// pero algunos endpoints devuelven { success, users: [], places: [], stats: {} }
  /// Este método maneja ambos formatos.
  static ApiResponse<T> _handleResponse<T>(http.Response response) {
    print('📥 Status: ${response.statusCode}');

    if (response.statusCode >= 500) {
      throw ApiException(
        'Error del servidor (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400) {
      try {
        final errorData    = jsonDecode(response.body);
        final errorMessage = errorData is Map
            ? (errorData['error'] ?? 'Error desconocido')
            : 'Error desconocido';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Error del cliente (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    }

    // Parsear JSON
    dynamic jsonData;
    try {
      jsonData = jsonDecode(response.body);
    } catch (e) {
      throw ApiException('Respuesta no es JSON válido: $e');
    }

    if (jsonData is! Map<String, dynamic>) {
      throw ApiException(
        'Formato de respuesta inválido: esperaba Map, recibió ${jsonData.runtimeType}',
      );
    }

    final responseMap = jsonData as Map<String, dynamic>;

    // Verificar campo 'success'
    final success = responseMap['success'];
    if (success == null) {
      throw ApiException('Respuesta sin campo "success"');
    }
    if (success != true) {
      final error = responseMap['error'] ?? 'Error desconocido';
      throw ApiException(error);
    }

    // ── Extraer datos con formato flexible ──────────────────
    // Formato 1: { success: true, data: {...} }  → usa data
    // Formato 2: { success: true, users: [...] } → usa el primer campo que no sea success/error
    dynamic responseData = responseMap['data'];

    if (responseData == null) {
      // Buscar el primer campo de datos que no sea metadatos
      const metaFields = {'success', 'error', 'message', 'meta', 'total'};
      for (final entry in responseMap.entries) {
        if (!metaFields.contains(entry.key)) {
          responseData = entry.value;
          break;
        }
      }
      // Si sigue null, devolver el mapa completo como datos
      responseData ??= responseMap;
    }

    final meta = responseMap['meta'];

    return ApiResponse<T>(
      success: true,
      data:    responseData as T,
      meta:    meta is Map<String, dynamic> ? ApiMeta.fromJson(meta) : null,
    );
  }
}

// ──────────────────────────────────────────────────────────
// MODELOS DE RESPUESTA
// ──────────────────────────────────────────────────────────

class ApiResponse<T> {
  final bool success;
  final T data;
  final ApiMeta? meta;

  ApiResponse({
    required this.success,
    required this.data,
    this.meta,
  });

  @override
  String toString() => 'ApiResponse(success: $success, data: $data, meta: $meta)';
}

class ApiMeta {
  final int? page;
  final int? limit;
  final int? total;
  final int? totalPages;

  ApiMeta({this.page, this.limit, this.total, this.totalPages});

  factory ApiMeta.fromJson(Map<String, dynamic> json) {
    return ApiMeta(
      page:       json['page']       as int?,
      limit:      json['limit']      as int?,
      total:      json['total']      as int?,
      totalPages: json['totalPages'] as int?,
    );
  }

  @override
  String toString() => 'ApiMeta(page: $page, limit: $limit, total: $total, totalPages: $totalPages)';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() {
    if (statusCode != null) return 'ApiException ($statusCode): $message';
    return 'ApiException: $message';
  }
}

extension ApiResponseExtensions<T> on ApiResponse<T> {
  bool get hasPagination => meta != null;
  int  get currentPage   => meta?.page       ?? 1;
  int  get totalPages    => meta?.totalPages  ?? 1;
  bool get hasMorePages  => currentPage < totalPages;
}