// lib/pages/places/qr_dialog.dart
// ============================================================
// DIÁLOGO DE QR — Genera y descarga QR del lugar en PNG
// Compatible con Flutter Web (usa dart:html para descarga)
// ============================================================

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../models/place.dart';
import '../../utils/constants.dart';

class QRDialog extends StatelessWidget {
  final Place place;

  const QRDialog({super.key, required this.place});

  // ── Código QR del lugar ───────────────────────────────
  String get _qrData => 'PLACE:${place.id}';

  // ── URL del QR usando la API de Google Charts ─────────
  // Genera un QR como imagen PNG sin librerías externas
  String get _qrImageUrl {
    final encoded = Uri.encodeComponent(_qrData);
    return 'https://api.qrserver.com/v1/create-qr-code/'
        '?size=300x300&data=$encoded&format=png&margin=10';
  }

  // ── Descargar QR como PNG ─────────────────────────────
  Future<void> _downloadQR(BuildContext context) async {
    try {
      if (kIsWeb) {
        // En Flutter Web: crear link y hacer click
        final anchor = html.AnchorElement(href: _qrImageUrl)
          ..setAttribute('download', 'QR_${place.name.replaceAll(' ', '_')}.png')
          ..setAttribute('target', '_blank');
        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Descargando QR de "${place.name}"'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al descargar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── Abrir QR en nueva pestaña ─────────────────────────
  void _openInNewTab() {
    if (kIsWeb) {
      html.window.open(_qrImageUrl, '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header ──────────────────────────────────
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6A4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(place.tipoEmoji,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${place.tipoLabel} · ${place.lugar}',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),

            const Divider(height: 24),

            // ── Código QR ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(children: [
                // Imagen del QR
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _qrImageUrl,
                    width: 250,
                    height: 250,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 250, height: 250,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF06B6A4),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      width: 250, height: 250,
                      color: Colors.grey[100],
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, size: 60, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Error al cargar QR',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Código del QR
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_2,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        _qrData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Instrucciones ────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF06B6A4).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF06B6A4).withOpacity(0.2)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Color(0xFF06B6A4)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Imprime este QR y colócalo en el establecimiento. '
                        'Los turistas lo escanean con la app Nova para '
                        'acumular puntos y obtener recompensas.',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Botones de acción ────────────────────────
            Row(children: [
              // Abrir en nueva pestaña
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openInNewTab,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Abrir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF06B6A4),
                    side: const BorderSide(color: Color(0xFF06B6A4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Descargar PNG
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadQR(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Descargar PNG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6A4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),

          ],
        ),
      ),
    );
  }
}