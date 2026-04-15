// lib/pages/reports_page.dart
// REESCRITURA COMPLETA:
//  1. Eliminado Timer.periodic que causaba el congelamiento
//     (llamaba /analytics/realtime cada 30s → excepción → loop infinito)
//  2. Eliminado getRealTimeAnalytics() → usa endpoints existentes:
//     - AdminService.getDashboardStats()  → stats + topPlaces + scansByDay
//     - AnalyticsService.getScansByDay()  → escaneos por día
//     - AnalyticsService.getTopPlacesByScans() → ranking
//  3. Selector de período funcional (7 / 30 / 90 días)
//  4. Gráfica de líneas + ranking de barras

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
  int    _selectedDays = 30;

  // Datos del dashboard
  int    _totalScans   = 0;
  int    _totalUsers   = 0;
  int    _totalPlaces  = 0;
  int    _totalRewards = 0;

  List<Map<String, dynamic>> _scansByDay  = [];
  List<Map<String, dynamic>> _topPlaces   = [];

  final List<Map<String, dynamic>> _periods = [
    {'value': 7,  'label': 'Últimos 7 días'},
    {'value': 30, 'label': 'Últimos 30 días'},
    {'value': 90, 'label': 'Últimos 90 días'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    // SIN Timer — el usuario refresca manualmente con el botón ↺
  }

  // SIN dispose de timer — ya no existe

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = ''; });
    try {
      // Parallel load — todos los endpoints existen
      final results = await Future.wait([
        AdminService.getDashboardStats(),
        _analytics.getScansByDay(days: _selectedDays),
        _analytics.getTopPlacesByScans(limit: 6),
      ]);

      if (!mounted) return;

      final dash     = results[0] as Map<String, dynamic>;
      final scans    = results[1] as List<Map<String, dynamic>>;
      final top      = results[2] as List<Map<String, dynamic>>;

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
          content: Text('✅ Datos actualizados'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reportes',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Selector de período
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: DropdownButton<int>(
              value: _selectedDays,
              dropdownColor: const Color(0xFF0891B2),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _periods.map((p) => DropdownMenuItem<int>(
                value: p['value'] as int,
                child: Text(p['label'] as String),
              )).toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedDays = v);
                  _loadData();
                }
              },
            ),
          ),
          // Botón refresh manual
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── 4 Tarjetas ──────────────────────────────────
          _buildStatsCards(),
          const SizedBox(height: 24),

          // ── Gráfica escaneos por día ─────────────────────
          _buildScansChart(),
          const SizedBox(height: 24),

          // ── Ranking top lugares ──────────────────────────
          if (_topPlaces.isNotEmpty) ...[
            _buildRankingChart(),
            const SizedBox(height: 24),
          ],

          // ── Lista detallada top lugares ──────────────────
          if (_topPlaces.isNotEmpty)
            _buildTopPlacesList(),

        ],
      ),
    );
  }

  // ── 4 tarjetas de estadísticas ───────────────────────────
  Widget _buildStatsCards() {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth > 700 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16, crossAxisSpacing: 16,
        childAspectRatio: 1.4,
        children: [
          _statCard('Total Escaneos',  _totalScans,   Icons.qr_code_scanner, Colors.blue),
          _statCard('Turistas',        _totalUsers,   Icons.people,          Colors.green),
          _statCard('Lugares Activos', _totalPlaces,  Icons.place,           Colors.orange),
          _statCard('Recompensas',     _totalRewards, Icons.card_giftcard,   Colors.purple),
        ],
      );
    });
  }

  Widget _statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(
            color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, color: color, size: 28),
          Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.trending_up, color: color, size: 16)),
        ]),
        const SizedBox(height: 10),
        Text(value.toString(), style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]),
    );
  }

  // ── Gráfica escaneos por día ─────────────────────────────
  Widget _buildScansChart() {
    if (_scansByDay.isEmpty) {
      return Container(
        height: 200, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)]),
        child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text('Sin datos para este período',
              style: TextStyle(color: Colors.grey[500])),
        ])),
      );
    }

    final chartData = _scansByDay.map((item) {
      final dateStr = item['date']?.toString() ?? '';
      String label = dateStr;
      try {
        final date = DateTime.parse(dateStr);
        label = DateFormat('d MMM', 'es').format(date);
      } catch (_) {}
      return {'label': label, 'value': item['count'] ?? 0};
    }).toList();

    return LineChartWidget(
      title: 'Actividad de Escaneos',
      subtitle: 'Últimos $_selectedDays días',
      data: chartData,
      color: const Color(0xFF0891B2),
      height: 300,
      fillArea: true,
    );
  }

  // ── Ranking de barras ────────────────────────────────────
  Widget _buildRankingChart() {
    final chartData = _topPlaces.take(6).map((p) => {
      'label': p['name']?.toString() ?? '',
      'value': p['total_scans'] ?? 0,
    }).toList();

    return BarChartWidget(
      title: 'Top Establecimientos',
      subtitle: 'Por número de escaneos',
      data: chartData,
      color: const Color(0xFF0891B2),
      height: 300,
      showValues: true,
    );
  }

  // ── Lista detallada top lugares ──────────────────────────
  Widget _buildTopPlacesList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 4, height: 18,
              decoration: BoxDecoration(color: const Color(0xFF0891B2),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          const Text('Detalle Top Lugares',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        ..._topPlaces.take(5).map((place) {
          final scans   = place['total_scans']     as int? ?? 0;
          final tipo    = place['tipo']?.toString() ?? '';
          final name    = place['name']?.toString() ?? 'Sin nombre';
          final loc     = place['lugar']?.toString() ?? '';
          final emoji   = _emoji(tipo);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: const Color(0xFF0891B2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text(emoji,
                      style: const TextStyle(fontSize: 18)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
                Text(loc, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFF0891B2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('$scans esc.',
                    style: const TextStyle(fontSize: 12,
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  String _emoji(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'hotel':      return '🏨';
      case 'restaurant': return '🍽️';
      case 'bar':        return '🍹';
      default:           return '📍';
    }
  }

  Widget _buildError() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.error_outline, size: 60, color: Colors.red),
      const SizedBox(height: 16),
      Text(_error, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15)),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _loadData,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0891B2),
            foregroundColor: Colors.white),
      ),
    ],
  ));
}