import 'package:flutter/material.dart';
import 'scan_page.dart';
import '../models/place_model.dart';
import '../models/place_type.dart';
import '../core/design/app_back_button.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

class PlaceDetailPage extends StatelessWidget {
  const PlaceDetailPage({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final type = PlaceType.fromTipo(place.tipo);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, type),
          SliverToBoxAdapter(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (_, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              ),
              child: _buildContent(context, type),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero image (SliverAppBar) ──────────────────────────────

  SliverAppBar _buildSliverAppBar(BuildContext context, PlaceType type) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 52,
      leading: const Padding(
        padding: EdgeInsets.only(left: AppSpacing.sm),
        child: Center(
          child: AppBackButton(variant: AppBackButtonVariant.onPrimary),
        ),
      ),
      title: Text(
        place.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: _buildHeroImage(type),
      ),
    );
  }

  Widget _buildHeroImage(PlaceType type) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Hero(
          tag: 'place-hero-${place.id}',
          child: Image.network(
            place.imageUrl ?? type.placeholderImage,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, prog) {
              if (prog == null) return child;
              return const ColoredBox(
                color: AppColors.surfaceVariant,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => ColoredBox(
              color: AppColors.surfaceVariant,
              child: Icon(type.icon, size: 64, color: AppColors.textHint),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black38],
              stops: [0.55, 1.0],
            ),
          ),
        ),
      ],
    );
  }

  // ── Contenido scrollable ───────────────────────────────────

  Widget _buildContent(BuildContext context, PlaceType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(type),
        const Divider(height: 1, thickness: 1, color: AppColors.border),
        _buildMetaRow(type),
        if (type == PlaceType.hotel) ...[
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildHotelTimes(),
        ],
        if (place.description.isNotEmpty) ...[
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildSection(
            'Descripción',
            Text(
              place.description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
        if (place.amenities.isNotEmpty) ...[
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildSection(
            type.amenitiesLabel.replaceAll(':', ''),
            _buildAmenitiesWrap(),
          ),
        ],
        if (type != PlaceType.hotel && place.priceRange != null) ...[
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildPriceRow(type),
        ],
        if (place.phone?.isNotEmpty == true || place.address?.isNotEmpty == true) ...[
          const Divider(height: 1, thickness: 1, color: AppColors.border),
          _buildContactSection(),
        ],
        const SizedBox(height: AppSpacing.lg),
        _buildScanButton(context, type),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  // ── Secciones ──────────────────────────────────────────────

  Widget _buildHeader(PlaceType type) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: AppRadius.pillAll,
                ),
                child: Text(
                  type.singular,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  place.lugar,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(PlaceType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Text(
            place.rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (type == PlaceType.hotel && place.priceRange != null) ...[
            const Icon(
              Icons.payments_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              place.priceRange!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ] else if (type.hours.isNotEmpty) ...[
            const Icon(
              Icons.access_time_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              type.hours,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHotelTimes() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          _buildInfoTile('Check-in', '3:00 PM', Icons.login_rounded),
          const SizedBox(width: AppSpacing.md),
          _buildInfoTile('Check-out', '12:00 PM', Icons.logout_rounded),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          content,
        ],
      ),
    );
  }

  Widget _buildAmenitiesWrap() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: place.amenities
          .map((a) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppRadius.pillAll,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  a,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildPriceRow(PlaceType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      child: Row(
        children: [
          Text(
            type.priceLabel.trim().replaceAll(':', ''),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            place.priceRange ?? 'Consultar',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contacto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (place.phone?.isNotEmpty == true)
            _buildContactRow(
              Icons.phone_rounded,
              'Tel: ${place.phone}',
            ),
          if (place.address?.isNotEmpty == true)
            _buildContactRow(
              Icons.location_on_rounded,
              place.address!,
            ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón escanear ─────────────────────────────────────────

  Widget _buildScanButton(BuildContext context, PlaceType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ScanPage()),
          ),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: Text(type.scanLabel),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
