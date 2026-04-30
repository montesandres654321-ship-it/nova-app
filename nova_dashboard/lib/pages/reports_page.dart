// lib/pages/reports_page.dart
// FIX: Color 0xFF06B6A4 + responsive LayoutBuilder
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../utils/app_theme.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/charts/bar_chart_widget.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final _analytics = AnalyticsService();
  bool _loading = true; bool _refreshing = false; String _error = '';
  int _selectedDays = 0;
  int _totalScans = 0, _totalUsers = 0, _totalPlaces = 0, _totalRewards = 0;
  List<Map<String, dynamic>> _scansByDay = [], _topPlaces = [];
  final List<int> _daysOptions = [7, 15, 30, 60, 90, 0];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final dp = _selectedDays == 0 ? 3650 : _selectedDays;
      final results = await Future.wait([
        AdminService.getDashboardStats(), _analytics.getScansByDay(days: dp), _analytics.getTopPlacesByScans(limit: 6)]);
      if (!mounted) return;
      final dash = results[0] as Map<String, dynamic>;
      final scans = results[1] as List<Map<String, dynamic>>;
      final top = results[2] as List<Map<String, dynamic>>;
      if (dash['success'] == true) {
        final stats = dash['stats'] as Map<String, dynamic>? ?? {};
        setState(() { _totalScans = stats['scans'] as int? ?? 0; _totalUsers = stats['users'] as int? ?? 0;
        _totalPlaces = stats['places'] as int? ?? 0; _totalRewards = stats['rewards'] as int? ?? 0;
        _scansByDay = scans; _topPlaces = top; _loading = false; });
      } else { setState(() { _error = dash['error']?.toString() ?? 'Error'; _loading = false; }); }
    } catch (e) { if (mounted) setState(() { _error = '$e'; _loading = false; }); }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try { await _loadData(); } finally { if (mounted) setState(() => _refreshing = false); }
  }

  String get _periodLabel => _selectedDays == 0 ? 'Todo el historial' : 'Últimos $_selectedDays días';

  Widget _buildPageHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceLG, vertical: AppTheme.spaceMD),
      child: Row(children: [
        Text('Reportes', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        DropdownButton<int>(
          value: _selectedDays,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down),
          items: _daysOptions.map((d) => DropdownMenuItem<int>(
              value: d,
              child: Text(d == 0 ? 'Todo el historial' : '$d días',
                  style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) {
            if (v != null) { setState(() => _selectedDays = v); _loadData(); }
          },
        ),
        _refreshing
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _refresh,
                tooltip: 'Actualizar'),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.backgroundGray,
      child: Column(children: [
        _buildPageHeader(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: AppTheme.primary))
              : _error.isNotEmpty
              ? _buildError()
              : _buildContent(),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(builder: (ctx, constraints) {
      final isWide = constraints.maxWidth > 800;
      return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        _buildStatsCards(isWide), const SizedBox(height: 16),
        Expanded(flex: 5, child: _buildScansChart()), const SizedBox(height: 16),
        if (_topPlaces.isNotEmpty) Expanded(flex: 4, child: _buildRankingChart()),
      ]));
    });
  }

  Widget _buildStatsCards(bool isWide) {
    final cards = [
      StatCard(title: 'Total Escaneos', value: _totalScans.toString(),
          icon: Icons.qr_code_scanner, color: AppTheme.info),
      StatCard(title: 'Turistas', value: _totalUsers.toString(),
          icon: Icons.people_rounded, color: AppTheme.success),
      StatCard(title: 'Lugares Activos', value: _totalPlaces.toString(),
          icon: Icons.place_rounded, color: AppTheme.warning),
      StatCard(title: 'Recompensas', value: _totalRewards.toString(),
          icon: Icons.card_giftcard_rounded, color: const Color(0xFF7C3AED)),
    ];
    if (isWide) {
      return IntrinsicHeight(child: Row(children: [
        Expanded(child: cards[0]), const SizedBox(width: 12),
        Expanded(child: cards[1]), const SizedBox(width: 12),
        Expanded(child: cards[2]), const SizedBox(width: 12),
        Expanded(child: cards[3]),
      ]));
    }
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: cards,
    );
  }

  Widget _buildScansChart() {
    final chartData = _scansByDay.map((item) {
      final ds = item['date']?.toString() ?? '';
      String l = ds; try { l = DateFormat('d MMM', 'es').format(DateTime.parse(ds)); } catch (_) {}
      return {'label': l, 'value': item['count'] ?? 0};
    }).toList();
    return Container(decoration: _cardDec(), child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Actividad de Escaneos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                child: Text(_periodLabel, style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
          ]),
          const SizedBox(height: 12),
          Expanded(child: chartData.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.bar_chart, size: 40, color: Colors.grey[300]), const SizedBox(height: 8),
            Text('Sin datos', style: TextStyle(color: Colors.grey[500], fontSize: 12))]))
              : LineChartWidget(title: '', data: chartData, color: AppTheme.primary, fillArea: true, height: double.infinity)),
        ])));
  }

  Widget _buildRankingChart() {
    final cd = _topPlaces.take(6).map((p) => {'label': p['name']?.toString() ?? '', 'value': p['totalScans'] ?? p['total_scans'] ?? 0}).toList();
    return Container(decoration: _cardDec(), child: Padding(padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 20, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('Top Establecimientos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Por número de escaneos', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ]),
          const SizedBox(height: 8),
          Expanded(child: BarChartWidget(title: '', data: cd, color: AppTheme.primary, height: double.infinity, showValues: true)),
        ])));
  }

  BoxDecoration _cardDec() => BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)]);
  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 16),
    Text(_error, textAlign: TextAlign.center), const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white))]));
}