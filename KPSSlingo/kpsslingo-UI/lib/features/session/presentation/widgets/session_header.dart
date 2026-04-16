import 'package:flutter/material.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class SessionHeader extends StatelessWidget {
  final int currentIndex;
  final int total;
  final String lessonId;

  const SessionHeader({
    required this.currentIndex,
    required this.total,
    required this.lessonId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ).copyWith(top: AppDimensions.md),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Gaps.w(AppDimensions.md),

              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: currentIndex / total,
                    end: (currentIndex + 1) / total,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  builder: (_, value, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ),

              Gaps.w(AppDimensions.md),

              Text(
                '${currentIndex + 1}/$total',
                style: AppTextStyles.labelBold.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
