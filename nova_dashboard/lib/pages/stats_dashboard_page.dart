// lib/pages/stats_dashboard_page.dart
// ============================================================
// FIX DEFINITIVO: scansByDay se obtiene de getDashboardStats()
// que ahora lo incluye en su respuesta
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/stat_card.dart';
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
  static const _teal   = Color(0xFF06B6A4);
  static const _blue   = Color(0xFF3B82F6);
  static const _green  = Color(0xFF10B981);
  static const _amber  = Color(0xFFF59E0B);
  static const _purple = Color(0xFF8B5CF6);

  bool   _loading = true;
  String _error   = '';
  int    _selectedDays = 0;

  int _totalUsers = 0, _totalPlaces = 0, _totalScans = 0, _totalRewards = 0;

  List<Map<String, dynamic>> _scansByDay     = [];
  List<Map<String, dynamic>> _topPlaces      = [];
  Map<String, dynamic>       _placesByType   = {};
  List<Map<String, dynamic>> _recentActivity = [];

  final List<int> _daysOptions = [7, 15, 30, 60, 90, 0];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await Future.wait([
        AdminService.getDashboardStats(),
        AdminService.getDashboardSummary(),
      ]);
      if (!mounted) return;

      final stats   = results[0];
      final summary = results[1];

      debugPrint('📊 getDashboardStats keys: ${stats.keys}');
      debugPrint('📊 scansByDay present: ${stats.containsKey('scansByDay')}');

      if (stats['success'] == true) {
        final s = stats['stats'] as Map<String, dynamic>? ?? {};
        _totalUsers   = _n(s['users']);
        _totalPlaces  = _n(s['places']);
        _totalScans   = _n(s['scans']);
        _totalRewards = _n(s['rewards']);
        _placesByType = stats['placesByType'] as Map<String, dynamic>? ?? {};
        _topPlaces    = List<Map<String, dynamic>>.from(stats['topPlaces'] ?? []);

        // scansByDay — todo el historial
        if (stats['scansByDay'] is List) {
          _scansByDay = List<Map<String, dynamic>>.from(stats['scansByDay'] as List);
        }
      }

      if (summary['success'] == true) {
        _recentActivity = List<Map<String, dynamic>>.from(summary['recentActivity'] ?? []);
        if (stats['success'] != true) {
          _totalUsers  = _n(summary['totalUsers']);
          _totalPlaces = _n(summary['activePlaces']);
          _totalScans  = _n(summary['totalScans']);
        }
        // Solo usar scansByDay del summary si stats no lo trajo
        if (_scansByDay.isEmpty && summary['scansByDay'] is List) {
          _scansByDay = List<Map<String, dynamic>>.from(summary['scansByDay'] as List);
        }
      }

      debugPrint('📊 scansByDay count: ${_scansByDay.length}');

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
      return SingleChildScrollView(padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatCards(wide),
          const SizedBox(height: 20),
          if (wide)
            IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(flex: 3, child: _buildScansChart()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _buildByTypeSection()),
            ]))
          else ...[_buildScansChart(), const SizedBox(height: 16), _buildByTypeSection()],
          const SizedBox(height: 20),
          _buildTopPlacesSection(),
          if (_recentActivity.isNotEmpty) ...[const SizedBox(height: 20), _buildActivityTable()],
        ]),
      );
    });
  }

  Widget _buildHeader() {
    final today = DateFormat('d MMM yyyy', 'es').format(DateTime.now());
    return Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Estadísticas Generales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('$_periodLabel · $today', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]),
      const Spacer(),
      DropdownButton<int>(value: _selectedDays, underline: const SizedBox(),
        items: _daysOptions.map((d) => DropdownMenuItem(value: d,
            child: Text(d == 0 ? 'Todo el historial' : '$d días', style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) { if (v != null) setState(() => _selectedDays = v); },
      ),
      const SizedBox(width: 8),
      IconButton(icon: const Icon(Icons.refresh_rounded, color: _teal), tooltip: 'Actualizar', onPressed: _load),
    ]);
  }

  String get _periodLabel => _selectedDays == 0 ? 'Todo el historial' : 'Últimos $_selectedDays días';

  Widget _buildStatCards(bool wide) {
    final cards = [
      StatCard(title: 'Turistas', value: _totalUsers.toString(), icon: Icons.people_rounded, color: _blue,
          onTap: () => widget.onNavigate?.call(widget.placesIndex + 2)),
      StatCard(title: 'Lugares', value: _totalPlaces.toString(), icon: Icons.place_rounded, color: _green,
          onTap: () => widget.onNavigate?.call(widget.placesIndex)),
      StatCard(title: 'Escaneos', value: _totalScans.toString(), icon: Icons.qr_code_scanner_rounded, color: _amber,
          onTap: () => widget.onNavigate?.call(widget.reportsIndex)),
      StatCard(title: 'Recompensas', value: _totalRewards.toString(), icon: Icons.card_giftcard_rounded, color: _purple,
          onTap: () => widget.onNavigate?.call(widget.rewardsIndex)),
    ];
    if (wide) return Row(children: [
      Expanded(child: cards[0]), const SizedBox(width: 12),
      Expanded(child: cards[1]), const SizedBox(width: 12),
      Expanded(child: cards[2]), const SizedBox(width: 12),
      Expanded(child: cards[3]),
    ]);
    return Column(children: [
      Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
    ]);
  }

  Widget _buildScansChart() {
    List<Map<String, dynamic>> filteredData = _scansByDay;
    if (_selectedDays > 0 && _scansByDay.isNotEmpty) {
      final cutoff = DateTime.now().subtract(Duration(days: _selectedDays));
      filteredData = _scansByDay.where((item) {
        try { return DateTime.parse(item['date'].toString()).isAfter(cutoff); }
        catch (_) { return true; }
      }).toList();
    }
    final chartData = filteredData.map((item) {
      final ds = item['date']?.toString() ?? '';
      String label = ds;
      try { label = DateFormat('d MMM', 'es').format(DateTime.parse(ds)); } catch (_) {}
      return {'label': label, 'value': item['count'] ?? 0};
    }).toList();

    return _card(height: 300, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _barIndicator(_teal), const Icon(Icons.show_chart_rounded, size: 15, color: _teal),
        const SizedBox(width: 6),
        const Text('Actividad de Escaneos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Text(_periodLabel, style: TextStyle(fontSize: 10, color: Colors.grey[600]))),
      ]),
      const SizedBox(height: 12),
      Expanded(child: chartData.isEmpty
          ? _emptyState('Sin actividad registrada')
          : LineChartWidget(title: '', data: chartData, color: _teal, fillArea: true, height: double.infinity)),
    ]));
  }

  Widget _buildByTypeSection() {
    final hotels = _n(_placesByType['hotel']);
    final restaurants = _n(_placesByType['restaurant']);
    final bars = _n(_placesByType['bar']);
    final total = hotels + restaurants + bars;
    return _card(height: 300, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _barIndicator(_amber), const Icon(Icons.pie_chart_rounded, size: 15, color: _amber),
        const SizedBox(width: 6),
        const Text('Por Tipo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 12),
      Expanded(child: total == 0
          ? _emptyState('Sin lugares')
          : DonutChartWidget(title: '', subtitle: '', data: [
        {'label': 'Hoteles', 'value': hotels, 'color': _blue},
        {'label': 'Restaurantes', 'value': restaurants, 'color': _green},
        {'label': 'Bares', 'value': bars, 'color': _amber},
      ], height: double.infinity, showLegend: true)),
      const SizedBox(height: 8),
      Row(children: [
        _typeCard('🏨', hotels, 'Hoteles', _blue, 'hotel'),
        const SizedBox(width: 8),
        _typeCard('🍽️', restaurants, 'Restaurantes', _green, 'restaurant'),
        const SizedBox(width: 8),
        _typeCard('🍹', bars, 'Bares', _amber, 'bar'),
      ]),
    ]));
  }

  Widget _typeCard(String emoji, int count, String label, Color color, String tipoFilter) {
    return Expanded(child: InkWell(
      onTap: () => widget.onNavigateToPlaces?.call(tipoFilter),
      borderRadius: BorderRadius.circular(8),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.2))),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ])),
    ));
  }

  Widget _buildTopPlacesSection() {
    final data = _topPlaces.take(6).map((p) => {
      'label': p['name']?.toString() ?? '',
      'value': p['totalScans'] ?? p['total_scans'] ?? 0,
    }).toList();
    return _card(height: 260, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _barIndicator(_amber), const Icon(Icons.bar_chart_rounded, size: 15, color: _amber),
        const SizedBox(width: 6),
        const Text('Top Establecimientos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        TextButton.icon(onPressed: () => widget.onNavigate?.call(widget.reportsIndex),
            icon: const Icon(Icons.analytics_rounded, size: 14),
            label: const Text('Ver reportes', style: TextStyle(fontSize: 11)),
            style: TextButton.styleFrom(foregroundColor: _teal)),
      ]),
      const SizedBox(height: 8),
      Expanded(child: data.isEmpty
          ? _emptyState('Sin escaneos')
          : BarChartWidget(title: '', data: data, color: _amber, height: double.infinity, showValues: true)),
    ]));
  }

  Widget _buildActivityTable() {
    return _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _barIndicator(_teal), const Icon(Icons.history_rounded, size: 15, color: _teal),
        const SizedBox(width: 6),
        const Text('Actividad Reciente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 12),
      SingleChildScrollView(scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
            headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600]),
            dataRowMinHeight: 40, dataRowMaxHeight: 48, dividerThickness: 0.5,
            columns: const [
              DataColumn(label: Text('Turista')), DataColumn(label: Text('Lugar')),
              DataColumn(label: Text('Tipo')), DataColumn(label: Text('Fecha y hora')),
            ],
            rows: _recentActivity.take(10).map((item) {
              final ts = item['timestamp']?.toString() ?? '';
              String dateLabel = ts;
              try { dateLabel = DateFormat('d MMM · HH:mm', 'es').format(DateTime.parse(ts)); } catch (_) {}
              return DataRow(cells: [
                DataCell(Text(item['userName']?.toString() ?? '—', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                DataCell(Text(item['placeName']?.toString() ?? '—', style: const TextStyle(fontSize: 13))),
                DataCell(_typeChip(item['type']?.toString() ?? item['placeType']?.toString() ?? '')),
                DataCell(Text(dateLabel, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
              ]);
            }).toList(),
          )),
    ]));
  }

  Widget _card({required Widget child, double? height}) => Container(height: height, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 2))]),
      child: child);

  Widget _barIndicator(Color color) => Container(width: 4, height: 16, margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)));

  Widget _emptyState(String msg) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(Icons.inbox_rounded, size: 36, color: Colors.grey[300]), const SizedBox(height: 6),
    Text(msg, style: TextStyle(fontSize: 12, color: Colors.grey[400]))]));

  Widget _typeChip(String type) {
    Color color; IconData icon;
    switch (type.toLowerCase()) {
      case 'hotel': color = _blue; icon = Icons.hotel_rounded; break;
      case 'restaurant': color = _green; icon = Icons.restaurant_rounded; break;
      case 'bar': color = _amber; icon = Icons.local_bar_rounded; break;
      default: color = Colors.grey; icon = Icons.place_rounded;
    }
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 11, color: color), const SizedBox(width: 3),
          Text(type, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
        ]));
  }
}