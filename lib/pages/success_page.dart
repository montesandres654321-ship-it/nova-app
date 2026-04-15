// lib/pages/success_page.dart
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

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsRemaining = 10;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _animationController.forward();
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

  // ✅ Verificar si hubo error
  bool get _hasError => widget.backendData['error'] != null;

  // ✅ Verificar si ganó recompensa
  bool get _hasReward =>
      widget.backendData['reward'] != null &&
          widget.backendData['reward'] is Map;

  // ✅ Obtener datos del lugar escaneado
  Map<String, dynamic>? get _placeData =>
      widget.backendData['place'] as Map<String, dynamic>?;

  // ✅ Obtener datos de la recompensa
  Map<String, dynamic>? get _rewardData =>
      widget.backendData['reward'] as Map<String, dynamic>?;

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _hasError
                ? [Colors.red.shade50, Colors.red.shade100]
                : [const Color(0xFF06B6A4).withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // ============================================
                // ÍCONO PRINCIPAL CON ANIMACIÓN
                // ============================================
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildMainIcon(),
                ),

                const SizedBox(height: 30),

                // ============================================
                // TÍTULO Y MENSAJE
                // ============================================
                _buildTitle(),
                const SizedBox(height: 16),
                _buildSubtitle(),

                const SizedBox(height: 40),

                // ============================================
                // INFORMACIÓN DEL LUGAR
                // ============================================
                if (_placeData != null) _buildPlaceCard(),

                // ============================================
                // INFORMACIÓN DE LA RECOMPENSA (SI GANÓ)
                // ============================================
                if (_hasReward) ...[
                  const SizedBox(height: 20),
                  _buildRewardCard(),
                ],

                const SizedBox(height: 40),

                // ============================================
                // CRONÓMETRO Y PROGRESO
                // ============================================
                _buildCountdownSection(),

                const SizedBox(height: 20),

                // ============================================
                // BOTÓN MANUAL (OPCIONAL)
                // ============================================
                _buildManualButton(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // WIDGETS AUXILIARES
  // ============================================

  Widget _buildMainIcon() {
    if (_hasError) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 3),
        ),
        child: const Icon(Icons.error_outline, size: 70, color: Colors.red),
      );
    }

    if (_hasReward) {
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _rewardData?['icon'] ?? '🎁',
            style: const TextStyle(fontSize: 70),
          ),
        ),
      );
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green, width: 3),
      ),
      child: const Icon(Icons.check_circle, size: 70, color: Colors.green),
    );
  }

  Widget _buildTitle() {
    String title;
    Color color;

    if (_hasError) {
      title = '¡Ups! Algo salió mal';
      color = Colors.red;
    } else if (_hasReward) {
      title = '¡Felicidades! 🎉';
      color = Colors.amber.shade700;
    } else {
      title = '¡Escaneo Exitoso!';
      color = Colors.green;
    }

    return Text(
      title,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    String subtitle;

    if (_hasError) {
      subtitle = widget.backendData['error'] ?? 'Error desconocido';
    } else if (_hasReward) {
      subtitle = '¡Has ganado una recompensa!';
    } else {
      subtitle = 'El código QR ha sido escaneado correctamente';
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade700,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPlaceCard() {
    final place = _placeData!;
    final placeIcon = _getPlaceIcon(place['tipo'] ?? '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF06B6A4), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6A4).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  placeIcon,
                  color: const Color(0xFF06B6A4),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place['name'] ?? 'Lugar',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getPlaceTypeLabel(place['tipo'] ?? ''),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (place['lugar'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  place['lugar'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    final reward = _rewardData!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.amber.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Ícono de la recompensa
          Text(
            reward['icon'] ?? '🎁',
            style: const TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 12),

          // Nombre de la recompensa
          Text(
            reward['name'] ?? 'Recompensa',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.amber.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Descripción
          if (reward['description'] != null && reward['description'].toString().isNotEmpty)
            Text(
              reward['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.amber.shade800,
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 16),

          // Badge "Nueva recompensa"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Nueva recompensa desbloqueada',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection() {
    return Column(
      children: [
        // Texto del cronómetro
        Text(
          'Volviendo al inicio en',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),

        // Número grande del cronómetro
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF06B6A4).withOpacity(0.1),
            border: Border.all(color: const Color(0xFF06B6A4), width: 3),
          ),
          child: Center(
            child: Text(
              '$_secondsRemaining',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF06B6A4),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Barra de progreso
        SizedBox(
          width: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (10 - _secondsRemaining) / 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6A4)),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualButton() {
    return TextButton.icon(
      onPressed: _redirectToHome,
      icon: const Icon(Icons.home),
      label: const Text('Ir al inicio ahora'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF06B6A4),
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return Icons.hotel;
      case 'restaurant':
        return Icons.restaurant;
      case 'bar':
        return Icons.local_bar;
      default:
        return Icons.place;
    }
  }

  String _getPlaceTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'hotel':
        return 'Hotel';
      case 'restaurant':
        return 'Restaurante';
      case 'bar':
        return 'Bar';
      default:
        return 'Lugar';
    }
  }
}