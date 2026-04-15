// lib/pages/home_page.dart -
import 'dart:convert';
import 'package:flutter/material.dart';
import 'scan_record.dart';
import 'api_service.dart';
import 'google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart';
import 'hotels_page.dart';
import 'restaurants_page.dart';
import 'bars_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScanRecord? _lastScan;
  bool _loading = true;
  String _userName = '';
  String _userEmail = '';
  int _totalScans = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLastScan();
    _loadUserStats();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user');

      if (userData != null) {
        final user = json.decode(userData); // ✅ AHORA FUNCIONA
        setState(() {
          _userName = user['first_name'] ?? user['username'] ?? 'Usuario';
          _userEmail = user['email'] ?? '';
        });
      } else {
        // Intentar cargar datos individuales
        final userName = prefs.getString('username') ?? 'Usuario';
        final firstName = prefs.getString('first_name') ?? '';
        final email = prefs.getString('email') ?? '';

        setState(() {
          _userName = firstName.isNotEmpty ? firstName : userName;
          _userEmail = email;
        });
      }
    } catch (e) {
      print('❌ Error cargando datos de usuario: $e');
      setState(() {
        _userName = 'Usuario';
        _userEmail = '';
      });
    }
  }

  Future<void> _loadLastScan() async {
    setState(() => _loading = true);
    try {
      final scans = await ApiService.getScanHistory();
      if (scans.isNotEmpty) {
        setState(() => _lastScan = scans.first);
      }
    } catch (e) {
      print('❌ Error cargando último escaneo: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId != null) {
        final scans = await ApiService.getScanHistory();
        setState(() => _totalScans = scans.length);
      }
    } catch (e) {
      print('❌ Error cargando estadísticas: $e');
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performLogout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      final isGoogleUser = await GoogleAuthService.isGoogleUser();
      if (isGoogleUser) {
        await GoogleAuthService.signOut();
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al cerrar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color tealStart = Color(0xFF06B6A4);
    const Color tealEnd = Color(0xFF0EA5E9);

    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth * 0.94;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [tealStart, tealEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: SizedBox(
                width: maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ ENCABEZADO MEJORADO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, $_userName! 👋',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail.isNotEmpty ? _userEmail : 'Bienvenido a Nova App',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                          tooltip: 'Cerrar sesión',
                        )
                      ],
                    ),

                    const SizedBox(height: 32),

                    // BOTONES PRINCIPALES MEJORADOS
                    _buildMenuButton(
                      context,
                      label: 'Escanear QR',
                      icon: Icons.qr_code_scanner,
                      description: 'Escanea códigos QR de lugares',
                      route: '/scan',
                    ),
                    const SizedBox(height: 16),

                    _buildMenuButton(
                      context,
                      label: 'Descubrir Lugares',
                      icon: Icons.explore,
                      description: 'Explora hoteles, restaurantes y bares',
                      route: '/passport',
                    ),
                    const SizedBox(height: 16),

                    _buildMenuButton(
                      context,
                      label: 'Mi Historial',
                      icon: Icons.history,
                      description: 'Revisa tus escaneos anteriores',
                      route: '/history',
                    ),

                    const SizedBox(height: 16),

                    _buildMenuButton(
                      context,
                      label: 'Configuración',
                      icon: Icons.settings,
                      description: 'Ajusta tu perfil y preferencias',
                      route: '/settings',
                    ),

                    const SizedBox(height: 32),

                    // RESUMEN DE ACTIVIDAD MEJORADO
                    Card(
                      clipBehavior: Clip.hardEdge,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.analytics, color: Color(0xFF06B6A4)),
                                SizedBox(width: 8),
                                Text(
                                  'Tu Actividad',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ESTADÍSTICAS RÁPIDAS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(_totalScans.toString(), 'Escaneos', Icons.qr_code),
                                _buildStatItem(_lastScan != null ? '1' : '0', 'Hoy', Icons.today),
                                _buildStatItem(_getPlaceTypeCount(), 'Lugares', Icons.place),
                              ],
                            ),

                            const SizedBox(height: 16),

                            _loading
                                ? const Center(child: CircularProgressIndicator())
                                : _lastScan != null
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Último escaneo:",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6A4).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getPlaceIcon(_lastScan!.type),
                                        color: const Color(0xFF06B6A4),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _lastScan!.local,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF06B6A4),
                                              ),
                                            ),
                                            Text(
                                              _lastScan!.place,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(_lastScan!.time),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                                : const Column(
                              children: [
                                Icon(Icons.qr_code, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Aún no tienes escaneos',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '¡Escanea tu primer código QR!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ACCESO RÁPIDO A LUGARES
                    const Text(
                      'Explorar Lugares',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAccessButton(
                            '🏨 Hoteles',
                            Icons.hotel,
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HotelsPage())),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickAccessButton(
                            '🍽️ Restaurantes',
                            Icons.restaurant,
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RestaurantsPage())),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickAccessButton(
                            '🍹 Bares',
                            Icons.local_bar,
                                () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BarsPage())),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context,
      {required String label, required IconData icon, required String description, required String route}) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF06B6A4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF06B6A4), size: 24),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF06B6A4).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF06B6A4)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF06B6A4),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessButton(String label, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: const Color(0xFF06B6A4)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF06B6A4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel': return Icons.hotel;
      case 'restaurant': return Icons.restaurant;
      case 'bar': return Icons.local_bar;
      default: return Icons.place;
    }
  }

  String _getPlaceTypeCount() {
    // Esto sería mejor calcularlo desde el backend
    return '3';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 30) return 'Hace ${diff.inDays}d';
    return 'Hace ${(diff.inDays / 30).floor()}mes';
  }
}