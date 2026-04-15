import 'package:flutter/material.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../../../session/models/complete_lesson_result.dart';

class GradeHeader extends StatelessWidget {
  final ResultGrade grade;
  const GradeHeader({required this.grade, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(grade.emoji, style: const TextStyle(fontSize: 56)),
        Gaps.sm,
        Text(grade.title, style: AppTextStyles.displayLarge),
        Gaps.xs,
        Text(
          grade.subtitle,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
