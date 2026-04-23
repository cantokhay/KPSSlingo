import 'package:flutter/material.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';

class CompleteLessonResult {
  final int score;        // 0-100 (yüzde)
  final int xpEarned;     // Bu seansta kazanılan XP
  final int streak;       // Güncel streak (seans sonrası)
  final int? correctCount; // Opsiyonel: Doğru cevap sayısı
  final int? totalCount;   // Opsiyonel: Toplam soru sayısı

  const CompleteLessonResult({
    required this.score,
    required this.xpEarned,
    required this.streak,
    this.correctCount,
    this.totalCount,
  });

  factory CompleteLessonResult.fromJson(Map<String, dynamic> json) =>
      CompleteLessonResult(
        score:    (json['score']    as num).toInt(),
        xpEarned: (json['xp_earned'] as num).toInt(),
        streak:   (json['streak']   as num).toInt(),
        correctCount: (json['correct_count'] as num?)?.toInt(),
        totalCount:   (json['total_count']   as num?)?.toInt(),
      );

  // Skor kategorisi — UI'da kullanılır
  ResultGrade get grade {
    if (score >= 90) return ResultGrade.perfect;
    if (score >= 70) return ResultGrade.great;
    if (score >= 50) return ResultGrade.good;
    return ResultGrade.needsWork;
  }
}

enum ResultGrade { perfect, great, good, needsWork }

extension ResultGradeX on ResultGrade {
  String get emoji {
    switch (this) {
      case ResultGrade.perfect:   return '🏆';
      case ResultGrade.great:     return '⭐';
      case ResultGrade.good:      return '👍';
      case ResultGrade.needsWork: return '💪';
    }
  }

  String get title {
    switch (this) {
      case ResultGrade.perfect:   return 'Mükemmel!';
      case ResultGrade.great:     return 'Harika!';
      case ResultGrade.good:      return 'İyi İş!';
      case ResultGrade.needsWork: return 'Devam Et!';
    }
  }

  String get subtitle {
    switch (this) {
      case ResultGrade.perfect:   return 'Tüm soruları doğru yanıtladın.';
      case ResultGrade.great:     return 'Çok iyi bir performans.';
      case ResultGrade.good:      return 'Biraz daha pratikle mükemmelleşeceksin.';
      case ResultGrade.needsWork: return 'Tekrar denemek seni daha iyi yapacak.';
    }
  }

  Color get color {
    switch (this) {
      case ResultGrade.perfect:   return AppColors.xpGold; // Assuming this color exists in AppColors
      case ResultGrade.great:     return AppColors.primary;
      case ResultGrade.good:      return AppColors.success;
      case ResultGrade.needsWork: return AppColors.textSecondary;
    }
  }
}
