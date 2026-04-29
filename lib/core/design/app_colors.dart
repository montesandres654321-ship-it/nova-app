import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary      = Color(0xFF06B6A4);
  static const Color primaryLight = Color(0xFF0EA5E9);
  static const Color onPrimary    = Color(0xFFFFFFFF);

  // Surfaces
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFF9CA3AF);

  // Status
  static const Color error   = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info    = Color(0xFF0EA5E9);

  // UI chrome
  static const Color border = Color(0xFFE5E7EB);

  // Gradient (top-left → bottom-right for depth)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
}
