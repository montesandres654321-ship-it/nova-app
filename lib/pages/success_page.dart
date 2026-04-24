// lib/pages/success_page.dart
// ============================================================
// FIX: Botón "Confirmar que recibí mi premio" cuando hay recompensa
// Llama PATCH /rewards/:id/redeem
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SuccessPage extends StatefulWidget {
  final String code;
  final Map<String, dynamic> backendData;

  const SuccessPage({super.key, required this.code, required this.backendData});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsRemaining = 15; // Más tiempo si hay recompensa
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _rewardConfirmed = false;
  bool _confirmingReward = false;

  @override
  void initState() {
    super.initState();
    // Más tiempo si hay recompensa para que el turista pueda confirmar
    _secondsRemaining = _hasReward ? 30 : 10;
    _startTimer();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    _animationController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining <= 0) { timer.cancel(); _redirectToHome(); }
      }
    });
  }

  void _redirectToHome() { if (mounted) Navigator.pushReplacementNamed(context, '/home'); }

  bool get _hasError => widget.backendData['error'] != null;
  bool get _hasReward => widget.backendData['reward'] != null && widget.backendData['reward'] is Map;
  Map<String, dynamic>? get _placeData => widget.backendData['place'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _rewardData => widget.backendData['reward'] as Map<String, dynamic>?;

  // ── Confirmar recepción de recompensa ───────────────────
  Future<void> _confirmReward() async {
    if (_confirmingReward || _rewardConfirmed) return;
    final rewardId = _rewardData?['id'];
    if (rewardId == null) return;

    setState(() => _confirmingReward = true);

    try {
      final result = await ApiService.redeemReward(rewardId);
      if (mounted) {
        if (result['success'] == true) {
          setState(() { _rewardConfirmed = true; _confirmingReward = false; });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('✅ ¡Recompensa confirmada!'), backgroundColor: Colors.green));
        } else {
          setState(() => _confirmingReward = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['error'] ?? 'Error al confirmar'), backgroundColor: Colors.red));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirmingReward = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() { _timer.cancel(); _animationController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: LinearGradient(
            colors: _hasError
                ? [Colors.red.shade50, Colors.red.shade100]
                : [const Color(0xFF06B6A4).withOpacity(0.1), Colors.white],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 40),
              ScaleTransition(scale: _scaleAnimation, child: _buildMainIcon()),
              const SizedBox(height: 30),
              _buildTitle(),
              const SizedBox(height: 16),
              _buildSubtitle(),
              const SizedBox(height: 40),
              if (_placeData != null) _buildPlaceCard(),
              if (_hasReward) ...[const SizedBox(height: 20), _buildRewardCard()],
              const SizedBox(height: 40),
              _buildCountdownSection(),
              const SizedBox(height: 20),
              _buildManualButton(),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildMainIcon() {
    if (_hasError) {
      return Container(width: 120, height: 120,
          decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 3)),
          child: const Icon(Icons.error_outline, size: 70, color: Colors.red));
    }
    if (_hasReward) {
      return Container(width: 140, height: 140,
          decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 4),
              boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)]),
          child: Center(child: Text(_rewardData?['icon'] ?? '🎁', style: const TextStyle(fontSize: 70))));
    }
    return Container(width: 120, height: 120,
        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle,
            border: Border.all(color: Colors.green, width: 3)),
        child: const Icon(Icons.check_circle, size: 70, color: Colors.green));
  }

  Widget _buildTitle() {
    String title; Color color;
    if (_hasError) { title = '¡Ups! Algo salió mal'; color = Colors.red; }
    else if (_hasReward) { title = '¡Felicidades! 🎉'; color = Colors.amber.shade700; }
    else { title = '¡Escaneo Exitoso!'; color = Colors.green; }
    return Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color), textAlign: TextAlign.center);
  }

  Widget _buildSubtitle() {
    String subtitle;
    if (_hasError) { subtitle = widget.backendData['error'] ?? 'Error desconocido'; }
    else if (_hasReward) { subtitle = '¡Has ganado una recompensa!'; }
    else { subtitle = 'El código QR ha sido escaneado correctamente'; }
    return Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.grey.shade700), textAlign: TextAlign.center);
  }

  Widget _buildPlaceCard() {
    final place = _placeData!;
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF06B6A4), width: 2),
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(
              color: const Color(0xFF06B6A4).withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(_getPlaceIcon(place['tipo'] ?? ''), color: const Color(0xFF06B6A4), size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(place['name'] ?? 'Lugar', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_getPlaceTypeLabel(place['tipo'] ?? ''), style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            if (place['lugar'] != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(place['lugar'], style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ]),
            ],
          ])),
        ]));
  }

  Widget _buildRewardCard() {
    final reward = _rewardData!;
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.amber.shade50, Colors.amber.shade100],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber, width: 2),
            boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))]),
        child: Column(children: [
          Text(reward['icon'] ?? '🎁', style: const TextStyle(fontSize: 50)),
          const SizedBox(height: 12),
          Text(reward['name'] ?? 'Recompensa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber.shade900), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          if (reward['description'] != null && reward['description'].toString().isNotEmpty)
            Text(reward['description'], style: TextStyle(fontSize: 14, color: Colors.amber.shade800), textAlign: TextAlign.center),
          const SizedBox(height: 16),

          // Badge
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.stars, color: Colors.white, size: 18), SizedBox(width: 8),
                Text('Nueva recompensa desbloqueada', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ])),

          const SizedBox(height: 16),

          // ── BOTÓN CONFIRMAR RECEPCIÓN ─────────────────────
          if (!_rewardConfirmed)
            SizedBox(width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: _confirmingReward ? null : _confirmReward,
                  icon: _confirmingReward
                      ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_confirmingReward ? 'Confirmando...' : 'Confirmar que recibí mi premio'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ))
          else
            Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF059669))),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.check_circle, color: Color(0xFF059669), size: 20), SizedBox(width: 8),
                  Text('¡Premio confirmado!', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 14)),
                ])),
        ]));
  }

  Widget _buildCountdownSection() => Column(children: [
    Text('Volviendo al inicio en', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
    const SizedBox(height: 8),
    Container(width: 80, height: 80, decoration: BoxDecoration(shape: BoxShape.circle,
        color: const Color(0xFF06B6A4).withOpacity(0.1),
        border: Border.all(color: const Color(0xFF06B6A4), width: 3)),
        child: Center(child: Text('$_secondsRemaining', style: const TextStyle(
            fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF06B6A4))))),
    const SizedBox(height: 16),
    SizedBox(width: 250, child: ClipRRect(borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
            value: _hasReward ? (30 - _secondsRemaining) / 30 : (10 - _secondsRemaining) / 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF06B6A4)), minHeight: 8))),
  ]);

  Widget _buildManualButton() => TextButton.icon(
      onPressed: _redirectToHome,
      icon: const Icon(Icons.home), label: const Text('Ir al inicio ahora'),
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF06B6A4)));

  IconData _getPlaceIcon(String type) {
    switch (type.toLowerCase()) { case 'hotel': return Icons.hotel; case 'restaurant': return Icons.restaurant;
      case 'bar': return Icons.local_bar; default: return Icons.place; }
  }

  String _getPlaceTypeLabel(String type) {
    switch (type.toLowerCase()) { case 'hotel': return 'Hotel'; case 'restaurant': return 'Restaurante';
      case 'bar': return 'Bar'; default: return 'Lugar'; }
  }
}