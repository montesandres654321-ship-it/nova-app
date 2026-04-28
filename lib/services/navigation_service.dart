// lib/services/navigation_service.dart
// Clave global de navegación para redirecciones desde ApiService (401, etc.)

import 'package:flutter/material.dart';

class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void goToLogin() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (_) => false);
  }
}
