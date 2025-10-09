// lib/pages/success_page.dart - VERSIÓN SIN BOTONES
import 'dart:async';
import 'package:flutter/material.dart';

class SuccessPage extends StatefulWidget {
  final String code;
  final Map<String, dynamic> backendData;

  const SuccessPage({
    super.key,
    required this.code,
    required this.backendData,
  });

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  late Timer _timer;
  int _secondsRemaining = 20;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsRemaining--;
        });

        if (_secondsRemaining <= 0) {
          timer.cancel();
          _redirectToHome();
        }
      }
    });
  }

  void _redirectToHome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ícono de éxito grande
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.check,
                size: 70,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 40),

            // Mensaje principal
            const Text(
              '¡Escaneo Exitoso!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Mensaje secundario
            const Text(
              'El código QR ha sido escaneado correctamente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Contador regresivo
            Text(
              'Volviendo al inicio en $_secondsRemaining segundos',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            // Indicador de progreso
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: (20 - _secondsRemaining) / 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6A4)),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}