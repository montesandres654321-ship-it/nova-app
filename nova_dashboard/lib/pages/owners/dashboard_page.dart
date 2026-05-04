// lib/pages/owners/dashboard_page.dart
// ============================================================
// FIX: Sección de recompensas pendientes con botón "Entregar"
// El propietario puede canjear recompensas de SU lugar
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../services/place_service.dart';
import '../../services/api_client.dart';
import '../../models/place.dart';
import '../../utils/constants.dart';
import '../places/qr_dialog.dart';
import '../profile/profile_page.dart';
import '../profile/change_password_dialog.dart';
import '../../widgets/charts/line_chart_widget.dart';
import '../../widgets/charts/donut_chart_widget.dart';
import '../../widgets/charts/bar_chart_widget.dart';
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
  List<Map<String, dynamic>> _scansByDay = [];
  List<Map<String, dynamic>> _pendingRewards = [];

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

      final rawScansByDay = stats['scans_by_day'] as List? ?? [];
      final scansByDay = rawScansByDay.whereType<Map<String, dynamic>>()
          .map((item) => {'date': item['date']?.toString() ?? '', 'count': (item['count'] as num?)?.toInt() ?? 0})
          .where((item) => (item['date'] as String).isNotEmpty).toList();

      // Cargar recompensas pendientes del lugar
      List<Map<String, dynamic>> pending = [];
      try {
        final r = await ApiClient.get<dynamic>('/rewards/place/${widget.placeId}');
        final d = r.data;
        if (d is Map<String, dynamic>) {
          pending = (d['pending'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
        } else if (d is List) {
          pending = d.whereType<Map<String, dynamic>>().where((r) => r['is_redeemed'] == 0).toList();
        }
      } catch (e) { debugPrint('Error cargando recompensas: $e'); }

      if (mounted) setState(() {
        _place = place; _visitors = stats['unique_visitors'] as int? ?? 0;
        _scans = stats['total_scans'] as int? ?? 0; _rewards = stats['total_rewards'] as int? ?? 0;
        _redeemed = stats['redeemed_rewards'] as int? ?? 0; _scansByDay = scansByDay;
        _pendingRewards = pending; _loading = false;
      });
    } catch (e) { if (mounted) setState(() { _error = '$e'; _loading = false; }); }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final id = reward['id'] as int?;
    if (id == null) return;

    final name = [reward['first_name'], reward['last_name']]
        .where((s) => s != null && s.toString().isNotEmpty).join(' ').trim();
    final displayName = name.isNotEmpty ? name : (reward['user_email'] ?? 'Turista');

    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Row(children: [
        Text(reward['reward_icon'] ?? '🎁', style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        const Expanded(child: Text('Entregar Recompensa', style: TextStyle(fontSize: 15))),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('¿Entregar esta recompensa?', style: TextStyle(color: Colors.grey[700])),
        const SizedBox(height: 10),
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
            color: _amber.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Turista: $displayName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('Premio: ${reward['reward_name'] ?? ''}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ]),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        ElevatedButton.icon(onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_rounded, size: 16), label: const Text('Entregar'),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white)),
      ],
    ));

    if (confirm != true) return;

    try {
      await ApiClient.patch<dynamic>('/rewards/$id/redeem');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Recompensa entregada a $displayName'), backgroundColor: _green));
      _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: _teal, foregroundColor: Colors.white,
        title: Row(children: [
          if (_place != null) ...[Text(_place!.tipoEmoji, style: const TextStyle(fontSize: 18)), const SizedBox(width: 8)],
          Expanded(child: Text(_place?.name ?? 'Mi Establecimiento',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
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
          : Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildStatsRow(),
        const SizedBox(height: 16),
        Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Columna izquierda (70%): gráficas
          Expanded(flex: 7, child: Column(children: [
            Expanded(child: _lineChart()),
            const SizedBox(height: 16),
            Expanded(child: _barChart()),
          ])),
          const SizedBox(width: 16),
          // Columna derecha (30%): donut + recompensa/QR + pendientes
          Expanded(flex: 3, child: Column(children: [
            SizedBox(height: 148, child: _donutChart()),
            const SizedBox(height: 12),
            IntrinsicHeight(child: Row(children: [
              if (_place!.hasReward) ...[Expanded(child: _rewardMini()), const SizedBox(width: 10)],
              _qrMini(),
            ])),
            const SizedBox(height: 12),
            // Recompensas pendientes
            Expanded(child: _pendingRewardsSection()),
          ])),
        ])),
      ])),
    );
  }

  // ── Recompensas pendientes ──────────────────────────
  Widget _pendingRewardsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(children: [
            Container(width: 3, height: 13, decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 7),
            Text('Pendientes (${_pendingRewards.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          ]),
        ),
        Expanded(child: _pendingRewards.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline, size: 28, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Text('Sin pendientes', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ]))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _pendingRewards.length,
          itemBuilder: (_, i) {
            final r = _pendingRewards[i];
            final name = [r['first_name'], r['last_name']]
                .where((s) => s != null && s.toString().isNotEmpty).join(' ').trim();
            final displayName = name.isNotEmpty ? name : (r['user_email'] ?? r['username'] ?? 'Turista');

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                CircleAvatar(radius: 14, backgroundColor: _teal.withOpacity(0.1),
                    child: Text(displayName[0].toUpperCase(),
                        style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.bold))),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(r['reward_name'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ])),
                SizedBox(height: 30, child: ElevatedButton(
                  onPressed: () => _redeemReward(r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amber, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Entregar', style: TextStyle(fontSize: 11)),
                )),
              ]),
            );
          },
        )),
      ]),
    );
  }

  Widget _buildStatsRow() => Row(children: [
    Expanded(child: _ownerStatCard(Icons.people_rounded, _visitors.toString(), 'Visitantes', _teal)),
    const SizedBox(width: 12),
    Expanded(child: _ownerStatCard(Icons.qr_code_scanner_rounded, _scans.toString(), 'Escaneos', _teal2)),
    const SizedBox(width: 12),
    Expanded(child: _ownerStatCard(Icons.card_giftcard_rounded, _rewards.toString(), 'Otorgadas', _amber)),
    const SizedBox(width: 12),
    Expanded(child: _ownerStatCard(Icons.check_circle_rounded, _redeemed.toString(), 'Canjeadas', _green)),
  ]);

  Widget _ownerStatCard(IconData icon, String value, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 17),
      ),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A), height: 1.1)),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ])),
    ]),
  );

  Widget _chartCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(16)}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    padding: padding,
    child: child,
  );

  Widget _lineChart() {
    if (_scansByDay.isEmpty) return _emptyBox(Icons.show_chart, 'Sin actividad');
    final d = _scansByDay.map((i) { String l = i['date']?.toString() ?? '';
    try { l = DateFormat('d MMM', 'es').format(DateTime.parse(l)); } catch (_) {}
    return {'label': l, 'value': i['count'] ?? 0}; }).toList();
    return _chartCard(
      child: LineChartWidget(title: 'Visitas por Día', data: d, color: _teal, height: double.infinity, fillArea: true),
    );
  }

  Widget _barChart() {
    if (_scansByDay.isEmpty) return _emptyBox(Icons.bar_chart_rounded, 'Sin datos');
    final d = _scansByDay.map((i) { String l = i['date']?.toString() ?? '';
    try { l = DateFormat('d MMM', 'es').format(DateTime.parse(l)); } catch (_) {}
    return {'label': l, 'value': i['count'] ?? 0}; }).toList();
    return _chartCard(
      child: BarChartWidget(title: 'Escaneos por Día', data: d, color: _teal, height: double.infinity, showValues: true),
    );
  }

  Widget _donutChart() {
    if (_rewards == 0) return _emptyBox(Icons.donut_large, 'Sin recompensas');
    return _chartCard(
      padding: const EdgeInsets.all(12),
      child: DonutChartWidget(title: 'Recompensas', subtitle: '', data: [
        {'label': 'Canjeadas', 'value': _redeemed, 'color': _green},
        {'label': 'Pendientes', 'value': _rewards - _redeemed, 'color': _amber},
      ], height: double.infinity, showLegend: true),
    );
  }

  Widget _rewardMini() => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(_place?.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Expanded(child: Text(_place?.rewardName ?? 'Recompensa',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 8),
        Row(children: [_miniStat('$_rewards', 'dadas', _amber), const SizedBox(width: 6), _miniStat('$_redeemed', 'canje', _green)]),
        const SizedBox(height: 8),
        InkWell(onTap: () => showDialog(context: context, builder: (_) => OwnerRewardDialog(
            currentIcon: _place?.rewardIcon, currentName: _place?.rewardName,
            currentDescription: _place?.rewardDescription, currentStock: _place?.rewardStock, onSaved: _loadAll)),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('Editar recompensa', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)))),
      ]));

  Widget _miniStat(String v, String l, Color c) => Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c, height: 1.1)),
        Text(l, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
      ])));

  Widget _qrMini() => Container(
      width: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(
            'https://api.qrserver.com/v1/create-qr-code/?size=70x70&data=PLACE:${_place!.id}&format=png&margin=2',
            width: 70, height: 70, errorBuilder: (_, __, ___) => Container(width: 70, height: 70,
            color: const Color(0xFFF1F5F9), child: const Icon(Icons.qr_code, size: 28, color: Color(0xFFCBD5E1))))),
        const SizedBox(height: 6),
        Text('PLACE:${_place!.id}', style: const TextStyle(fontFamily: 'monospace', fontSize: 10,
            fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 6),
        InkWell(onTap: () => showDialog(context: context, builder: (_) => QRDialog(place: _place!)),
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _teal.withOpacity(0.25)),
                ),
                child: const Text('Ver QR', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: _teal, fontWeight: FontWeight.w600)))),
      ]));

  Widget _emptyBox(IconData icon, String msg) => Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 28, color: const Color(0xFFCBD5E1)), const SizedBox(height: 6),
        Text(msg, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)))])));

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