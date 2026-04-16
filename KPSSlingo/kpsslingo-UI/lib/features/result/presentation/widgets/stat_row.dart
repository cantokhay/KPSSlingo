import 'package:flutter/material.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../../../session/models/complete_lesson_result.dart';
import 'stat_card.dart';

class StatRow extends StatelessWidget {
  final CompleteLessonResult result;
  
  const StatRow({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    // Doğru sayısı: score * 10 / 100 (10 soruluk seans varsayımı)
    final correctCount = (result.score / 10).round();

    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.xpGold,
            value: '+${result.xpEarned}',
            label: 'XP Kazanıldı',
            animateValue: true,
            targetValue: result.xpEarned,
          ),
        ),
        Gaps.w(AppDimensions.sm),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: AppColors.streakFire, // check if colors exist
            value: '${result.streak}',
            label: 'Günlük Seri',
            animateValue: result.streak > 1,
            targetValue: result.streak,
          ),
        ),
        Gaps.w(AppDimensions.sm),
        Expanded(
          child: StatCard(
            icon: Icons.check_circle_rounded,
            iconColor: AppColors.success,
            value: '$correctCount/10',
            label: 'Doğru',
            animateValue: false,
            targetValue: correctCount,
          ),
        ),
      ],
    );
  }
}
