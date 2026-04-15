// lib/services/user_service.dart
// ✅ SERVICIO REFACTORIZADO - Usa ApiClient centralizado

import 'api_client.dart';
import '../models/user_model.dart';

/// Servicio para gestión de usuarios normales (no admins)
class UserService {
  // ============================================
  // OBTENER TODOS LOS USUARIOS
  // ✅ CORRECCIÓN: Validación de tipos completa
  // ============================================

  static Future<List<UserModel>> getAllUsers({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      // ✅ Usar ApiClient con validación automática
      final response = await ApiClient.get<dynamic>(
        '/users',
        queryParams: {
          'page': page,
          'limit': limit,
        },
      );

      // ✅ VALIDACIÓN: Verificar que data sea List
      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      // ✅ CONVERSIÓN SEGURA: Mapear a UserModel
      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error en getAllUsers: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER USUARIO POR ID
  // ============================================

  static Future<UserModel> getUserById(int id) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/$id',
      );

      // ✅ VALIDACIÓN: Verificar que data sea Map
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      return UserModel.fromJson(data);
    } catch (e) {
      print('❌ Error en getUserById: $e');
      rethrow;
    }
  }

  // ============================================
  // CREAR USUARIO
  // ============================================

  static Future<UserModel> createUser({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    try {
      final response = await ApiClient.post<dynamic>(
        '/users',
        body: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null) 'phone': phone,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      return UserModel.fromJson(data);
    } catch (e) {
      print('❌ Error en createUser: $e');
      rethrow;
    }
  }

  // ============================================
  // ACTUALIZAR USUARIO
  // ============================================

  static Future<UserModel> updateUser({
    required int id,
    String? username,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? phone,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (phone != null) body['phone'] = phone;
      if (isActive != null) body['is_active'] = isActive;

      final response = await ApiClient.put<dynamic>(
        '/users/$id',
        body: body,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      return UserModel.fromJson(data);
    } catch (e) {
      print('❌ Error en updateUser: $e');
      rethrow;
    }
  }

  // ============================================
  // ELIMINAR USUARIO (SOFT DELETE)
  // ============================================

  static Future<bool> deleteUser(int id) async {
    try {
      final response = await ApiClient.delete<dynamic>(
        '/users/$id',
      );

      return response.success;
    } catch (e) {
      print('❌ Error en deleteUser: $e');
      rethrow;
    }
  }

  // ============================================
  // ACTIVAR/DESACTIVAR USUARIO
  // ============================================

  static Future<bool> toggleUserStatus(int id, bool isActive) async {
    try {
      final response = await ApiClient.put<dynamic>(
        '/users/$id/status',
        body: {
          'is_active': isActive,
        },
      );

      return response.success;
    } catch (e) {
      print('❌ Error en toggleUserStatus: $e');
      rethrow;
    }
  }

  // ============================================
  // BUSCAR USUARIOS
  // ============================================

  static Future<List<UserModel>> searchUsers({
    required String query,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/search',
        queryParams: {
          'q': query,
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error en searchUsers: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESTADÍSTICAS DE USUARIO
  // ============================================

  static Future<Map<String, dynamic>> getUserStats(int userId) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/$userId/stats',
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Formato inválido: esperaba Map, recibió ${data.runtimeType}',
        );
      }

      return data;
    } catch (e) {
      print('❌ Error en getUserStats: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER ESCANEOS DEL USUARIO
  // ============================================

  static Future<List<Map<String, dynamic>>> getUserScans({
    required int userId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/$userId/scans',
        queryParams: {
          'page': page,
          'limit': limit,
        },
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
      print('❌ Error en getUserScans: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER RECOMPENSAS DEL USUARIO
  // ============================================

  static Future<List<Map<String, dynamic>>> getUserRewards({
    required int userId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/$userId/rewards',
        queryParams: {
          'page': page,
          'limit': limit,
        },
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
      print('❌ Error en getUserRewards: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER LUGARES VISITADOS
  // ============================================

  static Future<List<Map<String, dynamic>>> getUserVisitedPlaces({
    required int userId,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/$userId/visited-places',
        queryParams: {
          'page': page,
          'limit': limit,
        },
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
      print('❌ Error en getUserVisitedPlaces: $e');
      rethrow;
    }
  }

  // ============================================
  // RESETEAR CONTRASEÑA
  // ============================================

  static Future<bool> resetPassword({
    required int userId,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.put<dynamic>(
        '/users/$userId/reset-password',
        body: {
          'new_password': newPassword,
        },
      );

      return response.success;
    } catch (e) {
      print('❌ Error en resetPassword: $e');
      rethrow;
    }
  }

  // ============================================
  // OBTENER USUARIOS ACTIVOS (últimos 30 días)
  // ============================================

  static Future<List<UserModel>> getActiveUsers({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/active',
        queryParams: {
          'page': page,
          'limit': limit,
        },
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Formato inválido: esperaba List, recibió ${data.runtimeType}',
        );
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error en getActiveUsers: $e');
      rethrow;
    }
  }

  // ============================================
  // EXPORTAR USUARIOS A CSV
  // ============================================

  static Future<String> exportUsersToCSV() async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/users/export/csv',
      );

      final data = response.data;
      if (data is! String) {
        throw ApiException(
          'Formato inválido: esperaba String (CSV), recibió ${data.runtimeType}',
        );
      }

      return data;
    } catch (e) {
      print('❌ Error en exportUsersToCSV: $e');
      rethrow;
    }
  }
}