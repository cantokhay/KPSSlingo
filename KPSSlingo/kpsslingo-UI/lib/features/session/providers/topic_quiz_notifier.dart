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
import 'mistakes_provider.dart';

final topicQuizNotifierProvider = StateNotifierProvider.autoDispose
    .family<TopicQuizNotifier, SessionState, String>(
  (ref, topicId) => TopicQuizNotifier(
    topicId: topicId,
    supabase: Supabase.instance.client,
    ref: ref,
  ),
);

class TopicQuizNotifier extends StateNotifier<SessionState> {
  final String topicId;
  final SupabaseClient supabase;
  final Ref ref;

  DateTime? _questionStartTime;

  TopicQuizNotifier({
    required this.topicId,
    required this.supabase,
    required this.ref,
  }) : super(const SessionState()) {
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    state = state.copyWith(phase: SessionPhase.loading);
    try {
      // Kullanıcının seviyesine göre zorluk aralığı belirle
      final userProfile = ref.read(userProfileProvider).value;
      final level = userProfile?.targetExam;
      
      double minDiff = 0.0;
      double maxDiff = 10.0; // Varsayılan (Lisans)

      if (level == 'onlisans') {
        maxDiff = 7.0;
      } else if (level == 'ortaogretim') {
        maxDiff = 3.5;
      }

      // RPC'yi kullanarak rastgele 15 soru ID'si getir
      final response = await supabase.rpc('get_random_topic_question_ids', params: {
        'p_topic_id': topicId,
        'p_limit': 15,
        'p_min_diff': minDiff,
        'p_max_diff': maxDiff,
      });

      final List<dynamic> questionIds = response as List<dynamic>;
      final List<String> ids = questionIds.map((e) => e['id'] as String).toList();

      if (ids.isEmpty) {
        state = state.copyWith(
          phase: SessionPhase.error,
          errorMessage: 'Bu konu için yeterli soru bulunamadı.',
        );
        return;
      }

      // Detayları çek
      final data = await supabase
          .from('questions')
          .select('*, question_options(*), question_answers(correct_option)')
          .inFilter('id', ids);

      final questions = (data as List)
          .map((e) => QuestionWithOptions.fromJson(e as Map<String, dynamic>))
          .toList();
      
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

      updatedQuestions.shuffle();

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

    await _handleResult(question.id, option, isCorrect);
  }

  Future<void> _handleResult(String questionId, String selectedOption, bool isCorrect) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Anında veritabanına işle (Hata takibi ve yarıda bırakanlar için)
    try {
      await supabase.rpc('log_single_answer', params: {
        'p_question_id': questionId,
        'p_lesson_id': null, // Topic quiz'de lesson_id yok
        'p_selected_option': selectedOption,
        'p_is_correct': isCorrect,
        'p_time_spent_ms': state.timeSpentMs,
      });
    } catch (e) {
      // Sessiz hata
    }

    if (!isCorrect) {
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
        selectedOption: null,
        isCorrect: null,
        answers: updatedAnswers,
        timeSpentMs: 0,
      );
      _startQuestionTimer();
    }
  }

  Future<void> _submitSession(List<AnswerRecord> answers) async {
    final user = ref.read(currentUserProvider);
    state = state.copyWith(
      phase: SessionPhase.submitting,
      answers: answers,
    );

    try {

      final response = await supabase.functions.invoke(
        'complete-topic-quiz', // Yeni Edge Function
        body: {
          'topic_id': topicId,
          'answers': answers.map((a) => a.toJson()).toList(),
        },
      );

      if (response.status != 200) {
        throw Exception('Sunucu hatası: ${response.status}');
      }

      final result = CompleteLessonResult.fromJson(
        response.data as Map<String, dynamic>,
      );

      ref.invalidate(userProfileProvider);
      ref.invalidate(mistakesCountProvider);
      ref.invalidate(streakProvider);
      ref.invalidate(topicProgressProvider);
      ref.invalidate(completedLessonIdsProvider);
      
      Future.microtask(() {
        ref.invalidate(dailyQuestProvider);
        ref.invalidate(dailyXpProvider);
      });

      ref.read(topicQuizResultProvider.notifier).state = result;

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

final topicQuizResultProvider = StateProvider.autoDispose<CompleteLessonResult?>((ref) => null);
