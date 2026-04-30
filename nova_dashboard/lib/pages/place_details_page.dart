// lib/pages/place_details_page.dart
// ============================================================
// REDESIGN: SaaS panel · hero image · KPI cards · responsive
// Lógica y navegación sin cambios
// ============================================================
import 'package:flutter/material.dart';
import '../models/place.dart';
import 'places/form_page.dart';
import 'places/qr_dialog.dart';

// ── Design tokens ─────────────────────────────────────────────
const _kPrimary   = Color(0xFF06B6A4);
const _kBgPage    = Color(0xFFF1F5F9);
const _kTextHead  = Color(0xFF0F172A);
const _kTextMuted = Color(0xFF64748B);
const _kTextSub   = Color(0xFF94A3B8);
const _kBorder    = Color(0xFFE2E8F0);
const _kBlue      = Color(0xFF3B82F6);
const _kGreen     = Color(0xFF10B981);
const _kAmber     = Color(0xFFF59E0B);

// ─────────────────────────────────────────────────────────────
class PlaceDetailsPage extends StatelessWidget {
  final Place place;
  const PlaceDetailsPage({super.key, required this.place});

  Color get _typeColor {
    switch (place.tipo.toLowerCase()) {
      case 'hotel':      return _kBlue;
      case 'restaurant': return _kGreen;
      case 'bar':        return _kAmber;
      default:           return _kTextSub;
    }
  }

  IconData get _typeIcon {
    switch (place.tipo.toLowerCase()) {
      case 'hotel':      return Icons.hotel_rounded;
      case 'restaurant': return Icons.restaurant_rounded;
      case 'bar':        return Icons.local_bar_rounded;
      default:           return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kTextHead,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: const BackButton(color: _kTextHead),
        titleSpacing: 0,
        title: Text(
          place.name,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: _kTextHead),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20, color: _kTextMuted),
            tooltip: 'Editar',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(
                    builder: (_) => PlaceFormPage(place: place))),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 20, color: _kTextMuted),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 6),
            elevation: 4,
            onSelected: (action) {
              if (action == 'qr') {
                showDialog(context: context,
                    builder: (_) => QRDialog(place: place));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'qr',
                height: 42,
                child: Row(children: [
                  Icon(Icons.qr_code_rounded, size: 16, color: _kPrimary),
                  SizedBox(width: 10),
                  Text('Ver código QR',
                      style: TextStyle(fontSize: 13, color: _kPrimary,
                          fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: _kBorder),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Hero ──────────────────────────────────────
            _buildHero(),

            // ── Nombre + ubicación ─────────────────────────
            _buildNameSection(),

            // ── Contenido responsive ───────────────────────
            LayoutBuilder(builder: (_, constraints) {
              final isWide = constraints.maxWidth > 700;
              return Padding(
                padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 280,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _leftColumn(context),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _rightColumn(context),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _mobileColumn(context),
                      ),
              );
            }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────
  Widget _buildHero() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen o placeholder
          (place.imageUrl != null && place.imageUrl!.isNotEmpty)
              ? Image.network(
                  place.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _heroPlaceholder(),
                )
              : _heroPlaceholder(),

          // Gradiente inferior
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Badge de tipo (top-left)
          Positioned(
            top: 12, left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: _typeColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6, offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(place.tipoEmoji,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(place.tipoLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ),

          // Badge de estado (top-right)
          Positioned(
            top: 12, right: 12,
            child: _StatusBadge(isActive: place.isActive, onHero: true),
          ),
        ],
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: _typeColor.withOpacity(0.1),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_typeIcon, size: 56, color: _typeColor.withOpacity(0.45)),
        const SizedBox(height: 8),
        Text('Sin imagen',
            style: TextStyle(
                fontSize: 12, color: _typeColor.withOpacity(0.55))),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // NOMBRE + UBICACIÓN
  // ─────────────────────────────────────────────────────────
  Widget _buildNameSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(place.name,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _kTextHead,
                height: 1.2)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 14, color: _kTextSub),
          const SizedBox(width: 4),
          Text(place.lugar,
              style: const TextStyle(fontSize: 13, color: _kTextMuted)),
          if (place.address != null && place.address!.isNotEmpty) ...[
            const Text(' · ',
                style: TextStyle(fontSize: 13, color: _kTextSub)),
            Expanded(
              child: Text(place.address!,
                  style: const TextStyle(fontSize: 13, color: _kTextMuted),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ]),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // KPI ROW (datos del modelo)
  // ─────────────────────────────────────────────────────────
  Widget _buildKpiRow() {
    final rating = place.rating > 0
        ? place.rating.toStringAsFixed(1) : '—';
    final services = place.amenities.length.toString();
    final reward = place.hasReward
        ? (place.rewardStock?.toString() ?? '∞') : '—';

    return Row(children: [
      Expanded(child: _KpiMini(
          icon: Icons.star_rounded,
          label: 'Valoración',
          value: rating,
          color: _kAmber)),
      const SizedBox(width: 10),
      Expanded(child: _KpiMini(
          icon: Icons.check_circle_outline_rounded,
          label: 'Servicios',
          value: services,
          color: _kPrimary)),
      const SizedBox(width: 10),
      Expanded(child: _KpiMini(
          icon: Icons.card_giftcard_rounded,
          label: 'Recompensa',
          value: reward,
          color: _kBlue)),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // COLUMNAS
  // ─────────────────────────────────────────────────────────
  List<Widget> _leftColumn(BuildContext context) => [
    _buildInfoCard(),
    const SizedBox(height: 16),
    _buildQrCard(context),
  ];

  List<Widget> _rightColumn(BuildContext context) => [
    _buildKpiRow(),
    const SizedBox(height: 16),
    _buildDescriptionCard(),
    if (place.amenities.isNotEmpty) ...[
      const SizedBox(height: 16),
      _buildAmenitiesCard(),
    ],
    if (place.hasReward) ...[
      const SizedBox(height: 16),
      _buildRewardCard(),
    ],
    if (place.hasOwner) ...[
      const SizedBox(height: 16),
      _buildOwnerCard(),
    ],
  ];

  List<Widget> _mobileColumn(BuildContext context) => [
    _buildKpiRow(),
    const SizedBox(height: 14),
    _buildInfoCard(),
    const SizedBox(height: 14),
    _buildDescriptionCard(),
    if (place.amenities.isNotEmpty) ...[
      const SizedBox(height: 14),
      _buildAmenitiesCard(),
    ],
    if (place.hasReward) ...[
      const SizedBox(height: 14),
      _buildRewardCard(),
    ],
    const SizedBox(height: 14),
    _buildQrCard(context),
    if (place.hasOwner) ...[
      const SizedBox(height: 14),
      _buildOwnerCard(),
    ],
  ];

  // ─────────────────────────────────────────────────────────
  // CARDS
  // ─────────────────────────────────────────────────────────
  Widget _buildInfoCard() {
    return _SectionCard(
      title: 'Información',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _infoRow(Icons.location_on_outlined, place.lugar),
        if (place.address != null && place.address!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _infoRow(Icons.home_outlined, place.address!),
        ],
        if (place.phone != null && place.phone!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _infoRow(Icons.phone_outlined, place.phone!),
        ],
        if (place.priceRange != null && place.priceRange!.isNotEmpty) ...[
          const SizedBox(height: 10),
          _infoRow(Icons.attach_money_rounded, place.priceRange!),
        ],
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 0.5, color: _kBorder),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.tag_rounded, size: 12, color: _kTextSub),
          const SizedBox(width: 5),
          Text('ID ${place.id}',
              style: const TextStyle(fontSize: 11, color: _kTextSub)),
          const Spacer(),
          if (place.createdAt != null)
            Text(_fmt(place.createdAt!),
                style: const TextStyle(fontSize: 11, color: _kTextSub)),
        ]),
      ]),
    );
  }

  Widget _buildDescriptionCard() {
    return _SectionCard(
      title: 'Descripción',
      child: Text(
        place.description.isNotEmpty
            ? place.description
            : 'Sin descripción disponible.',
        style: const TextStyle(
            fontSize: 13, color: _kTextMuted, height: 1.65),
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    return _SectionCard(
      title: 'Servicios',
      subtitle: '${place.amenities.length} disponibles',
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: place.amenities
            .map((a) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _kPrimary.withOpacity(0.15)),
                  ),
                  child: Text(a,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kPrimary,
                          fontWeight: FontWeight.w500)),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRewardCard() {
    return _SectionCard(
      title: 'Recompensa',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kAmber.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kAmber.withOpacity(0.18)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(place.rewardIcon ?? '🎁',
              style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.rewardName ?? 'Recompensa',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kAmber)),
                if (place.rewardDescription != null &&
                    place.rewardDescription!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(place.rewardDescription!,
                      style: const TextStyle(
                          fontSize: 12,
                          color: _kTextMuted,
                          height: 1.5)),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kAmber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _kAmber.withOpacity(0.25)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min,
                      children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 11, color: _kAmber),
                    const SizedBox(width: 5),
                    Text(place.rewardStockLabel,
                        style: const TextStyle(
                            fontSize: 11,
                            color: _kAmber,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildQrCard(BuildContext context) {
    return _SectionCard(
      title: 'Código QR',
      subtitle: 'Escanear para registrar visita',
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kPrimary.withOpacity(0.15)),
          ),
          child: const Icon(Icons.qr_code_2_rounded,
              size: 26, color: _kPrimary),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QR generado y activo',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextHead)),
              SizedBox(height: 2),
              Text('Presenta el QR en el establecimiento',
                  style: TextStyle(fontSize: 11, color: _kTextSub)),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => showDialog(
              context: context,
              builder: (_) => QRDialog(place: place)),
          icon: const Icon(Icons.open_in_new_rounded,
              size: 14, color: _kPrimary),
          label: const Text('Ver',
              style: TextStyle(
                  fontSize: 12,
                  color: _kPrimary,
                  fontWeight: FontWeight.w600)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ]),
    );
  }

  Widget _buildOwnerCard() {
    return _SectionCard(
      title: 'Propietario',
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _kPrimary.withOpacity(0.1),
          child: Text(place.ownerInitials,
              style: const TextStyle(
                  fontSize: 13,
                  color: _kPrimary,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.ownerDisplay,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextHead)),
              if (place.ownerEmail != null) ...[
                const SizedBox(height: 2),
                Text(place.ownerEmail!,
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSub)),
              ],
              if (place.ownerPhone != null) ...[
                const SizedBox(height: 2),
                Text(place.ownerPhone!,
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSub)),
              ],
            ],
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────
  Widget _infoRow(IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: _kTextSub),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text,
            style: const TextStyle(
                fontSize: 13, color: _kTextMuted, height: 1.4)),
      ),
    ],
  );

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String  title;
  final String? subtitle;
  final Widget  child;
  const _SectionCard({
    required this.title, this.subtitle, required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8, offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _kTextHead)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 11, color: _kTextSub)),
              ],
            ],
          ),
        ),
        const Divider(height: 20, thickness: 0.5, color: _kBorder),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
          child: child,
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI MINI CARD
// ─────────────────────────────────────────────────────────────────────────────
class _KpiMini extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    color;
  const _KpiMini({
    required this.icon, required this.label,
    required this.value, required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _kBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 6, offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(height: 12),
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _kTextHead,
                height: 1.0)),
        const SizedBox(height: 3),
        Text(label,
            style: const TextStyle(fontSize: 11, color: _kTextSub)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final bool onHero;
  const _StatusBadge({required this.isActive, this.onHero = false});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? _kGreen : _kTextSub;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: onHero
            ? Colors.white.withOpacity(0.92)
            : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: onHero
                ? Colors.transparent
                : color.withOpacity(0.25)),
        boxShadow: onHero
            ? [BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6, offset: const Offset(0, 2))]
            : null,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          isActive ? 'Activo' : 'Inactivo',
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600),
        ),
      ]),
    );
  }
}
