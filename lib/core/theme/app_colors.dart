import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary       = Color(0xFF1A3DE4);  // Koyu mavi — güven, akademik
  static const Color primaryLight  = Color(0xFF4F6FFF);
  static const Color accent        = Color(0xFFFF6B35);  // Turuncu — enerji, aksiyon

  // Nötrler
  static const Color background    = Color(0xFFF5F7FF);  // Hafif mavi-beyaz
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color surfaceAlt    = Color(0xFFEDF0FF);  // Kart arka planı

  // Semantic
  static const Color success       = Color(0xFF22C55E);  // Doğru cevap
  static const Color error         = Color(0xFFEF4444);  // Yanlış cevap
  static const Color warning       = Color(0xFFF59E0B);  // Streak risk

  // Metin
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled  = Color(0xFFCBD5E1);

  // XP & Gamification
  static const Color xpGold        = Color(0xFFFFD700);
  static const Color streakFire    = Color(0xFFFF4500);

  // Konu Renkleri (her konu için sabit)
  static const Map<String, Color> topicColors = {
    'genel-yetenek-matematik':  Color(0xFF6366F1),  // Indigo
    'genel-yetenek-turkce':     Color(0xFF10B981),  // Emerald
    'genel-kultur-tarih':       Color(0xFFF59E0B),  // Amber
    'genel-kultur-cografya':    Color(0xFF3B82F6),  // Blue
    'genel-kultur-vatandaslik': Color(0xFFEF4444),  // Red
    'genel-kultur-guncel':      Color(0xFF8B5CF6),  // Violet
  };
}
