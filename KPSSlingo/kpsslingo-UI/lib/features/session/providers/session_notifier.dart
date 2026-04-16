import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_state.dart';
import '../models/question_with_options.dart';
import '../models/complete_lesson_result.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import '../../home/providers/home_providers.dart';

final sessionNotifierProvider = StateNotifierProvider.autoDispose
    .family<SessionNotifier, SessionState, String>(
  (ref, lessonId) => SessionNotifier(
    lessonId: lessonId,
    supabase: Supabase.instance.client,
    ref: ref,
  ),
);

class SessionNotifier extends StateNotifier<SessionState> {
  final String lessonId;
  final SupabaseClient supabase;
  final Ref ref;

  DateTime? _questionStartTime;

  SessionNotifier({
    required this.lessonId,
    required this.supabase,
    required this.ref,
  }) : super(const SessionState()) {
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    state = state.copyWith(phase: SessionPhase.loading);
    try {
      final data = await supabase
          .from('questions')
          .select('*, question_options(*)')
          .eq('lesson_id', lessonId)
          .eq('status', 'published')
          .order('created_at');

      final questions = (data as List)
          .map((e) => QuestionWithOptions.fromJson(e as Map<String, dynamic>))
          .toList();

      if (questions.isEmpty) {
        state = state.copyWith(
          phase: SessionPhase.error,
          errorMessage: 'Bu ders için henüz soru yok.',
        );
        return;
      }

      state = state.copyWith(
        phase: SessionPhase.question,
        questions: questions,
        currentIndex: 0,
      );
      _startQuestionTimer();
    } catch (e) {
      state = state.copyWith(
        phase: SessionPhase.error,
        errorMessage: 'Sorular yüklenemedi. Lütfen tekrar dene.',
      );
    }
  }

  void selectOption(String option) async {
    if (state.phase != SessionPhase.question) return;

    final question = state.currentQuestion!;
    final isCorrect = option == question.correctOption;
    final timeSpentMs = _stopQuestionTimer();

    state = state.copyWith(
      phase: SessionPhase.feedback,
      selectedOption: option,
      isCorrect: isCorrect,
      timeSpentMs: timeSpentMs,
    );

    // Can Düşürme & Hata Kaydı (Arka planda)
    _handleResult(question.id, option, isCorrect);
  }

  Future<void> _handleResult(String questionId, String selectedOption, bool isCorrect) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (!isCorrect) {
      // 1. Can düşür
      await ref.read(heartsProvider.notifier).useHeart();

      // 2. Hatayı kaydet/güncelle
      await supabase.from('user_mistakes').upsert({
        'user_id': user.id,
        'question_id': questionId,
        'last_wrong_answer': selectedOption,
        'consecutive_correct_count': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Doğruysa hata listesini kontrol et
      final existingMistake = await supabase
          .from('user_mistakes')
          .select('id, consecutive_correct_count')
          .eq('user_id', user.id)
          .eq('question_id', questionId)
          .maybeSingle();

      if (existingMistake != null) {
        final count = (existingMistake['consecutive_correct_count'] as int) + 1;
        if (count >= 2) {
          // 2 kere üst üste doğru yapıldı, hatayı sil
          await supabase.from('user_mistakes').delete().eq('id', existingMistake['id']);
        } else {
          // Sayacı artır
          await supabase.from('user_mistakes').update({
            'consecutive_correct_count': count,
          }).eq('id', existingMistake['id']);
        }
      }
    }
  }

  void nextQuestion() {
    if (state.phase != SessionPhase.feedback) return;

    final record = AnswerRecord(
      questionId: state.currentQuestion!.id,
      selectedOption: state.selectedOption!,
      isCorrect: state.isCorrect!,
      timeSpentMs: state.timeSpentMs,
    );

    final updatedAnswers = [...state.answers, record];

    if (state.isLastQuestion) {
      _submitSession(updatedAnswers);
    } else {
      state = state.copyWith(
        phase: SessionPhase.question,
        currentIndex: state.currentIndex + 1,
        selectedOption: null, // this will invoke our copyWith where null is ignored if we use ??, but we used Object? so it's clearing properly. 
        isCorrect: null,      // Same here
        answers: updatedAnswers,
        timeSpentMs: 0,
      );
      _startQuestionTimer();
    }
  }

  Future<void> _submitSession(List<AnswerRecord> answers) async {
    state = state.copyWith(
      phase: SessionPhase.submitting,
      answers: answers,
    );

    try {
      final response = await supabase.functions.invoke(
        'complete-lesson',
        body: {
          'lesson_id': lessonId,
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );

      if (response.status != 200) {
        throw Exception('Sunucu hatası: ${response.status}');
      }

      final result = CompleteLessonResult.fromJson(
        response.data as Map<String, dynamic>,
      );

      ref.invalidate(streakProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(nextLessonProvider);
      ref.invalidate(topicProgressProvider);

      ref.read(sessionResultProvider.notifier).state = result;

    } catch (e) {
      state = state.copyWith(
        phase: SessionPhase.error,
        errorMessage: 'Sonuç kaydedilemedi. Lütfen tekrar dene.',
      );
    }
  }

  void _startQuestionTimer() {
    _questionStartTime = DateTime.now();
  }

  int _stopQuestionTimer() {
    if (_questionStartTime == null) return 0;
    final elapsed = DateTime.now().difference(_questionStartTime!).inMilliseconds;
    _questionStartTime = null;
    return elapsed;
  }

  void retry() => _loadQuestions();
}

final sessionResultProvider = StateProvider.autoDispose<CompleteLessonResult?>((ref) => null);
