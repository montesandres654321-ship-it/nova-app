import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';

enum AppBackButtonVariant { light, onPrimary }

class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.variant = AppBackButtonVariant.light,
    this.onTap,
  });

  final AppBackButtonVariant variant;

  /// Override the default Navigator.pop() behavior.
  final VoidCallback? onTap;

  static const double _size = 36.0;
  static const double _iconSize = 16.0;

  @override
  Widget build(BuildContext context) {
    final isOnPrimary = variant == AppBackButtonVariant.onPrimary;
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pop(context),
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: isOnPrimary
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.surfaceVariant,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: isOnPrimary
                ? Colors.white.withValues(alpha: 0.25)
                : AppColors.border,
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: _iconSize,
          color: isOnPrimary ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}
