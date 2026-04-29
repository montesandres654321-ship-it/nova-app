import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headlineLg = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -0.3,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle title = TextStyle(
    fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle titleMd = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  );
  static const TextStyle bodyLg = TextStyle(
    fontSize: 15, color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14, color: AppColors.textSecondary, height: 1.5,
  );
  static const TextStyle bodySm = TextStyle(
    fontSize: 13, color: AppColors.textSecondary,
  );
  static const TextStyle labelLg = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle label = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle labelSm = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 12, color: AppColors.textHint,
  );
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600,
    color: AppColors.textHint, letterSpacing: 0.8,
  );
}
