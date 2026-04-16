import 'package:flutter/material.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../../models/question_with_options.dart';

class FeedbackOptionTile extends StatelessWidget {
  final QuestionOption option;
  final String selectedOption;
  final String correctOption;

  const FeedbackOptionTile({
    required this.option,
    required this.selectedOption,
    required this.correctOption,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect   = option.label == correctOption;
    final isSelected  = option.label == selectedOption;
    final isWrongPick = isSelected && !isCorrect;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color borderColor = Theme.of(context).dividerColor.withOpacity(0.1);
    Color bgColor     = Theme.of(context).cardColor;
    Color labelColor  = isDark ? Colors.white70 : AppColors.textSecondary;
    Widget? trailingIcon;

    if (isCorrect) {
      borderColor = AppColors.success;
      bgColor     = AppColors.success.withOpacity(0.08);
      labelColor  = AppColors.success;
      trailingIcon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
    } else if (isWrongPick) {
      borderColor = AppColors.error;
      bgColor     = AppColors.error.withOpacity(0.08);
      labelColor  = AppColors.error;
      trailingIcon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor, width: (isCorrect || isWrongPick) ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCorrect
                    ? AppColors.success.withOpacity(0.15)
                    : isWrongPick
                        ? AppColors.error.withOpacity(0.15)
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  option.label,
                  style: AppTextStyles.labelBold.copyWith(color: labelColor),
                ),
              ),
            ),
            Gaps.w(AppDimensions.md),
            Expanded(
              child: Text(option.body, style: AppTextStyles.bodyLarge),
            ),
            if (trailingIcon != null) trailingIcon,
          ],
        ),
      ),
    );
  }
}
