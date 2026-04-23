import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/features/home/presentation/widgets/heart_indicator.dart';

class SessionHeader extends StatelessWidget {
  final int currentIndex;
  final int total;
  /// Kullanıcı X'e basınca çalışacak callback.
  /// Verilmezse GoRouter üzerinden /home'a gider.
  final VoidCallback? onClose;

  const SessionHeader({
    required this.currentIndex,
    required this.total,
    this.onClose,
    // Geriye dönük uyumluluk: lessonId artık kullanılmıyor ama parametreyi
    // eski çağrı yerlerinin derlenmesi için opsiyonel tutuyoruz.
    @Deprecated('Artık kullanılmıyor') String? lessonId,
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
                onPressed: onClose ?? () => context.go('/home'),
                icon: const Icon(Icons.close_rounded),
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
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ),
              ),

              Gaps.w(AppDimensions.md),

              Text(
                '${currentIndex + 1}/$total',
                style: AppTextStyles.labelBold,
              ),

              Gaps.w(AppDimensions.sm),
              const HeartIndicator(isCompact: true),
            ],
          ),
        ],
      ),
    );
  }
}
