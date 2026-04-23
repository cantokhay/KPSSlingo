import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 28, fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
    fontSize: 24, fontWeight: FontWeight.w800,
  );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
    fontSize: 20, fontWeight: FontWeight.w700,
  );

  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
    fontSize: 18, fontWeight: FontWeight.w700,
  );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 18, fontWeight: FontWeight.w600,
  );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w600,
  );

  static TextStyle get titleSmall => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w600,
  );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 15, fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 13, fontWeight: FontWeight.w400,
  );

  static TextStyle get labelBold => GoogleFonts.plusJakartaSans(
    fontSize: 12, fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 11, fontWeight: FontWeight.w500,
  );

  static TextStyle get xpLabel => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.xpGold,
  );
}
