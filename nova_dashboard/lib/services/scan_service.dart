// lib/services/scan_service.dart
// ============================================================
// Solo endpoints que EXISTEN en el backend:
//   POST /scan                    → registrar escaneo
//   GET  /scans/details/:userId   → historial del usuario
//   POST /qr/validate             → validar QR sin registrar
//   GET  /analytics/scans/by-day  → escaneos por día
//   GET  /analytics/scans/by-hour → escaneos por hora
//   GET  /analytics/scans/top-places → top lugares por escaneos
// ============================================================

import 'package:flutter/foundation.dart';
import 'api_client.dart';

class ScanService {

  /// Registrar un escaneo — POST /scan
  static Future<Map<String, dynamic>> registerScan({
    required int placeId,
  }) async {
    try {
      final response = await ApiClient.post<dynamic>(
        '/scan',
        body: {'place_id': placeId},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido');
      }
      return data;
    } catch (e) {
      debugPrint('❌ Error en registerScan: $e');
      rethrow;
    }
  }

  /// Historial de escaneos del usuario — GET /scans/details/:userId
  static Future<Map<String, dynamic>> getScanHistory(int userId) async {
    try {
      final response = await ApiClient.get<dynamic>('/scans/details/$userId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return {
          'scans': data['data'] ?? data['scans'] ?? [],
          'stats': data['stats'] ?? {},
        };
      }
      if (data is List) {
        return {'scans': data, 'stats': {}};
      }
      return {'scans': [], 'stats': {}};
    } catch (e) {
      debugPrint('❌ Error en getScanHistory: $e');
      rethrow;
    }
  }

  /// Validar QR sin registrar — POST /qr/validate
  static Future<Map<String, dynamic>> validateQR(String qrData) async {
    try {
      final response = await ApiClient.post<dynamic>(
        '/qr/validate',
        body: {'qr_data': qrData},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido');
      }
      return data;
    } catch (e) {
      debugPrint('❌ Error en validateQR: $e');
      rethrow;
    }
  }

  /// Escaneos por día — GET /analytics/scans/by-day?days=N
  static Future<List<Map<String, dynamic>>> getScansByDay({int days = 30}) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/analytics/scans/by-day',
        queryParams: {'days': days.toString()},
      );
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error en getScansByDay: $e');
      rethrow;
    }
  }

  /// Escaneos por hora — GET /analytics/scans/by-hour
  static Future<List<Map<String, dynamic>>> getScansByHour() async {
    try {
      final response = await ApiClient.get<dynamic>('/analytics/scans/by-hour');
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error en getScansByHour: $e');
      rethrow;
    }
  }

  /// Top lugares por escaneos — GET /analytics/scans/top-places?limit=N
  static Future<List<Map<String, dynamic>>> getTopPlaces({int limit = 10}) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/analytics/scans/top-places',
        queryParams: {'limit': limit.toString()},
      );
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      if (data is Map<String, dynamic>) {
        final places = data['places'] as List?;
        if (places != null) return places.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error en getTopPlaces: $e');
      rethrow;
    }
  }
}