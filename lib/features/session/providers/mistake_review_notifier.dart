import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/session_state.dart';
import '../models/question_with_options.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';

final mistakeReviewNotifierProvider = StateNotifierProvider.autoDispose<MistakeReviewNotifier, SessionState>((ref) {
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

      final data = await supabase
          .from('user_mistakes')
          .select('questions(*, question_options(*))')
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final questions = (data as List)
          .map((e) => QuestionWithOptions.fromJson(e['questions'] as Map<String, dynamic>))
          .toList();

      if (questions.isEmpty) {
        state = state.copyWith(
          phase: SessionPhase.error,
          errorMessage: 'Harika! Hiç hatan kalmamış.',
        );
        return;
      }

      state = state.copyWith(
        phase: SessionPhase.question,
        questions: questions,
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

    // Can & Hata Logic
    if (!isCorrect) {
      await ref.read(heartsProvider.notifier).useHeart();
      // Sayacı sıfırla
      await supabase.from('user_mistakes').update({
        'consecutive_correct_count': 0,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('question_id', question.id).eq('user_id', ref.read(currentUserProvider)!.id);
    } else {
      // Doğruysa sayacı artır veya sil
      final user = ref.read(currentUserProvider)!;
      final existingMistake = await supabase
          .from('user_mistakes')
          .select('id, consecutive_correct_count')
          .eq('user_id', user.id)
          .eq('question_id', question.id)
          .single();

      final count = (existingMistake['consecutive_correct_count'] as int) + 1;
      if (count >= 2) {
        await supabase.from('user_mistakes').delete().eq('id', existingMistake['id']);
      } else {
        await supabase.from('user_mistakes').update({
          'consecutive_correct_count': count,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existingMistake['id']);
      }
    }
  }

  void nextQuestion() {
    if (state.phase != SessionPhase.feedback) return;

    if (state.isLastQuestion) {
      // Bittiğinde Home'a dön (UI tarafında halledilecek veya burada state set edilecek)
      state = state.copyWith(phase: SessionPhase.submitting); // Mock bitti state'i
    } else {
      state = state.copyWith(
        phase: SessionPhase.question,
        currentIndex: state.currentIndex + 1,
        selectedOption: null,
        isCorrect: null,
      );
    }
  }

  void retry() => _loadMistakes();
}
