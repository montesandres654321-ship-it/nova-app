// lib/pages/places/qr_dialog.dart
// ============================================================
// MEJORAS:
//   1. QR personalizado por tipo (colores diferentes para hotel/restaurant/bar)
//   2. Descarga real al PC — usa fetch + blob en vez de abrir pestaña
//   3. Diseño mejorado con colores del tipo de lugar
// ============================================================

import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../models/place.dart';

class QRDialog extends StatelessWidget {
  final Place place;

  const QRDialog({super.key, required this.place});

  String get _qrData => 'PLACE:${place.id}';

  // Colores por tipo de lugar
  Color get _typeColor {
    switch (place.tipo.toLowerCase()) {
      case 'hotel':      return const Color(0xFF2563EB);
      case 'restaurant': return const Color(0xFF059669);
      case 'bar':        return const Color(0xFFD97706);
      default:           return const Color(0xFF06B6A4);
    }
  }

  Color get _typeLightColor {
    switch (place.tipo.toLowerCase()) {
      case 'hotel':      return const Color(0xFFDBEAFE);
      case 'restaurant': return const Color(0xFFD1FAE5);
      case 'bar':        return const Color(0xFFFEF3C7);
      default:           return const Color(0xFFE0F7FA);
    }
  }

  String get _typeIcon {
    switch (place.tipo.toLowerCase()) {
      case 'hotel':      return '🏨';
      case 'restaurant': return '🍽️';
      case 'bar':        return '🍹';
      default:           return '📍';
    }
  }

  // URL del QR con color personalizado por tipo
  String get _qrImageUrl {
    final encoded = Uri.encodeComponent(_qrData);
    // Color del QR según tipo (sin #)
    String qrColor;
    switch (place.tipo.toLowerCase()) {
      case 'hotel':      qrColor = '2563EB'; break;
      case 'restaurant': qrColor = '059669'; break;
      case 'bar':        qrColor = 'D97706'; break;
      default:           qrColor = '06B6A4'; break;
    }
    return 'https://api.qrserver.com/v1/create-qr-code/'
        '?size=400x400&data=$encoded&format=png&margin=12'
        '&color=$qrColor&bgcolor=FFFFFF';
  }

  // FIX: Descarga real — fetch la imagen y crear blob para download
  Future<void> _downloadQR(BuildContext context) async {
    try {
      if (kIsWeb) {
        // Mostrar indicador de descarga
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preparando descarga...'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 1),
            ),
          );
        }

        // Fetch la imagen como bytes
        final response = await http.get(Uri.parse(_qrImageUrl));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final blob = html.Blob([bytes], 'image/png');
          final url = html.Url.createObjectUrlFromBlob(blob);

          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'QR_${place.name.replaceAll(' ', '_')}_${place.tipo}.png')
            ..style.display = 'none';

          html.document.body?.append(anchor);
          anchor.click();

          // Limpiar
          Future.delayed(const Duration(milliseconds: 100), () {
            anchor.remove();
            html.Url.revokeObjectUrl(url);
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ QR de "${place.name}" descargado'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Error al descargar imagen: ${response.statusCode}');
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
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Header con color del tipo ─────────────────
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _typeLightColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _typeColor.withOpacity(0.3)),
                ),
                child: Center(
                  child: Text(_typeIcon, style: const TextStyle(fontSize: 22)),
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

            const SizedBox(height: 16),

            // ── QR con borde del color del tipo ───────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _typeColor.withOpacity(0.25), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _typeColor.withOpacity(0.08),
                    spreadRadius: 2,
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(children: [
                // Imagen del QR
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _qrImageUrl,
                    width: 260,
                    height: 260,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        width: 260, height: 260,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: _typeColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      width: 260, height: 260,
                      color: Colors.grey[100],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text('Error al cargar QR',
                              style: TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Código con color del tipo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _typeLightColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_2, size: 16, color: _typeColor),
                      const SizedBox(width: 6),
                      Text(
                        _qrData,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _typeColor,
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
                color: _typeLightColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _typeColor.withOpacity(0.15)),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16, color: _typeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Imprime este QR y colócalo en el establecimiento. '
                        'Los turistas lo escanean con la app Nova para '
                        'acumular puntos y obtener recompensas.',
                    style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 20),

            // ── Botones ──────────────────────────────────
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openInNewTab,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Abrir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _typeColor,
                    side: BorderSide(color: _typeColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _downloadQR(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Descargar PNG'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _typeColor,
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