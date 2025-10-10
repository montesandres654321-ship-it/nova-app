// lib/pages/home_page.dart - VERSIÓN COMPLETAMENTE CORREGIDA
import 'package:flutter/material.dart';
import 'scan_record.dart';
import 'api_service.dart';
import 'google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLastScan();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('username') ?? 'Usuario';
      final firstName = prefs.getString('first_name') ?? '';
      final email = prefs.getString('email') ?? '';

      setState(() {
        _userName = firstName.isNotEmpty ? firstName : userName;
        _userEmail = email;
      });
    } catch (e) {
      print('❌ Error cargando datos de usuario: $e');
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

  Future<void> _logout() async {
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
        const SnackBar(content: Text('Error al cerrar sesión')),
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
                    // ✅ CORREGIDO: Encabezado mejorado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola, $_userName!',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _userEmail.isNotEmpty ? _userEmail : 'Bienvenido a Nova App',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 28),
                          tooltip: 'Cerrar sesión',
                        )
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Botones principales
                    _menuButton(
                      context,
                      label: 'Escanear QR',
                      icon: Icons.qr_code_scanner,
                      route: '/scan',
                    ),
                    const SizedBox(height: 16),

                    _menuButton(
                      context,
                      label: 'Mi Pasaporte',
                      icon: Icons.card_travel,
                      route: '/passport',
                    ),
                    const SizedBox(height: 16),

                    _menuButton(
                      context,
                      label: 'Configuración',
                      icon: Icons.settings,
                      route: '/settings',
                    ),

                    const SizedBox(height: 32),

                    // Resumen rápido
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
                                Icon(Icons.history, color: Color(0xFF06B6A4)),
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
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _lastScan!.local,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF06B6A4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _lastScan!.place,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Hace: ${_timeAgo(_lastScan!.time)}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                                : const Column(
                              children: [
                                Icon(Icons.qr_code, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'Aún no tienes escaneos',
                                  style: TextStyle(
                                    fontSize: 14,
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

                    // Botón ver historial completo
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const HistoryPage()),
                          ).then((_) => _loadLastScan());
                        },
                        icon: const Icon(Icons.history),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Ver Historial Completo',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF06B6A4),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
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

  Widget _menuButton(BuildContext context,
      {required String label, required IconData icon, required String route}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(icon, size: 24),
        ),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF06B6A4),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds} segundos';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutos';
    if (diff.inHours < 24) return '${diff.inHours} horas';
    if (diff.inDays < 30) return '${diff.inDays} días';
    return '${(diff.inDays / 30).floor()} meses';
  }
}