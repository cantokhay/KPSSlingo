import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class ActionButtons extends StatelessWidget {
  final String lessonId;
  final int score;

  const ActionButtons({
    required this.lessonId,
    required this.score,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primary: Eve Dön
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              elevation: 0,
            ),
            child: Text(
              'Eve Dön',
              style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
            ),
          ),
        ),

        Gaps.sm,

        // Secondary: Tekrar Dene (sadece score < 100 ise göster)
        if (score < 100)
          TextButton(
            onPressed: () => context.go('/lesson/$lessonId'),
            child: Text(
              'Tekrar Dene',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}
