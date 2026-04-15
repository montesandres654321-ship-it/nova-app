// lib/pages/scans_page.dart
// ✅ COMPLETO Y CORREGIDO

import 'package:flutter/material.dart';
import 'package:nova_dashboard/services/admin_service.dart';
import 'package:nova_dashboard/widgets/charts/line_chart_widget.dart';

class ScansPage extends StatefulWidget {
  const ScansPage({super.key});

  @override
  State<ScansPage> createState() => _ScansPageState();
}

class _ScansPageState extends State<ScansPage> {
  bool _loading = true;
  String _error = '';
  int _totalScans = 0;
  int _todayScans = 0;
  double _avgScans = 0;
  List<Map<String, dynamic>> _scansByDay = [];
  List<Map<String, dynamic>> _topPlaces = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      // ✅ CORRECCIÓN: Usar instancia en lugar de método estático
      final data = await AdminService.getDashboardStats();

      if (mounted && data['success'] == true) {
        final stats = data['stats'];
        final scansByDay = List<Map<String, dynamic>>.from(
          data['scansByDay'] ?? [],
        );
        final topPlaces = List<Map<String, dynamic>>.from(
          data['topPlaces'] ?? [],
        );

        double avg = 0;
        if (scansByDay.isNotEmpty) {
          final total = scansByDay
              .map((e) => (e['count'] as num).toInt())
              .reduce((a, b) => a + b);
          avg = total / scansByDay.length;
        }

        setState(() {
          _totalScans = stats['scans'] ?? 0;
          _todayScans = scansByDay.isNotEmpty
              ? ((scansByDay.first['count'] as num?)?.toInt() ?? 0)
              : 0;
          _avgScans = avg;
          _scansByDay = scansByDay;
          _topPlaces = topPlaces;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Análisis de Escaneos'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar datos',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? _buildErrorView()
          : _buildDashboard(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(),
          const SizedBox(height: 24),
          if (_scansByDay.isNotEmpty) ...[
            LineChartWidget(
              title: 'Escaneos por Día',
              subtitle: 'Últimos 7 días',
              data: _scansByDay.map((item) {
                return {
                  'label': item['day']?.toString() ?? '',
                  'value': (item['count'] as num?)?.toInt() ?? 0,
                };
              }).toList(),
              color: Colors.deepPurple,
              fillArea: true,
              height: 300,
            ),
            const SizedBox(height: 24),
          ],
          if (_topPlaces.isNotEmpty) ...[
            _buildTopPlacesCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Escaneos',
            _totalScans.toString(),
            Icons.qr_code_scanner,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Hoy',
            _todayScans.toString(),
            Icons.today,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Promedio/Día',
            _avgScans.toStringAsFixed(1),
            Icons.analytics,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPlacesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 5 Lugares Más Escaneados',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...(_topPlaces.take(5).map((place) {
            final scans = (place['scans'] as num?)?.toInt() ?? 0;
            final name = place['name']?.toString() ?? 'Sin nombre';
            final tipo = place['tipo']?.toString() ?? '';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        _getTipoEmoji(tipo),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          tipo.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$scans escaneos',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList()),
        ],
      ),
    );
  }

  String _getTipoEmoji(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'hotel':
        return '🏨';
      case 'restaurant':
        return '🍽️';
      case 'bar':
        return '🍺';
      default:
        return '📍';
    }
  }
}