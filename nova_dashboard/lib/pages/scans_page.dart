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
  static const _teal  = Color(0xFF06B6A4);
  static const _kBlue  = Color(0xFF3B82F6);
  static const _kGreen = Color(0xFF10B981);
  static const _kAmber = Color(0xFFF59E0B);
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
                data: _scansByDay.map((i) => {'label': i['date']?.toString() ?? '', 'value': (i['count'] as num?)?.toInt() ?? 0}).toList(),
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
      _statCard('Total Escaneos', _totalScans.toString(), Icons.qr_code_scanner, _kBlue),
      _statCard('Hoy', _todayScans.toString(), Icons.today, _kGreen),
      _statCard('Promedio/Día', _avgScans.toStringAsFixed(1), Icons.analytics, _kAmber),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Franja de color superior (único acento de color)
        Container(height: 3, decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
        )),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A), height: 1.1)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ]),
          ]),
        ),
      ]));

  Widget _buildTopPlacesCard() => Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          const Text('Top 5 Lugares Más Escaneados',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        ]),
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
                decoration: BoxDecoration(color: _teal.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _teal.withOpacity(0.25))),
                child: Text('$scans esc.', style: const TextStyle(fontSize: 11, color: _teal, fontWeight: FontWeight.w600))),
          ]));
        })),
      ]));

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 60, color: Colors.red), const SizedBox(height: 16),
    Text(_error, textAlign: TextAlign.center), const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white))]));
}