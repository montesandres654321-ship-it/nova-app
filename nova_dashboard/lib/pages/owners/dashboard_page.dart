// lib/pages/owners/dashboard_page.dart
// ============================================================
// FIXES:
//   #7 — Gráfica de visitas por día: fix parsing de fechas
//         getMyPlaceScans devuelve 'data' no 'scans'
//   #9 — Admin viendo dashboard de otro: pasa placeId como
//         query param a getMyPlaceStats/Scans
// ============================================================

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
import 'visitors_page.dart';
import 'reward_dialog.dart';
import 'place_edit_page.dart';

class OwnerDashboardPage extends StatefulWidget {
  final String       userName;
  final String       userEmail;
  final int?         placeId;
  final VoidCallback onLogout;

  const OwnerDashboardPage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.placeId,
    required this.onLogout,
  });

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  static const _teal   = Color(0xFF06B6A4);
  static const _teal2  = Color(0xFF0891B2);
  static const _amber  = Color(0xFFD97706);
  static const _green  = Color(0xFF059669);
  static const _bgPage = Color(0xFFF0FDFA);

  bool   _loading  = true;
  String _error    = '';
  int?   _userId;
  Place? _place;
  int    _visitors = 0;
  int    _scans    = 0;
  int    _rewards  = 0;
  int    _redeemed = 0;
  List<Map<String, dynamic>> _recentScans = [];
  List<Map<String, dynamic>> _scansByDay  = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadAll();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _userId = prefs.getInt(AppConstants.keyUserId));
  }

  Future<void> _loadAll() async {
    if (widget.placeId == null) {
      setState(() { _error = 'No tienes un lugar asignado.'; _loading = false; });
      return;
    }
    setState(() { _loading = true; _error = ''; });
    try {
      final place = await PlaceService.getPlaceById(widget.placeId!);

      // FIX #9: pasar placeId para que admin pueda ver datos de otro propietario
      final stats = await AdminService.getMyPlaceStats(placeId: widget.placeId);

      List<Map<String, dynamic>> scans     = [];
      List<Map<String, dynamic>> scansByDay = [];
      try {
        // FIX #9: pasar placeId
        final r = await AdminService.getMyPlaceScans(placeId: widget.placeId);

        // FIX #7: el servicio devuelve 'scans' (key en el Map devuelto por admin_service)
        final raw = r['scans'] as List? ?? [];
        scans = raw.take(5).whereType<Map<String, dynamic>>().toList();

        // FIX #7: agrupar por día con parsing robusto de fechas
        final Map<String, int> byDay = {};
        for (final s in raw.whereType<Map<String, dynamic>>()) {
          final dateStr = (s['created_at'] ?? '').toString();
          if (dateStr.isEmpty) continue;

          String? day;
          // Intentar extraer fecha YYYY-MM-DD
          if (dateStr.length >= 10) {
            day = dateStr.substring(0, 10);
            // Verificar que es una fecha válida
            try {
              DateTime.parse(day);
            } catch (_) {
              day = null;
            }
          }

          // Si no se pudo parsear, intentar con el formato completo
          if (day == null) {
            try {
              final parsed = DateTime.parse(dateStr);
              day = DateFormat('yyyy-MM-dd').format(parsed);
            } catch (_) {
              continue; // Saltar este scan si no tiene fecha válida
            }
          }

          if (day != null) {
            byDay[day] = (byDay[day] ?? 0) + 1;
          }
        }

        scansByDay = byDay.entries
            .map((e) => {'date': e.key, 'count': e.value})
            .toList()
          ..sort((a, b) =>
              (a['date'] as String).compareTo(b['date'] as String));
      } catch (e) {
        debugPrint('⚠️ Error cargando scans: $e');
      }

      if (mounted) {
        setState(() {
          _place       = place;
          _visitors    = stats['unique_visitors']  as int? ?? 0;
          _scans       = stats['total_scans']      as int? ?? 0;
          _rewards     = stats['total_rewards']    as int? ?? 0;
          _redeemed    = stats['redeemed_rewards'] as int? ?? 0;
          _recentScans = scans;
          _scansByDay  = scansByDay;
          _loading     = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error.isNotEmpty
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return CustomScrollView(slivers: [
      SliverAppBar(
        expandedHeight: 180,
        pinned: true,
        backgroundColor: _teal,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            }),
        actions: [
          _buildUserMenu(),
          if (_place != null)
            IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                tooltip: 'Editar mi lugar',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => OwnerPlaceEditPage(
                            place:   _place!,
                            onSaved: _loadAll)))),
          if (_place != null)
            IconButton(
                icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white),
                tooltip: 'Mi QR',
                onPressed: () => showDialog(context: context,
                    builder: (_) => QRDialog(place: _place!))),
          const SizedBox(width: 4),
        ],
        flexibleSpace: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_place?.name ?? 'Mi Establecimiento',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 8)])),
                Text(
                    '${_place?.tipoEmoji ?? ''} ${_place?.tipoLabel ?? ''} · ${_place?.lugar ?? ''}',
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ]),
          background: _place?.imageUrl != null
              ? Stack(fit: StackFit.expand, children: [
            Image.network(_place!.imageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: _teal)),
            Container(decoration: const BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC006064)]))),
          ])
              : Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [_teal, _teal2],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Center(child: Text(_place?.tipoEmoji ?? '🏪',
                  style: const TextStyle(fontSize: 64)))),
        ),
      ),

      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(delegate: SliverChildListDelegate([
          _buildStatsRow(),
          const SizedBox(height: 16),

          SizedBox(height: 200, child: Row(children: [
            Expanded(flex: 3, child: _buildLineChart()),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: _buildDonutChart()),
          ])),
          const SizedBox(height: 16),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_place?.hasReward == true)
              Expanded(child: _buildRewardCard()),
            if (_place?.hasReward == true)
              const SizedBox(width: 12),
            Expanded(child: _buildQRCard()),
          ]),

          if (_recentScans.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildVisitors(),
          ],

          const SizedBox(height: 24),
        ])),
      ),
    ]);
  }

  Widget _buildUserMenu() {
    return PopupMenuButton<String>(
        offset: const Offset(0, 50),
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(radius: 14, backgroundColor: Colors.white,
                  child: Text(
                      widget.userName.isNotEmpty
                          ? widget.userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                          color: _teal, fontWeight: FontWeight.bold,
                          fontSize: 12))),
              const SizedBox(width: 5),
              Text(widget.userName.split(' ').first,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ])),
        itemBuilder: (_) => [
          PopupMenuItem(enabled: false, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                Text(widget.userEmail,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const Divider(),
              ])),
          const PopupMenuItem(value: 'profile',
              child: ListTile(
                  leading: Icon(Icons.person_rounded, color: Colors.teal),
                  title: Text('Mi Perfil'),
                  contentPadding: EdgeInsets.zero, dense: true)),
          const PopupMenuItem(value: 'password',
              child: ListTile(
                  leading: Icon(Icons.lock_rounded, color: Colors.teal),
                  title: Text('Cambiar Contraseña'),
                  contentPadding: EdgeInsets.zero, dense: true)),
          const PopupMenuItem(value: 'logout',
              child: ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red),
                  title: Text('Cerrar Sesión',
                      style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero, dense: true)),
        ],
        onSelected: (v) {
          switch (v) {
            case 'profile':
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()));
              break;
            case 'password':
              if (_userId != null) {
                showDialog(context: context,
                    builder: (_) => ChangePasswordDialog(userId: _userId!));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No se pudo obtener el ID de usuario')));
              }
              break;
            case 'logout':
              widget.onLogout();
              break;
          }
        });
  }

  Widget _buildStatsRow() {
    return Row(children: [
      _statCard('Visitantes', _visitors, Icons.people_rounded,          _teal),
      const SizedBox(width: 10),
      _statCard('Escaneos',   _scans,    Icons.qr_code_scanner_rounded,  _teal2),
      const SizedBox(width: 10),
      _statCard('Otorgadas',  _rewards,  Icons.card_giftcard_rounded,    _amber),
      const SizedBox(width: 10),
      _statCard('Canjeadas',  _redeemed, Icons.check_circle_rounded,     _green),
    ]);
  }

  Widget _statCard(String title, int value, IconData icon, Color color) =>
      Expanded(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Column(children: [
            Container(width: 40, height: 40,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(height: 8),
            Text(value.toString(), style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                textAlign: TextAlign.center),
          ])));

  // FIX #7: gráfica de líneas con datos reales
  Widget _buildLineChart() {
    if (_scansByDay.isEmpty) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: Colors.grey.withOpacity(0.07), blurRadius: 8)]),
          child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 32, color: Colors.grey[300]),
                const SizedBox(height: 6),
                Text('Sin actividad aún',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ])));
    }
    final chartData = _scansByDay.map((item) {
      final dateStr = item['date']?.toString() ?? '';
      String label  = dateStr;
      try { label = DateFormat('d MMM', 'es').format(DateTime.parse(dateStr)); }
      catch (_) {}
      return {'label': label, 'value': item['count'] ?? 0};
    }).toList();
    return LineChartWidget(
        title: 'Visitas por Día', subtitle: 'Últimos 30 días',
        data: chartData, color: _teal,
        height: double.infinity, fillArea: true);
  }

  Widget _buildDonutChart() {
    final pending = _rewards - _redeemed;
    if (_rewards == 0) {
      return Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: Colors.grey.withOpacity(0.07), blurRadius: 8)]),
          child: Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.donut_large, size: 32, color: Colors.grey[300]),
                const SizedBox(height: 6),
                Text('Sin recompensas aún',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ])));
    }
    return DonutChartWidget(
        title: 'Recompensas', subtitle: '',
        data: [
          {'label': 'Canjeadas',  'value': _redeemed, 'color': _green},
          {'label': 'Pendientes', 'value': pending,   'color': _amber},
        ],
        height: double.infinity, showLegend: true);
  }

  Widget _buildRewardCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber.withOpacity(0.3)),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 16,
              decoration: BoxDecoration(
                  color: _amber, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          const Text('Mi Recompensa',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const Spacer(),
          InkWell(
              onTap: () => showDialog(context: context,
                  builder: (_) => OwnerRewardDialog(
                      currentIcon:        _place?.rewardIcon,
                      currentName:        _place?.rewardName,
                      currentDescription: _place?.rewardDescription,
                      currentStock:       _place?.rewardStock,
                      onSaved:            _loadAll)),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _amber.withOpacity(0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.edit_rounded, size: 13, color: _amber),
                    const SizedBox(width: 4),
                    Text('Editar', style: TextStyle(
                        fontSize: 11, color: _amber,
                        fontWeight: FontWeight.w600)),
                  ]))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Text(_place!.rewardIcon ?? '🎁',
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_place!.rewardName ?? 'Sin nombre',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (_place!.rewardDescription != null)
                  Text(_place!.rewardDescription!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                if (_place!.rewardStock != null)
                  Text('Stock: ${_place!.rewardStock} disponibles',
                      style: TextStyle(fontSize: 10, color: _amber,
                          fontWeight: FontWeight.w500)),
              ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _rewardStat('$_rewards',  'otorgadas', _amber),
          const SizedBox(width: 12),
          _rewardStat('$_redeemed', 'canjeadas', _green),
        ]),
      ]),
    );
  }

  Widget _rewardStat(String value, String label, Color color) => Expanded(
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8)),
          child: Column(children: [
            Text(value, style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          ])));

  Widget _buildQRCard() => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withOpacity(0.3)),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 16,
              decoration: BoxDecoration(
                  color: _teal, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          const Text('Código QR',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(6),
              child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/'
                      '?size=60x60&data=PLACE:${_place!.id}&format=png&margin=4',
                  width: 60, height: 60,
                  errorBuilder: (_, __, ___) => Container(
                      width: 60, height: 60,
                      color: Colors.grey[100],
                      child: const Icon(Icons.qr_code,
                          size: 28, color: Colors.grey)))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PLACE:${_place!.id}',
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12,
                        fontWeight: FontWeight.w700, color: _teal)),
                const SizedBox(height: 3),
                Text('Coloca en tu establecimiento.',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                    onPressed: () => showDialog(context: context,
                        builder: (_) => QRDialog(place: _place!)),
                    icon: const Icon(Icons.download_rounded, size: 13),
                    label: const Text('Descargar', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _teal, foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: const Size(0, 0))),
              ])),
        ]),
      ]));

  Widget _buildVisitors() => Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(children: [
              Container(width: 4, height: 16,
                  decoration: BoxDecoration(
                      color: _teal2, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 6),
              const Text('Últimos Visitantes',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const OwnerVisitorsPage())),
                  icon: const Icon(Icons.people_rounded, size: 14),
                  label: const Text('Ver todos', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(foregroundColor: _teal2)),
            ])),
        ..._recentScans.map((scan) {
          final name = '${scan['first_name'] ?? ''} ${scan['last_name'] ?? ''}'.trim();
          final date = (scan['created_at'] ?? '').toString();
          String dateLabel = date;
          try {
            dateLabel = DateFormat('d MMM yyyy, HH:mm', 'es')
                .format(DateTime.parse(date));
          } catch (_) {}
          return ListTile(
              dense: true,
              leading: CircleAvatar(radius: 18,
                  backgroundColor: _teal.withOpacity(0.12),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: _teal, fontWeight: FontWeight.bold,
                          fontSize: 13))),
              title: Text(name.isNotEmpty ? name : 'Turista',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(dateLabel,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              trailing: const Icon(Icons.qr_code_scanner_rounded,
                  size: 16, color: _teal));
        }),
        const SizedBox(height: 4),
      ]));

  Widget _buildError() => Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.store_mall_directory_outlined, size: 60, color: _teal),
        const SizedBox(height: 16),
        Text(_error, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal, foregroundColor: Colors.white)),
      ])));
}