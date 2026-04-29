// lib/services/image_service.dart
// ============================================================
// FIX 1: URL usa AppConstants.backendUrl (no hardcodeada)
// FIX 2: Token usa AppConstants.keyToken = 'auth_token' (no 'admin_token')
// FIX 3: Endpoint usa /admin/upload-image (no /admin/upload)
// FIX 4: Parsing respuesta: backend devuelve imageUrl en raíz, no data['image']['url']
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

class ImageService {
  // FIX 1: URL centralizada desde AppConstants
  static String get baseUrl => AppConstants.backendUrl;

  // FIX 2: Token con clave correcta
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.keyToken); // 'auth_token'
    } catch (e) {
      debugPrint('Error obteniendo token: $e');
      return null;
    }
  }

  // 📸 Método para selección de imagen en web
  Future<Map<String, dynamic>> pickImage() async {
    try {
      return {
        'needsUpload': true,
        'message': 'Use el botón de selección de archivos',
      };
    } catch (e) {
      debugPrint('Error en pickImage: $e');
      return {'needsUpload': false, 'error': 'Error seleccionando imagen: $e'};
    }
  }

  // ☁️ SUBIR IMAGEN DESDE BYTES (para web)
  Future<Map<String, dynamic>> uploadImageFromBytes(List<int> imageBytes, String filename) async {
    try {
      final token = await _getAuthToken();

      if (token == null || token.isEmpty) {
        return {'success': false, 'error': 'No hay token de autenticación. Inicie sesión nuevamente.'};
      }

      // FIX 3: Endpoint correcto
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/upload-image'),
      );

      // FIX 2: Header con Bearer token
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ));

      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
        // FIX 4: Backend devuelve imageUrl y image_url en raíz
        final imageUrl = data['imageUrl'] ?? data['image_url'] ?? '';

        return {
          'success': true,
          'imageUrl': imageUrl,
          'message': data['message'] ?? 'Imagen subida exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error subiendo imagen (${response.statusCode})',
        };
      }
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ☁️ SUBIR IMAGEN DESDE URL (para imágenes existentes)
  Future<Map<String, dynamic>> uploadImageFromUrl(String imageUrl) async {
    try {
      return {
        'success': true,
        'imageUrl': imageUrl,
        'message': 'Imagen existente preservada',
      };
    } catch (e) {
      debugPrint('Error procesando imagen URL: $e');
      return {'success': false, 'error': 'Error procesando imagen: $e'};
    }
  }

  // 🖼️ Imagen por tipo (fallback)
  static String getImageByType(String type) {
    switch (type) {
      case 'hotel':
        return 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&h=300&fit=crop';
      case 'restaurant':
        return 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400&h=300&fit=crop';
      case 'bar':
        return 'https://images.unsplash.com/photo-1572116469696-31de0f17cc34?w=400&h=300&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=400&h=300&fit=crop';
    }
  }
}