// lib/pages/stats_dashboard_page.dart
// ============================================================
// FUSIÓN: usa getDashboardSummary() para KPIs + actividad reciente
//         usa getDashboardStats() para scansByDay completo + topPlaces
// Así muestra todo el historial, no solo 7 días
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../utils/app_theme.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/stat_card.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/charts/bar_chart_widget.dart';

class StatsDashboardPage extends StatefulWidget {
  final void Function(int index)?   onNavigate;
  final void Function(String tipo)? onNavigateToPlaces;
  final int placesIndex;
  final int rewardsIndex;
  final int reportsIndex;

  const StatsDashboardPage({
    super.key,
    this.onNavigate,
    this.onNavigateToPlaces,
    this.placesIndex  = 1,
    this.rewardsIndex = 3,
    this.reportsIndex = 4,
  });

  @override
  State<StatsDashboardPage> createState() => _StatsDashboardPageState();
}

class _StatsDashboardPageState extends State<StatsDashboardPage> {
  bool   _loading = true;
  String _error   = '';

  // KPIs del summary
  int _totalUsers     = 0;
  int _activePlaces   = 0;
  int _totalScans     = 0;
  int _scansToday     = 0;
  int _pendingRewards = 0;

  // Datos de gráficas — del stats/dashboard (historial completo)
  List<Map<String, dynamic>> _topPlaces      = [];
  List<Map<String, dynamic>> _scansByDay     = [];

  // Actividad reciente — del dashboard/summary
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      // Cargar ambas fuentes en paralelo
      final results = await Future.wait([
        AdminService.getDashboardSummary(),  // KPIs + actividad reciente
        AdminService.getDashboardStats(),    // scansByDay completo + topPlaces
      ]);

      if (!mounted) return;

      final summary = results[0];
      final stats   = results[1];

      // KPIs del summary (más precisos)
      if (summary['success'] == true) {
        _totalUsers     = _n(summary['totalUsers']);
        _activePlaces   = _n(summary['activePlaces']);
        _totalScans     = _n(summary['totalScans']);
        _scansToday     = _n(summary['scansToday']);
        _pendingRewards = _n(summary['pendingRewards']);
        _recentActivity = List<Map<String, dynamic>>.from(summary['recentActivity'] ?? []);
      }

      // Gráficas del stats/dashboard (historial completo)
      if (stats['success'] == true) {
        final rawStats = stats['stats'] as Map<String, dynamic>? ?? {};

        // Si summary falló, usar stats como fallback para KPIs
        if (summary['success'] != true) {
          _totalUsers   = _n(rawStats['users']);
          _activePlaces = _n(rawStats['places']);
          _totalScans   = _n(rawStats['scans']);
        }

        // scansByDay del endpoint /stats/dashboard — TODO el historial
        final rawScansByDay = stats['scansByDay'] as List? ??
            (stats['data'] is Map ? (stats['data'] as Map)['scansByDay'] as List? : null) ?? [];
        _scansByDay = List<Map<String, dynamic>>.from(rawScansByDay);

        // topPlaces
        final rawTopPlaces = stats['topPlaces'] as List? ?? [];
        _topPlaces = List<Map<String, dynamic>>.from(rawTopPlaces);
      }

      setState(() { _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  static int _n(dynamic v) => v is num ? v.toInt() : 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingIndicator(message: 'Cargando estadísticas...');
    if (_error.isNotEmpty) return ErrorDisplay(message: _error, onRetry: _load, retryLabel: 'Reintentar');

    return LayoutBuilder(builder: (_, constraints) {
      final wide = constraints.maxWidth > 900;
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLG),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          const SizedBox(height: AppTheme.spaceLG),
          _buildStatCards(wide),
          const SizedBox(height: AppTheme.spaceLG),
          if (wide)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildScansChart()),
              const SizedBox(width: AppTheme.spaceLG),
              Expanded(flex: 2, child: _buildTopPlacesChart()),
            ])
          else ...[
            _buildScansChart(),
            const SizedBox(height: AppTheme.spaceLG),
            _buildTopPlacesChart(),
          ],
          const SizedBox(height: AppTheme.spaceLG),
          _buildActivityTable(),
        ]),
      );
    });
  }

  Widget _buildHeader() {
    final today = DateFormat('d MMM yyyy', 'es').format(DateTime.now());
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Estadísticas Generales',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gray900)),
        const SizedBox(height: 2),
        Text('Todo el historial · $today',
            style: const TextStyle(fontSize: 12, color: AppTheme.gray500)),
      ]),
      const Spacer(),
      if (_pendingRewards > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.withOpacity(0.3))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.card_giftcard_rounded, size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text('$_pendingRewards pendientes', style: TextStyle(fontSize: 11, color: Colors.amber[800], fontWeight: FontWeight.w600)),
          ]),
        ),
      const SizedBox(width: 8),
      IconButton(icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary), tooltip: 'Actualizar', onPressed: _load),
    ]);
  }

  Widget _buildStatCards(bool wide) {
    final cards = [
      StatCard(title: 'Turistas', value: _totalUsers.toString(), icon: Icons.people_rounded, color: AppTheme.info,
          onTap: () => widget.onNavigate?.call(3)),
      StatCard(title: 'Lugares activos', value: _activePlaces.toString(), icon: Icons.place_rounded, color: AppTheme.success,
          onTap: () => widget.onNavigate?.call(widget.placesIndex)),
      StatCard(title: 'Escaneos totales', value: _totalScans.toString(), icon: Icons.qr_code_scanner_rounded, color: AppTheme.warning,
          onTap: () => widget.onNavigate?.call(widget.reportsIndex)),
      StatCard(title: 'Escaneos hoy', value: _scansToday.toString(), icon: Icons.today_rounded, color: AppTheme.primary),
    ];
    if (wide) {
      return Row(children: [
        Expanded(child: cards[0]), const SizedBox(width: AppTheme.spaceMD),
        Expanded(child: cards[1]), const SizedBox(width: AppTheme.spaceMD),
        Expanded(child: cards[2]), const SizedBox(width: AppTheme.spaceMD),
        Expanded(child: cards[3]),
      ]);
    }
    return Column(children: [
      Row(children: [Expanded(child: cards[0]), const SizedBox(width: AppTheme.spaceMD), Expanded(child: cards[1])]),
      const SizedBox(height: AppTheme.spaceMD),
      Row(children: [Expanded(child: cards[2]), const SizedBox(width: AppTheme.spaceMD), Expanded(child: cards[3])]),
    ]);
  }

  Widget _buildScansChart() {
    final data = _scansByDay.map((item) {
      final ds = item['date']?.toString() ?? '';
      String label = ds;
      try { label = DateFormat('d MMM', 'es').format(DateTime.parse(ds)); } catch (_) {}
      return {'label': label, 'value': item['count'] ?? 0};
    }).toList();

    return _chartCard(height: 280, title: 'Actividad de Escaneos', icon: Icons.show_chart_rounded, color: AppTheme.primary,
        child: data.isEmpty
            ? _emptyState('Sin actividad registrada')
            : LineChartWidget(title: '', data: data, color: AppTheme.primary, fillArea: true, height: double.infinity));
  }

  Widget _buildTopPlacesChart() {
    final data = _topPlaces.take(5).map((p) => {
      'label': (p['name']?.toString() ?? ''),
      'value': p['totalScans'] ?? p['total_scans'] ?? 0,
    }).toList();

    return _chartCard(height: 280, title: 'Top Establecimientos', icon: Icons.bar_chart_rounded, color: AppTheme.warning,
        child: data.isEmpty
            ? _emptyState('Sin escaneos registrados')
            : BarChartWidget(title: '', data: data, color: AppTheme.warning, height: double.infinity, showValues: true));
  }

  Widget _buildActivityTable() {
    if (_recentActivity.isEmpty) return const SizedBox();
    return _chartCard(title: 'Actividad Reciente', icon: Icons.history_rounded, color: AppTheme.secondary,
        child: SingleChildScrollView(scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.gray50),
              headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.gray600),
              dataRowMinHeight: 40, dataRowMaxHeight: 48, dividerThickness: 0.5,
              columns: const [
                DataColumn(label: Text('Turista')),
                DataColumn(label: Text('Lugar')),
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Fecha y hora')),
              ],
              rows: _recentActivity.take(10).map((item) {
                final ts = item['timestamp']?.toString() ?? '';
                String dateLabel = ts;
                try { dateLabel = DateFormat('d MMM · HH:mm', 'es').format(DateTime.parse(ts)); } catch (_) {}
                return DataRow(cells: [
                  DataCell(Text(item['userName']?.toString() ?? item['username']?.toString() ?? '—',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.gray800))),
                  DataCell(Text(item['placeName']?.toString() ?? '—',
                      style: const TextStyle(fontSize: 13, color: AppTheme.gray700))),
                  DataCell(_typeChip(item['type']?.toString() ?? item['placeType']?.toString() ?? '')),
                  DataCell(Text(dateLabel, style: const TextStyle(fontSize: 12, color: AppTheme.gray500))),
                ]);
              }).toList(),
            )));
  }

  Widget _chartCard({required String title, required IconData icon, required Color color, required Widget child, double? height}) {
    return Container(height: height, padding: const EdgeInsets.all(AppTheme.spaceLG),
        decoration: AppTheme.cardDecoration(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: AppTheme.spaceXS),
            Icon(icon, size: 15, color: color),
            const SizedBox(width: AppTheme.spaceXS),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gray800)),
          ]),
          const SizedBox(height: AppTheme.spaceMD),
          if (height != null) Expanded(child: child) else child,
        ]));
  }

  Widget _emptyState(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.inbox_rounded, size: 36, color: AppTheme.gray300), const SizedBox(height: AppTheme.spaceXS),
    Text(msg, style: const TextStyle(fontSize: 12, color: AppTheme.gray400)),
  ]));

  Widget _typeChip(String type) {
    Color color; IconData icon;
    switch (type.toLowerCase()) {
      case 'hotel': color = AppTheme.info; icon = Icons.hotel_rounded; break;
      case 'restaurant': color = AppTheme.success; icon = Icons.restaurant_rounded; break;
      case 'bar': color = AppTheme.warning; icon = Icons.local_bar_rounded; break;
      default: color = AppTheme.gray400; icon = Icons.place_rounded;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(AppTheme.radiusSM)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color), const SizedBox(width: 3),
          Text(type, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ]));
  }
}