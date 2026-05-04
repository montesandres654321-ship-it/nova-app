// lib/pages/user_detail_page.dart
// UI: layout responsivo 3 col (>900) / 2 col (600-900) / 1 col (<600)
// Lógica, endpoints y modelos sin cambios
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
  List<dynamic> _scans = [], _rewards = [], _topPlaces = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() { super.initState(); _loadUserDetail(); }

  Future<void> _loadUserDetail() async {
    try {
      setState(() { _loading = true; _error = ''; });
      final r = await AdminService.getUserDetail(widget.userId);
      if (r['success'] == true && mounted) {
        setState(() {
          _user      = UserModel.fromJson(r['user']);
          _scans     = r['scans']     ?? [];
          _rewards   = r['rewards']   ?? [];
          _topPlaces = r['topPlaces'] ?? [];
          _stats     = r['stats']     ?? {};
          _loading   = false;
        });
      } else { throw Exception(r['error'] ?? 'Error'); }
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUserDetail),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error.isNotEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  // ── Layout responsivo ─────────────────────────────────
  Widget _buildContent() {
    if (_user == null) return const SizedBox();
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth;

      if (w > 900) {
        // Desktop: 3 columnas
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Col 1 — Perfil
            SizedBox(
              width: 260,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildCompactStats(),
                ]),
              ),
            ),
            const SizedBox(width: 16),
            // Col 2 — Actividad
            Expanded(child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_topPlaces.isNotEmpty) ...[
                  _buildTopPlaces(),
                  const SizedBox(height: 16),
                ],
                _buildRecentScans(),
              ]),
            )),
            const SizedBox(width: 16),
            // Col 3 — Recompensas
            Expanded(child: SingleChildScrollView(
              child: _buildRecentRewards(),
            )),
          ]),
        );
      } else if (w > 600) {
        // Tablet: 2 columnas
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Col 1 — Perfil
            SizedBox(
              width: 250,
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildCompactStats(),
                ]),
              ),
            ),
            const SizedBox(width: 16),
            // Col 2 — Actividad + Recompensas
            Expanded(child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_topPlaces.isNotEmpty) ...[
                  _buildTopPlaces(),
                  const SizedBox(height: 16),
                ],
                _buildRecentScans(),
                const SizedBox(height: 16),
                _buildRecentRewards(),
              ]),
            )),
          ]),
        );
      } else {
        // Mobile: 1 columna
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildProfileCard(),
            const SizedBox(height: 12),
            _buildCompactStats(),
            if (_topPlaces.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildTopPlaces(),
            ],
            const SizedBox(height: 12),
            _buildRecentScans(),
            const SizedBox(height: 12),
            _buildRecentRewards(),
          ]),
        );
      }
    });
  }

  // ── Col 1: Perfil ──────────────────────────────────────
  Widget _buildProfileCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: _cardDec(),
    child: Column(children: [
      // Avatar centrado grande
      CircleAvatar(
        radius: 36,
        backgroundColor: _user!.isActive
            ? _teal.withOpacity(0.12)
            : Colors.grey.shade200,
        child: Icon(
          _user!.isGoogleUser ? Icons.g_mobiledata : Icons.person,
          size: 34,
          color: _user!.isActive ? _teal : Colors.grey,
        ),
      ),
      const SizedBox(height: 14),
      // Nombre
      Text(
        _user!.displayName,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
            color: Color(0xFF111827)),
        textAlign: TextAlign.center,
        maxLines: 2, overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 5),
      // Email
      Text(
        _user!.email,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        textAlign: TextAlign.center,
        maxLines: 1, overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 14),
      // Badges estado + rol
      Wrap(
        spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
        children: [
          _badge(_user!.roleEmoji, _user!.roleLabel, _teal),
          _badge(
            _user!.isActive ? '✓' : '✗',
            _user!.isActive ? 'Activo' : 'Inactivo',
            _user!.isActive ? _green : Colors.red,
          ),
        ],
      ),
      // Teléfono
      if (_user!.phone != null && _user!.phone!.isNotEmpty) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Icon(Icons.phone_rounded, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 8),
            Expanded(child: Text(_user!.phone!,
                style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
          ]),
        ),
      ],
    ]),
  );

  Widget _badge(String icon, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]));

  // ── Estadísticas (Col 1) ───────────────────────────────
  Widget _buildCompactStats() {
    final ts = _stats['totalScans']      ?? 0;
    final tr = _stats['totalRewards']    ?? 0;
    final rd = _stats['redeemedRewards'] ?? 0;
    final pn = tr - rd;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDec(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Estadísticas', _teal),
        const SizedBox(height: 12),
        Row(children: [
          _miniStat('Escaneos',    '$ts', Icons.qr_code_scanner,     _blue),
          const SizedBox(width: 10),
          _miniStat('Recompensas', '$tr', Icons.card_giftcard,        _amber),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _miniStat('Canjeadas',  '$rd', Icons.check_circle_rounded,  _green),
          const SizedBox(width: 10),
          _miniStat('Pendientes', '$pn', Icons.access_time_rounded,   Colors.purple),
        ]),
      ]),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) =>
      Expanded(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: color, height: 1.1)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ])),
        ]),
      ));

  // ── Col 2: Lugares más visitados ───────────────────────
  Widget _buildTopPlaces() => Container(
    decoration: _cardDec(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: _sectionHeader('Lugares Más Visitados', _amber),
      ),
      ...(_topPlaces.take(5).map((p) {
        final vc = p['visit_count'] ?? 0;
        final n  = p['name']        ?? 'N/A';
        final t  = p['tipo']        ?? '';
        final l  = p['lugar']       ?? '';
        String e = '📍';
        switch (t.toString().toLowerCase()) {
          case 'hotel':      e = '🏨'; break;
          case 'restaurant': e = '🍽️'; break;
          case 'bar':        e = '🍹'; break;
        }
        return ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 16,
            backgroundColor: _teal.withOpacity(0.1),
            child: Text('$vc', style: const TextStyle(
                fontWeight: FontWeight.bold, color: _teal, fontSize: 12)),
          ),
          title: Text(n, style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('$e $t · $l',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('$vc visitas', style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
          ),
        );
      })),
      const SizedBox(height: 8),
    ]),
  );

  // ── Col 2: Últimos escaneos ────────────────────────────
  Widget _buildRecentScans() => Container(
    decoration: _cardDec(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: _sectionHeader('Últimos Escaneos', _blue),
      ),
      if (_scans.isEmpty)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Column(children: [
            Icon(Icons.qr_code_scanner, size: 32, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Sin escaneos registrados',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
        )
      else
        ...(_scans.take(5).map((s) => ListTile(
          dense: true,
          leading: const Icon(Icons.qr_code_scanner, color: _teal, size: 20),
          title: Text(s['place_name'] ?? 'N/A',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          subtitle: Text('${s['tipo'] ?? ''} · ${s['lugar'] ?? ''}',
              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          trailing: Text(_formatDate(s['created_at']),
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ))),
      const SizedBox(height: 8),
    ]),
  );

  // ── Col 3: Recompensas recientes ───────────────────────
  Widget _buildRecentRewards() => Container(
    decoration: _cardDec(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: _sectionHeader('Recompensas Recientes', _amber),
      ),
      if (_rewards.isEmpty)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Center(child: Column(children: [
            Icon(Icons.card_giftcard, size: 32, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Sin recompensas registradas',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
        )
      else
        ...(_rewards.take(5).map((r) => ListTile(
          dense: true,
          leading: Icon(
            r['is_redeemed'] == 1
                ? Icons.check_circle
                : Icons.card_giftcard,
            color: r['is_redeemed'] == 1 ? _green : _amber,
            size: 20,
          ),
          title: Text(r['reward_name'] ?? 'N/A',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          subtitle: Text(r['place_name'] ?? 'N/A',
              style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (r['is_redeemed'] == 1 ? _green : _amber).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              r['is_redeemed'] == 1 ? 'Canjeada' : 'Pendiente',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: r['is_redeemed'] == 1 ? _green : _amber),
            ),
          ),
        ))),
      const SizedBox(height: 8),
    ]),
  );

  // ── Helpers ────────────────────────────────────────────
  Widget _sectionHeader(String title, Color color) => Row(children: [
    Container(width: 3, height: 14,
        decoration: BoxDecoration(
            color: _teal, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A))),
  ]);

  BoxDecoration _cardDec() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: const Color(0xFFE2E8F0)),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  String _formatDate(String? ds) {
    if (ds == null) return 'N/A';
    try {
      final d    = DateTime.parse(ds);
      final diff = DateTime.now().difference(d);
      if (diff.inDays == 0) {
        if (diff.inHours == 0) return 'Hace ${diff.inMinutes}m';
        return 'Hace ${diff.inHours}h';
      }
      if (diff.inDays == 1) return 'Ayer';
      if (diff.inDays < 7)  return 'Hace ${diff.inDays}d';
      return '${d.day}/${d.month}/${d.year}';
    } catch (e) { return ds; }
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
