// lib/utils/app_theme.dart - CORREGIDO

import 'package:flutter/material.dart';

class AppTheme {
  // ============================================
  // COLORES PRINCIPALES
  // ============================================

  // Primary (Teal)
  static const Color primary = Color(0xFF06B6A4);
  static const Color primaryDark = Color(0xFF0891A3);
  static const Color primaryLight = Color(0xFF2DD4BF);

  // Secondary (Azul)
  static const Color secondary = Color(0xFF0EA5E9);
  static const Color secondaryDark = Color(0xFF0284C7);
  static const Color secondaryLight = Color(0xFF38BDF8);

  // Estados
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Neutros
  static const Color gray900 = Color(0xFF111827);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray50 = Color(0xFFF9FAFB);

  // Fondos
  static const Color background = Colors.white;
  static const Color backgroundGray = gray50;
  static const Color surface = Colors.white;

  // ============================================
  // ESPACIADO (Sistema de 8px)
  // ============================================

  static const double spaceXXS = 4.0;
  static const double spaceXS = 8.0;
  static const double spaceSM = 12.0;
  static const double spaceMD = 16.0;
  static const double spaceLG = 24.0;
  static const double spaceXL = 32.0;
  static const double spaceXXL = 48.0;
  static const double spaceXXXL = 64.0;

  // ============================================
  // BORDER RADIUS
  // ============================================

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 9999.0;

  // ============================================
  // SOMBRAS
  // ============================================

  static List<BoxShadow> get shadowSM => [
    BoxShadow(
      color: gray900.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get shadowMD => [
    BoxShadow(
      color: gray900.withOpacity(0.1),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get shadowLG => [
    BoxShadow(
      color: primary.withOpacity(0.2),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
  ];

  // ============================================
  // THEME DATA
  // ============================================

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundGray,
      fontFamily: 'Roboto', // ✅ Cambiado a Roboto (viene por defecto)

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: gray900,
        onError: Colors.white,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: gray900,
        iconTheme: IconThemeData(color: gray700),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray900,
          fontFamily: 'Roboto',
        ),
      ),

      // Card Theme ✅ CORREGIDO
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: gray700,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          side: const BorderSide(color: gray300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Roboto',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(
          color: gray600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(
          color: gray400,
          fontSize: 14,
        ),
      ),

      // Tab Bar Theme ✅ CORREGIDO
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: gray500,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'Roboto',
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          fontFamily: 'Roboto',
        ),
      ),

      // Drawer Theme
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        iconColor: gray600,
        textColor: gray800,
        selectedColor: primary,
        selectedTileColor: primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: gray200,
        thickness: 1,
        space: 24,
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: gray600,
        size: 24,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: gray900,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: gray900,
          height: 1.2,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: gray900,
          height: 1.3,
        ),
        headlineLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: gray900,
          height: 1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: gray900,
          height: 1.4,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: gray900,
          height: 1.4,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: gray900,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: gray700,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: gray600,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: gray500,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: gray700,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: gray600,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: gray500,
        ),
      ),
    );
  }

  // ============================================
  // DECORACIONES REUTILIZABLES
  // ============================================

  static BoxDecoration cardDecoration({
    Color? color,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(radiusMD),
      boxShadow: boxShadow ?? shadowSM,
    );
  }

  static BoxDecoration statCardDecoration({
    required Color color,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.1),
          color.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radiusMD),
      border: Border.all(
        color: color.withOpacity(0.2),
        width: 1,
      ),
    );
  }
}