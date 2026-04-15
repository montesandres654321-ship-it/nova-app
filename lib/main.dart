// lib/main.dart
import 'package:flutter/material.dart';

// Importa todas las páginas
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/home_page.dart';
import 'pages/scan_page.dart';
import 'pages/passport_page.dart';
import 'pages/settings_page.dart';
import 'pages/hotels_page.dart';
import 'pages/restaurants_page.dart';
import 'pages/bars_page.dart';
import 'pages/history_page.dart';
import 'pages/profile_page.dart';
import 'pages/change_password_page.dart';
import 'pages/about_page.dart';
import 'pages/success_page.dart';

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
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF06B6A4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const HomePage(),
        '/scan': (context) => const ScanPage(),
        '/passport': (context) => const PassportPage(),
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/about': (context) => const AboutPage(),
        '/history': (context) => const HistoryPage(),
        '/hotels': (context) => const HotelsPage(),
        '/restaurants': (context) => const RestaurantsPage(),
        '/bars': (context) => const BarsPage(),
        '/success': (context) => const SuccessPage(code: '', backendData: {}),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginPage(),
        );
      },
    );
  }
}