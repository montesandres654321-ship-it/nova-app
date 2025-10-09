// lib/pages/api_service.dart - VERSIÓN MEJORADA
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'scan_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://172.17.8.124:3000";
  static const int timeoutSeconds = 30;

  static Future<http.Response> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request.timeout(const Duration(seconds: timeoutSeconds));
      return response;
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception("Error de conexión: Verifica tu internet");
      } else {
        throw Exception("Timeout: El servidor no respondió");
      }
    }
  }

  // ✅ CORREGIDO: Ahora filtra por usuario actual
  static Future<List<ScanRecord>> getScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      final response = await _handleRequest(
        http.get(Uri.parse("$baseUrl/scans/details/$userId")),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> scans = data['scans'] ?? [];
          return scans.map((s) => ScanRecord.fromMap(s)).toList();
        } else {
          throw Exception(data['error'] ?? "Error en la respuesta del servidor");
        }
      } else {
        throw Exception("Error ${response.statusCode}: No se pudo obtener el historial");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> registerScan(String qrCode) async {
    try {
      if (!qrCode.startsWith('PLACE:')) {
        throw Exception("Código QR inválido: No es un código de lugar");
      }

      final parts = qrCode.split(":");
      if (parts.length != 2) {
        throw Exception("Formato QR incorrecto");
      }

      final placeId = int.tryParse(parts[1]);
      if (placeId == null) {
        throw Exception("ID de lugar inválido en el QR");
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) {
        throw Exception("Usuario no autenticado. Por favor, inicia sesión nuevamente");
      }

      final response = await _handleRequest(
        http.post(
          Uri.parse("$baseUrl/scan"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "userId": userId,
            "placeId": placeId,
            "qrCode": qrCode,
          }),
        ),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? "Error al registrar escaneo");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<dynamic>> getPlaces() async {
    try {
      final response = await _handleRequest(
        http.get(Uri.parse("$baseUrl/places")),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['places'] ?? [];
        } else {
          throw Exception(data['error'] ?? "Error al cargar lugares");
        }
      } else {
        throw Exception("Error ${response.statusCode}: No se pudieron cargar los lugares");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<bool> checkServerHealth() async {
    try {
      final response = await _handleRequest(
        http.get(Uri.parse("$baseUrl/health")),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}