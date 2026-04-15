import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_theme_dark.dart';

class NeumorphicStyle {
  /// Hafif ve Modern Neumorphic Efekti (Dışbükey - Convex)
  static List<BoxShadow> modernShadow(BuildContext context, {bool isSelected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isSelected) {
      // Seçiliyken içbükey (concave) efekti simülasyonu veya sadece vurgu
      return [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    }

    if (isDark) {
      return [
        // Koyu tema: Alt-sağ koyu gölge
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(4, 4),
          blurRadius: 10,
          spreadRadius: 1,
        ),
        // Koyu tema: Üst-sol hafif aydınlık (Sleek Dark için)
        BoxShadow(
          color: AppColorsDark.surfaceCard.withOpacity(0.2),
          offset: const Offset(-4, -4),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ];
    } else {
      return [
        // Açık tema: Alt-sağ yumuşak gri gölge
        BoxShadow(
          color: const Color(0xFFA3B1C6).withOpacity(0.4),
          offset: const Offset(6, 6),
          blurRadius: 12,
        ),
        // Açık tema: Üst-sol saf beyaz parlama
        const BoxShadow(
          color: Colors.white,
          offset: Offset(-6, -6),
          blurRadius: 12,
        ),
      ];
    }
  }

  /// Neumorphic basılma efekti için özel dekorasyon
  static BoxDecoration containerDecoration(BuildContext context, {
    Color? color, 
    double borderRadius = 16,
    bool isSelected = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = color ?? (isDark ? AppColorsDark.surface : AppColors.surface);

    return BoxDecoration(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: modernShadow(context, isSelected: isSelected),
    );
  }
}
