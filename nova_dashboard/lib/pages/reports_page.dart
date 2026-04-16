// lib/pages/reports_page.dart
// ============================================================
// CAMBIOS:
//   1. Dropdown con "Todo el historial" + default = 0
//   2. Layout sin scroll: Column + Expanded (como stats_dashboard)
//   3. Cards compactas con childAspectRatio 2.2
//   4. Gráfica + ranking en Expanded
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/charts/bar_chart_widget.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _analytics = AnalyticsService();

  bool   _loading    = true;
  bool   _refreshing = false;
  String _error      = '';
  // FIX: default = 0 (Todo el historial)
  int    _selectedDays = 0;

  int    _totalScans   = 0;
  int    _totalUsers   = 0;
  int    _totalPlaces  = 0;
  int    _totalRewards = 0;

  List<Map<String, dynamic>> _scansByDay  = [];
  List<Map<String, dynamic>> _topPlaces   = [];

  // FIX: opciones con 0 = Todo
  final List<int> _daysOptions = [7, 15, 30, 60, 90, 0];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final daysParam = _selectedDays == 0 ? 3650 : _selectedDays;

      final results = await Future.wait([
        AdminService.getDashboardStats(),
        _analytics.getScansByDay(days: daysParam),
        _analytics.getTopPlacesByScans(limit: 6),
      ]);

      if (!mounted) return;

      final dash  = results[0] as Map<String, dynamic>;
      final scans = results[1] as List<Map<String, dynamic>>;
      final top   = results[2] as List<Map<String, dynamic>>;

      if (dash['success'] == true) {
        final stats = dash['stats'] as Map<String, dynamic>? ?? {};
        setState(() {
          _totalScans   = stats['scans']   as int? ?? 0;
          _totalUsers   = stats['users']   as int? ?? 0;
          _totalPlaces  = stats['places']  as int? ?? 0;
          _totalRewards = stats['rewards'] as int? ?? 0;
          _scansByDay   = scans;
          _topPlaces    = top;
          _loading      = false;
        });
      } else {
        setState(() {
          _error   = dash['error']?.toString() ?? 'Error al cargar';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Datos actualizados'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  String get _periodLabel => _selectedDays == 0
      ? 'Todo el historial'
      : 'Últimos $_selectedDays días';

  static const _cyan = Color(0xFF0891B2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reportes',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _cyan,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // FIX: Dropdown con "Todo el historial"
          DropdownButton<int>(
            value: _selectedDays,
            dropdownColor: _cyan,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            items: _daysOptions.map((d) => DropdownMenuItem<int>(
              value: d,
              child: Text(d == 0 ? 'Todo el historial' : '$d días'),
            )).toList(),
            onChanged: (v) {
              if (v != null) { setState(() => _selectedDays = v); _loadData(); }
            },
          ),
          _refreshing
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white)),
          )
              : IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Actualizar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _buildError()
          : _buildContent(),
    );
  }

  // FIX: Layout sin scroll — Column + Expanded
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [

        // 4 tarjetas compactas
        _buildStatsCards(),
        const SizedBox(height: 16),

        // Gráfica de escaneos
        Expanded(
          flex: 5,
          child: _buildScansChart(),
        ),
        const SizedBox(height: 16),

        // Ranking
        if (_topPlaces.isNotEmpty)
          Expanded(
            flex: 4,
            child: _buildRankingChart(),
          ),
      ]),
    );
  }

  // Cards compactas en fila
  Widget _buildStatsCards() {
    return IntrinsicHeight(
      child: Row(children: [
        _statCard('Total Escaneos',  _totalScans,   Icons.qr_code_scanner,    Colors.blue),
        const SizedBox(width: 12),
        _statCard('Turistas',        _totalUsers,   Icons.people_rounded,      Colors.green),
        const SizedBox(width: 12),
        _statCard('Lugares Activos', _totalPlaces,  Icons.place_rounded,       Colors.orange),
        const SizedBox(width: 12),
        _statCard('Recompensas',     _totalRewards, Icons.card_giftcard_rounded, Colors.purple),
      ]),
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value.toString(), style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _buildScansChart() {
    final chartData = _scansByDay.map((item) {
      final dateStr = item['date']?.toString() ?? '';
      String label = dateStr;
      try {
        label = DateFormat('d MMM', 'es').format(DateTime.parse(dateStr));
      } catch (_) {}
      return {'label': label, 'value': item['count'] ?? 0};
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20,
                decoration: BoxDecoration(color: _cyan,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Actividad de Escaneos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _cyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(_periodLabel,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
          ]),
          const SizedBox(height: 12),
          Expanded(child: chartData.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Text('Sin datos para este período',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ]))
              : LineChartWidget(
              title: '', data: chartData,
              color: _cyan, fillArea: true, height: double.infinity)),
        ]),
      ),
    );
  }

  Widget _buildRankingChart() {
    final chartData = _topPlaces.take(6).map((p) => {
      'label': p['name']?.toString() ?? '',
      'value': p['total_scans'] ?? 0,
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20,
                decoration: BoxDecoration(color: _cyan,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Top Establecimientos',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Por número de escaneos',
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ]),
          const SizedBox(height: 8),
          Expanded(child: BarChartWidget(
              title: '', data: chartData,
              color: _cyan, height: double.infinity,
              showValues: true)),
        ]),
      ),
    );
  }

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, size: 60, color: Colors.red),
      const SizedBox(height: 16),
      Text(_error, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _loadData,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(
            backgroundColor: _cyan, foregroundColor: Colors.white),
      ),
    ],
  ));
}