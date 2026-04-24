// lib/services/reward_service.dart
// ============================================================
// FIX: IP centralizada + parsing data['data'] + método redeemReward
// ============================================================

import 'api_client.dart';
import '../models/reward_model.dart';

class RewardService {

  /// Obtener todas las recompensas (admin)
  static Future<List<RewardModel>> getAllRewards({String? status}) async {
    try {
      final response = await ApiClient.get<dynamic>('/admin/rewards');
      final data = response.data;

      if (data is List) {
        return data
            .where((item) => item is Map<String, dynamic>)
            .map((json) => RewardModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('❌ Error en getAllRewards: $e');
      return [];
    }
  }

  /// Canjear/entregar una recompensa — PATCH /rewards/:id/redeem
  static Future<Map<String, dynamic>> redeemReward(int rewardId) async {
    try {
      final response = await ApiClient.patch<dynamic>('/rewards/$rewardId/redeem');
      return {'success': true, 'message': response.data?['message'] ?? 'Canjeada'};
    } catch (e) {
      print('❌ Error en redeemReward: $e');
      throw Exception('Error al canjear recompensa: $e');
    }
  }

  /// Estadísticas de recompensas
  static Future<Map<String, int>> getRewardStats() async {
    try {
      final allRewards = await getAllRewards();
      final total = allRewards.length;
      final redeemed = allRewards.where((r) => r.isRedeemedBool).length;
      return {'total': total, 'redeemed': redeemed, 'pending': total - redeemed};
    } catch (e) {
      print('❌ Error en getRewardStats: $e');
      return {'total': 0, 'redeemed': 0, 'pending': 0};
    }
  }

  /// Recompensas pendientes
  static Future<List<RewardModel>> getPendingRewards() async {
    try {
      final allRewards = await getAllRewards();
      return allRewards.where((r) => !r.isRedeemedBool).toList();
    } catch (e) {
      print('❌ Error en getPendingRewards: $e');
      return [];
    }
  }

  /// Recompensas canjeadas
  static Future<List<RewardModel>> getRedeemedRewards() async {
    try {
      final allRewards = await getAllRewards();
      return allRewards.where((r) => r.isRedeemedBool).toList();
    } catch (e) {
      print('❌ Error en getRedeemedRewards: $e');
      return [];
    }
  }

  /// Recompensas por lugar
  static Future<List<RewardModel>> getRewardsByPlace(int placeId) async {
    try {
      final allRewards = await getAllRewards();
      return allRewards.where((r) => r.placeId == placeId).toList();
    } catch (e) {
      print('❌ Error en getRewardsByPlace: $e');
      return [];
    }
  }
}