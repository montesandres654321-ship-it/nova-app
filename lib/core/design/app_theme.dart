import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdAll,
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return null;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
    ),
  );
}
