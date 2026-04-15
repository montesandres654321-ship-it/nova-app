// lib/pages/rewards_detail_page.dart
// ============================================================
// NUEVA PÁGINA: Detalle de recompensas a pantalla completa
// Se accede desde los stat cards de RewardsPage
// Recibe el filtro inicial ('all', 'redeemed', 'pending')
// Muestra la tabla con búsqueda, filtros y espacio amplio
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/reward_service.dart';
import '../models/reward_model.dart';

class RewardsDetailPage extends StatefulWidget {
  final String initialFilter; // 'all' | 'redeemed' | 'pending'

  const RewardsDetailPage({
    super.key,
    this.initialFilter = 'all',
  });

  @override
  State<RewardsDetailPage> createState() => _RewardsDetailPageState();
}

class _RewardsDetailPageState extends State<RewardsDetailPage> {
  static const _teal  = Color(0xFF06B6A4);
  static const _green = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);

  List<RewardModel> _allRewards      = [];
  List<RewardModel> _filteredRewards = [];
  bool    _loading      = true;
  String? _error;
  late String _tableFilter;
  String _searchQuery = '';

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tableFilter = widget.initialFilter;
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rewards = await RewardService.getAllRewards();
      if (!mounted) return;
      setState(() {
        _allRewards      = rewards;
        _filteredRewards = _applyFilters(rewards);
        _loading         = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<RewardModel> _applyFilters(List<RewardModel> list) {
    var result = list;

    // Filtro por estado
    switch (_tableFilter) {
      case 'redeemed': result = result.where((r) =>  r.isRedeemedBool).toList(); break;
      case 'pending':  result = result.where((r) => !r.isRedeemedBool).toList(); break;
    }

    // Filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((r) {
        final name = '${r.firstName ?? ''} ${r.lastName ?? ''}'.toLowerCase();
        final place = (r.placeName ?? '').toLowerCase();
        final reward = r.rewardName.toLowerCase();
        return name.contains(q) || place.contains(q) || reward.contains(q);
      }).toList();
    }

    return result;
  }

  void _setFilter(String filter) {
    setState(() {
      _tableFilter     = filter;
      _filteredRewards = _applyFilters(_allRewards);
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery     = query;
      _filteredRewards = _applyFilters(_allRewards);
    });
  }

  String get _pageTitle {
    switch (_tableFilter) {
      case 'redeemed': return 'Recompensas Canjeadas';
      case 'pending':  return 'Recompensas Pendientes';
      default:         return 'Todas las Recompensas';
    }
  }

  int get _totalCount    => _allRewards.length;
  int get _redeemedCount => _allRewards.where((r) =>  r.isRedeemedBool).length;
  int get _pendingCount  => _allRewards.where((r) => !r.isRedeemedBool).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(_pageTitle),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null
          ? _buildError()
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // ── Barra superior: resumen + búsqueda + filtros ──
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
                color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
          ),
          child: Row(children: [
            // Contadores
            _counterBadge('Total', _totalCount, _teal, 'all'),
            const SizedBox(width: 8),
            _counterBadge('Canjeadas', _redeemedCount, _green, 'redeemed'),
            const SizedBox(width: 8),
            _counterBadge('Pendientes', _pendingCount, _amber, 'pending'),

            const SizedBox(width: 16),

            // Búsqueda
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Buscar por turista, lugar o recompensa...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        _onSearch('');
                      })
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _teal)),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Cantidad de resultados
            Text(
              '${_filteredRewards.length} resultados',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // ── Tabla ───────────────────────────────────────
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: Colors.grey.withOpacity(0.08), blurRadius: 8)],
            ),
            child: Column(children: [

              // Cabecera columnas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12)),
                ),
                child: Row(children: [
                  _colHead('Turista',    flex: 3),
                  _colHead('Lugar',      flex: 3),
                  _colHead('Recompensa', flex: 3),
                  _colHead('Fecha',      flex: 2),
                  _colHead('Estado',     flex: 2),
                ]),
              ),
              const Divider(height: 1),

              // Lista
              Expanded(
                child: _filteredRewards.isEmpty
                    ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.card_giftcard_outlined,
                          size: 52, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No hay resultados para "$_searchQuery"'
                            : _tableFilter == 'redeemed'
                            ? 'No hay recompensas canjeadas'
                            : _tableFilter == 'pending'
                            ? 'No hay recompensas pendientes'
                            : 'No hay recompensas registradas',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey[500]),
                      ),
                    ]))
                    : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: _filteredRewards.length,
                  separatorBuilder: (_, __) =>
                  const Divider(height: 1, thickness: 0.5),
                  itemBuilder: (_, i) =>
                      _buildRow(_filteredRewards[i]),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _counterBadge(String label, int count, Color color, String filter) {
    final active = _tableFilter == filter;
    return InkWell(
      onTap: () => _setFilter(filter),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color : color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? color : color.withOpacity(0.2),
              width: active ? 2 : 1),
        ),
        child: Column(children: [
          Text(count.toString(), style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold,
              color: active ? Colors.white : color)),
          Text(label, style: TextStyle(
              fontSize: 10,
              color: active ? Colors.white70 : Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _colHead(String text, {int flex = 1}) => Expanded(
      flex: flex,
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: Colors.grey[600], letterSpacing: 0.5),
          overflow: TextOverflow.ellipsis));

  Widget _buildRow(RewardModel r) {
    final name = [r.firstName, r.lastName]
        .where((s) => s != null && s.isNotEmpty).join(' ');
    final displayName = name.isNotEmpty ? name : (r.email ?? 'Turista');
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'T';

    String emoji = '📍';
    switch (r.placeType?.toLowerCase()) {
      case 'hotel':      emoji = '🏨'; break;
      case 'restaurant': emoji = '🍽️'; break;
      case 'bar':        emoji = '🍹'; break;
    }

    String dateLabel = '';
    try {
      dateLabel = DateFormat('d MMM yyyy', 'es').format(
          DateTime.parse(r.earnedAt));
    } catch (_) {
      dateLabel = r.earnedAt.length >= 10
          ? r.earnedAt.substring(0, 10) : r.earnedAt;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        // Turista
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(radius: 16,
              backgroundColor: _teal.withOpacity(0.1),
              child: Text(initial,
                  style: const TextStyle(
                      color: _teal, fontSize: 12,
                      fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                if (r.email != null)
                  Text(r.email!,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
              ])),
        ])),

        // Lugar
        Expanded(flex: 3, child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.placeName ?? 'Sin lugar',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                if (r.lugar != null)
                  Text(r.lugar!,
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      overflow: TextOverflow.ellipsis),
              ])),
        ])),

        // Recompensa
        Expanded(flex: 3, child: Row(children: [
          Text(r.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(r.rewardName,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis)),
        ])),

        // Fecha
        Expanded(flex: 2, child: Text(dateLabel,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]))),

        // Estado
        Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: r.isRedeemedBool
                    ? _green.withOpacity(0.08) : _amber.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Text(
                r.isRedeemedBool ? 'Canjeada' : 'Pendiente',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600,
                    color: r.isRedeemedBool ? _green : _amber),
                textAlign: TextAlign.center))),
      ]),
    );
  }

  Widget _buildError() => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 56, color: Colors.red),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal, foregroundColor: Colors.white)),
      ]));
}