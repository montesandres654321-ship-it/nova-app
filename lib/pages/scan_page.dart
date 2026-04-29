// lib/pages/scan_page.dart
// ============================================================
// FIX: eliminado Future.delayed(1s) código muerto post-navegación
// ============================================================

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../core/design/app_colors.dart';
import 'success_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isTorchOn = false;
  double _zoom = 0.0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    final result = await ApiService.registerScan(code);

    // FIX: navegar y no hacer nada más — el widget se destruye con pushReplacement
    if (mounted) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => SuccessPage(code: code, backendData: result)),
      );
    }
    // FIX: eliminado Future.delayed(1s) + setState código muerto
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() => _isProcessing = true);
    try {
      final result = await _controller.analyzeImage(image.path);
      if (result != null && result.barcodes.isNotEmpty) {
        final code = result.barcodes.first.rawValue;
        if (code != null) {
          final backendRes = await ApiService.registerScan(code);
          if (mounted) {
            Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => SuccessPage(code: code, backendData: backendRes)),
            );
          }
          return;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("No se detectó ningún código QR"),
            backgroundColor: AppColors.warning));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: $e"), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: Stack(children: [
              MobileScanner(controller: _controller, onDetect: _handleBarcode),
              _buildScannerOverlay(),
              if (_isProcessing)
                Container(color: Colors.black54, child: const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                    SizedBox(height: 16),
                    Text("Procesando código QR...", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ]),
                )),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.black87,
            child: Column(children: [
              Row(children: [
                const Icon(Icons.zoom_out, color: Colors.white),
                Expanded(child: Slider(value: _zoom, min: 0.0, max: 1.0,
                    onChanged: (v) { setState(() => _zoom = v); _controller.setZoomScale(v); })),
                const Icon(Icons.zoom_in, color: Colors.white),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                IconButton(onPressed: _scanFromGallery,
                    icon: const Icon(Icons.image, color: Colors.white, size: 30), tooltip: "Galería"),
                IconButton(onPressed: () { _controller.toggleTorch(); setState(() => _isTorchOn = !_isTorchOn); },
                    icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off, color: Colors.white, size: 30), tooltip: "Linterna"),
                IconButton(onPressed: () => _controller.switchCamera(),
                    icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30), tooltip: "Cambiar cámara"),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildScannerOverlay() => CustomPaint(size: Size.infinite, painter: ScannerOverlayPainter());
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54..style = PaintingStyle.fill;
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final center = Offset(size.width / 2, size.height / 2);
    final sq = size.width * 0.7;
    path.addRect(Rect.fromCenter(center: center, width: sq, height: sq));
    canvas.drawPath(path, paint);

    final borderPaint = Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 3;
    final rect = Rect.fromCenter(center: center, width: sq, height: sq);
    const cl = 25.0;

    canvas.drawLine(Offset(rect.left, rect.top + cl), Offset(rect.left, rect.top), borderPaint);
    canvas.drawLine(Offset(rect.left, rect.top), Offset(rect.left + cl, rect.top), borderPaint);
    canvas.drawLine(Offset(rect.right - cl, rect.top), Offset(rect.right, rect.top), borderPaint);
    canvas.drawLine(Offset(rect.right, rect.top), Offset(rect.right, rect.top + cl), borderPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom - cl), Offset(rect.left, rect.bottom), borderPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom), Offset(rect.left + cl, rect.bottom), borderPaint);
    canvas.drawLine(Offset(rect.right - cl, rect.bottom), Offset(rect.right, rect.bottom), borderPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom), Offset(rect.right, rect.bottom - cl), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}