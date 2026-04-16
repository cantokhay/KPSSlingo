import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../../models/question_with_options.dart';
import '../../providers/session_notifier.dart';

class OptionTile extends ConsumerWidget {
  final QuestionOption option;
  final String? selectedOption;
  final String lessonId;

  const OptionTile({
    required this.option,
    required this.selectedOption,
    required this.lessonId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = selectedOption == option.label;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected 
            ? AppColors.primary.withOpacity(isDark ? 0.2 : 0.05) 
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: isSelected 
          ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
          : [
              // Neumorphic Soft Shadow
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 15,
                offset: const Offset(4, 4),
              ),
              if (!isDark)
              const BoxShadow(
                color: Colors.white,
                blurRadius: 15,
                offset: Offset(-4, -4),
              ),
            ],
      ),
      child: InkWell(
        onTap: () => ref
            .read(sessionNotifierProvider(lessonId).notifier)
            .selectOption(option.label),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.md,
            vertical: AppDimensions.md,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                  boxShadow: isSelected ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    option.label,
                    style: AppTextStyles.labelBold.copyWith(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Gaps.w(AppDimensions.md),
              Expanded(
                child: Text(
                  option.body, 
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
