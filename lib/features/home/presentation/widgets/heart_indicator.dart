import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';

class HeartIndicator extends ConsumerWidget {
  const HeartIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartsState = ref.watch(heartsProvider);

    if (heartsState == null) return const SizedBox.shrink();

    final hearts = heartsState.hearts;
    final isCritical = hearts <= 2;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Neumorphic Soft Shadow
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(3, 3),
          ),
          if (!isDark)
          const BoxShadow(
            color: Colors.white,
            blurRadius: 8,
            offset: Offset(-3, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hearts == 0 ? Icons.favorite_border_rounded : Icons.favorite_rounded,
            color: isCritical ? AppColors.error : AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            hearts.toString(),
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          if (hearts < kMaxHearts) ...[
            const SizedBox(width: 6),
            Container(width: 1, height: 14, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(width: 6),
            Text(
              _formatDuration(heartsState.timeUntilNext),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
