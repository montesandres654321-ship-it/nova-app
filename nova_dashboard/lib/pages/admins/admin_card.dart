// lib/pages/admins/admin_card.dart
// ============================================================
// FIX: Eliminado ⭐ rating de _buildPlaceInfo
// Todo lo demás sin cambios
// ============================================================
import 'package:flutter/material.dart';
import '../../models/admin_stats_model.dart';
import '../../utils/constants.dart';

class AdminCard extends StatelessWidget {
  final AdminStats      adminStats;
  final VoidCallback?   onTapDetail;
  final VoidCallback?   onTapEdit;
  final VoidCallback?   onTapReassign;
  final VoidCallback?   onTapDashboard;
  final VoidCallback?   onTapDeactivate;

  const AdminCard({
    Key? key,
    required this.adminStats,
    this.onTapDetail,
    this.onTapEdit,
    this.onTapReassign,
    this.onTapDashboard,
    this.onTapDeactivate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final admin    = adminStats.admin;
    final hasPlace = adminStats.hasPlace;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                  radius: 24,
                  backgroundColor: _getRoleColor(admin.role),
                  child: Text(
                      admin.firstName.isNotEmpty
                          ? admin.firstName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20))),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin.displayName,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(admin.email,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('${admin.roleEmoji} ${admin.roleLabel}',
                          style: const TextStyle(fontSize: 12)),
                      if (!admin.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(4)),
                            child: const Text('INACTIVO',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ]),
                  ])),
            ]),

            if (hasPlace && adminStats.placeStats != null) ...[
              const Divider(height: 24),
              _buildPlaceInfo(adminStats.placeStats!),
            ],

            const SizedBox(height: 12),
            _buildActionButtons(hasPlace),
          ],
        ),
      ),
    );
  }

  // FIX: Eliminado ⭐ rating — solo muestra tipo, ubicación, escaneos, recompensas
  Widget _buildPlaceInfo(PlaceStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(stats.typeWithEmoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(stats.placeName,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 4),
        Text('📍 ${stats.placeLocation}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 8),
        // FIX: sin ⭐ rating — solo escaneos y recompensas
        Wrap(spacing: 16, children: [
          Text('📱 ${stats.totalScans} escaneos',
              style: const TextStyle(fontSize: 12)),
          Text('🎁 ${stats.totalRewards} recompensas',
              style: const TextStyle(fontSize: 12)),
        ]),
      ],
    );
  }

  Widget _buildActionButtons(bool hasPlace) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildButton('Ver Detalle',    Icons.visibility,  onTapDetail),
        _buildButton('Editar',         Icons.edit,        onTapEdit),
        if (hasPlace) ...[
          _buildButton('Ver Dashboard', Icons.dashboard,  onTapDashboard),
          _buildButton('Reasignar',     Icons.swap_horiz, onTapReassign),
        ],
        if (onTapDeactivate != null)
          _buildDeactivateButton(),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback? onTap) {
    return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(fontSize: 12)));
  }

  Widget _buildDeactivateButton() {
    return OutlinedButton.icon(
        onPressed: onTapDeactivate,
        icon: const Icon(Icons.person_off_rounded, size: 16, color: Colors.red),
        label: const Text('Desactivar',
            style: TextStyle(color: Colors.red, fontSize: 12)),
        style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            side: const BorderSide(color: Colors.red, width: 1),
            textStyle: const TextStyle(fontSize: 12)));
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case AppConstants.roleAdminGeneral: return Colors.purple;
      case AppConstants.roleUserGeneral:  return Colors.blue;
      case AppConstants.roleUserPlace:    return Colors.teal;
      default:                            return Colors.grey;
    }
  }
}