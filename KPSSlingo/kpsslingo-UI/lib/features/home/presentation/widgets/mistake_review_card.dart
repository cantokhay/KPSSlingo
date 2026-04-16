import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/core/theme/neumorphic_style.dart';
import 'package:kpsslingo/features/session/providers/mistakes_provider.dart';

class MistakeReviewCard extends ConsumerWidget {
  const MistakeReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mistakesCount = ref.watch(mistakesCountProvider);

    return mistakesCount.when(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();
        
        return Padding(
          padding: const EdgeInsets.only(top: AppDimensions.lg),
          child: Container(
            decoration: NeumorphicStyle.containerDecoration(
              context, 
              color: AppColors.error.withOpacity(0.05),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/mistake-review'),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.md),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_fix_high_rounded, color: AppColors.error),
                      ),
                      Gaps.w(AppDimensions.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hatalarını Temizle',
                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.error),
                            ),
                            Text(
                              '$count soruyu yanlış cevapladın. Hemen tekrar et!',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.error),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
