import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';

class FeedbackBottomBanner extends ConsumerStatefulWidget {
  final bool isCorrect;
  final String? explanation;
  final VoidCallback onNext;
  final bool isLast;
  
  // AI Deep Dive için gereken veriler
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
  ConsumerState<FeedbackBottomBanner> createState() => _FeedbackBottomBannerState();
}

class _FeedbackBottomBannerState extends ConsumerState<FeedbackBottomBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  
  String? _deepDiveText;
  bool _isLoadingDeepDive = false;

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

  Future<void> _fetchDeepDive() async {
    setState(() => _isLoadingDeepDive = true);
    try {
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.functions.invoke(
        'generate-deep-dive',
        body: {
          'questionBody': widget.questionBody,
          'correctAnswer': widget.correctAnswer,
          'selectedAnswer': widget.selectedAnswer,
        },
      );
      
      if (response.data != null) {
        setState(() => _deepDiveText = response.data['text']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Açıklama getirilemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingDeepDive = false);
    }
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
    
    // Neumorphic ve Cam Efekti Renkleri
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
              border: Border(top: BorderSide(color: bannerColor.withOpacity(0.3), width: 1.5)),
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
                        isCorrect ? Icons.check_rounded : Icons.close_rounded,
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
                    if (widget.onCustomAction != null && widget.customActionLabel != null)
                      TextButton(
                        onPressed: widget.onCustomAction,
                        child: Text(widget.customActionLabel!, style: TextStyle(color: bannerColor, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                Gaps.md,
                if (_deepDiveText != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      border: Border.all(color: bannerColor.withOpacity(0.1)),
                    ),
                    child: Text(
                      _deepDiveText!,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
                    ),
                  ),
                  Gaps.md,
                ] else if (widget.explanation != null) ...[
                  Text(
                    widget.explanation!,
                    style: AppTextStyles.bodyLarge.copyWith(height: 1.4),
                  ),
                  Gaps.md,
                  TextButton.icon(
                    onPressed: _isLoadingDeepDive ? null : _fetchDeepDive,
                    icon: _isLoadingDeepDive 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.psychology_outlined, color: bannerColor, size: 20),
                    label: Text(
                      _isLoadingDeepDive ? 'Yapay Zeka Analiz Ediyor...' : 'Nedenini Derinden Öğren (AI)',
                      style: TextStyle(color: bannerColor, fontWeight: FontWeight.bold),
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
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
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
