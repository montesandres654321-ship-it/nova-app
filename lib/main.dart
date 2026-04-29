// lib/main.dart — Nova App Móvil
// ============================================================
// FIX: eliminada ruta /success estática con datos vacíos
// La navegación a SuccessPage solo se hace con MaterialPageRoute
// desde ScanPage (con datos reales)
// ============================================================

import 'package:flutter/material.dart';
import 'core/design/app_theme.dart';

import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/main_navigation_page.dart';
import 'pages/scan_page.dart';
import 'pages/settings_page.dart';
import 'pages/history_page.dart';
import 'pages/profile_page.dart';
import 'pages/change_password_page.dart';
import 'pages/about_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/':                (context) => const LoginPage(),
        '/register':        (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home':            (context) => const MainNavigationPage(),
        '/scan':            (context) => const ScanPage(),
        '/settings':        (context) => const SettingsPage(),
        '/profile':         (context) => const ProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/about':           (context) => const AboutPage(),
        '/history':         (context) => const HistoryPage(),
        // FIX: /success ELIMINADA — solo se navega con MaterialPageRoute
        // desde ScanPage con datos reales del backend
      },
      onUnknownRoute: (settings) {
        // Si alguien intenta /success por deep link, redirige al login
        return MaterialPageRoute(builder: (context) => const LoginPage());
      },
    );
  }
}