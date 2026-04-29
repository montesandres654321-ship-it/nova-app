import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../utils/app_theme.dart';
import '../widgets/charts/line_chart_widget.dart';
import '../widgets/charts/bar_chart_widget.dart';

class StatsDashboardPage extends StatefulWidget {
  const StatsDashboardPage({super.key});

  @override
  State<StatsDashboardPage> createState() => _StatsDashboardPageState();
}

class _StatsDashboardPageState extends State<StatsDashboardPage> {
  bool _loading = true;
  String _error = '';

  int _totalUsers = 0;
  int _activePlaces = 0;
  int _totalScans = 0;
  int _scansToday = 0;
  int _pendingRewards = 0;

  List<Map<String, dynamic>> _topPlaces = [];
  List<Map<String, dynamic>> _scansByDay = [];
  List<Map<String, dynamic>> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final summary = await AdminService.getDashboardSummary();
      final stats = await AdminService.getDashboardStats();

      if (summary['success'] == true) {
        _totalUsers = _n(summary['totalUsers']);
        _activePlaces = _n(summary['activePlaces']);
        _totalScans = _n(summary['totalScans']);
        _scansToday = _n(summary['scansToday']);
        _pendingRewards = _n(summary['pendingRewards']);
        _recentActivity =
        List<Map<String, dynamic>>.from(summary['recentActivity'] ?? []);
      }

      if (stats['success'] == true) {
        _scansByDay =
        List<Map<String, dynamic>>.from(stats['scansByDay'] ?? []);
        _topPlaces =
        List<Map<String, dynamic>>.from(stats['topPlaces'] ?? []);
      }

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static int _n(dynamic v) => v is num ? v.toInt() : 0;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStats(),
              const SizedBox(height: 20),
              if (wide)
                Row(
                  children: [
                    Expanded(child: _buildScansChart()),
                    const SizedBox(width: 20),
                    Expanded(child: _buildTopPlacesChart()),
                  ],
                )
              else ...[
                _buildScansChart(),
                const SizedBox(height: 20),
                _buildTopPlacesChart(),
              ],
              const SizedBox(height: 20),
              _buildRecentActivity(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _card("Usuarios", _totalUsers),
        _card("Lugares activos", _activePlaces),
        _card("Escaneos", _totalScans),
        _card("Hoy", _scansToday),
      ],
    );
  }

  Widget _card(String title, int value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScansChart() {
    final data = _scansByDay.map((e) {
      return {
        'label': e['date'] ?? '',
        'value': e['count'] ?? 0,
      };
    }).toList();

    return Container(
      height: 300,
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: LineChartWidget(
        title: 'Escaneos por día',
        data: data,
      ),
    );
  }

  Widget _buildTopPlacesChart() {
    final data = _topPlaces.map((e) {
      return {
        'label': e['name'] ?? '',
        'value': e['totalScans'] ?? 0,
      };
    }).toList();

    return Container(
      height: 300,
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: BarChartWidget(
        title: 'Top lugares',
        data: data,
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _recentActivity.take(10).map((e) {
          return ListTile(
            title: Text(e['userName'] ?? ''),
            subtitle: Text(e['placeName'] ?? ''),
            trailing: Text(
              _formatDate(e['timestamp']),
              style: const TextStyle(fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(String? date) {
    try {
      return DateFormat('d MMM HH:mm', 'es')
          .format(DateTime.parse(date ?? ''));
    } catch (_) {
      return '';
    }
  }
}