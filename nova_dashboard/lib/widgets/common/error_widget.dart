// lib/widgets/common/error_widget.dart
import 'package:flutter/material.dart';

/// Widget de error reutilizable
///
/// Ejemplo de uso:
/// ```dart
/// ErrorDisplay(
///   message: 'Error al cargar datos',
///   onRetry: () => _loadData(),
/// )
/// ```
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String? retryLabel;

  const ErrorDisplay({
    Key? key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 24),
            const Text(
              'Oops! Algo salió mal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryLabel ?? 'Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}