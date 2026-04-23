import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/session_state.dart';
import '../models/question_with_options.dart';
import '../models/complete_lesson_result.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import '../../home/providers/home_providers.dart';
import '../../home/providers/home_data_provider.dart';

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
      // Kullanıcının seviyesine göre zorluk filtresi uygula
      final userProfile = ref.read(userProfileProvider).value;
      final level = userProfile?.targetExam;
      
      var query = supabase
          .from('questions')
          .select('*, question_options(*)')
          .eq('lesson_id', lessonId)
          .eq('status', 'published');

      if (level == 'onlisans') {
        query = query.lte('difficulty_score', 7.0);
      } else if (level == 'ortaogretim') {
        query = query.lte('difficulty_score', 3.5);
      }

      final data = await query.order('created_at');

      final List<QuestionWithOptions> allQuestions = (data as List)
          .map((e) => QuestionWithOptions.fromJson(e as Map<String, dynamic>))
          .toList();

      if (allQuestions.isEmpty) {
        state = state.copyWith(
          phase: SessionPhase.error,
          errorMessage: 'Bu ders için henüz soru yok.',
        );
        return;
      }

      // Maksimum 15 soru göster (Karıştırarak seç)
      allQuestions.shuffle();
      final questions = allQuestions.take(15).toList();

      // GÜVENLİK: Cevapları seans başladığında ayrı bir RPC ile çek
      final questionIds = questions.map((q) => q.id).toList();
      final answersData = await supabase.rpc('get_session_answers', params: {
        'p_question_ids': questionIds,
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

    // Can Düşürme (Hata kaydı artık DB tetikleyicisi tarafından yapılıyor)
    await _handleResult(question.id, option, isCorrect);
  }

  Future<void> _handleResult(String questionId, String selectedOption, bool isCorrect) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Anında veritabanına işle (Hata takibi ve yarıda bırakanlar için)
    try {
      await supabase.rpc('log_single_answer', params: {
        'p_question_id': questionId,
        'p_lesson_id': lessonId,
        'p_selected_option': selectedOption,
        'p_is_correct': isCorrect,
        'p_time_spent_ms': state.timeSpentMs,
      });
    } catch (e) {
      // Sessiz hata (internet kesintisi vs)
    }

    if (!isCorrect) {
      // Can düşür
      await ref.read(heartsProvider.notifier).useHeart();
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

      // Agresif invalidasyonları grupla veya debouncela
      // Burada sadece en kritik olanları tetikliyoruz, geri kalanı ana ekran (Home) 
      // aktif olduğunda (watch sayesinde) güncellenecek.
      ref.invalidate(userProfileProvider);
      ref.invalidate(streakProvider);
      
      // Delay ile diğerlerini arka planda tazele
      Future.microtask(() {
        ref.invalidate(nextLessonProvider);
        ref.invalidate(topicProgressProvider);
        ref.invalidate(dailyQuestProvider);
        ref.invalidate(dailyXpProvider);
      });

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
