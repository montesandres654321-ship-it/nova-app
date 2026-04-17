// lib/services/image_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  static const String baseUrl = 'http://192.168.18.6:3000';

  // ✅ Obtener token de autenticación
  static Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('admin_token');
    } catch (e) {
      debugPrint('Error obteniendo token: $e');
      return null;
    }
  }

  // 📸 Método simplificado para web
  Future<Map<String, dynamic>> pickImage() async {
    try {
      // En web, simplemente retornamos un mapa indicando que se necesita upload
      return {
        'needsUpload': true,
        'message': 'Use el botón de selección de archivos'
      };
    } catch (e) {
      debugPrint('Error en pickImage: $e');
      return {
        'needsUpload': false,
        'error': 'Error seleccionando imagen: $e'
      };
    }
  }

  // ☁️ SUBIR IMAGEN DESDE BYTES (para web)
  Future<Map<String, dynamic>> uploadImageFromBytes(List<int> imageBytes, String filename) async {
    try {
      final token = await _getAuthToken();

      // Crear request multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/upload'),
      );

      request.headers['Authorization'] = token ?? '';
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final data = json.decode(responseData);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'imageUrl': data['image']['url'],
          'message': 'Imagen subida exitosamente',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Error subiendo imagen',
        };
      }
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return {
        'success': false,
        'error': 'Error de conexión: $e',
      };
    }
  }

  // ☁️ SUBIR IMAGEN DESDE URL (para imágenes existentes)
  Future<Map<String, dynamic>> uploadImageFromUrl(String imageUrl) async {
    try {
      // Simular upload exitoso para URLs existentes
      await Future.delayed(const Duration(milliseconds: 500));

      return {
        'success': true,
        'imageUrl': imageUrl,
        'message': 'Imagen existente preservada',
      };
    } catch (e) {
      debugPrint('Error procesando imagen URL: $e');
      return {
        'success': false,
        'error': 'Error procesando imagen: $e',
      };
    }
  }

  // 🖼️ Obtener imagen por tipo (fallback)
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