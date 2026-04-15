// lib/services/admin_service.dart
// CORRECCIONES:
//  1. getUsersWithDetails: lee raw['data'] no raw['users']
//  2. getMyPlaceScans: ruta /places/my-place/scans
//  3. updateUser: PATCH /admin/users/:id (antes PUT /users/update/:id)
//  4. deactivateUser: DELETE /admin/users/:id — soft delete
//  5. updateMyProfile: PATCH /users/me/profile — cualquier rol
//  6. changePassword: POST /users/me/password (antes /users/change-password no existía)

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/admin_model.dart';
import '../models/admin_stats_model.dart';
import '../utils/constants.dart';

class AdminService {

  // ─── AUTENTICACIÓN ─────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.post<dynamic>(
        '/login',
        body: {'email': email, 'password': password},
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) throw ApiException('Formato inválido');
      final token = data['token'] as String?;
      final user  = data['user']  as Map<String, dynamic>?;
      if (token == null || user == null) throw ApiException('Falta token o user');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyToken,    token);
      await prefs.setString(AppConstants.keyUserName,
          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim());
      await prefs.setString(AppConstants.keyUserEmail, user['email']   as String? ?? '');
      await prefs.setString(AppConstants.keyUserRole,  user['role']    as String? ?? '');
      if (user['id']       != null) await prefs.setInt(AppConstants.keyUserId, user['id'] as int);
      if (user['place_id'] != null) await prefs.setInt('placeId', user['place_id'] as int);
      final userName  = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
      final userEmail = user['email'] as String? ?? '';
      debugPrint('✅ Login: ${user['email']} (${user['role'] ?? 'mobile'})');
      return {
        'success':   true,
        'role':      user['role'],
        'place_id':  user['place_id'],
        'userName':  userName,
        'userEmail': userEmail,
      };
    } catch (e) {
      debugPrint('❌ Login error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyToken);
    await prefs.remove(AppConstants.keyUserName);
    await prefs.remove(AppConstants.keyUserEmail);
    await prefs.remove(AppConstants.keyUserRole);
    await prefs.remove(AppConstants.keyUserId);
    await prefs.remove('placeId');
  }

  static Future<String?> getCurrentRole()   async =>
      (await SharedPreferences.getInstance()).getString(AppConstants.keyUserRole);
  static Future<int?>    getCurrentUserId() async =>
      (await SharedPreferences.getInstance()).getInt(AppConstants.keyUserId);
  static Future<String?> getCurrentEmail()  async =>
      (await SharedPreferences.getInstance()).getString(AppConstants.keyUserEmail);
  static Future<bool> isAdminGeneral() async =>
      (await getCurrentRole()) == AppConstants.roleAdminGeneral;
  static Future<bool> isUserGeneral()  async =>
      (await getCurrentRole()) == AppConstants.roleUserGeneral;
  static Future<bool> isUserPlace()    async =>
      (await getCurrentRole()) == AppConstants.roleUserPlace;
  static Future<bool> hasAdminAccess() async {
    final r = await getCurrentRole();
    return r == AppConstants.roleAdminGeneral || r == AppConstants.roleUserGeneral;
  }

  // ─── USUARIOS MÓVILES ──────────────────────────────────
  static Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final r = await ApiClient.get<dynamic>('/admin/users');
      if (r.data is! List) throw ApiException('Esperaba List');
      return {'success': true, 'users': r.data};
    } catch (e) {
      debugPrint('❌ getAllUsers: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> toggleUserStatus(int userId) async {
    try {
      final r = await ApiClient.patch<dynamic>('/admin/users/$userId/toggle');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      return {'success': true, 'message': d['message'] ?? 'Estado actualizado'};
    } catch (e) {
      debugPrint('❌ toggleUserStatus: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserDetail(int userId) async {
    try {
      final r = await ApiClient.get<dynamic>('/admin/users/$userId');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      return {
        'success':   true,
        'user':      d['user'],
        'scans':     d['scans']     ?? [],
        'rewards':   d['rewards']   ?? [],
        'topPlaces': d['topPlaces'] ?? [],
        'stats':     d['stats']     ?? {},
      };
    } catch (e) {
      debugPrint('❌ getUserDetail: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── ADMINS DEL PANEL ──────────────────────────────────
  static Future<List<AdminStats>> getUsersWithDetails() async {
    try {
      final r = await ApiClient.get<dynamic>('/analytics/admins/users-with-details');
      final raw = r.data;
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic> && raw['data'] is List) {
        list = raw['data'] as List;
      } else {
        list = [];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => AdminStats.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ getUsersWithDetails: $e');
      rethrow;
    }
  }

  // ─── ESTADÍSTICAS DASHBOARD ────────────────────────────
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final r = await ApiClient.get<dynamic>('/stats/dashboard');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      return {'success': true, ...d};
    } catch (e) {
      debugPrint('❌ getDashboardStats: $e');
      return {
        'success': false, 'error': e.toString(),
        'stats': {'users': 0, 'places': 0, 'scans': 0, 'rewards': 0},
        'scansByDay': [], 'topPlaces': [], 'placesByType': {},
      };
    }
  }

  // ─── ESTADÍSTICAS MI LUGAR (user_place) ────────────────
  static Future<Map<String, dynamic>> getMyPlaceStats() async {
    try {
      final r = await ApiClient.get<dynamic>('/places/my-place/stats');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      final inner = d['data'] as Map<String, dynamic>? ?? d;
      return {
        'success':          true,
        'unique_visitors':  inner['uniqueVisitors']  ?? inner['unique_visitors']  ?? 0,
        'total_scans':      inner['totalScans']      ?? inner['total_scans']      ?? 0,
        'total_rewards':    inner['totalRewards']    ?? inner['total_rewards']    ?? 0,
        'redeemed_rewards': inner['redeemedRewards'] ?? inner['redeemed_rewards'] ?? 0,
        'scans_by_day':     inner['scansByDay']      ?? inner['scans_by_day']     ?? [],
      };
    } catch (e) {
      debugPrint('❌ getMyPlaceStats: $e');
      return {
        'success': false, 'error': e.toString(),
        'unique_visitors': 0, 'total_scans': 0,
        'total_rewards': 0, 'redeemed_rewards': 0, 'scans_by_day': [],
      };
    }
  }

  static Future<Map<String, dynamic>> getMyPlaceScans() async {
    try {
      final r = await ApiClient.get<dynamic>('/places/my-place/scans');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      final list = d['data'] as List? ?? (r.data is List ? r.data as List : []);
      return {'success': true, 'scans': list};
    } catch (e) {
      debugPrint('❌ getMyPlaceScans: $e');
      return {'success': false, 'error': e.toString(), 'scans': []};
    }
  }

  static Future<Map<String, dynamic>> getMyPlaceVisitors() async {
    try {
      final r = await ApiClient.get<dynamic>('/places/my-place/visitors');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      final list = d['data'] as List? ?? [];
      return {'success': true, 'visitors': list};
    } catch (e) {
      debugPrint('❌ getMyPlaceVisitors: $e');
      return {'success': false, 'error': e.toString(), 'visitors': []};
    }
  }

  // ─── PERFIL PROPIO (cualquier rol) ────────────────────
  // PATCH /users/me/profile — funciona para admin_general, user_general y user_place
  // El userId viene del token JWT — no puede editar a otro usuario
  static Future<Map<String, dynamic>> updateMyProfile({
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        'first_name': firstName,
        'last_name':  lastName,
      };
      if (phone != null) body['phone'] = phone;
      await ApiClient.patch<dynamic>('/users/me/profile', body: body);
      return {'success': true, 'message': 'Perfil actualizado correctamente'};
    } catch (e) {
      debugPrint('❌ updateMyProfile: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── CONTRASEÑA PROPIA ─────────────────────────────────
  // POST /users/me/password — cualquier rol autenticado
  static Future<Map<String, dynamic>> changePassword({
    required int    userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await ApiClient.post<dynamic>(
        '/users/me/password',
        body: {'current_password': oldPassword, 'new_password': newPassword},
      );
      return {'success': true, 'message': 'Contraseña actualizada exitosamente'};
    } catch (e) {
      debugPrint('❌ changePassword: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── EDITAR PERFIL DE OTRO USUARIO (solo admin_general) ──
  // PATCH /admin/users/:id
  static Future<Map<String, dynamic>> updateUser({
    required int    userId,
    required String firstName,
    required String lastName,
    String? email,
    String? username,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        'first_name': firstName,
        'last_name':  lastName,
      };
      if (phone    != null) body['phone']    = phone;
      if (email    != null) body['email']    = email;
      if (username != null) body['username'] = username;
      await ApiClient.patch<dynamic>('/admin/users/$userId', body: body);
      return {'success': true, 'message': 'Usuario actualizado correctamente'};
    } catch (e) {
      debugPrint('❌ updateUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── DESACTIVAR USUARIO (soft delete) ──────────────────
  static Future<Map<String, dynamic>> deactivateUser(int userId) async {
    try {
      final r = await ApiClient.delete<dynamic>('/admin/users/$userId');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      return {
        'success': true,
        'message': d['message'] ?? 'Usuario desactivado correctamente',
        'data':    d['data'],
      };
    } catch (e) {
      debugPrint('❌ deactivateUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─── PROPIETARIOS Y ADMINS ─────────────────────────────
  static Future<List<AdminModel>> getOwners() async {
    try {
      final r = await ApiClient.get<dynamic>('/api/admins/owners');
      if (r.data is! List) throw ApiException('Esperaba List');
      return (r.data as List)
          .whereType<Map<String, dynamic>>()
          .map((j) => AdminModel.fromJson(j))
          .toList();
    } catch (e) { debugPrint('❌ getOwners: $e'); rethrow; }
  }

  static Future<List<AdminModel>> getOwnersWithoutPlace() async {
    try {
      final r = await ApiClient.get<dynamic>('/api/admins/owners/without-place');
      if (r.data is! List) throw ApiException('Esperaba List');
      return (r.data as List)
          .whereType<Map<String, dynamic>>()
          .map((j) => AdminModel.fromJson(j))
          .toList();
    } catch (e) { debugPrint('❌ getOwnersWithoutPlace: $e'); rethrow; }
  }

  static Future<Map<String, dynamic>> toggleOwnerStatus(int ownerId) async {
    try {
      final r = await ApiClient.patch<dynamic>('/api/admins/$ownerId/toggle');
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      return {'success': true, 'message': d['message'] ?? 'Estado actualizado'};
    } catch (e) {
      debugPrint('❌ toggleOwnerStatus: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    required String role,
    int? placeId,
  }) async {
    try {
      final body = <String, dynamic>{
        'first_name': firstName, 'last_name': lastName,
        'email': email, 'password': password,
        'username': username, 'role': role,
        if (placeId != null) 'place_id': placeId,
      };
      final r = await ApiClient.post<dynamic>('/admin/users/create', body: body);
      final d = r.data;
      if (d is! Map<String, dynamic>) throw ApiException('Formato inválido');
      return {'success': true, 'user': d};
    } catch (e) {
      debugPrint('❌ createUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> changeUserRole(
      int userId, String role, {int? placeId}) async {
    try {
      await ApiClient.patch<dynamic>(
        '/admin/users/$userId/role',
        body: {'role': role, if (placeId != null) 'place_id': placeId},
      );
      return {'success': true};
    } catch (e) {
      debugPrint('❌ changeUserRole: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}