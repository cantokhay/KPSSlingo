import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/home_providers.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/shared/widgets/skeleton.dart';
import '../../data/models/lesson.dart';

class ContinueLessonSection extends ConsumerWidget {
  const ContinueLessonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextLessonAsync = ref.watch(nextLessonProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      child: nextLessonAsync.when(
        data: (lesson) => lesson != null
            ? _ContinueLessonCard(lesson: lesson)
            : const _FirstLessonPrompt(),
        loading: () => const _LessonCardSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _ContinueLessonCard extends StatelessWidget {
  final Lesson lesson;
  const _ContinueLessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.topicColors[lesson.topicId] ?? AppColors.primary;

    return Hero(
      tag: 'lesson-card-${lesson.id}',
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Devam Et', style: AppTextStyles.labelBold.copyWith(color: AppColors.textSecondary)),
          Gaps.sm,
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.menu_book_rounded, color: color, size: 20),
                ),
              ),
              Gaps.w(AppDimensions.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lesson.title, style: AppTextStyles.titleMedium),
                    Gaps.xs,
                    Text('Ders ${lesson.order}', style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => context.go('/lesson/${lesson.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusSm)),
                ),
                child: const Row(
                  children: [
                    Text('Başla'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
          Gaps.h(12),
          LinearProgressIndicator(
            value: 0.35, // Demo progress percentage
            backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    ),
    );
  }
}

class _FirstLessonPrompt extends StatelessWidget {
  const _FirstLessonPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.rocket_launch, color: AppColors.primary, size: 32),
          Gaps.w(AppDimensions.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('İlk derse başla!', style: AppTextStyles.titleMedium),
                Text('Aşağıdan bir konu seçerek KPSS serüvenine başla.', style: AppTextStyles.bodySmall),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _LessonCardSkeleton extends StatelessWidget {
  const _LessonCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(
      width: double.infinity,
      height: 110,
      radius: AppDimensions.radiusMd,
    );
  }
}
