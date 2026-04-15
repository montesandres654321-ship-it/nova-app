// lib/services/analytics_service.dart
// CORRECCIONES:
//  1. getScansByDay: usa Uri.replace(queryParameters) en lugar de
//     replaceParams() — backend usa ?days=N no /:days
//  2. getRewardsByDay: idem — usa queryParameters
//  3. getTopPlacesByScans: usa ?limit=N como query param
//  4. getTopPlacesByRewards: idem
//  5. getRewardsStats(): retorna body['stats'] no body completo
//  6. getScansByDay default 180 días para mostrar datos históricos

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AnalyticsService {
  static const String baseUrl = AppConstants.backendUrl;

  // ── JWT Headers ───────────────────────────────────────
  Future<Map<String, String>> getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken) ?? '';
    return {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── REALTIME (stub — endpoint no existe) ──────────────
  // Mantenido por compatibilidad, retorna vacío sin lanzar excepción
  Future<Map<String, dynamic>> getRealTimeAnalytics() async {
    return {'available': false, 'message': 'Endpoint no disponible'};
  }

  // ── CLEAR CACHE (stub) ────────────────────────────────
  Future<void> clearCache() async {
    // No hay endpoint real — no hacer nada
  }

  // ── ESCANEOS STATS ────────────────────────────────────
  Future<Map<String, dynamic>> getScansStats() async {
    try {
      final headers = await getAuthHeaders();
      final url     = Uri.parse('$baseUrl${AppConstants.scansStatsEndpoint}');
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── ESCANEOS POR DÍA ──────────────────────────────────
  // CORRECCIÓN: usa queryParameters — backend: GET /analytics/scans/by-day?days=N
  Future<List<Map<String, dynamic>>> getScansByDay({int days = 180}) async {
    try {
      final headers = await getAuthHeaders();
      // Construir URL con query param ?days=N (no path param :days)
      final url = Uri.parse('$baseUrl/analytics/scans/by-day')
          .replace(queryParameters: {'days': days.toString()});
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data['data'] ?? data['scans'] ?? []);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── TOP LUGARES POR ESCANEOS ──────────────────────────
  // CORRECCIÓN: usa ?limit=N como query param
  Future<List<Map<String, dynamic>>> getTopPlacesByScans({int limit = 10}) async {
    try {
      final headers = await getAuthHeaders();
      final url = Uri.parse('$baseUrl/analytics/scans/top-places')
          .replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['places'] ?? []);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── ESCANEOS POR HORA ─────────────────────────────────
  Future<List<Map<String, dynamic>>> getScansByHour() async {
    try {
      final headers = await getAuthHeaders();
      final url     = Uri.parse('$baseUrl/analytics/scans/by-hour');
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── RECOMPENSAS STATS ─────────────────────────────────
  // CORRECCIÓN: retorna body['stats'] — backend: { success, stats: {...} }
  // rewards_page lee _stats['total_rewards'] directamente
  Future<Map<String, dynamic>> getRewardsStats() async {
    try {
      final headers  = await getAuthHeaders();
      final url      = Uri.parse('$baseUrl${AppConstants.rewardsStatsEndpoint}');
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Extraer el objeto 'stats' anidado
        if (body.containsKey('stats') && body['stats'] is Map) {
          return body['stats'] as Map<String, dynamic>;
        }
        return body; // fallback si ya viene plano
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── RECOMPENSAS POR DÍA ───────────────────────────────
  // CORRECCIÓN: usa ?days=N como query param
  Future<List<Map<String, dynamic>>> getRewardsByDay({int days = 30}) async {
    try {
      final headers = await getAuthHeaders();
      final url = Uri.parse('$baseUrl/analytics/rewards/by-day')
          .replace(queryParameters: {'days': days.toString()});
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(
            data['data'] ?? data['rewards'] ?? []);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── TOP LUGARES POR RECOMPENSAS ───────────────────────
  // CORRECCIÓN: usa ?limit=N como query param
  Future<List<Map<String, dynamic>>> getTopPlacesByRewards({int limit = 10}) async {
    try {
      final headers = await getAuthHeaders();
      final url = Uri.parse('$baseUrl/analytics/rewards/top-places')
          .replace(queryParameters: {'limit': limit.toString()});
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['places'] ?? []);
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── RECOMPENSAS POR TIPO ──────────────────────────────
  Future<Map<String, dynamic>?> getRewardsByType() async {
    try {
      final headers  = await getAuthHeaders();
      final url      = Uri.parse('$baseUrl/analytics/rewards/by-type');
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['data'] as Map<String, dynamic>? ?? body;
      }
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── USUARIOS STATS ────────────────────────────────────
  Future<Map<String, dynamic>> getUsersStats() async {
    try {
      final headers  = await getAuthHeaders();
      final url      = Uri.parse('$baseUrl/analytics/users/stats');
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }

  // ── LUGARES STATS ─────────────────────────────────────
  Future<Map<String, dynamic>> getPlacesStats() async {
    try {
      final headers  = await getAuthHeaders();
      final url      = Uri.parse('$baseUrl/analytics/places/stats');
      final response = await http.get(url, headers: headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Error ${response.statusCode}');
    } catch (e) { throw Exception('Error de red: $e'); }
  }
}