import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import '../models/session_state.dart';
import '../providers/mistake_review_notifier.dart';
import 'widgets/session_header.dart';
import 'widgets/option_tile.dart';
import 'widgets/feedback_option_tile.dart';
import 'widgets/feedback_bottom_banner.dart';
import 'widgets/hearts_out_dialog.dart';

class MistakeReviewScreen extends ConsumerStatefulWidget {
  const MistakeReviewScreen({super.key});

  @override
  ConsumerState<MistakeReviewScreen> createState() => _MistakeReviewScreenState();
}

class _MistakeReviewScreenState extends ConsumerState<MistakeReviewScreen> {

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mistakeReviewNotifierProvider);

    ref.listen(heartsProvider, (previous, next) {
      if (next != null && next.hearts == 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const HeartsOutDialog(),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (state.phase) {
            SessionPhase.loading    => const Center(child: CircularProgressIndicator()),
            SessionPhase.question   => _MistakeQuestionView(state: state),
            SessionPhase.feedback   => _MistakeFeedbackView(state: state),
            SessionPhase.submitting => _ReviewCompleteView(),
            SessionPhase.error      => _ReviewErrorView(message: state.errorMessage ?? 'Bir hata oluştu.'),
          },
        ),
      ),
    );
  }
}

class _MistakeQuestionView extends ConsumerWidget {
  final SessionState state;
  const _MistakeQuestionView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion!;
    
    return Column(
      children: [
        SessionHeader(
          currentIndex: state.currentIndex,
          total: state.totalQuestions,
          lessonId: 'mistakes', // Fake ID for progress
        ),
        Gaps.lg,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageHorizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hatalarını Temizle', style: AppTextStyles.labelBold.copyWith(color: AppColors.error)),
                Gaps.sm,
                Text(question.body, style: AppTextStyles.headlineMedium),
                const Spacer(),
                ...question.options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.sm),
                  child: GestureDetector(
                    onTap: () => ref.read(mistakeReviewNotifierProvider.notifier).selectOption(option.id),
                    child: OptionTile(
                      option: option,
                      selectedOption: state.selectedOption,
                      lessonId: 'mistakes',
                    ),
                  ),
                )),
                Gaps.xl,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MistakeFeedbackView extends ConsumerWidget {
  final SessionState state;
  const _MistakeFeedbackView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = state.currentQuestion!;

    return Column(
      children: [
        SessionHeader(
          currentIndex: state.currentIndex,
          total: state.totalQuestions,
          lessonId: 'mistakes',
        ),
        Gaps.lg,
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageHorizontalPadding),
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
                // "AI Açıkla" butonu buraya eklenebilir
              ],
            ),
          ),
        ),
        FeedbackBottomBanner(
          isCorrect: state.isCorrect!,
          explanation: question.explanation,
          onNext: () => ref.read(mistakeReviewNotifierProvider.notifier).nextQuestion(),
          isLast: state.isLastQuestion,
          questionBody: question.body,
          correctAnswer: question.correctOption,
          selectedAnswer: state.selectedOption!,
          customActionLabel: 'AI ile Analiz Et',
          onCustomAction: () => _showAIAnalysis(context, question.body, question.explanation ?? ''),
        ),
      ],
    );
  }

  Future<void> _showAIAnalysis(BuildContext context, String question, String explanation) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AIAnalysisSheet(
        question: question,
        explanation: explanation,
      ),
    );
  }
}

class _AIAnalysisSheet extends ConsumerStatefulWidget {
  final String question;
  final String explanation;
  const _AIAnalysisSheet({required this.question, required this.explanation});

  @override
  ConsumerState<_AIAnalysisSheet> createState() => _AIAnalysisSheetState();
}

class _AIAnalysisSheetState extends ConsumerState<_AIAnalysisSheet> {
  String? _analysis;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalysis();
  }

  Future<void> _fetchAnalysis() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-explain',
        body: {
          'question': widget.question,
          'explanation': widget.explanation,
        },
      );

      if (response.status != 200) throw Exception('Analiz alınamadı.');
      
      if (mounted) {
        setState(() {
          _analysis = response.data['analysis'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Şu an analiz yapılamıyor. Lütfen sonra tekrar dene.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              Gaps.w(AppDimensions.sm),
              Text('Mini Analiz', style: AppTextStyles.titleLarge),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          Gaps.md,
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Text(_error!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))
          else if (_analysis != null)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Text(_analysis!, style: AppTextStyles.bodyLarge),
            ),
          Gaps.xl,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Anladım'),
            ),
          ),
          Gaps.md,
        ],
      ),
    );
  }
}

class _ReviewCompleteView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 80, color: AppColors.success),
          Gaps.lg,
          Text('Harika!', style: AppTextStyles.headlineMedium),
          Text('Hatalarını temizledin.', style: AppTextStyles.bodyLarge),
          Gaps.xl,
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Ana Sayfaya Dön'),
          ),
        ],
      ),
    );
  }
}

class _ReviewErrorView extends ConsumerWidget {
  final String message;
  const _ReviewErrorView({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppTextStyles.bodyLarge),
          Gaps.lg,
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Ana Sayfaya Dön'),
          ),
        ],
      ),
    );
  }
}
