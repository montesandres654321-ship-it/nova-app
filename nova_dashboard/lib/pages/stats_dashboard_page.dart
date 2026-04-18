// lib/pages/stats_dashboard_page.dart
// FIX: Color unificado 0xFF06B6A4 + responsive LayoutBuilder
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/charts/bar_chart_widget.dart';
import '../widgets/charts/donut_chart_widget.dart';

class StatsDashboardPage extends StatefulWidget {
  final void Function(int index)?   onNavigate;
  final void Function(String tipo)? onNavigateToPlaces;
  final int placesIndex;
  final int rewardsIndex;
  final int reportsIndex;

  const StatsDashboardPage({
    super.key, this.onNavigate, this.onNavigateToPlaces,
    this.placesIndex = 1, this.rewardsIndex = 3, this.reportsIndex = 4,
  });

  @override
  State<StatsDashboardPage> createState() => _StatsDashboardPageState();
}

class _StatsDashboardPageState extends State<StatsDashboardPage> {
  static const _teal = Color(0xFF06B6A4);
  bool _loading = true; String _error = '';
  int _selectedDays = 0;
  final List<int> _daysOptions = [7, 15, 30, 60, 90, 0];
  int _totalUsers = 0, _totalPlaces = 0, _totalScans = 0, _totalRewards = 0;
  Map<String, dynamic> _placesByType = {};
  List<Map<String, dynamic>> _topPlaces = [], _scansByDay = [];
  final _analytics = AnalyticsService();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final dp = _selectedDays == 0 ? 3650 : _selectedDays;
      final results = await Future.wait([AdminService.getDashboardStats(), _analytics.getScansByDay(days: dp)]);
      final data = results[0] as Map<String, dynamic>;
      final scansData = results[1] as List<Map<String, dynamic>>;
      if (!mounted) return;
      if (data['success'] == true) {
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        final pbt = data['placesByType'];
        setState(() {
          _totalUsers = stats['users'] as int? ?? 0; _totalPlaces = stats['places'] as int? ?? 0;
          _totalScans = stats['scans'] as int? ?? 0; _totalRewards = stats['rewards'] as int? ?? 0;
          _placesByType = pbt is Map<String, dynamic> ? pbt : {};
          _topPlaces = List<Map<String, dynamic>>.from(data['topPlaces'] ?? []);
          _scansByDay = scansData; _loading = false;
        });
      } else { setState(() { _error = data['error']?.toString() ?? 'Error'; _loading = false; }); }
    } catch (e) { if (mounted) setState(() { _error = '$e'; _loading = false; }); }
  }

  void _goTo(int i) => widget.onNavigate?.call(i);
  String get _periodLabel => _selectedDays == 0 ? 'Todo el historial' : 'Últimos $_selectedDays días';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Estadísticas Generales', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0,
        actions: [
          DropdownButton<int>(value: _selectedDays, dropdownColor: _teal,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              underline: const SizedBox(), icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: _daysOptions.map((d) => DropdownMenuItem(value: d,
                  child: Text(d == 0 ? 'Todo el historial' : '$d días'))).toList(),
              onChanged: (v) { if (v != null) { setState(() => _selectedDays = v); _load(); } }),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error.isNotEmpty ? _buildError() : _buildLayout(),
    );
  }

  Widget _buildLayout() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isWide = constraints.maxWidth > 800;
      return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildCardsRow(isWide),
        const SizedBox(height: 16),
        Expanded(flex: 5, child: isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(flex: 3, child: _buildScansByDayChart()),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _buildDistributionChart()),
        ])
            : Column(children: [
          Expanded(child: _buildScansByDayChart()),
          const SizedBox(height: 12),
          Expanded(child: _buildDistributionChart()),
        ])),
        const SizedBox(height: 16),
        Expanded(flex: 4, child: _buildRankingChart()),
      ]));
    });
  }

  Widget _buildCardsRow(bool isWide) {
    final cards = [
      _cardBody('Turistas', _totalUsers, Icons.people_rounded, const Color(0xFF2563EB), () => Navigator.of(context).pushNamed('/users')),
      _cardBody('Lugares', _totalPlaces, Icons.place_rounded, const Color(0xFF059669), () => _goTo(widget.placesIndex)),
      _cardBody('Escaneos', _totalScans, Icons.qr_code_scanner, const Color(0xFFD97706), () => _goTo(widget.reportsIndex)),
      _cardBody('Recompensas', _totalRewards, Icons.card_giftcard_rounded, const Color(0xFF7C3AED), () => _goTo(widget.rewardsIndex)),
    ];
    if (isWide) {
      return IntrinsicHeight(child: Row(children: [
        Expanded(child: cards[0]), const SizedBox(width: 12),
        Expanded(child: cards[1]), const SizedBox(width: 12),
        Expanded(child: cards[2]), const SizedBox(width: 12),
        Expanded(child: cards[3]),
      ]));
    }
    return GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.2, children: cards);
  }

  Widget _cardBody(String title, int value, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.15)),
                boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 3))]),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(
                  color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ])),
              Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.4), size: 16),
            ])));
  }

  Widget _buildScansByDayChart() {
    final chartData = _scansByDay.map((item) {
      final ds = item['date']?.toString() ?? '';
      String l = ds;
      try { l = DateFormat('d MMM', 'es').format(DateTime.parse(ds)); } catch (_) {}
      return {'label': l, 'value': item['count'] ?? 0};
    }).toList();
    return Container(decoration: _cardDec(), child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Actividad de Escaneos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(_periodLabel, style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
          ]),
          const SizedBox(height: 12),
          Expanded(child: chartData.isEmpty
              ? Center(child: Text('Sin datos', style: TextStyle(color: Colors.grey[400])))
              : LineChartWidget(title: '', data: chartData, color: _teal, fillArea: true, height: double.infinity)),
        ])));
  }

  Widget _buildDistributionChart() {
    final h = _placesByType['hotel'] as int? ?? 0;
    final r = _placesByType['restaurant'] as int? ?? 0;
    final b = _placesByType['bar'] as int? ?? 0;
    return Container(decoration: _cardDec(), child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF059669), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Por Tipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Expanded(child: DonutChartWidget(title: '', subtitle: '', data: [
            {'label': 'Hoteles', 'value': h, 'color': const Color(0xFF2563EB)},
            {'label': 'Restaurantes', 'value': r, 'color': const Color(0xFF059669)},
            {'label': 'Bares', 'value': b, 'color': const Color(0xFFD97706)},
          ], height: double.infinity, showLegend: true)),
          const SizedBox(height: 8),
          Row(children: [
            _typeChip('🏨', h, const Color(0xFF2563EB), 'hotel'), const SizedBox(width: 4),
            _typeChip('🍽️', r, const Color(0xFF059669), 'restaurant'), const SizedBox(width: 4),
            _typeChip('🍹', b, const Color(0xFFD97706), 'bar'),
          ]),
        ])));
  }

  Widget _typeChip(String emoji, int count, Color color, String tipo) => Expanded(child: InkWell(
      onTap: () => widget.onNavigateToPlaces?.call(tipo), borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Column(children: [Text(emoji, style: const TextStyle(fontSize: 14)),
            Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))]))));

  Widget _buildRankingChart() {
    if (_topPlaces.isEmpty) return const SizedBox();
    final cd = _topPlaces.take(6).map((p) => {'label': p['name']?.toString() ?? '', 'value': p['total_scans'] ?? 0}).toList();
    return Container(decoration: _cardDec(), child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Top Establecimientos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(onPressed: () => _goTo(widget.reportsIndex),
                icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                label: const Text('Ver reportes', style: TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 8),
          Expanded(child: BarChartWidget(title: '', data: cd, color: const Color(0xFFD97706), height: double.infinity, showValues: true)),
        ])));
  }

  BoxDecoration _cardDec() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)]);
  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 16),
    Text(_error, textAlign: TextAlign.center), const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Reintentar'))]));
}