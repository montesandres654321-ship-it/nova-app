// lib/pages/rewards_detail_page.dart
// ============================================================
// FIX: Botón "Canjear" en columna Estado para recompensas pendientes
// Usa PATCH /rewards/:id/redeem del backend
// ============================================================
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/reward_service.dart';
import '../models/reward_model.dart';

class RewardsDetailPage extends StatefulWidget {
  final String initialFilter;

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
    switch (_tableFilter) {
      case 'redeemed': result = result.where((r) =>  r.isRedeemedBool).toList(); break;
      case 'pending':  result = result.where((r) => !r.isRedeemedBool).toList(); break;
    }
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
    setState(() { _tableFilter = filter; _filteredRewards = _applyFilters(_allRewards); });
  }

  void _onSearch(String query) {
    setState(() { _searchQuery = query; _filteredRewards = _applyFilters(_allRewards); });
  }

  // ── CANJEAR RECOMPENSA ──────────────────────────────────
  Future<void> _redeemReward(RewardModel reward) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Text(reward.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          const Expanded(child: Text('Canjear Recompensa', style: TextStyle(fontSize: 16))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('¿Entregar esta recompensa?', style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _amber.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Turista: ${[reward.firstName, reward.lastName].where((s) => s != null && s.isNotEmpty).join(' ')}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Lugar: ${reward.placeName ?? 'N/A'}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Premio: ${reward.rewardName}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ),
          const SizedBox(height: 8),
          Text('Esta acción no se puede deshacer.', style: TextStyle(fontSize: 11, color: Colors.red[400])),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_rounded, size: 16),
            label: const Text('Entregar'),
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await RewardService.redeemReward(reward.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Recompensa "${reward.rewardName}" entregada exitosamente'),
        backgroundColor: _green,
      ));
      _loadData(); // Recargar lista
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al canjear: $e'),
        backgroundColor: Colors.red,
      ));
    }
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
        backgroundColor: _teal, foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadData, tooltip: 'Actualizar'),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error != null ? _buildError() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Barra superior
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 8)]),
          child: Row(children: [
            _counterBadge('Total', _totalCount, _teal, 'all'),
            const SizedBox(width: 8),
            _counterBadge('Canjeadas', _redeemedCount, _green, 'redeemed'),
            const SizedBox(width: 8),
            _counterBadge('Pendientes', _pendingCount, _amber, 'pending'),
            const SizedBox(width: 16),
            Expanded(child: TextField(
              controller: _searchCtrl, onChanged: _onSearch,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Buscar por turista, lugar o recompensa...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close, size: 16),
                    onPressed: () { _searchCtrl.clear(); _onSearch(''); })
                    : null,
                isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _teal)),
              ),
            )),
            const SizedBox(width: 12),
            Text('${_filteredRewards.length} resultados', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
        ),

        const SizedBox(height: 16),

        // Tabla
        Expanded(child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(children: [
            // Cabecera de tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(children: [
                _colHead('Turista', flex: 3),
                _colHead('Lugar', flex: 3),
                _colHead('Recompensa', flex: 2),
                _colHead('Fecha', flex: 2),
                _colHead('Estado', flex: 2),
                _colHead('Acción', flex: 2),
              ]),
            ),
            Expanded(
              child: _filteredRewards.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.card_giftcard_outlined, size: 52, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(_searchQuery.isNotEmpty ? 'Sin resultados para "$_searchQuery"'
                    : _tableFilter == 'redeemed' ? 'No hay canjeadas'
                    : _tableFilter == 'pending' ? 'No hay pendientes'
                    : 'No hay recompensas', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              ]))
                  : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _filteredRewards.length,
                itemBuilder: (_, i) => _RewardRow(
                  r: _filteredRewards[i],
                  index: i,
                  isLast: i == _filteredRewards.length - 1,
                  onRedeem: () => _redeemReward(_filteredRewards[i]),
                ),
              ),
            ),
          ]),
        )),
      ]),
    );
  }

  Widget _counterBadge(String label, int count, Color color, String filter) {
    final active = _tableFilter == filter;
    return InkWell(
      onTap: () => _setFilter(filter), borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: active ? color : color.withOpacity(0.06), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: active ? color : color.withOpacity(0.2), width: active ? 2 : 1)),
        child: Column(children: [
          Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
              color: active ? Colors.white : color)),
          Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.white70 : Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _colHead(String text, {int flex = 1}) => Expanded(flex: flex,
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
          color: Color(0xFF374151), letterSpacing: 0.6), overflow: TextOverflow.ellipsis));

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 56, color: Colors.red),
    const SizedBox(height: 16), Text(_error!, textAlign: TextAlign.center),
    const SizedBox(height: 20),
    ElevatedButton.icon(onPressed: _loadData, icon: const Icon(Icons.refresh), label: const Text('Reintentar'),
        style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white)),
  ]));
}

// ── Fila de tabla con striped + hover ─────────────────────────
class _RewardRow extends StatefulWidget {
  final RewardModel r;
  final int index;
  final bool isLast;
  final VoidCallback onRedeem;

  const _RewardRow({
    required this.r,
    required this.index,
    required this.isLast,
    required this.onRedeem,
  });

  @override
  State<_RewardRow> createState() => _RewardRowState();
}

class _RewardRowState extends State<_RewardRow> {
  static const _teal  = Color(0xFF06B6A4);
  static const _green = Color(0xFF059669);
  static const _amber = Color(0xFFD97706);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.r;

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
      dateLabel = DateFormat('yyyy-MM-dd', 'es').format(DateTime.parse(r.earnedAt));
    } catch (_) {
      dateLabel = r.earnedAt.length >= 10 ? r.earnedAt.substring(0, 10) : r.earnedAt;
    }

    // Fondo: hover > striped
    Color rowBg;
    if (_hovered) {
      rowBg = const Color(0xFFEEFBFA);
    } else if (widget.index % 2 == 0) {
      rowBg = Colors.white;
    } else {
      rowBg = const Color(0xFFF8FAFC);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: rowBg,
          border: widget.isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.8)),
          borderRadius: widget.isLast
              ? const BorderRadius.vertical(bottom: Radius.circular(12))
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(children: [

            // Turista
            Expanded(flex: 3, child: Row(children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _teal.withOpacity(0.12),
                child: Text(initial, style: const TextStyle(
                    color: _teal, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(displayName, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                if (r.email != null)
                  Text(r.email!, style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
              ])),
            ])),

            // Lugar
            Expanded(flex: 3, child: Row(children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.placeName ?? 'Sin lugar', style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                if (r.lugar != null)
                  Text(r.lugar!, style: const TextStyle(
                      fontSize: 10, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
              ])),
            ])),

            // Recompensa
            Expanded(flex: 2, child: Row(children: [
              Text(r.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(child: Text(r.rewardName,
                  style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
            ])),

            // Fecha
            Expanded(flex: 2, child: Text(dateLabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),

            // Estado — badge mejorado
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: r.isRedeemedBool
                    ? _green.withOpacity(0.12)
                    : _amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: r.isRedeemedBool
                      ? _green.withOpacity(0.30)
                      : _amber.withOpacity(0.30),
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: r.isRedeemedBool ? _green : _amber,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(r.isRedeemedBool ? 'Canjeada' : 'Pendiente',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: r.isRedeemedBool ? _green : _amber)),
              ]),
            )),

            // Acción — botón Entregar
            Expanded(flex: 2, child: r.isRedeemedBool
                ? Center(child: Icon(Icons.check_circle_rounded,
                    color: _green.withOpacity(0.5), size: 20))
                : Center(child: ElevatedButton.icon(
              onPressed: widget.onRedeem,
              icon: const Icon(Icons.card_giftcard_rounded, size: 13),
              label: const Text('Entregar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                minimumSize: const Size(0, 0),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ))),
          ]),
        ),
      ),
    );
  }

}