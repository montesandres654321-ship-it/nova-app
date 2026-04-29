// lib/main.dart
import 'package:flutter/material.dart';
import 'core/design/app_theme.dart';

// Importa todas las páginas
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
      theme: AppTheme.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/home': (context) => const MainNavigationPage(),
        '/scan': (context) => const ScanPage(),
        '/settings': (context) => const SettingsPage(),
        '/profile': (context) => const ProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/about': (context) => const AboutPage(),
        '/history': (context) => const HistoryPage(),
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