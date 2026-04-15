// lib/pages/admins/admin_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_stats_model.dart';

class AdminDetailDialog extends StatelessWidget {
  final AdminStats adminStats;

  const AdminDetailDialog({
    Key? key,
    required this.adminStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final admin = adminStats.admin;

    return Dialog(
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalle del Administrador',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.teal,
                        child: Text(
                          admin.firstName.isNotEmpty ? admin.firstName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSection('Información Personal', [
                      _buildInfoRow('Nombre', admin.displayName),
                      _buildInfoRow('Email', admin.email),
                      _buildInfoRow('Usuario', admin.username),
                      if (admin.phone != null) _buildInfoRow('Teléfono', admin.phone!),
                    ]),
                    const SizedBox(height: 16),
                    _buildSection('Rol y Permisos', [
                      _buildInfoRow('Rol', '${admin.roleEmoji} ${admin.roleLabel}'),
                      _buildInfoRow('Estado', admin.isActive ? '✅ Activo' : '❌ Inactivo'),
                    ]),
                    if (admin.createdAt != null || admin.lastLogin != null) ...[
                      const SizedBox(height: 16),
                      _buildSection('Actividad', [
                        if (admin.createdAt != null)
                          _buildInfoRow('Registrado', DateFormat('dd/MM/yyyy').format(admin.createdAt!)),
                        if (admin.lastLogin != null)
                          _buildInfoRow('Último login', DateFormat('dd/MM/yyyy HH:mm').format(admin.lastLogin!)),
                      ]),
                    ],
                    if (adminStats.hasPlace && adminStats.placeStats != null) ...[
                      const SizedBox(height: 16),
                      _buildSection('Lugar Asignado', [
                        _buildInfoRow('Nombre', adminStats.placeStats!.placeName),
                        _buildInfoRow('Tipo', adminStats.placeStats!.typeWithEmoji),
                        _buildInfoRow('Ubicación', adminStats.placeStats!.placeLocation),
                        _buildInfoRow('Rating', '⭐ ${adminStats.placeStats!.ratingFormatted}/5'),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Estadísticas', [
                        _buildInfoRow('Total escaneos', adminStats.placeStats!.totalScans.toString()),
                        _buildInfoRow('Visitantes únicos', adminStats.placeStats!.uniqueVisitors.toString()),
                        _buildInfoRow('Recompensas', adminStats.placeStats!.totalRewards.toString()),
                      ]),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}