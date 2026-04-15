// lib/services/owner_service.dart
// ✅ Servicio para gestión de propietarios (SIN DUPLICACIONES)

import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/admin_model.dart';

/// Servicio para gestión de propietarios
class OwnerService {
  /// Obtener todos los propietarios (admins con rol)
  static Future<List<AdminModel>> getAllOwners() async {
    try {
      final response = await ApiClient.get<dynamic>('/api/admins/owners');

      final data = response.data;

      if (data is! List) {
        throw ApiException('Formato inválido: esperaba List');
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => AdminModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error en getAllOwners: $e');
      rethrow;
    }
  }

  /// Alternar estado de propietario
  static Future<bool> toggleOwnerStatus(int ownerId) async {
    try {
      final response = await ApiClient.patch<dynamic>(
        '/api/admins/$ownerId/toggle',
      );

      return response.success;
    } catch (e) {
      debugPrint('❌ Error en toggleOwnerStatus: $e');
      rethrow;
    }
  }

  /// Obtener propietarios sin lugar asignado
  static Future<List<AdminModel>> getOwnersWithoutPlace() async {
    try {
      final response = await ApiClient.get<dynamic>(
        '/api/admins/owners/without-place',
      );

      final data = response.data;

      if (data is! List) {
        throw ApiException('Formato inválido: esperaba List');
      }

      return data
          .where((item) => item is Map<String, dynamic>)
          .map((json) => AdminModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Error en getOwnersWithoutPlace: $e');
      return [];
    }
  }
}