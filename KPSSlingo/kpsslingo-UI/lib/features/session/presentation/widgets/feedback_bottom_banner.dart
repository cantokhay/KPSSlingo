import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class FeedbackBottomBanner extends ConsumerStatefulWidget {
  final bool isCorrect;
  final String? explanation;
  final VoidCallback onNext;
  final bool isLast;

  // AI Deep Dive için gereken veriler (ileride kullanılacak)
  final String questionBody;
  final String correctAnswer;
  final String selectedAnswer;

  final VoidCallback? onCustomAction;
  final String? customActionLabel;

  const FeedbackBottomBanner({
    required this.isCorrect,
    this.explanation,
    required this.onNext,
    required this.isLast,
    required this.questionBody,
    required this.correctAnswer,
    required this.selectedAnswer,
    this.onCustomAction,
    this.customActionLabel,
    super.key,
  });

  @override
  ConsumerState<FeedbackBottomBanner> createState() =>
      _FeedbackBottomBannerState();
}

class _FeedbackBottomBannerState extends ConsumerState<FeedbackBottomBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  void _showComingSoonSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu özellik yakında aktif olacak.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.isCorrect;
    final bannerColor = isCorrect ? AppColors.success : AppColors.error;

    final bgColor = isCorrect
        ? const Color(0xFFF0FFF4).withOpacity(0.9)
        : const Color(0xFFFFF5F5).withOpacity(0.9);

    return SlideTransition(
      position: _slide,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.pageHorizontalPadding,
              AppDimensions.lg,
              AppDimensions.pageHorizontalPadding,
              MediaQuery.of(context).padding.bottom + AppDimensions.lg,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                  top: BorderSide(
                      color: bannerColor.withOpacity(0.3), width: 1.5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bannerColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCorrect
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                        color: bannerColor,
                        size: 20,
                      ),
                    ),
                    Gaps.w(AppDimensions.sm),
                    Text(
                      isCorrect ? 'Mükemmel!' : 'Önemli Değil!',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: bannerColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    // customAction: AI analiz — şu an aktif değil
                    if (widget.onCustomAction != null &&
                        widget.customActionLabel != null)
                      TextButton(
                        onPressed: _showComingSoonSnackBar,
                        child: Text(
                          widget.customActionLabel!,
                          style: TextStyle(
                            color: bannerColor.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                Gaps.md,
                if (widget.explanation != null) ...[
                  Text(
                    widget.explanation!,
                    style: AppTextStyles.bodyLarge
                        .copyWith(height: 1.4, color: Colors.black87),
                  ),
                  Gaps.md,
                  // "Derinden Öğren" butonu — şu an aktif değil
                  TextButton.icon(
                    onPressed: _showComingSoonSnackBar,
                    icon: Icon(
                      Icons.psychology_outlined,
                      color: bannerColor.withOpacity(0.5),
                      size: 20,
                    ),
                    label: Text(
                      'Nedenini Derinden Öğren (AI)',
                      style: TextStyle(
                        color: bannerColor.withOpacity(0.5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                Gaps.lg,
                ElevatedButton(
                  onPressed: widget.onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bannerColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  child: Text(
                    widget.isLast ? 'Sonuçları Gör' : 'Sıradaki Soru',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
