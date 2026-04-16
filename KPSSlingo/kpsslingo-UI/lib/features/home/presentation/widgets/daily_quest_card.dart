import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../../providers/home_providers.dart';

class DailyQuestCard extends ConsumerWidget {
  const DailyQuestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyCount = ref.watch(dailyQuestProvider).value ?? 0;
    const target = 3;
    final progress = (dailyCount / target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress Indicator
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  color: AppColors.success,
                  backgroundColor: AppColors.success.withOpacity(0.1),
                ),
                Center(
                  child: Text(
                    '$dailyCount/$target',
                    style: AppTextStyles.labelBold.copyWith(
                      color: AppColors.success,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Gaps.md,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GÜNLÜK GÖREV',
                  style: AppTextStyles.labelBold,
                ),
                Text(
                  'Günü bitirmek için 3 ders tamamla!',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (progress >= 1.0)
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28)
          else
             const Text('🏃', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
