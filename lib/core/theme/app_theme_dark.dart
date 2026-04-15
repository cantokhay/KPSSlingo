import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

// ── Dark renk paleti ──────────────────────────────────────────────────────────
class AppColorsDark {
  // Arka planlar
  static const Color background    = Color(0xFF121218); // Çok koyu lacivert-siyah
  static const Color surface       = Color(0xFF1E1E2E); // Kart yüzeyi
  static const Color surfaceAlt    = Color(0xFF16161F); // Alternatif yüzey
  static const Color surfaceCard   = Color(0xFF252836); // Modal / elevated card

  // Metin
  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled  = Color(0xFF475569);

  // Semantic (aynı kalır)
  static const Color success       = Color(0xFF22C55E);
  static const Color error         = Color(0xFFEF4444);
  static const Color warning       = Color(0xFFF59E0B);

  // Border
  static const Color border        = Color(0xFF2D2D42);
}

// ── Dark ThemeData ────────────────────────────────────────────────────────────
ThemeData get appDarkTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColorsDark.surface,
    onSurface: AppColorsDark.textPrimary,
  ).copyWith(
    surface: AppColorsDark.surface,
    onSurface: AppColorsDark.textPrimary,
    surfaceContainerHighest: AppColorsDark.surfaceCard,
  ),
  scaffoldBackgroundColor: AppColorsDark.background,
  textTheme: ThemeData.dark().textTheme.apply(
    fontFamily: 'Plus Jakarta Sans',
    bodyColor: AppColorsDark.textPrimary,
    displayColor: AppColorsDark.textPrimary,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColorsDark.background,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    iconTheme: IconThemeData(color: AppColorsDark.textPrimary),
  ),
  cardTheme: CardThemeData(
    color: AppColorsDark.surface,
    elevation: AppDimensions.cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      side: const BorderSide(color: AppColorsDark.border, width: 1),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColorsDark.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColorsDark.textSecondary,
    elevation: 12,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColorsDark.surfaceCard,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColorsDark.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: const BorderSide(color: AppColorsDark.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColorsDark.textSecondary),
  ),
  dividerColor: AppColorsDark.border,
  dividerTheme: const DividerThemeData(color: AppColorsDark.border),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColorsDark.surface,
  ),
);
