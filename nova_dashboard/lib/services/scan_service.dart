// lib/services/scan_service.dart
// ✅ SERVICIO REFACTORIZADO - Usa ApiClient centralizado

import 'api_client.dart';

/// Servicio para gestión de escaneos de QR
class ScanService {
  // ============================================
  // OBTENER TODOS LOS ESCANEOS
  // ✅ CORRECCIÓN: Validación de tipos completa
  // ============================================

  static Future<List<Map<String, dynamic>>> getAllScans({
    int page = 1,
    int limit = 50,
    int? userId,
    int? placeId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      // Construir query params
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (userId != null) queryParams['user_id'] = userId;
      if (placeId != null) queryParams['place_id'] = placeId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      // ✅ Usar ApiClient con validación automática
      final response = await ApiClient.get<dynamic>(
        '/scans',
        queryParams: queryParams,
      );

      // ✅ VALIDACIÓN: Verificar que data sea List
      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      // ✅ CONVERSIÓN SEGURA
      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error en getAllScans: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESCANEO POR ID
  // ============================================

  static Future<Map<String, dynamic>> getScanById(int id) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/scans/$id',
      );

      // ✅ VALIDACIÓN: Verificar que data sea Map
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      return data;
    } catch (e) {
      print('❌ Error en getScanById: $e');
      rethrow;
    }
  }

  // ============================================
  // CREAR ESCANEO (registrar nuevo escaneo)
  // ============================================

  static Future<Map<String, dynamic>> createScan({
    required int userId,
    required int placeId,
    String? qrData,
  }) async {
    try {
      final response = await ApiClient.post<dynamic>(
        '/scans',
        body: {
          'user_id': userId,
          'place_id': placeId,
          if (qrData != null) 'qr_data': qrData,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      return data;
    } catch (e) {
      print('❌ Error en createScan: $e');
      rethrow;
    }
  }

  // ============================================
  // PROCESAR ESCANEO DE QR
  // (Incluye validación de recompensas)
  // ============================================

  static Future<Map<String, dynamic>> processScan({
    required int userId,
    required String qrCode,
  }) async {
    try {
      final response = await ApiClient.post<dynamic>(
        '/scans/process',
        body: {
          'user_id': userId,
          'qr_code': qrCode,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      // Respuesta esperada:
      // {
      //   "scan": {...},
      //   "reward": {...} o null,
      //   "message": "...",
      //   "earned_reward": true/false
      // }

      return data;
    } catch (e) {
      print('❌ Error en processScan: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESCANEOS POR USUARIO
  // ============================================

  static Future<List<Map<String, dynamic>>> getScansByUser({
    required int userId,
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await ApiClient.get<dynamic>(
        '/users/$userId/scans',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error en getScansByUser: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESCANEOS POR LUGAR
  // ============================================

  static Future<List<Map<String, dynamic>>> getScansByPlace({
    required int placeId,
    int page = 1,
    int limit = 50,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await ApiClient.get<dynamic>(
        '/places/$placeId/scans',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error en getScansByPlace: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESTADÍSTICAS DE ESCANEOS
  // ============================================

  static Future<Map<String, dynamic>> getScanStats({
    String? startDate,
    String? endDate,
    int? placeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (placeId != null) queryParams['place_id'] = placeId;

      final response = await ApiClient.get<dynamic>(
        '/scans/stats',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      return data;
    } catch (e) {
      print('❌ Error en getScanStats: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESCANEOS POR DÍA
  // (Para gráficas de tendencias)
  // ============================================

  static Future<List<Map<String, dynamic>>> getScansByDay({
    int days = 30,
    int? placeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'days': days,
      };

      if (placeId != null) queryParams['place_id'] = placeId;

      final response = await ApiClient.get<dynamic>(
        '/scans/by-day',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error en getScansByDay: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESCANEOS POR HORA
  // (Para análisis de horarios pico)
  // ============================================

  static Future<List<Map<String, dynamic>>> getScansByHour({
    String? date,
    int? placeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (date != null) queryParams['date'] = date;
      if (placeId != null) queryParams['place_id'] = placeId;

      final response = await ApiClient.get<dynamic>(
        '/scans/by-hour',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error en getScansByHour: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESCANEOS RECIENTES
  // ============================================

  static Future<List<Map<String, dynamic>>> getRecentScans({
    int limit = 20,
    int? placeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };

      if (placeId != null) queryParams['place_id'] = placeId;

      final response = await ApiClient.get<dynamic>(
        '/scans/recent',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error en getRecentScans: $e');
      rethrow;
    }
  }

  // ============================================
  // VERIFICAR SI USUARIO YA ESCANEÓ HOY
  // ============================================

  static Future<bool> hasScannedToday({
    required int userId,
    required int placeId,
  }) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/scans/check-today',
        queryParams: {
          'user_id': userId,
          'place_id': placeId,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      final hasScanned = data['has_scanned'];
      if (hasScanned is! bool) {
        throw ApiException(
          'Valor inválido: esperaba bool, recibió ${hasScanned.runtimeType}',
        );
      }

      return hasScanned;
    } catch (e) {
      print('❌ Error en hasScannedToday: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER CONTEO DE ESCANEOS
  // ============================================

  static Future<int> getScanCount({
    int? userId,
    int? placeId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (userId != null) queryParams['user_id'] = userId;
      if (placeId != null) queryParams['place_id'] = placeId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await ApiClient.get<dynamic>(
        '/scans/count',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      final count = data['count'];
      if (count is! int) {
        throw ApiException(
          'Count inválido: esperaba int, recibió ${count.runtimeType}',
        );
      }

      return count;
    } catch (e) {
      print('❌ Error en getScanCount: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER VISITANTES ÚNICOS
  // ============================================

  static Future<int> getUniqueVisitors({
    int? placeId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (placeId != null) queryParams['place_id'] = placeId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await ApiClient.get<dynamic>(
        '/scans/unique-visitors',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      final count = data['count'];
      if (count is! int) {
        throw ApiException(
          'Count inválido: esperaba int, recibió ${count.runtimeType}',
        );
      }

      return count;
    } catch (e) {
      print('❌ Error en getUniqueVisitors: $e');
      rethrow;
    }
  }

  // ============================================
  // ELIMINAR ESCANEO
  // (Solo para admin)
  // ============================================

  static Future<bool> deleteScan(int id) async {
    try {
      final response = await ApiClient.delete<dynamic>(
        '/scans/$id',
      );

      return response.success;
    } catch (e) {
      print('❌ Error en deleteScan: $e');
      rethrow;
    }
  }

  // ============================================
  // EXPORTAR ESCANEOS A CSV
  // ============================================

  static Future<String> exportScansToCSV({
    String? startDate,
    String? endDate,
    int? placeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (placeId != null) queryParams['place_id'] = placeId;

      final response = await ApiClient.get<dynamic>(
        '/scans/export/csv',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! String) {
        throw ApiException(
          'Formato inválido: esperaba String (CSV), recibió ${data.runtimeType}',
        );
      }

      return data;
    } catch (e) {
      print('❌ Error en exportScansToCSV: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ANÁLISIS DE PATRONES
  // (Análisis de comportamiento de usuarios)
  // ============================================

  static Future<Map<String, dynamic>> getScanPatterns({
    int? placeId,
    int days = 30,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'days': days,
      };

      if (placeId != null) queryParams['place_id'] = placeId;

      final response = await ApiClient.get<dynamic>(
        '/scans/patterns',
        queryParams: queryParams,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      // Respuesta esperada:
      // {
      //   "peak_hours": [18, 19, 20],
      //   "peak_days": ["viernes", "sábado"],
      //   "avg_scans_per_day": 45.5,
      //   "total_scans": 1365,
      //   "unique_visitors": 342
      // }

      return data;
    } catch (e) {
      print('❌ Error en getScanPatterns: $e');
      rethrow;
    }
  }
}