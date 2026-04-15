// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/users_page.dart';
import 'pages/user_detail_page.dart';
import 'pages/rewards_page.dart';
import 'pages/scans_page.dart';
import 'pages/reports_page.dart';
import 'pages/places/list_tab.dart';
import 'pages/owners/dashboard_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6A4),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {

        // ── CORRECCIÓN: ruta raíz redirige a login ──────
        // Evita el 404 al refrescar el navegador en Flutter Web
        if (settings.name == '/' || settings.name == null) {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }

        // ── RUTAS PÚBLICAS ─────────────────────────────
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        }

        // ── RUTAS PANEL ADMIN / SECRETARÍA ─────────────
        if (settings.name == '/dashboard') {
          return MaterialPageRoute(builder: (_) => const DashboardPage());
        }

        if (settings.name == '/users') {
          return MaterialPageRoute(builder: (_) => const UsersPage());
        }

        if (settings.name == '/rewards') {
          return MaterialPageRoute(builder: (_) => const RewardsPage());
        }

        if (settings.name == '/scans') {
          return MaterialPageRoute(builder: (_) => const ScansPage());
        }

        if (settings.name == '/reports') {
          return MaterialPageRoute(builder: (_) => const ReportsPage());
        }

        if (settings.name == '/places') {
          return MaterialPageRoute(
            builder: (_) => const PlacesListTab(canEdit: true),
          );
        }

        if (settings.name == '/user-detail') {
          final userId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (_) => UserDetailPage(userId: userId),
          );
        }

        // ── RUTA PROPIETARIO (user_place) ───────────────
        if (settings.name == '/owner-dashboard') {
          final args = settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return _buildErrorRoute('Acceso no autorizado',
                'Esta ruta requiere autenticación como propietario.');
          }

          final placeId = args['placeId'] as int?;
          if (placeId == null) {
            return _buildErrorRoute('Lugar no asignado',
                'Su usuario no tiene un lugar asignado. Contacte al administrador.');
          }

          return MaterialPageRoute(
            builder: (context) => OwnerDashboardPage(
              userName:  args['userName']  ?? '',
              userEmail: args['userEmail'] ?? '',
              placeId:   placeId,
              onLogout: () {
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          );
        }

        // ── 404 ────────────────────────────────────────
        return _buildErrorRoute(
          '404 - Página no encontrada',
          'La ruta "${settings.name}" no existe.',
        );
      },
    );
  }

  MaterialPageRoute _buildErrorRoute(String title, String message) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/login'),
                  icon: const Icon(Icons.home),
                  label: const Text('Ir al Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6A4),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}