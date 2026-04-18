// lib/pages/owners/dashboard_page.dart
// LAYOUT SIN SCROLL — todo visible en una pantalla
// Columna izq: stats + líneas + barras
// Columna der: donut + recompensa + QR + visitantes

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../services/place_service.dart';
import '../../models/place.dart';
import '../../utils/constants.dart';
import '../places/qr_dialog.dart';
import '../profile/profile_page.dart';
import '../profile/change_password_dialog.dart';
import '../../widgets/charts/line_chart_widget.dart';
import '../../widgets/charts/donut_chart_widget.dart';
import '../../widgets/charts/bar_chart_widget.dart';
import 'visitors_page.dart';
import 'reward_dialog.dart';
import 'place_edit_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final int? placeId;
  final VoidCallback onLogout;
  const OwnerDashboardPage({super.key, required this.userName, required this.userEmail, required this.placeId, required this.onLogout});
  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  static const _teal = Color(0xFF06B6A4);
  static const _teal2 = Color(0xFF0891B2);
  static const _amber = Color(0xFFD97706);
  static const _green = Color(0xFF059669);

  bool _loading = true;
  String _error = '';
  int? _userId;
  Place? _place;
  int _visitors = 0, _scans = 0, _rewards = 0, _redeemed = 0;
  List<Map<String, dynamic>> _recentScans = [];
  List<Map<String, dynamic>> _scansByDay = [];

  @override
  void initState() { super.initState(); _loadUserId(); _loadAll(); }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userId = prefs.getInt(AppConstants.keyUserId));
  }

  Future<void> _loadAll() async {
    if (widget.placeId == null) { setState(() { _error = 'No tienes un lugar asignado.'; _loading = false; }); return; }
    setState(() { _loading = true; _error = ''; });
    try {
      final place = await PlaceService.getPlaceById(widget.placeId!);
      final stats = await AdminService.getMyPlaceStats(placeId: widget.placeId);
      List<Map<String, dynamic>> scans = [];
      try {
        final r = await AdminService.getMyPlaceScans(placeId: widget.placeId);
        final raw = r['scans'] as List? ?? [];
        scans = raw.take(5).whereType<Map<String, dynamic>>().toList();
      } catch (e) { debugPrint('Error scans: $e'); }

      final rawScansByDay = stats['scans_by_day'] as List? ?? [];
      final scansByDay = rawScansByDay.whereType<Map<String, dynamic>>()
          .map((item) => {'date': item['date']?.toString() ?? '', 'count': (item['count'] as num?)?.toInt() ?? 0})
          .where((item) => (item['date'] as String).isNotEmpty).toList();

      if (mounted) setState(() {
        _place = place; _visitors = stats['unique_visitors'] as int? ?? 0;
        _scans = stats['total_scans'] as int? ?? 0; _rewards = stats['total_rewards'] as int? ?? 0;
        _redeemed = stats['redeemed_rewards'] as int? ?? 0; _recentScans = scans; _scansByDay = scansByDay; _loading = false;
      });
    } catch (e) { if (mounted) setState(() { _error = '$e'; _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      appBar: AppBar(
        backgroundColor: _teal, foregroundColor: Colors.white,
        title: Row(children: [
          if (_place != null) ...[
            Text(_place!.tipoEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(_place?.name ?? 'Mi Establecimiento',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          if (_place != null) IconButton(icon: const Icon(Icons.edit_rounded, size: 20), tooltip: 'Editar',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OwnerPlaceEditPage(place: _place!, onSaved: _loadAll)))),
          if (_place != null) IconButton(icon: const Icon(Icons.qr_code_2_rounded, size: 20), tooltip: 'Mi QR',
              onPressed: () => showDialog(context: context, builder: (_) => QRDialog(place: _place!))),
          IconButton(icon: const Icon(Icons.refresh_rounded, size: 20), tooltip: 'Actualizar', onPressed: _loadAll),
          _buildUserMenu(),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error.isNotEmpty ? _buildError()
          : _place == null ? const Center(child: Text('No se pudo cargar el lugar.'))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          // Fila 1: 4 stats compactos
          _buildStatsRow(),
          const SizedBox(height: 10),
          // Fila 2: contenido principal en 2 columnas
          Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Columna izquierda: gráfica líneas + gráfica barras
            Expanded(flex: 3, child: Column(children: [
              Expanded(child: _lineChart()),
              const SizedBox(height: 10),
              Expanded(child: _barChart()),
            ])),
            const SizedBox(width: 10),
            // Columna derecha: donut + recompensa/QR
            Expanded(flex: 2, child: Column(children: [
              // Donut
              Expanded(child: _donutChart()),
              const SizedBox(height: 10),
              // Recompensa + QR en fila
              IntrinsicHeight(child: Row(children: [
                if (_place!.hasReward) ...[
                  Expanded(child: _rewardMini()),
                  const SizedBox(width: 8),
                ],
                _qrMini(),
              ])),
            ])),
          ])),
        ]),
      ),
    );
  }

  // ── Stats row compacto ──────────────────────────────
  Widget _buildStatsRow() {
    return Row(children: [
      _stat('Visitantes', _visitors, Icons.people_rounded, _teal),
      const SizedBox(width: 8),
      _stat('Escaneos', _scans, Icons.qr_code_scanner_rounded, _teal2),
      const SizedBox(width: 8),
      _stat('Otorgadas', _rewards, Icons.card_giftcard_rounded, _amber),
      const SizedBox(width: 8),
      _stat('Canjeadas', _redeemed, Icons.check_circle_rounded, _green),
    ]);
  }

  Widget _stat(String t, int v, IconData i, Color c) => Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: c.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(
            color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(i, color: c, size: 16)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(v.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: c)),
          Text(t, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        ])),
      ])));

  // ── Gráfica de líneas ───────────────────────────────
  Widget _lineChart() {
    if (_scansByDay.isEmpty) return _emptyBox(Icons.show_chart, 'Sin actividad aún');
    final d = _scansByDay.map((i) { String l = i['date']?.toString() ?? '';
    try { l = DateFormat('d MMM', 'es').format(DateTime.parse(l)); } catch (_) {}
    return {'label': l, 'value': i['count'] ?? 0}; }).toList();
    return LineChartWidget(title: 'Visitas por Día', data: d, color: _teal, height: double.infinity, fillArea: true);
  }

  // ── Gráfica de barras ───────────────────────────────
  Widget _barChart() {
    if (_scansByDay.isEmpty) return _emptyBox(Icons.bar_chart_rounded, 'Sin datos');
    final d = _scansByDay.map((i) { String l = i['date']?.toString() ?? '';
    try { l = DateFormat('d MMM', 'es').format(DateTime.parse(l)); } catch (_) {}
    return {'label': l, 'value': i['count'] ?? 0}; }).toList();
    return BarChartWidget(title: 'Escaneos por Día', data: d, color: _teal, height: double.infinity, showValues: true);
  }

  // ── Donut compacto ──────────────────────────────────
  Widget _donutChart() {
    if (_rewards == 0) return _emptyBox(Icons.donut_large, 'Sin recompensas');
    return DonutChartWidget(title: 'Recompensas', subtitle: '', data: [
      {'label': 'Canjeadas', 'value': _redeemed, 'color': _green},
      {'label': 'Pendientes', 'value': _rewards - _redeemed, 'color': _amber},
    ], height: double.infinity, showLegend: true);
  }

  // ── Recompensa mini ─────────────────────────────────
  Widget _rewardMini() => Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _amber.withOpacity(0.2))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(_place?.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(_place?.rewardName ?? 'Recompensa',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          _miniStat('$_rewards', 'dadas', _amber),
          const SizedBox(width: 6),
          _miniStat('$_redeemed', 'canje', _green),
        ]),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => showDialog(context: context, builder: (_) => OwnerRewardDialog(
              currentIcon: _place?.rewardIcon, currentName: _place?.rewardName,
              currentDescription: _place?.rewardDescription, currentStock: _place?.rewardStock, onSaved: _loadAll)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: _amber.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
            child: const Text('Editar', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: _amber, fontWeight: FontWeight.w600)),
          ),
        ),
      ]));

  Widget _miniStat(String v, String l, Color c) => Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(color: c.withOpacity(0.06), borderRadius: BorderRadius.circular(6)),
      child: Column(children: [
        Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: c)),
        Text(l, style: TextStyle(fontSize: 8, color: Colors.grey[600])),
      ])));

  // ── QR mini ─────────────────────────────────────────
  Widget _qrMini() => Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _teal.withOpacity(0.2))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(
            'https://api.qrserver.com/v1/create-qr-code/?size=60x60&data=PLACE:${_place!.id}&format=png&margin=2',
            width: 60, height: 60, errorBuilder: (_, __, ___) => Container(width: 60, height: 60,
            color: Colors.grey[100], child: const Icon(Icons.qr_code, size: 24, color: Colors.grey)))),
        const SizedBox(height: 4),
        Text('PLACE:${_place!.id}', style: const TextStyle(fontFamily: 'monospace', fontSize: 9, fontWeight: FontWeight.w700, color: _teal)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => showDialog(context: context, builder: (_) => QRDialog(place: _place!)),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(6)),
            child: const Text('Descargar', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ]));

  // ── Visitantes compacto ─────────────────────────────
  Widget _visitorsCompact() => Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: [
              Container(width: 3, height: 14, decoration: BoxDecoration(color: _teal2, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Últimos Visitantes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OwnerVisitorsPage())),
                child: Text('Ver todos →', style: TextStyle(fontSize: 10, color: _teal2, fontWeight: FontWeight.w600)),
              ),
            ])),
        Expanded(child: _recentScans.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.people_outline, size: 28, color: Colors.grey[300]),
          const SizedBox(height: 4),
          Text('Sin visitantes aún', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ]))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _recentScans.length,
          itemBuilder: (_, i) {
            final s = _recentScans[i];
            final n = '${s['first_name'] ?? ''} ${s['last_name'] ?? ''}'.trim();
            final d = (s['created_at'] ?? '').toString();
            String dl = ''; try { dl = DateFormat('d MMM, HH:mm', 'es').format(DateTime.parse(d)); } catch (_) { dl = d; }
            return ListTile(
              dense: true, visualDensity: const VisualDensity(vertical: -3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: CircleAvatar(radius: 14, backgroundColor: _teal.withOpacity(0.1),
                  child: Text(n.isNotEmpty ? n[0].toUpperCase() : '?',
                      style: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 10))),
              title: Text(n.isNotEmpty ? n : 'Turista',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              trailing: Text(dl, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            );
          },
        )),
      ]));

  Widget _emptyBox(IconData icon, String msg) => Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 6)]),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 28, color: Colors.grey[300]), const SizedBox(height: 4),
        Text(msg, style: TextStyle(fontSize: 10, color: Colors.grey[400]))])));

  // ── User menu ───────────────────────────────────────
  Widget _buildUserMenu() => PopupMenuButton<String>(offset: const Offset(0, 50),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 13, backgroundColor: Colors.white,
            child: Text(widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                style: const TextStyle(color: _teal, fontWeight: FontWeight.bold, fontSize: 11))),
        const SizedBox(width: 4),
        Text(widget.userName.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
      ])),
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(widget.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(widget.userEmail, style: TextStyle(fontSize: 11, color: Colors.grey[600])), const Divider()])),
        const PopupMenuItem(value: 'profile', child: ListTile(leading: Icon(Icons.person_rounded, color: _teal), title: Text('Mi Perfil'), contentPadding: EdgeInsets.zero, dense: true)),
        const PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.lock_rounded, color: _teal), title: Text('Cambiar Contraseña'), contentPadding: EdgeInsets.zero, dense: true)),
        const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout_rounded, color: Colors.red), title: Text('Cerrar Sesión', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero, dense: true)),
      ],
      onSelected: (v) {
        switch (v) {
          case 'profile': Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfilePage())); break;
          case 'password': if (_userId != null) showDialog(context: context, builder: (_) => ChangePasswordDialog(userId: _userId!)); break;
          case 'logout': widget.onLogout(); break;
        }
      });

  Widget _buildError() => Center(child: Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.store_mall_directory_outlined, size: 60, color: _teal), const SizedBox(height: 16),
        Text(_error, textAlign: TextAlign.center), const SizedBox(height: 24),
        ElevatedButton.icon(onPressed: _loadAll, icon: const Icon(Icons.refresh), label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white)),
      ])));
}