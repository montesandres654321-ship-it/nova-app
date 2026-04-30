// lib/services/user_service.dart
// ============================================================
// Solo endpoints que EXISTEN en el backend:
//   GET    /users                      → lista todos los usuarios
//   GET    /users/:id                  → detalle de un usuario
//   GET    /admin/users                → turistas con stats (admin)
//   GET    /admin/users/:id            → detalle completo (admin)
//   POST   /admin/users/create         → crear usuario del panel
//   PATCH  /admin/users/:id            → editar usuario
//   PATCH  /admin/users/:id/toggle     → activar/desactivar
//   PATCH  /admin/users/:id/role       → cambiar rol
//   DELETE /admin/users/:id            → soft delete
// ============================================================

import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/user_model.dart';

class UserService {

  /// Obtener todos los usuarios — GET /users
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await ApiClient.get<dynamic>('/users');
      final data = response.data;
      if (data is! List) {
        throw ApiException('Formato inválido: esperaba List');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Error en getAllUsers: $e');
      rethrow;
    }
  }

  /// Obtener usuario por ID — GET /users/:id
  static Future<UserModel> getUserById(int id) async {
    try {
      final response = await ApiClient.get<dynamic>('/users/$id');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido: esperaba Map');
      }
      return UserModel.fromJson(data);
    } catch (e) {
      debugPrint('❌ Error en getUserById: $e');
      rethrow;
    }
  }

  /// Obtener turistas con stats — GET /admin/users
  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final response = await ApiClient.get<dynamic>('/admin/users');
      final data = response.data;
      if (data is List) {
        return data.whereType<Map<String, dynamic>>().toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error en getAdminUsers: $e');
      rethrow;
    }
  }

  /// Detalle completo de turista — GET /admin/users/:id
  static Future<Map<String, dynamic>> getAdminUserDetail(int id) async {
    try {
      final response = await ApiClient.get<dynamic>('/admin/users/$id');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido');
      }
      return data;
    } catch (e) {
      debugPrint('❌ Error en getAdminUserDetail: $e');
      rethrow;
    }
  }

  /// Crear usuario del panel — POST /admin/users/create
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
      final response = await ApiClient.post<dynamic>(
        '/admin/users/create',
        body: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'username': username,
          'role': role,
          if (placeId != null) 'place_id': placeId,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido');
      }
      return {'success': true, 'user': data};
    } catch (e) {
      debugPrint('❌ Error en createUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Editar usuario — PATCH /admin/users/:id
  static Future<Map<String, dynamic>> updateUser({
    required int id,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phone != null) body['phone'] = phone;

      await ApiClient.patch<dynamic>('/admin/users/$id', body: body);
      return {'success': true, 'message': 'Usuario actualizado'};
    } catch (e) {
      debugPrint('❌ Error en updateUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Activar/desactivar usuario — PATCH /admin/users/:id/toggle
  static Future<Map<String, dynamic>> toggleUserStatus(int id) async {
    try {
      final response = await ApiClient.patch<dynamic>('/admin/users/$id/toggle');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido');
      }
      return {'success': true, 'message': data['message'] ?? 'Estado actualizado'};
    } catch (e) {
      debugPrint('❌ Error en toggleUserStatus: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Cambiar rol — PATCH /admin/users/:id/role
  static Future<Map<String, dynamic>> changeUserRole(int id, String role, {int? placeId}) async {
    try {
      await ApiClient.patch<dynamic>(
        '/admin/users/$id/role',
        body: {'role': role, if (placeId != null) 'place_id': placeId},
      );
      return {'success': true};
    } catch (e) {
      debugPrint('❌ Error en changeUserRole: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Desactivar usuario (soft delete) — DELETE /admin/users/:id
  static Future<Map<String, dynamic>> deleteUser(int id) async {
    try {
      final response = await ApiClient.delete<dynamic>('/admin/users/$id');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException('Formato inválido');
      }
      return {
        'success': true,
        'message': data['message'] ?? 'Usuario desactivado',
      };
    } catch (e) {
      debugPrint('❌ Error en deleteUser: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}