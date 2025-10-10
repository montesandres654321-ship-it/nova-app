// lib/pages/history_page.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'scan_record.dart';
import 'api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ScanRecord> _records = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final scans = await ApiService.getScanHistory();
      setState(() => _records = scans);

      if (scans.isEmpty) {
        setState(() => _error = 'No hay escaneos registrados');
      }
    } catch (e) {
      setState(() => _error = 'Error al cargar historial: $e');
      print('❌ Error en _loadHistory: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Escaneos"),
        backgroundColor: const Color(0xFF06B6A4),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHistory,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      )
          : _records.isEmpty
          ? const Center(
        child: Text(
          "No hay escaneos registrados",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadHistory,
        child: ListView.builder(
          itemCount: _records.length,
          itemBuilder: (context, i) {
            final record = _records[i];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: _getPlaceIcon(record.type),
                title: Text(
                  record.local,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.place),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(record.time),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: Text(
                  _timeAgo(record.time),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return const Icon(Icons.hotel, color: Colors.blue);
      case 'restaurant':
        return const Icon(Icons.restaurant, color: Colors.orange);
      case 'bar':
        return const Icon(Icons.local_bar, color: Colors.red);
      default:
        return const Icon(Icons.place, color: Colors.grey);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 30) return 'Hace ${diff.inDays}d';
    return 'Hace ${(diff.inDays / 30).floor()}mes';
  }
}