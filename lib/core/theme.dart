import 'package:flutter/material.dart';

/// Design tokens from mockup/kalkulator_cerdas_nusantara/DESIGN.md.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF059669);
  static const primaryDark = Color(0xFF006948);
  static const secondary = Color(0xFF0D9488);
  static const tertiary = Color(0xFF10B981);
  static const canvas = Color(0xFFF8FAFC);
  static const ink = Color(0xFF0F172A);
  static const inkMuted = Color(0xFF334155);
  static const inkSubtle = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const tint = Color(0xFFECFDF5);
  static const lavender = Color(0xFFEEF0FF);
  static const danger = Color(0xFFEF4444);
  static const dangerTint = Color(0xFFFEF2F2);
  static const amber = Color(0xFFF59E0B);
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData light() => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF86F2E4),
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.secondary,
          tertiary: AppColors.tertiary,
          surface: Colors.white,
          onSurface: AppColors.ink,
          onSurfaceVariant: AppColors.inkMuted,
          outline: AppColors.inkSubtle,
          outlineVariant: AppColors.line,
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: AppColors.canvas,
          surfaceContainer: const Color(0xFFF1F5F9),
          surfaceContainerHigh: AppColors.lavender,
          error: const Color(0xFFBA1A1A),
        ),
        canvas: AppColors.canvas,
      );

  static ThemeData dark() => _build(
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF68DBA9),
          onPrimary: const Color(0xFF002114),
          primaryContainer: const Color(0xFF005137),
          onPrimaryContainer: const Color(0xFF85F8C4),
          secondary: const Color(0xFF6BD8CB),
          tertiary: const Color(0xFF4EDEA3),
          surface: const Color(0xFF1B2236),
          onSurface: const Color(0xFFE6EAF5),
          onSurfaceVariant: const Color(0xFFBCC6DA),
          outlineVariant: const Color(0xFF334155),
          surfaceContainerLowest: const Color(0xFF131B2E),
          surfaceContainerLow: const Color(0xFF172036),
          surfaceContainer: const Color(0xFF222B42),
          surfaceContainerHigh: const Color(0xFF2A3450),
        ),
        canvas: const Color(0xFF0F1626),
      );

  static ThemeData _build(ColorScheme scheme, {required Color canvas}) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: canvas,
    );
    final radius = BorderRadius.circular(12);
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        enabledBorder:
            OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
              fontFamily: fontFamily, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
            fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
