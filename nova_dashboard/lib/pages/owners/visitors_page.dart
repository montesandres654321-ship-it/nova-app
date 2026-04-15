// lib/pages/owners/visitors_page.dart
// Lista completa de visitantes únicos del lugar del propietario
// Usa GET /places/my-place/visitors
// Campos: Avatar | Nombre | Email | Nº visitas | Última visita

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';

class OwnerVisitorsPage extends StatefulWidget {
  const OwnerVisitorsPage({super.key});

  @override
  State<OwnerVisitorsPage> createState() => _OwnerVisitorsPageState();
}

class _OwnerVisitorsPageState extends State<OwnerVisitorsPage> {
  static const _teal  = Color(0xFF06B6A4);
  static const _teal2 = Color(0xFF0891B2);

  bool   _loading = true;
  String _error   = '';
  List<Map<String, dynamic>> _visitors = [];
  List<Map<String, dynamic>> _filtered = [];
  String _search  = '';

  @override
  void initState() {
    super.initState();
    _loadVisitors();
  }

  Future<void> _loadVisitors() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final result = await AdminService.getMyPlaceVisitors();
      if (result['success'] == true) {
        final list = (result['visitors'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        if (mounted) setState(() {
          _visitors = list;
          _filtered = list;
          _loading  = false;
        });
      } else {
        throw Exception(result['error'] ?? 'Error al cargar');
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  void _filterVisitors(String query) {
    setState(() {
      _search   = query;
      if (query.isEmpty) {
        _filtered = _visitors;
      } else {
        final q = query.toLowerCase();
        _filtered = _visitors.where((v) {
          final name = '${v['first_name'] ?? ''} ${v['last_name'] ?? ''}'.toLowerCase();
          final email = (v['email'] ?? '').toString().toLowerCase();
          final user  = (v['username'] ?? '').toString().toLowerCase();
          return name.contains(q) || email.contains(q) || user.contains(q);
        }).toList();
      }
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      return DateFormat('d MMM yyyy, HH:mm', 'es')
          .format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      appBar: AppBar(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context)),
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Visitantes',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              if (!_loading && _error.isEmpty)
                Text('${_visitors.length} turistas únicos',
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _loadVisitors,
              tooltip: 'Actualizar'),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [

        // ── Barra de búsqueda ────────────────────────────
        Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
                decoration: InputDecoration(
                    hintText: 'Buscar turista...',
                    prefixIcon: const Icon(Icons.search, color: _teal),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _filterVisitors('');
                        })
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _teal)),
                    filled: true, fillColor: Colors.grey[50],
                    isDense: true),
                onChanged: _filterVisitors)),

        // ── Contenido ─────────────────────────────────────
        Expanded(child: _loading
            ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _teal),
              SizedBox(height: 12),
              Text('Cargando visitantes...'),
            ]))
            : _error.isNotEmpty
            ? _buildError()
            : _filtered.isEmpty
            ? _buildEmpty()
            : _buildList()),
      ]),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
        color: _teal,
        onRefresh: _loadVisitors,
        child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _buildCard(_filtered[i], i + 1)));
  }

  Widget _buildCard(Map<String, dynamic> v, int rank) {
    final firstName  = (v['first_name'] ?? '').toString();
    final lastName   = (v['last_name']  ?? '').toString();
    final name       = '$firstName $lastName'.trim();
    final displayName = name.isNotEmpty ? name : (v['username'] ?? 'Turista').toString();
    final email      = (v['email'] ?? '').toString();
    final visits     = (v['visit_count'] as num?)?.toInt() ?? 0;
    final lastVisit  = _formatDate(v['last_visit']?.toString());
    final initial    = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    // Color del ranking top 3
    Color rankColor = _teal;
    if (rank == 1) rankColor = const Color(0xFFD97706);
    if (rank == 2) rankColor = Colors.grey[600]!;
    if (rank == 3) rankColor = const Color(0xFF92400E);

    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 8, offset: const Offset(0, 2))]),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [

          // Número de ranking
          Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                  color: rank <= 3
                      ? rankColor.withOpacity(0.12)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text('$rank',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: rank <= 3 ? rankColor : Colors.grey[500])))),

          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
              radius: 22,
              backgroundColor: _teal.withOpacity(0.12),
              child: Text(initial,
                  style: const TextStyle(
                      color: _teal,
                      fontWeight: FontWeight.bold,
                      fontSize: 16))),

          const SizedBox(width: 12),

          // Nombre y email
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                if (email.isNotEmpty)
                  Text(email,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
              ])),

          const SizedBox(width: 12),

          // Estadísticas
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.qr_code_scanner_rounded,
                  size: 14, color: _teal),
              const SizedBox(width: 4),
              Text('$visits',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _teal)),
              const SizedBox(width: 4),
              Text(visits == 1 ? 'visita' : 'visitas',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ]),
            const SizedBox(height: 3),
            Text(lastVisit,
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ]),
        ]),
      ),
    );
  }

  Widget _buildError() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 56, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton.icon(
            onPressed: _loadVisitors,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal, foregroundColor: Colors.white)),
      ]));

  Widget _buildEmpty() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(
            _search.isNotEmpty
                ? 'Sin resultados para "$_search"'
                : 'Aún no hay visitantes registrados.\nColoca el código QR en tu establecimiento.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center),
      ]));
}