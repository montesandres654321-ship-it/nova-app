import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  // ✅ SIN clientId para desarrollo
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static final String backendUrl = "http://172.17.8.124:3000";

  // Iniciar sesión con Google
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

      // Sincronizar con el backend
      final backendResult = await _syncWithBackend(googleUser);

      if (backendResult != null && backendResult['success'] == true) {
        final userData = backendResult['user'];

        // Guardar en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(userData));
        await prefs.setString('email', userData['email'] ?? '');
        await prefs.setString('username', userData['username'] ?? '');
        await prefs.setString('auth_provider', 'google');
        await prefs.setInt('userId', userData['id']);

        debugPrint('✅ Login con Google exitoso');

        return {
          'success': true,
          'user': userData,
          'message': backendResult['message'] ?? 'Bienvenido ${userData['first_name'] ?? userData['username']}'
        };
      } else {
        final errorMsg = backendResult?['error'] ?? 'Error al sincronizar con el servidor';
        debugPrint('🔴 Error en backend: $errorMsg');
        return {
          'success': false,
          'error': errorMsg
        };
      }

    } catch (error) {
      debugPrint('🔴 Error crítico en Google SignIn: $error');
      return {
        'success': false,
        'error': 'Error al iniciar sesión con Google: $error'
      };
    }
  }

  static Future<Map<String, dynamic>?> _syncWithBackend(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('🌐 Enviando datos al backend...');

      // ✅ ENVIAR AMBOS CAMPOS: google_uid Y uid (para compatibilidad)
      final Map<String, dynamic> requestData = {
        "google_uid": googleUser.id,  // ✅ CORRECTO: lo que el backend espera
        "uid": googleUser.id,         // ✅ MANTENER: por compatibilidad
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
      debugPrint('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Backend procesó correctamente');
        return result;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? 'Error del servidor: ${response.statusCode}';
        debugPrint('🔴 Error del backend: $errorMsg');

        // ✅ INTENTAR REGISTRO NORMAL SI FALLA GOOGLE AUTH
        return await _tryNormalRegistration(googleUser);
      }
    } catch (e) {
      debugPrint('🔴 Error de conexión: $e');
      return {
        'success': false,
        'error': 'Error de conexión con el servidor: $e'
      };
    }
  }

  static Future<Map<String, dynamic>?> _tryNormalRegistration(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('🔄 Intentando registro normal como fallback...');

      // Generar username único
      final baseUsername = googleUser.email?.split('@').first ?? 'user';
      String finalUsername = '${baseUsername}_google';

      // ✅ CORREGIDO: Manejo de null safety
      final displayName = googleUser.displayName ?? 'Google User';
      final nameParts = displayName.split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts[0] : 'Google';
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

      final response = await http.post(
        Uri.parse("$backendUrl/users/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "username": finalUsername,
          "email": googleUser.email,
          "password": "google_auth_${DateTime.now().millisecondsSinceEpoch}",
          "accepted_terms": 1,
        }),
      );

      debugPrint('📥 Respuesta registro normal: ${response.statusCode}');
      debugPrint('📄 Body registro: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('✅ Registro normal exitoso como fallback');
        return result;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['error'] ?? 'Error en registro normal: ${response.statusCode}';
        debugPrint('🔴 Error en registro normal: $errorMsg');
        return {
          'success': false,
          'error': errorMsg
        };
      }
    } catch (e) {
      debugPrint('🔴 Error en registro alternativo: $e');
      return {
        'success': false,
        'error': 'Error en registro alternativo: $e'
      };
    }
  }

  // Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('auth_provider');
      await prefs.remove('userId');
      await prefs.remove('email');
      await prefs.remove('username');
      debugPrint('✅ Sesión de Google cerrada');
    } catch (error) {
      debugPrint('🔴 Error al cerrar sesión: $error');
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