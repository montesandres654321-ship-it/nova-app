// lib/services/google_auth_service.dart
// ============================================================
// SERVICIO DE AUTENTICACIÓN GOOGLE — Nova App Móvil
// ============================================================
// Usa AppConstants para IP y keys
// Guarda token JWT tras login exitoso
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Login completo con Google: autenticar + sincronizar con backend
  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      debugPrint('🔵 Iniciando autenticación con Google...');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Inicio de sesión cancelado'};
      }

      debugPrint('🟢 Google autenticado: ${googleUser.email}');

      // Sincronizar con backend
      final backendResult = await _syncWithBackend(googleUser);

      if (backendResult != null && backendResult['success'] == true) {
        // Backend devuelve token y user en raíz Y en data.data
        final inner = backendResult['data'];
        final userData = backendResult['user'] ?? inner?['user'];
        final token = backendResult['token'] ?? inner?['token'];

        // Guardar datos en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (token != null) await prefs.setString(AppConstants.keyToken, token);
        if (userData != null) {
          await prefs.setString(AppConstants.keyUser, jsonEncode(userData));
          await prefs.setString(AppConstants.keyEmail, userData['email'] ?? '');
          await prefs.setString(AppConstants.keyUsername, userData['username'] ?? '');
          await prefs.setString(AppConstants.keyFirstName, userData['first_name'] ?? '');
          await prefs.setString(AppConstants.keyAuthProvider, 'google');
          if (userData['id'] != null) await prefs.setInt(AppConstants.keyUserId, userData['id']);
        }

        debugPrint('✅ Login Google exitoso');
        return {
          'success': true,
          'user': userData,
          'message': 'Bienvenido ${userData?['first_name'] ?? userData?['username'] ?? ''}',
        };
      } else {
        await _googleSignIn.signOut();
        return {
          'success': false,
          'error': backendResult?['error'] ?? 'Error al sincronizar con el servidor',
        };
      }
    } catch (error) {
      debugPrint('🔴 Error en Google SignIn: $error');
      await _googleSignIn.signOut();
      return {'success': false, 'error': 'Error: $error'};
    }
  }

  /// Sincronizar usuario Google con el backend
  static Future<Map<String, dynamic>?> _syncWithBackend(GoogleSignInAccount googleUser) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.buildUrl(AppConstants.googleAuthEndpoint)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'google_uid': googleUser.id,
          'uid': googleUser.id,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'photoUrl': googleUser.photoUrl,
        }),
      ).timeout(AppConstants.timeoutNormal);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'error': errorData['error'] ?? 'Error del servidor'};
      }
    } catch (e) {
      debugPrint('🔴 Error de conexión: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Verificar si el usuario actual es de Google
  static Future<bool> isGoogleUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.keyAuthProvider) == 'google';
  }

  /// Obtener usuario actual desde SharedPreferences
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.keyUser);
    if (userData != null) return jsonDecode(userData);
    return null;
  }

  /// Verificar si hay sesión activa de Google
  static Future<bool> isSignedIn() async => await _googleSignIn.isSignedIn();
}