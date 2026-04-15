// lib/services/reward_service.dart
// CORRECCIONES:
//  1. IP: '192.168.2.180' → AppConstants.backendUrl
//  2. Lee data['data'] no data['rewards'] — backend devuelve { success, data:[...] }
//  3. Agrega Authorization header con token JWT
//  4. FIX: extension static method → función privada _rewardFromAdminJson()
//     (Dart no permite llamar métodos estáticos de extension como RewardModel.fromJson())
//     El backend /admin/rewards usa alias: place_tipo, place_lugar, user_email

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reward_model.dart';
import '../utils/constants.dart';

// ── Función privada de parseo para /admin/rewards ──────────
// Maneja los alias del backend:
//   place_tipo  → placeType
//   place_lugar → lugar
//   user_email  → email
RewardModel _rewardFromAdminJson(Map<String, dynamic> json) {
  return RewardModel(
    id:                json['id']                 ?? 0,
    userId:            json['user_id']            ?? 0,
    placeId:           json['place_id']           ?? 0,
    rewardName:        json['reward_name']        ?? '',
    rewardDescription: json['reward_description'],
    rewardIcon:        json['reward_icon'],
    earnedAt:          json['earned_at']          ?? '',
    isRedeemed:        json['is_redeemed']        ?? 0,
    redeemedAt:        json['redeemed_at'],
    firstName:         json['first_name'],
    lastName:          json['last_name'],
    email:             json['user_email'] ?? json['email'],
    placeName:         json['place_name'],
    placeType:         json['place_tipo'] ?? json['place_type'],
    lugar:             json['place_lugar'] ?? json['lugar'],
  );
}

class RewardService {

  // ── Headers con JWT ───────────────────────────────────
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyToken) ?? '';
    return {
      'Content-Type':  'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Obtener todas las recompensas ─────────────────────
  // GET /admin/rewards → { success, data: [...] }
  static Future<List<RewardModel>> getAllRewards({String? status}) async {
    try {
      final headers = await _getHeaders();
      String url = '${AppConstants.backendUrl}/admin/rewards';
      if (status != null) url += '?status=$status';

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 401) {
        throw Exception('Sin autorización — token inválido o expirado');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final rawList = data['data'];
          if (rawList is List) {
            // ← usa función libre, no extension
            return rawList
                .map((json) => _rewardFromAdminJson(json as Map<String, dynamic>))
                .toList();
          }
        }
      }

      return [];
    } catch (e) {
      print('❌ Error en getAllRewards: $e');
      rethrow;
    }
  }

  // ── Estadísticas calculadas desde la lista ────────────
  static Future<Map<String, int>> getRewardStats() async {
    try {
      final all      = await getAllRewards();
      final total    = all.length;
      final redeemed = all.where((r) => r.isRedeemedBool).length;
      return {'total': total, 'redeemed': redeemed, 'pending': total - redeemed};
    } catch (e) {
      print('❌ Error en getRewardStats: $e');
      return {'total': 0, 'redeemed': 0, 'pending': 0};
    }
  }

  // ── Recompensas pendientes ────────────────────────────
  static Future<List<RewardModel>> getPendingRewards() async {
    try {
      return (await getAllRewards()).where((r) => !r.isRedeemedBool).toList();
    } catch (e) {
      print('❌ Error en getPendingRewards: $e');
      return [];
    }
  }

  // ── Recompensas canjeadas ─────────────────────────────
  static Future<List<RewardModel>> getRedeemedRewards() async {
    try {
      return (await getAllRewards()).where((r) => r.isRedeemedBool).toList();
    } catch (e) {
      print('❌ Error en getRedeemedRewards: $e');
      return [];
    }
  }

  // ── Recompensas por lugar ─────────────────────────────
  static Future<List<RewardModel>> getRewardsByPlace(int placeId) async {
    try {
      return (await getAllRewards()).where((r) => r.placeId == placeId).toList();
    } catch (e) {
      print('❌ Error en getRewardsByPlace: $e');
      return [];
    }
  }

  // ── Recompensas por usuario ───────────────────────────
  static Future<List<RewardModel>> getRewardsByUser(int userId) async {
    try {
      return (await getAllRewards()).where((r) => r.userId == userId).toList();
    } catch (e) {
      print('❌ Error en getRewardsByUser: $e');
      return [];
    }
  }
}