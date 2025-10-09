import 'package:flutter/material.dart';
import 'scan_record.dart';
import 'api_service.dart';
import 'google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'history_page.dart'; // ✅ AGREGAR ESTE IMPORT

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScanRecord? _lastScan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLastScan();
  }

  Future<void> _loadLastScan() async {
    setState(() => _loading = true);
    try {
      final scans = await ApiService.getScanHistory();
      if (scans.isNotEmpty) {
        setState(() => _lastScan = scans.first);
      }
    } catch (e) {
      // Error silenciado para producción
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

    final theme = Theme.of(context);
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
                    // Encabezado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Inicio',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.exit_to_app, color: Colors.white),
                          tooltip: 'Cerrar sesión',
                        )
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Escanear
                    _menuButton(
                      context,
                      label: 'Escanear',
                      icon: Icons.qr_code,
                      route: '/scan',
                    ),
                    const SizedBox(height: 16),

                    // Pasaporte
                    _menuButton(
                      context,
                      label: 'Pasaporte',
                      icon: Icons.card_travel,
                      route: '/passport',
                    ),
                    const SizedBox(height: 16),

                    // Configuración
                    _menuButton(
                      context,
                      label: 'Configuración',
                      icon: Icons.settings,
                      route: '/settings',
                    ),

                    const SizedBox(height: 26),

                    // Resumen rápido
                    Card(
                      clipBehavior: Clip.hardEdge,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Resumen rápido',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _lastScan != null
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Último escaneo:",
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _lastScan!.place,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Hace: ${_timeAgo(_lastScan!.time)}",
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            )
                                : Text(
                              'Aún no tienes escaneos registrados.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 26),

                    // ✅ CORREGIDO: Navegación funcional a HistoryPage
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryPage()),
                        ).then((_) => _loadLastScan());
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Ver actividad completa',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
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
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(icon, size: 20),
        ),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, style: const TextStyle(fontSize: 16)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: theme.colorScheme.secondary,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}