import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onNavigateToTab});

  final void Function(int) onNavigateToTab;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ScanRecord? _lastScan;
  bool _loading = true;
  String _userName = '';
  String _userEmail = '';
  int _totalScans = 0;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLastScan();
  }

  // ── Data ───────────────────────────────────────────────────

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(AppConstants.keyUser);

      if (userData != null) {
        final user = json.decode(userData);
        setState(() {
          _userName = user['first_name'] ?? user['username'] ?? 'Usuario';
          _userEmail = user['email'] ?? '';
        });
      } else {
        final userName =
            prefs.getString(AppConstants.keyUsername) ?? 'Usuario';
        final firstName =
            prefs.getString(AppConstants.keyFirstName) ?? '';
        final email = prefs.getString(AppConstants.keyEmail) ?? '';
        setState(() {
          _userName = firstName.isNotEmpty ? firstName : userName;
          _userEmail = email;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
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
      setState(() {
        _totalScans = scans.length;
        if (scans.isNotEmpty) _lastScan = scans.first;
      });
    } catch (e) {
      debugPrint('Error cargando historial: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Actions ────────────────────────────────────────────────

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded,
                    color: AppColors.error, size: 32),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Cerrar sesión',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                '¿Estás seguro de que quieres salir?',
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdAll),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final isGoogle =
                            await GoogleAuthService.isGoogleUser();
                        if (isGoogle) await GoogleAuthService.signOut();
                        await ApiService.logout();
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.mdAll),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Salir',
                          style:
                              TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'bar':
        return Icons.local_bar;
      default:
        return Icons.place;
    }
  }

  String _timeAgo(DateTime dt) {
    final localDt = dt.toLocal();
    final diff = DateTime.now().difference(localDt);
    if (diff.isNegative || diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) {
      return 'Hace ${(diff.inDays / 7).floor()} sem';
    }
    if (diff.inDays < 365) {
      return 'Hace ${(diff.inDays / 30).floor()} meses';
    }
    return 'Hace ${(diff.inDays / 365).floor()} año(s)';
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // [1] CTA principal
                    _buildScanCTA(),
                    const SizedBox(height: AppSpacing.lg),

                    // [2] Último escaneo
                    _buildLastScanSection(),
                    const SizedBox(height: AppSpacing.lg),

                    // [3] Accesos rápidos
                    _buildQuickGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Secciones principales ──────────────────────────────────

  // Header: saludo + botón de logout
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $_userName',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _userEmail.isNotEmpty
                      ? _userEmail
                      : 'Bienvenido a Nova',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 22),
            color: AppColors.textSecondary,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
    );
  }

  // [1] Botón principal de escaneo QR
  Widget _buildScanCTA() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/scan'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.lgAll,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escanear QR',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Toca para escanear un lugar',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: AppRadius.mdAll,
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // [2] Último escaneo registrado
  Widget _buildLastScanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Último escaneo',
          trailing: _totalScans > 0 ? '$_totalScans en total' : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_loading)
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: const LinearProgressIndicator(
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceVariant,
              minHeight: 3,
            ),
          )
        else if (_lastScan != null)
          _buildLastScanCard()
        else
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildLastScanCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              _getPlaceIcon(_lastScan!.type),
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastScan!.local,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _lastScan!.place,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            _timeAgo(_lastScan!.time),
            style: const TextStyle(
                fontSize: 12, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
      ),
      child: const Column(
        children: [
          Icon(Icons.qr_code_outlined,
              size: 32, color: AppColors.textHint),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Aún no tienes escaneos',
            style: TextStyle(
                fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            'Escanea tu primer código QR',
            style: TextStyle(
                fontSize: 12, color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // [3] Grid 2×2 de accesos secundarios
  Widget _buildQuickGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Accesos rápidos'),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.7,
          children: [
            _buildGridItem(
              Icons.history_rounded,
              'Historial',
              () => widget.onNavigateToTab(2),
            ),
            _buildGridItem(
              Icons.explore_rounded,
              'Lugares',
              () => widget.onNavigateToTab(1),
            ),
            _buildGridItem(
              Icons.person_outline_rounded,
              'Mi Perfil',
              () => widget.onNavigateToTab(3),
            ),
            _buildGridItem(
              Icons.settings_outlined,
              'Ajustes',
              () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ],
    );
  }

  // ── Widgets privados ───────────────────────────────────────

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          Text(
            trailing,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildGridItem(
      IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
