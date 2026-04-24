import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../models/place_type.dart';
import '../services/api_service.dart';
import '../widgets/place_card.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Explorar'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: AppColors.surface,
        automaticallyImplyLeading: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Hoteles'),
            Tab(text: 'Restaurantes'),
            Tab(text: 'Bares'),
          ],
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          dividerColor: AppColors.border,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _PlacesList(type: PlaceType.hotel),
          _PlacesList(type: PlaceType.restaurant),
          _PlacesList(type: PlaceType.bar),
        ],
      ),
    );
  }
}

// ── Tab de lista ───────────────────────────────────────────

class _PlacesList extends StatefulWidget {
  const _PlacesList({required this.type});

  final PlaceType type;

  @override
  State<_PlacesList> createState() => _PlacesListState();
}

class _PlacesListState extends State<_PlacesList>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<Place> _places = [];
  bool _loading = true;
  String _error = '';

  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  bool get wantKeepAlive => true;

  // ── Lifecycle ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shimmerAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
    _loadPlaces();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    _shimmerController.repeat(reverse: true);
    try {
      final result = await _fetch();
      if (!mounted) return;
      setState(() => _places = result);
      if (result.isEmpty) setState(() => _error = widget.type.emptyMessage);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = 'Error al cargar ${widget.type.title.toLowerCase()}: $e');
    } finally {
      if (mounted) {
        _shimmerController.stop();
        setState(() => _loading = false);
      }
    }
  }

  Future<List<Place>> _fetch() {
    switch (widget.type) {
      case PlaceType.hotel:
        return ApiService.getHotels();
      case PlaceType.restaurant:
        return ApiService.getRestaurants();
      case PlaceType.bar:
        return ApiService.getBars();
    }
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget content;
    String stateKey;

    if (_loading) {
      content = _buildSkeleton();
      stateKey = 'skeleton';
    } else if (_error.isNotEmpty) {
      content = _buildError();
      stateKey = 'error';
    } else {
      content = RefreshIndicator(
        onRefresh: _loadPlaces,
        color: AppColors.primary,
        child: ListView.builder(
          padding: const EdgeInsets.only(
            top: AppSpacing.xs,
            bottom: AppSpacing.xl,
          ),
          itemCount: _places.length,
          itemBuilder: (_, i) => PlaceCard(place: _places[i]),
        ),
      );
      stateKey = 'list';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(key: ValueKey(stateKey), child: content),
    );
  }

  // ── Estados ────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return FadeTransition(
      opacity: _shimmerAnimation,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        itemCount: 4,
        itemBuilder: (_, __) => _buildSkeletonCard(),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 170,
            decoration: const BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.md),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerWide(15),
                const SizedBox(height: AppSpacing.sm),
                _shimmerBox(12, 130),
                const SizedBox(height: AppSpacing.sm),
                _shimmerBox(12, 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmerWide(double height) => Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  Widget _shimmerBox(double height, double width) => Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      );

  Widget _buildError() {
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
              child: Icon(
                widget.type.icon,
                size: 44,
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _error,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _loadPlaces,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.mdAll,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
