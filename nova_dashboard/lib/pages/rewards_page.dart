// lib/pages/rewards_page.dart
// ============================================================
// CAMBIOS vs versión anterior:
//   1. Eliminada la tabla "Detalle de Recompensas" de esta página
//      → movida a rewards_detail_page.dart
//   2. Los stat cards (Total, Canjeadas, Pendientes) ahora navegan
//      a RewardsDetailPage con el filtro correspondiente
//   3. Layout más limpio: header + cards + gráfica línea + donut
//   4. El donut se corrige automáticamente con el fix global
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/analytics_service.dart';
import '../services/reward_service.dart';
import '../models/reward_model.dart';
import '../widgets/charts/donut_chart_widget.dart';
import '../widgets/charts/line_chart_widget.dart';
import 'rewards_detail_page.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({Key? key}) : super(key: key);
  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  final _analytics = AnalyticsService();

  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _rewardsByDay = [];

  bool    _loading      = true;
  String? _error;
  int     _selectedDays = 30;

  // 0 = sin límite (todo el historial)
  final List<int> _daysOptions = [7, 15, 30, 60, 90, 0];

  static const _teal   = Color(0xFF06B6A4);
  static const _green  = Color(0xFF059669);
  static const _amber  = Color(0xFFD97706);
  static const _blue   = Color(0xFF2563EB);
  static const _bgPage = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });

    try {
      final results = await Future.wait([
        _analytics.getRewardsStats(),
        _analytics.getRewardsByDay(days: _selectedDays == 0 ? 3650 : _selectedDays),
      ]);

      if (!mounted) return;

      setState(() {
        _stats        = results[0] as Map<String, dynamic>?;
        _rewardsByDay = results[1] as List<Map<String, dynamic>>;
        _loading      = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Navegar a la vista de detalle con filtro ───────────
  void _navigateToDetail(String filter) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RewardsDetailPage(initialFilter: filter),
      ),
    );
  }

  String _calculateRate() {
    if (_stats == null) return '0%';
    final total    = (_stats!['total_rewards']    as num?)?.toInt() ?? 0;
    final redeemed = (_stats!['redeemed_rewards'] as num?)?.toInt() ?? 0;
    if (total == 0) return '0%';
    return '${(redeemed / total * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // ── Header ────────────────────────────────────────
        _buildHeader(),

        // ── 4 Tarjetas clickeables ────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _buildStatsCards(),
        ),

        // ── Gráficas: línea + donut — llenan el resto ────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _buildLineChart()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildDonutChart()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Header con título + período ────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _teal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.card_giftcard_rounded,
                color: _teal, size: 26)),
        const SizedBox(width: 14),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recompensas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('Gestión y análisis',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ])),

        DropdownButton<int>(
            value: _selectedDays,
            underline: const SizedBox(),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            items: _daysOptions.map((d) => DropdownMenuItem(
                value: d, child: Text(d == 0 ? 'Todo el historial' : '$d días'))).toList(),
            onChanged: (v) {
              if (v != null) { setState(() => _selectedDays = v); _loadData(); }
            }),
        const SizedBox(width: 8),

        IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _teal),
            onPressed: _loadData,
            tooltip: 'Actualizar'),
      ]),
    );
  }

  // ── 4 tarjetas — navegan a RewardsDetailPage ───────────
  Widget _buildStatsCards() {
    final total    = (_stats?['total_rewards']    as num?)?.toInt() ?? 0;
    final redeemed = (_stats?['redeemed_rewards'] as num?)?.toInt() ?? 0;
    final pending  = (_stats?['pending_rewards']  as num?)?.toInt() ?? 0;
    final rate     = _calculateRate();

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        _statCard('Total',       total.toString(),    Icons.card_giftcard_rounded, _teal,  'all'),
        _statCard('Canjeadas',   redeemed.toString(), Icons.check_circle_rounded,  _green, 'redeemed'),
        _statCard('Pendientes',  pending.toString(),  Icons.pending_rounded,        _amber, 'pending'),
        _statCard('Tasa Canje',  rate,                Icons.trending_up_rounded,   _blue,  null),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color,
      String? tapFilter) {
    return InkWell(
      onTap: tapFilter != null ? () => _navigateToDetail(tapFilter) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.07), blurRadius: 8,
              offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color,
                    height: 1.1)),
                Text(title, style: TextStyle(
                    fontSize: 11, color: Colors.grey[600])),
                if (tapFilter != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.open_in_new_rounded, size: 10,
                        color: color.withOpacity(0.6)),
                    const SizedBox(width: 3),
                    Text('Ver detalle',
                        style: TextStyle(fontSize: 9,
                            color: color.withOpacity(0.7))),
                  ]),
              ])),
        ]),
      ),
    );
  }

  // ── Gráfica de líneas ──────────────────────────────────
  Widget _buildLineChart() {
    if (_rewardsByDay.isEmpty) {
      return _emptyChart('Sin actividad en este período');
    }
    final chartData = _rewardsByDay.map((item) {
      final dateStr = item['date']?.toString() ?? '';
      String label  = dateStr;
      try {
        label = DateFormat('d MMM', 'es').format(DateTime.parse(dateStr));
      } catch (_) {}
      return {'label': label, 'value': item['count'] ?? 0};
    }).toList();

    return LineChartWidget(
      title:    'Recompensas por Día',
      subtitle: _selectedDays == 0 ? 'Todo el historial' : 'Últimos $_selectedDays días',
      data:     chartData,
      color:    _teal,
      height:   double.infinity,
      fillArea: true,
    );
  }

  // ── Donut: Canjeadas vs Pendientes ─────────────────────
  Widget _buildDonutChart() {
    final redeemed = (_stats?['redeemed_rewards'] as num?)?.toInt() ?? 0;
    final pending  = (_stats?['pending_rewards']  as num?)?.toInt() ?? 0;

    if (redeemed == 0 && pending == 0) {
      return _emptyChart('Sin recompensas aún');
    }

    return DonutChartWidget(
      title:      'Estado de Recompensas',
      subtitle:   'Distribución actual',
      data: [
        {'label': 'Canjeadas',  'value': redeemed, 'color': _green},
        {'label': 'Pendientes', 'value': pending,  'color': _amber},
      ],
      height:     double.infinity,
      showLegend: true,
    );
  }

  Widget _emptyChart(String msg) => Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.grey.withOpacity(0.07), blurRadius: 8)]),
      child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded, size: 44, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text(msg, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])));

  Widget _buildError() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 56, color: Colors.red),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal, foregroundColor: Colors.white)),
      ]));
}