// lib/pages/scan_page.dart - VERSIÓN CORREGIDA
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  final String backendUrl = "http://172.20.10.2:3000"; // tu PC en red local

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ CORREGIDO: Ahora siempre retorna Map, nunca null
  Future<Map<String, dynamic>> _registerScan(String qrCode) async {
    try {
      final parts = qrCode.split(":");
      if (parts.length != 2) {
        return {'error': 'Formato QR inválido', 'code': qrCode};
      }

      final placeId = int.tryParse(parts[1]);
      if (placeId == null) {
        return {'error': 'ID de lugar inválido', 'code': qrCode};
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      if (userId == null) {
        debugPrint("❌ No hay usuario logueado");
        return {'error': 'Usuario no autenticado', 'code': qrCode};
      }

      final response = await http.post(
        Uri.parse("$backendUrl/scan"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "placeId": placeId,
          "qrCode": qrCode,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Error backend: ${response.body}");
        return {
          'error': 'Error del servidor: ${response.statusCode}',
          'code': qrCode,
          'statusCode': response.statusCode
        };
      }
    } catch (e) {
      debugPrint("Error _registerScan: $e");
      return {
        'error': 'Error de conexión: $e',
        'code': qrCode,
        'timestamp': DateTime.now().toIso8601String()
      };
    }
  }

  void _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    // ✅ CORREGIDO: result ya no puede ser null
    final Map<String, dynamic> result = await _registerScan(code);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SuccessPage(
            code: code,
            backendData: result, // ✅ Ahora es compatible
          ),
        ),
      );
    }

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _scanFromGallery() async {
    if (_isProcessing) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      setState(() => _isProcessing = true);

      try {
        final BarcodeCapture? result = await _controller.analyzeImage(image.path);

        if (result != null && result.barcodes.isNotEmpty) {
          final code = result.barcodes.first.rawValue;
          if (code != null) {
            // ✅ CORREGIDO: backendRes ya no puede ser null
            final Map<String, dynamic> backendRes = await _registerScan(code);
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SuccessPage(
                    code: code,
                    backendData: backendRes, // ✅ Ahora es compatible
                  ),
                ),
              );
            }
            return;
          }
        }

        // Si no se encontró QR
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No se detectó ningún código QR en la imagen"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error procesando imagen: $e"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Escanear QR',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF06B6A4),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleBarcode,
                  ),

                  // ✅ MARCO DEL CENTRO AGREGADO
                  _buildScannerOverlay(),

                  if (_isProcessing)
                    Container(
                      color: Colors.black54,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6A4)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              "Procesando código QR...",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.black87,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.zoom_out, color: Colors.white),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (v) {
                            setState(() => _zoom = v);
                            _controller.setZoomScale(v);
                          },
                        ),
                      ),
                      const Icon(Icons.zoom_in, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: _scanFromGallery,
                        icon: const Icon(Icons.image,
                            color: Colors.white, size: 30),
                        tooltip: "Escanear desde galería",
                      ),
                      IconButton(
                        onPressed: () {
                          _controller.toggleTorch();
                          setState(() => _isTorchOn = !_isTorchOn);
                        },
                        icon: Icon(
                          _isTorchOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                          size: 30,
                        ),
                        tooltip: "Linterna",
                      ),
                      IconButton(
                        onPressed: () => _controller.switchCamera(),
                        icon: const Icon(Icons.cameraswitch,
                            color: Colors.white, size: 30),
                        tooltip: "Cambiar cámara",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Widget para el marco del centro
  Widget _buildScannerOverlay() {
    return CustomPaint(
      size: Size.infinite,
      painter: ScannerOverlayPainter(),
    );
  }
}

// ✅ CustomPainter para el marco del scanner
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final squareSize = size.width * 0.7;

    // Agujero central transparente
    path.addRect(Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    ));

    canvas.drawPath(path, paint);

    // Bordes del scanner con esquinas
    final borderPaint = Paint()
      ..color = const Color(0xFF06B6A4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final scannerRect = Rect.fromCenter(
      center: center,
      width: squareSize,
      height: squareSize,
    );

    // Dibujar esquinas
    const cornerLength = 25.0;
    const cornerWidth = 3.0;

    // Esquina superior izquierda
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top + cornerLength),
      Offset(scannerRect.left, scannerRect.top),
      borderPaint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.top),
      Offset(scannerRect.left + cornerLength, scannerRect.top),
      borderPaint..strokeWidth = cornerWidth,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(scannerRect.right - cornerLength, scannerRect.top),
      Offset(scannerRect.right, scannerRect.top),
      borderPaint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.top),
      Offset(scannerRect.right, scannerRect.top + cornerLength),
      borderPaint..strokeWidth = cornerWidth,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom - cornerLength),
      Offset(scannerRect.left, scannerRect.bottom),
      borderPaint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(scannerRect.left, scannerRect.bottom),
      Offset(scannerRect.left + cornerLength, scannerRect.bottom),
      borderPaint..strokeWidth = cornerWidth,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(scannerRect.right - cornerLength, scannerRect.bottom),
      Offset(scannerRect.right, scannerRect.bottom),
      borderPaint..strokeWidth = cornerWidth,
    );
    canvas.drawLine(
      Offset(scannerRect.right, scannerRect.bottom),
      Offset(scannerRect.right, scannerRect.bottom - cornerLength),
      borderPaint..strokeWidth = cornerWidth,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}