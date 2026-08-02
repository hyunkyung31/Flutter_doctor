import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.text,
        error: Color(0xFFDC2626),
      ),

      scaffoldBackgroundColor: AppColors.background,

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: const CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.lightBlue,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      dividerColor: const Color(0xFFE2E8F0),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF93C5FD),
        secondary: AppColors.secondary,
        surface: Color(0xFF1F2937),
        onPrimary: Color(0xFF0F172A),
        onSecondary: Colors.white,
        onSurface: Color(0xFFF8FAFC),
        error: Color(0xFFFCA5A5),
      ),

      scaffoldBackgroundColor: const Color(0xFF0F172A),

      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111827),
        foregroundColor: Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: const CardThemeData(
        color: Color(0xFF1F2937),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF111827),
        indicatorColor: Color(0xFF1E3A8A),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: Color(0xFFF8FAFC),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      dividerColor: const Color(0xFF334155),
    );
  }
}