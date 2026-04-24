// lib/pages/history_page.dart
// ============================================================
// HISTORIAL DE ESCANEOS — Nova App Móvil
// ============================================================
// Imports corregidos: api_service desde services/, scan_record desde models/
// ============================================================

import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/api_service.dart';

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
    setState(() { _loading = true; _error = ''; });
    try {
      final scans = await ApiService.getScanHistory();
      setState(() => _records = scans);
      if (scans.isEmpty) setState(() => _error = 'No hay escaneos registrados');
    } catch (e) {
      setState(() => _error = 'Error al cargar historial: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Escaneos"),
        backgroundColor: const Color(0xFF06B6A4), foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadHistory, tooltip: 'Actualizar')],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadHistory, child: const Text('Reintentar')),
      ]))
          : RefreshIndicator(onRefresh: _loadHistory,
          child: ListView.builder(itemCount: _records.length, itemBuilder: (_, i) {
            final r = _records[i];
            return Card(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: _getPlaceIcon(r.type),
                  title: Text(r.local, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(r.place),
                    const SizedBox(height: 4),
                    Text(_formatDateTime(r.time), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ]),
                  trailing: Text(_timeAgo(r.time), style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                ));
          })),
    );
  }

  Widget _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel': return const Icon(Icons.hotel, color: Colors.blue);
      case 'restaurant': return const Icon(Icons.restaurant, color: Colors.orange);
      case 'bar': return const Icon(Icons.local_bar, color: Colors.red);
      default: return const Icon(Icons.place, color: Colors.grey);
    }
  }

  String _formatDateTime(DateTime dt) => '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _timeAgo(DateTime dt) {
    // El backend guarda en UTC, convertir a local para comparar
    final localDt = dt.toLocal();
    final diff = DateTime.now().difference(localDt);

    // Si la diferencia es negativa (zona horaria), mostrar "Ahora"
    if (diff.isNegative || diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
    if (diff.inDays < 365) return 'Hace ${(diff.inDays / 30).floor()} mes${(diff.inDays / 30).floor() > 1 ? 'es' : ''}';
    return 'Hace ${(diff.inDays / 365).floor()} año${(diff.inDays / 365).floor() > 1 ? 's' : ''}';
  }
}