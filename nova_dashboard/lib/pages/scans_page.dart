// lib/pages/scans_page.dart
// FIX: Color 0xFF06B6A4 (era deepPurple) + responsive
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../widgets/charts/line_chart_widget.dart';

class ScansPage extends StatefulWidget {
  const ScansPage({super.key});
  @override
  State<ScansPage> createState() => _ScansPageState();
}

class _ScansPageState extends State<ScansPage> {
  static const _teal = Color(0xFF06B6A4);
  bool _loading = true; String _error = '';
  int _totalScans = 0, _todayScans = 0; double _avgScans = 0;
  List<Map<String, dynamic>> _scansByDay = [], _topPlaces = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final data = await AdminService.getDashboardStats();
      if (mounted && data['success'] == true) {
        final stats = data['stats'];
        final scansByDay = List<Map<String, dynamic>>.from(data['scansByDay'] ?? []);
        final topPlaces = List<Map<String, dynamic>>.from(data['topPlaces'] ?? []);
        double avg = 0;
        if (scansByDay.isNotEmpty) {
          final total = scansByDay.map((e) => (e['count'] as num).toInt()).reduce((a, b) => a + b);
          avg = total / scansByDay.length;
        }
        setState(() { _totalScans = stats['scans'] ?? 0;
        _todayScans = scansByDay.isNotEmpty ? ((scansByDay.first['count'] as num?)?.toInt() ?? 0) : 0;
        _avgScans = avg; _scansByDay = scansByDay; _topPlaces = topPlaces; _loading = false; });
      }
    } catch (e) { if (mounted) setState(() { _error = 'Error: $e'; _loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis de Escaneos'),
          backgroundColor: _teal, foregroundColor: Colors.white,
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Actualizar')]),
      body: _loading ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error.isNotEmpty ? _buildError()
          : LayoutBuilder(builder: (ctx, constraints) {
        final isWide = constraints.maxWidth > 700;
        return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          _buildStatsCards(isWide), const SizedBox(height: 20),
          if (_scansByDay.isNotEmpty) ...[
            LineChartWidget(title: 'Escaneos por Día', subtitle: 'Últimos 7 días',
                data: _scansByDay.map((i) => {'label': i['day']?.toString() ?? '', 'value': (i['count'] as num?)?.toInt() ?? 0}).toList(),
                color: _teal, fillArea: true, height: 280),
            const SizedBox(height: 20),
          ],
          if (_topPlaces.isNotEmpty) _buildTopPlacesCard(),
        ]));
      }),
    );
  }

  Widget _buildStatsCards(bool isWide) {
    final cards = [
      _statCard('Total Escaneos', _totalScans.toString(), Icons.qr_code_scanner, Colors.blue),
      _statCard('Hoy', _todayScans.toString(), Icons.today, Colors.green),
      _statCard('Promedio/Día', _avgScans.toStringAsFixed(1), Icons.analytics, Colors.orange),
    ];
    if (isWide) {
      return Row(children: [
        Expanded(child: cards[0]), const SizedBox(width: 14),
        Expanded(child: cards[1]), const SizedBox(width: 14),
        Expanded(child: cards[2]),
      ]);
    }
    return Column(children: [
      Row(children: [Expanded(child: cards[0]), const SizedBox(width: 10), Expanded(child: cards[1])]),
      const SizedBox(height: 10), cards[2],
    ]);
  }

  Widget _statCard(String title, String value, IconData icon, Color color) => Container(
      padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28), const SizedBox(height: 10),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]));

  Widget _buildTopPlacesCard() => Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Top 5 Lugares Más Escaneados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...(_topPlaces.take(5).map((place) {
          final scans = (place['scans'] as num?)?.toInt() ?? 0;
          final name = place['name']?.toString() ?? 'Sin nombre';
          final tipo = place['tipo']?.toString() ?? '';
          String emoji = '📍';
          switch (tipo.toLowerCase()) { case 'hotel': emoji = '🏨'; break; case 'restaurant': emoji = '🍽️'; break; case 'bar': emoji = '🍹'; break; }
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: _teal.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18)))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(tipo.toUpperCase(), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(20)),
                child: Text('$scans esc.', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600))),
          ]));
        })),
      ]));

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 16),
    Text(_error, textAlign: TextAlign.center), const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white))]));
}