import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_state.dart';
import '../models/question_with_options.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import 'package:kpsslingo/features/home/providers/home_providers.dart';
import 'package:kpsslingo/features/home/providers/home_data_provider.dart';
import 'mistakes_provider.dart';

final mistakeReviewNotifierProvider =
    StateNotifierProvider.autoDispose<MistakeReviewNotifier, SessionState>(
        (ref) {
  return MistakeReviewNotifier(
    supabase: Supabase.instance.client,
    ref: ref,
  );
});

class MistakeReviewNotifier extends StateNotifier<SessionState> {
  final SupabaseClient supabase;
  final Ref ref;

  MistakeReviewNotifier({
    required this.supabase,
    required this.ref,
  }) : super(const SessionState()) {
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    state = state.copyWith(phase: SessionPhase.loading);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) throw Exception('Giriş yapılmamış.');

      // Maksimum 15 hata göster (cevaplar hariç)
      final data = await supabase
          .from('user_mistakes')
          .select('questions(*, question_options(*))')
          .eq('user_id', user.id)
          .order('updated_at', ascending: false)
          .limit(15);


      final questions = (data as List)
          .map((e) {
            if (e['questions'] == null) return null;
            return QuestionWithOptions.fromJson(e['questions'] as Map<String, dynamic>);
          })
          .whereType<QuestionWithOptions>()
          .toList();

      if (questions.isEmpty) {
        state = state.copyWith(
          phase: SessionPhase.error,
          errorMessage: 'Harika! Hiç hatan kalmamış.',
        );
        return;
      }

      // GÜVENLİK: Cevapları ayrı bir RPC ile çek
      final qIds = questions.map((q) => q.id).toList();
      final answersData = await supabase.rpc('get_session_answers', params: {
        'p_question_ids': qIds,
      });

      final List<dynamic> answersList = answersData as List<dynamic>;
      final updatedQuestions = questions.map((q) {
        final ans = answersList.firstWhere((a) => a['question_id'] == q.id, orElse: () => null);
        if (ans != null) {
          return q.copyWith(correctOption: ans['correct_option'] as String);
        }
        return q;
      }).toList();

      state = state.copyWith(
        phase: SessionPhase.question,
        questions: updatedQuestions,
        currentIndex: 0,
      );
    } catch (e) {
      state = state.copyWith(
        phase: SessionPhase.error,
        errorMessage: 'Hatalar yüklenemedi. Lütfen tekrar dene.',
      );
    }
  }

  void selectOption(String option) async {
    if (state.phase != SessionPhase.question) return;

    final question = state.currentQuestion!;
    final isCorrect = option == question.correctOption;

    state = state.copyWith(
      phase: SessionPhase.feedback,
      selectedOption: option,
      isCorrect: isCorrect,
    );

    final record = AnswerRecord(
      questionId: question.id,
      selectedOption: option,
      isCorrect: isCorrect,
      timeSpentMs: 0,
    );
    state = state.copyWith(answers: [...state.answers, record]);

    if (!isCorrect) {
      await ref.read(heartsProvider.notifier).useHeart();
    }
  }

  void nextQuestion() {
    if (state.phase != SessionPhase.feedback) return;
    final nextIndex = state.currentIndex + 1;

    if (nextIndex >= state.questions.length) {
      _completeReview();
      return;
    }

    state = state.copyWith(
      phase: SessionPhase.question,
      currentIndex: nextIndex,
      selectedOption: null,
      isCorrect: null,
    );
  }

  Future<void> _completeReview() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = state.copyWith(phase: SessionPhase.summary);
      return;
    }

    state = state.copyWith(phase: SessionPhase.submitting);

    try {
      // Atomik RPC kullanımı
      if (state.answers.isNotEmpty) {
        await supabase.rpc('complete_mistake_review', params: {
          'p_user_id': user.id,
          'p_answers': state.answers.map((a) => a.toJson()).toList(),
        });
      }

      ref.invalidate(userProfileProvider);
      ref.invalidate(mistakesCountProvider);
      ref.invalidate(streakProvider);
      
      Future.microtask(() {
        ref.invalidate(dailyQuestProvider);
        ref.invalidate(dailyXpProvider);
      });

      state = state.copyWith(phase: SessionPhase.summary);
    } catch (e) {
      state = state.copyWith(phase: SessionPhase.summary);
    }
  }

  void retry() => _loadMistakes();
}
