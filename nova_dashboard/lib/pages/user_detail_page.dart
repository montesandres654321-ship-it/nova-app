// lib/pages/user_detail_page.dart
// ============================================================
// FIX: Teléfono movido a fila separada debajo de badges
// para que no se corte cuando el número es largo
// ============================================================
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../models/user_model.dart';

class UserDetailPage extends StatefulWidget {
  final int userId;

  const UserDetailPage({super.key, required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  static const _teal  = Color(0xFF06B6A4);
  static const _green = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);
  static const _blue  = Color(0xFF2563EB);

  bool _loading = true;
  String _error = '';

  UserModel? _user;
  List<dynamic> _scans = [];
  List<dynamic> _rewards = [];
  List<dynamic> _topPlaces = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadUserDetail();
  }

  Future<void> _loadUserDetail() async {
    try {
      setState(() { _loading = true; _error = ''; });

      final response = await AdminService.getUserDetail(widget.userId);

      if (response['success'] == true) {
        if (mounted) {
          setState(() {
            _user = UserModel.fromJson(response['user']);
            _scans = response['scans'] ?? [];
            _rewards = response['rewards'] ?? [];
            _topPlaces = response['topPlaces'] ?? [];
            _stats = response['stats'] ?? {};
            _loading = false;
          });
        }
      } else {
        throw Exception(response['error'] ?? 'Error al cargar detalle');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_user?.displayName ?? 'Detalle de Usuario'),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserDetail,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error.isNotEmpty
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_user == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Columna izquierda: Perfil + Stats ─────────
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCompactHeader(),
                const SizedBox(height: 16),
                _buildCompactStats(),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // ── Columna derecha: Lugares + Actividad ──────
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_topPlaces.isNotEmpty) ...[
                    _buildTopPlacesSection(),
                    const SizedBox(height: 16),
                  ],
                  _buildRecentActivitySection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header compacto — teléfono en fila separada ───────
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(children: [
        // Avatar + Nombre + Email
        Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _user!.isActive
                ? _teal.withOpacity(0.15)
                : Colors.grey.shade200,
            child: Icon(
              _user!.isGoogleUser ? Icons.g_mobiledata : Icons.person,
              size: 28,
              color: _user!.isActive ? _teal : Colors.grey,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _user!.displayName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _user!.email,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
        ]),
        const SizedBox(height: 12),

        // Rol + Estado en una fila
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_user!.roleEmoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 4),
              Text(_user!.roleLabel,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600, color: _teal)),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _user!.isActive
                  ? _green.withOpacity(0.08) : Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                _user!.isActive ? Icons.check_circle : Icons.block,
                size: 12,
                color: _user!.isActive ? _green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                _user!.isActive ? 'Activo' : 'Inactivo',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: _user!.isActive ? _green : Colors.red),
              ),
            ]),
          ),
        ]),

        // FIX: Teléfono en fila separada — ya no se corta
        if (_user!.phone != null && _user!.phone!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(children: [
              Icon(Icons.phone_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _user!.phone!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Stats compactas 2x2 ───────────────────────────────
  Widget _buildCompactStats() {
    final totalScans    = _stats['totalScans']    ?? 0;
    final totalRewards  = _stats['totalRewards']  ?? 0;
    final redeemed      = _stats['redeemedRewards'] ?? 0;
    final pending       = totalRewards - redeemed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 4, height: 16,
                decoration: BoxDecoration(
                    color: _teal, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Estadísticas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _miniStat('Escaneos',    '$totalScans',   Icons.qr_code_scanner,    _blue),
            const SizedBox(width: 10),
            _miniStat('Recompensas', '$totalRewards',  Icons.card_giftcard,      _amber),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _miniStat('Canjeadas',   '$redeemed', Icons.check_circle_rounded, _green),
            const SizedBox(width: 10),
            _miniStat('Pendientes',  '$pending',  Icons.access_time_rounded,  Colors.purple),
          ]),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
            ],
          )),
        ]),
      ),
    );
  }

  // ── Top Places ────────────────────────────────────────
  Widget _buildTopPlacesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Container(width: 4, height: 16,
                decoration: BoxDecoration(
                    color: _amber, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Lugares Más Visitados',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
        ),
        ...(_topPlaces.take(5).map((place) {
          final visitCount = place['visit_count'] ?? 0;
          final name = place['name'] ?? 'N/A';
          final tipo = place['tipo'] ?? '';
          final lugar = place['lugar'] ?? '';

          String emoji = '📍';
          switch (tipo.toString().toLowerCase()) {
            case 'hotel':      emoji = '🏨'; break;
            case 'restaurant': emoji = '🍽️'; break;
            case 'bar':        emoji = '🍹'; break;
          }

          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: _teal.withOpacity(0.1),
              child: Text('$visitCount',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: _teal, fontSize: 12)),
            ),
            title: Text(name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: Text('$emoji $tipo · $lugar',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$visitCount visitas',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
            ),
          );
        })),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ── Actividad Reciente ────────────────────────────────
  Widget _buildRecentActivitySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(children: [
            Container(width: 4, height: 16,
                decoration: BoxDecoration(
                    color: _blue, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Actividad Reciente',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
        ),
        if (_scans.isEmpty && _rewards.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(children: [
                Icon(Icons.history_rounded, size: 36, color: Colors.grey[300]),
                const SizedBox(height: 8),
                Text('No hay actividad reciente',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ]),
            ),
          )
        else ...[
          if (_scans.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text('Últimos Escaneos',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
            ),
            ...(_scans.take(5).map((scan) => ListTile(
              dense: true,
              leading: const Icon(Icons.qr_code_scanner, color: _teal, size: 20),
              title: Text(scan['place_name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              subtitle: Text('${scan['tipo'] ?? ''} · ${scan['lugar'] ?? ''}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              trailing: Text(
                _formatDate(scan['created_at']),
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
            ))),
          ],
          if (_rewards.isNotEmpty) ...[
            const Divider(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text('Últimas Recompensas',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: Colors.grey[700])),
            ),
            ...(_rewards.take(5).map((reward) => ListTile(
              dense: true,
              leading: Icon(
                reward['is_redeemed'] == 1
                    ? Icons.check_circle : Icons.card_giftcard,
                color: reward['is_redeemed'] == 1 ? _green : _amber,
                size: 20,
              ),
              title: Text(reward['reward_name'] ?? 'N/A',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              subtitle: Text(reward['place_name'] ?? 'N/A',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: reward['is_redeemed'] == 1
                      ? _green.withOpacity(0.08) : _amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  reward['is_redeemed'] == 1 ? 'Canjeada' : 'Pendiente',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: reward['is_redeemed'] == 1 ? _green : _amber),
                ),
              ),
            ))),
          ],
        ],
        const SizedBox(height: 8),
      ]),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) return 'Hace ${difference.inMinutes}m';
        return 'Hace ${difference.inHours}h';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 7) {
        return 'Hace ${difference.inDays}d';
      }
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, size: 60, color: Colors.red),
      const SizedBox(height: 16),
      Text('Error: $_error', textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: _loadUserDetail,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(
            backgroundColor: _teal, foregroundColor: Colors.white),
      ),
    ],
  ));
}