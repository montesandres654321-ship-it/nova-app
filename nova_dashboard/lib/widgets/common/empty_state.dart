// lib/widgets/common/empty_state.dart
import 'package:flutter/material.dart';

/// Widget de estado vacío reutilizable
///
/// Ejemplo de uso:
/// ```dart
/// EmptyState(
///   icon: Icons.inbox,
///   title: 'No hay elementos',
///   message: 'Agrega tu primer elemento',
///   actionLabel: 'Agregar',
///   onActionPressed: () => print('Action'),
/// )
/// ```
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
    this.iconColor,
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
              color: iconColor ?? Colors.grey[300],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
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
            if (onActionPressed != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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