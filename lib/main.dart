// lib/main.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';

// Importa todas las páginas
import 'package:nova_app/pages/login_page.dart';
import 'package:nova_app/pages/register_page.dart';
import 'package:nova_app/pages/forgot_password_page.dart';
import 'package:nova_app/pages/home_page.dart';
import 'package:nova_app/pages/scan_page.dart';
import 'package:nova_app/pages/passport_page.dart';
import 'package:nova_app/pages/settings_page.dart';
import 'package:nova_app/pages/hotels_page.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF06B6A4),
          foregroundColor: Colors.white,
        ),
      ),
      // ✅ ELIMINADO: Localizations innecesarias para ahora
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/passport': (context) => const PassportPage(),
        '/settings': (context) => const SettingsPage(),
        '/hotels': (context) => const HotelsPage(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      },
    );
  }
}