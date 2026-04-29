import 'package:flutter/material.dart';
import '../models/scan_record.dart';
import '../services/api_service.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<ScanRecord> _records = [];
  bool _loading = true;
  String _error = '';

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ── Data ───────────────────────────────────────────────────

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
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Helpers ────────────────────────────────────────────────

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return Icons.hotel_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'bar':
        return Icons.local_bar_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return AppColors.primaryLight;
      case 'restaurant':
        return AppColors.warning;
      case 'bar':
        return AppColors.error;
      default:
        return AppColors.textHint;
    }
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return 'Hotel';
      case 'restaurant':
        return 'Restaurante';
      case 'bar':
        return 'Bar';
      default:
        return type;
    }
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year}  $hour:$min';
  }

  String _timeAgo(DateTime dt) {
    final localDt = dt.toLocal();
    final diff = DateTime.now().difference(localDt);

    if (diff.isNegative || diff.inSeconds < 60) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'Hace ${(diff.inDays / 7).floor()} sem';
    if (diff.inDays < 365) {
      final m = (diff.inDays / 30).floor();
      return 'Hace $m mes${m > 1 ? 'es' : ''}';
    }
    final y = (diff.inDays / 365).floor();
    return 'Hace $y año${y > 1 ? 's' : ''}';
  }

  String _dateGroup(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    if (diff < 7) return 'Esta semana';
    if (diff < 30) return 'Este mes';
    return 'Anteriores';
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.surface,
        automaticallyImplyLeading: false,
        leadingWidth: 52,
        leading: Navigator.canPop(context)
            ? const Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Center(child: AppBackButton()),
              )
            : null,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _loadHistory,
            tooltip: 'Actualizar',
            color: AppColors.textSecondary,
          ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _records.isNotEmpty
              ? _buildList()
              : _error == 'No hay escaneos registrados'
                  ? _buildEmptyState()
                  : _buildErrorState(),
    );
  }

  // ── Estados ────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.sm,
        bottom: AppSpacing.xl,
      ),
      itemCount: 5,
      itemBuilder: (_, __) => _buildSkeletonItem(),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _shimmerBox(44, 44, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerWide(13),
                const SizedBox(height: 6),
                _shimmerBox(10, 110),
                const SizedBox(height: 6),
                _shimmerBox(10, 72),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _shimmerBox(10, 50),
        ],
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = AppRadius.sm}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _shimmerWide(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 44,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Aún no has escaneado lugares',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Cuando escanees un código QR, el registro aparecerá aquí.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 44,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'No se pudo cargar el historial',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.mdAll),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lista ──────────────────────────────────────────────────

  Widget _buildList() {
    final groups = <String, List<ScanRecord>>{};
    final groupOrder = <String>[];
    for (final r in _records) {
      final key = _dateGroup(r.time);
      if (!groups.containsKey(key)) {
        groups[key] = [];
        groupOrder.add(key);
      }
      groups[key]!.add(r);
    }

    final items = <_ListItem>[];
    for (final group in groupOrder) {
      items.add(_ListItem.header(group));
      for (final r in groups[group]!) {
        items.add(_ListItem.record(r));
      }
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              bottom: AppSpacing.xl,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final item = items[i];
                  return item.isHeader
                      ? _buildGroupHeader(item.label!)
                      : _buildScanItem(item.record!);
                },
                childCount: items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Divider(
              color: AppColors.border,
              height: 1,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanItem(ScanRecord r) {
    final color = _typeColor(r.type);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono del tipo de lugar
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(_typeIcon(r.type), color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),

          // Contenido principal
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.local,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _TypePill(label: _typeLabel(r.type), color: color),
                    if (r.place.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Text(
                        '·',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          r.place,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDateTime(r.time),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Columna derecha: tiempo relativo + badge de recompensa
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _timeAgo(r.time),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
              if (r.hasReward) ...[
                const SizedBox(height: AppSpacing.xs),
                _RewardBadge(name: r.rewardName),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 90),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.card_giftcard_rounded,
            size: 10,
            color: AppColors.warning,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              name ?? 'Premio',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// Tipo interno para la lista flat de headers + records
class _ListItem {
  final bool isHeader;
  final String? label;
  final ScanRecord? record;

  const _ListItem._({required this.isHeader, this.label, this.record});

  factory _ListItem.header(String label) =>
      _ListItem._(isHeader: true, label: label);

  factory _ListItem.record(ScanRecord r) =>
      _ListItem._(isHeader: false, record: r);
}
