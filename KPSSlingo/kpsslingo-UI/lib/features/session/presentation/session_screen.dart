import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/shared/widgets/skeleton.dart';
import '../models/session_state.dart';
import 'widgets/session_header.dart';
import 'widgets/option_tile.dart';
import 'widgets/feedback_option_tile.dart';
import '../providers/session_notifier.dart';
import 'widgets/feedback_bottom_banner.dart';
import 'widgets/exit_session_dialog.dart';
import 'widgets/xp_float_widget.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import 'widgets/hearts_out_dialog.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String lessonId;
  const SessionScreen({required this.lessonId, super.key});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  bool _showXP = false;

  Future<void> _showHeartsOutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const HeartsOutDialog(),
    );
  }

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.listenManual(sessionResultProvider, (_, result) {
        if (result != null) {
          context.go('/result', extra: {
            'result': {
              'score': result.score,
              'xp_earned': result.xpEarned,
              'streak': result.streak,
            },
            'lesson_id': widget.lessonId,
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionState = ref.watch(
      sessionNotifierProvider(widget.lessonId),
    );

    ref.listen(sessionNotifierProvider(widget.lessonId), (previous, next) {
      if (previous?.phase == SessionPhase.question && next.phase == SessionPhase.feedback) {
        if (next.isCorrect == true) {
          setState(() => _showXP = true);
        } else {
          _shakeController.forward(from: 0);
        }
      }
    });

    ref.listen(heartsProvider, (previous, next) {
      if (next != null && next.hearts == 0) {
        _showHeartsOutDialog(context);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitDialog(context);
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCirc,
                transitionBuilder: (Widget child, Animation<double> animation) {
                   final offsetAnimation = Tween<Offset>(
                     begin: const Offset(1.0, 0.0),
                     end: Offset.zero,
                   ).animate(animation);
                   
                   return SlideTransition(
                     position: offsetAnimation,
                     child: FadeTransition(opacity: animation, child: child),
                   );
                },
                child: switch (sessionState.phase) {
                  SessionPhase.loading    => const _SessionLoadingView(key: ValueKey('loading')),
                  SessionPhase.question   => _QuestionView(
                      key: ValueKey('q-${sessionState.currentIndex}'),
                      state: sessionState,
                      lessonId: widget.lessonId,
                      shakeAnimation: _shakeController,
                    ),
                  SessionPhase.feedback   => _FeedbackView(
                      key: ValueKey('f-${sessionState.currentIndex}'),
                      state: sessionState,
                      lessonId: widget.lessonId,
                    ),
                  SessionPhase.submitting => const _SubmittingView(key: ValueKey('submitting')),
                  SessionPhase.error      => _ErrorView(
                      key: const ValueKey('error'),
                      message: sessionState.errorMessage ?? 'Bir hata oluştu.',
                      lessonId: widget.lessonId,
                    ),
                },
              ),
            ),
            
            // XP Animation Overlay
            if (_showXP)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: XPFloatWidget(
                    xp: 10, // Static for now or get from state
                    onComplete: () => setState(() => _showXP = false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showExitDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const ExitSessionDialog(),
    );
    if (confirmed == true && context.mounted) context.go('/home');
  }
}

class _QuestionView extends StatelessWidget {
  final SessionState state;
  final String lessonId;
  final Animation<double> shakeAnimation;

  const _QuestionView({
    required this.state, 
    required this.lessonId,
    required this.shakeAnimation,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion!;

    return Hero(
      tag: 'lesson-card-$lessonId',
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SessionHeader(
              currentIndex: state.currentIndex,
              total: state.totalQuestions,
              lessonId: lessonId,
            ),
            Gaps.lg,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pageHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.sm,
                        vertical: AppDimensions.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Text(
                        'Soru ${state.currentIndex + 1}',
                        style: AppTextStyles.labelBold.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Gaps.md,
                    AnimatedBuilder(
                      animation: shakeAnimation,
                      builder: (context, child) {
                        final sineValue = 
                            (shakeAnimation.value * 3 * 3.14159); // 3 cycles
                        final offset = 10 * (1 - shakeAnimation.value) * (sineValue > 0 ? 1 : -1) * (shakeAnimation.value > 0 ? 1 : 0);
                        
                        double x = 0;
                        if (shakeAnimation.value > 0 && shakeAnimation.value < 1) {
                          x = (10 * (1 - shakeAnimation.value)) * 
                              ( ( (shakeAnimation.value * 20).floor() % 2 == 0 ) ? 1 : -1 );
                        }

                        return Transform.translate(
                          offset: Offset(x, 0),
                          child: child,
                        );
                      },
                      child: Text(
                        question.body,
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    const Spacer(),
                    ...question.options.map((option) => Padding(
                      padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                      child: OptionTile(
                        option: option,
                        selectedOption: state.selectedOption,
                        lessonId: lessonId,
                      ),
                    )),
                    Gaps.md,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackView extends ConsumerWidget {
  final SessionState state;
  final String lessonId;
  const _FeedbackView({required this.state, required this.lessonId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion!;
    final isCorrect = state.isCorrect!;

    return Hero(
      tag: 'lesson-card-$lessonId',
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SessionHeader(
              currentIndex: state.currentIndex,
              total: state.totalQuestions,
              lessonId: lessonId,
            ),
            Gaps.lg,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pageHorizontalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(question.body, style: AppTextStyles.headlineMedium),
                    Gaps.md,
                    ...question.options.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                          child: FeedbackOptionTile(
                            option: option,
                            selectedOption: state.selectedOption!,
                            correctOption: question.correctOption,
                          ),
                        )),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            FeedbackBottomBanner(
              isCorrect: isCorrect,
              explanation: question.explanation,
              questionBody: question.body,
              correctAnswer: question.correctOption,
              selectedAnswer: state.selectedOption!,
              onNext: () => ref.read(sessionNotifierProvider(lessonId).notifier).nextQuestion(),
              isLast: state.isLastQuestion,
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionLoadingView extends StatelessWidget {
  const _SessionLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const SkeletonBox(width: 32, height: 32, radius: AppDimensions.radiusFull),
            Gaps.w(AppDimensions.md),
            const Expanded(child: SkeletonBox(width: double.infinity, height: 10, radius: AppDimensions.radiusFull)),
            Gaps.w(AppDimensions.md),
            const SkeletonBox(width: 32, height: 16),
          ]),
          Gaps.xl,
          const SkeletonBox(width: double.infinity, height: 28),
          Gaps.sm,
          const SkeletonBox(width: 220, height: 28),
          Gaps.xl,
          ...List.generate(5, (_) => const Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.sm),
            child: SkeletonBox(width: double.infinity, height: 60, radius: AppDimensions.radiusMd),
          )),
        ],
      ),
    );
  }
}

class _SubmittingView extends StatelessWidget {
  const _SubmittingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          Gaps.md,
          Text('Sonuçlar kaydediliyor...'),
        ],
      ),
    );
  }
}

class _ErrorView extends ConsumerWidget {
  final String message;
  final String lessonId;
  const _ErrorView({required this.message, required this.lessonId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
            Gaps.md,
            Text(message, style: AppTextStyles.bodyLarge, textAlign: TextAlign.center),
            Gaps.lg,
            ElevatedButton(
              onPressed: () => ref
                  .read(sessionNotifierProvider(lessonId).notifier)
                  .retry(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 48),
              ),
              child: const Text('Tekrar Dene'),
            ),
            Gaps.sm,
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ana Sayfaya Dön', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
