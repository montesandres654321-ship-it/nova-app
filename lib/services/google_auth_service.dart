// lib/services/google_auth_service.dart
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static final String backendUrl = "http://192.168.2.178:3000";

  // ✅ CORREGIDO: Login con Google mejorado
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Iniciando autenticación con Google...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('🟡 Usuario canceló el login');
        return {
          'success': false,
          'error': 'El usuario canceló el inicio de sesión'
        };
      }

      debugPrint('🟢 Usuario de Google autenticado: ${googleUser.email}');
      debugPrint('📝 ID: ${googleUser.id}');
      debugPrint('👤 Nombre: ${googleUser.displayName}');

      // ✅ CORREGIDO: Sincronizar con el backend
      final backendResult = await _syncWithBackend(googleUser);

      if (backendResult != null && backendResult['success'] == true) {
        final userData = backendResult['user'];

        // ✅ CORREGIDO: Guardar datos completos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userData));
        await prefs.setString('email', userData['email'] ?? '');
        await prefs.setString('username', userData['username'] ?? '');
        await prefs.setString('first_name', userData['first_name'] ?? '');
        await prefs.setString('auth_provider', 'google');
        await prefs.setInt('userId', userData['id']);

        debugPrint('✅ Login con Google exitoso - Datos guardados');

        return {
          'success': true,
          'user': userData,
          'message': backendResult['message'] ?? 'Bienvenido ${userData['first_name'] ?? userData['username']}'
        };
      } else {
        final errorMsg = backendResult?['error'] ?? 'Error al sincronizar con el servidor';
        debugPrint('🔴 Error en backend: $errorMsg');

        // Cerrar sesión de Google si falla
        await _googleSignIn.signOut();

        return {
          'success': false,
          'error': errorMsg
        };
      }

    } catch (error) {
      debugPrint('🔴 Error crítico en Google SignIn: $error');

      // Cerrar sesión de Google si hay error
      await _googleSignIn.signOut();

      return {
        'success': false,
        'error': 'Error al iniciar sesión con Google: $error'
      };
    }
  }

  static Future<Map<String, dynamic>?> _syncWithBackend(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('🌐 Enviando datos al backend...');

      final Map<String, dynamic> requestData = {
        "google_uid": googleUser.id,
        "uid": googleUser.id,
        "email": googleUser.email,
        "name": googleUser.displayName,
        "photoUrl": googleUser.photoUrl,
      };

      debugPrint('📤 Datos enviados: ${jsonEncode(requestData)}');

      final response = await http.post(
        Uri.parse("$backendUrl/users/google-auth"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      debugPrint('📥 Respuesta del backend: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Backend procesó correctamente');
        return result;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? 'Error del servidor: ${response.statusCode}';
        debugPrint('🔴 Error del backend: $errorMsg');

        return {
          'success': false,
          'error': errorMsg
        };
      }
    } catch (e) {
      debugPrint('🔴 Error de conexión: $e');
      return {
        'success': false,
        'error': 'Error de conexión con el servidor: $e'
      };
    }
  }

  // ✅ CORREGIDO: Cerrar sesión mejorado
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Limpiar TODO
      debugPrint('✅ Sesión de Google cerrada y datos limpiados');
    } catch (error) {
      debugPrint('🔴 Error al cerrar sesión: $error');
      // Forzar limpieza incluso si hay error
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    }
  }

  // Verificar si el usuario actual es de Google
  static Future<bool> isGoogleUser() async {
    final prefs = await SharedPreferences.getInstance();
    final authProvider = prefs.getString('auth_provider');
    return authProvider == 'google';
  }

  // Obtener usuario actual
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      return jsonDecode(userData);
    }
    return null;
  }

  // Verificar si hay una sesión activa de Google
  static Future<bool> isSignedIn() async {
    return await _googleSignIn.isSignedIn();
  }

  // Obtener el usuario actual de Google
  static Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    return _googleSignIn.currentUser;
  }
}