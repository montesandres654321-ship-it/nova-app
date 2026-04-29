import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/design/app_colors.dart';
import '../core/design/app_spacing.dart';
import '../core/design/app_radius.dart';

class SuccessPage extends StatefulWidget {
  final String code;
  final Map<String, dynamic> backendData;

  const SuccessPage(
      {super.key, required this.code, required this.backendData});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _secondsRemaining = 10;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _rewardConfirmed = false;
  bool _confirmingReward = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = _hasReward ? 30 : 10;
    _startTimer();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _animationController, curve: Curves.elasticOut));
    _animationController.forward();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsRemaining--);
        if (_secondsRemaining <= 0) {
          timer.cancel();
          _redirectToHome();
        }
      }
    });
  }

  void _redirectToHome() {
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  bool get _hasError => widget.backendData['error'] != null;
  bool get _hasReward =>
      widget.backendData['reward'] != null &&
      widget.backendData['reward'] is Map;
  Map<String, dynamic>? get _placeData =>
      widget.backendData['place'] as Map<String, dynamic>?;
  Map<String, dynamic>? get _rewardData =>
      widget.backendData['reward'] as Map<String, dynamic>?;

  Future<void> _confirmReward() async {
    if (_confirmingReward || _rewardConfirmed) return;
    final rewardId = _rewardData?['id'];
    if (rewardId == null) return;

    setState(() => _confirmingReward = true);
    try {
      final result = await ApiService.redeemReward(rewardId);
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _rewardConfirmed = true;
            _confirmingReward = false;
          });
          _showSnack('¡Recompensa confirmada!', AppColors.success);
        } else {
          setState(() => _confirmingReward = false);
          _showSnack(result['error'] ?? 'Error al confirmar', AppColors.error);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _confirmingReward = false);
        _showSnack('Error: $e', AppColors.error);
      }
    }
  }

  void _showSnack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
      );

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _hasError
                ? [
                    AppColors.error.withValues(alpha: 0.08),
                    AppColors.error.withValues(alpha: 0.02),
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.surface,
                  ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.paddingOf(context).bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: AppSpacing.sm),
                    ScaleTransition(
                        scale: _scaleAnimation, child: _buildMainIcon()),
                    const SizedBox(height: AppSpacing.sm),
                    _buildTitle(),
                    const SizedBox(height: AppSpacing.xs),
                    _buildSubtitle(),
                    const SizedBox(height: AppSpacing.md),
                    if (_placeData != null) _buildPlaceCard(),
                    if (_hasReward) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _buildRewardCard(),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _buildCountdownSection(),
                    const SizedBox(height: AppSpacing.xs),
                    _buildManualButton(),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainIcon() {
    if (_hasError) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error, width: 3),
        ),
        child: const Icon(Icons.error_outline, size: 52, color: AppColors.error),
      );
    }
    if (_hasReward) {
      return Container(
        width: 105,
        height: 105,
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.warning, width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.warning.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Text(_rewardData?['icon'] ?? '🎁',
              style: const TextStyle(fontSize: 52)),
        ),
      );
    }
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.success, width: 3),
      ),
      child:
          const Icon(Icons.check_circle, size: 52, color: AppColors.success),
    );
  }

  Widget _buildTitle() {
    late String title;
    late Color color;
    if (_hasError) {
      title = '¡Ups! Algo salió mal';
      color = AppColors.error;
    } else if (_hasReward) {
      title = '¡Felicidades! 🎉';
      color = AppColors.warning;
    } else {
      title = '¡Escaneo Exitoso!';
      color = AppColors.success;
    }
    return Text(
      title,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    final String subtitle;
    if (_hasError) {
      subtitle = widget.backendData['error'] ?? 'Error desconocido';
    } else if (_hasReward) {
      subtitle = '¡Has ganado una recompensa!';
    } else {
      subtitle = 'El código QR ha sido escaneado correctamente';
    }
    return Text(
      subtitle,
      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPlaceCard() {
    final place = _placeData!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textHint.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getPlaceIcon(place['tipo'] ?? ''),
                color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place['name'] ?? 'Lugar',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _getPlaceTypeLabel(place['tipo'] ?? ''),
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
                if (place['lugar'] != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: AppColors.textHint),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        place['lugar'],
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    final reward = _rewardData!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm + 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withValues(alpha: 0.08),
            AppColors.warning.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.warning, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.warning.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(reward['icon'] ?? '🎁',
              style: const TextStyle(fontSize: 40)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            reward['name'] ?? 'Recompensa',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.warning),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (reward['description'] != null &&
              reward['description'].toString().isNotEmpty)
            Text(
              reward['description'],
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs + 4),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: AppRadius.pillAll,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, color: Colors.white, size: 18),
                SizedBox(width: AppSpacing.xs + 4),
                Text(
                  'Nueva recompensa desbloqueada',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!_rewardConfirmed)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _confirmingReward ? null : _confirmReward,
                icon: _confirmingReward
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.onPrimary),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_confirmingReward
                    ? 'Confirmando...'
                    : 'Confirmar que recibí mi premio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.mdAll),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.success),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: AppSpacing.xs + 4),
                  Text(
                    '¡Premio confirmado!',
                    style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCountdownSection() {
    final total = _hasReward ? 30 : 10;
    final progress = ((total - _secondsRemaining) / total).clamp(0.0, 1.0);
    return Column(
      children: [
        const Text(
          'Volviendo al inicio en',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs + 4),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.1),
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: Center(
            child: Text(
              '$_secondsRemaining',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: AppRadius.smAll,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualButton() => TextButton.icon(
        onPressed: _redirectToHome,
        icon: const Icon(Icons.home),
        label: const Text('Ir al inicio ahora'),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      );

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
