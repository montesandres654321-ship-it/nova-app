// lib/services/api_service.dart - VERSIÓN CORREGIDA
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'scan_record.dart';

class ApiService {
  static final String backendUrl = "http://172.30.22.4:3000";

  // ✅ CORREGIDO: Obtener historial con userId
  static Future<List<ScanRecord>> getScanHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      final response = await http.get(
        Uri.parse('$backendUrl/scans/details/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          final List<dynamic> scansData = data['scans'];
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

  // ✅ CORREGIDO: Registrar escaneo
  static Future<Map<String, dynamic>> registerScan(String qrCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception("Usuario no autenticado");
      }

      // Extraer placeId del código QR (formato: "PLACE:7")
      final parts = qrCode.split(':');
      if (parts.length != 2) {
        throw Exception("Formato de QR inválido");
      }

      final placeId = int.tryParse(parts[1]);
      if (placeId == null) {
        throw Exception("ID de lugar inválido en QR");
      }

      final response = await http.post(
        Uri.parse('$backendUrl/scan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'placeId': placeId,
          'qrCode': qrCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
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

  // ✅ Login tradicional
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

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

  // ✅ Registro de usuario
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
      );

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
}