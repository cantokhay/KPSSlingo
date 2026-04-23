import 'question_with_options.dart';

enum SessionPhase {
  loading,
  question,
  feedback,
  submitting,
  summary,
  error,
}

class SessionState {
  final SessionPhase phase;
  final List<QuestionWithOptions> questions;
  final int currentIndex;
  final String? selectedOption;
  final bool? isCorrect;
  final List<AnswerRecord> answers;
  final int timeSpentMs;
  final String? errorMessage;

  const SessionState({
    this.phase = SessionPhase.loading,
    this.questions = const [],
    this.currentIndex = 0,
    this.selectedOption,
    this.isCorrect,
    this.answers = const [],
    this.timeSpentMs = 0,
    this.errorMessage,
  });

  QuestionWithOptions? get currentQuestion =>
      questions.isEmpty ? null : questions[currentIndex];

  bool get isLastQuestion => currentIndex == questions.length - 1;

  int get totalQuestions => questions.length;

  double get progressFraction =>
      questions.isEmpty ? 0 : (currentIndex + 1) / questions.length;

  SessionState copyWith({
    SessionPhase? phase,
    List<QuestionWithOptions>? questions,
    int? currentIndex,
    Object? selectedOption = const Object(),
    Object? isCorrect = const Object(),
    List<AnswerRecord>? answers,
    int? timeSpentMs,
    String? errorMessage,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedOption: selectedOption == const Object() 
          ? this.selectedOption 
          : selectedOption as String?,
      isCorrect: isCorrect == const Object() 
          ? this.isCorrect 
          : isCorrect as bool?,
      answers: answers ?? this.answers,
      timeSpentMs: timeSpentMs ?? this.timeSpentMs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AnswerRecord {
  final String questionId;
  final String selectedOption;
  final bool isCorrect;
  final int timeSpentMs;

  const AnswerRecord({
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.timeSpentMs,
  });

  Map<String, dynamic> toJson() => {
    'question_id': questionId,
    'selected_option': selectedOption,
    'is_correct': isCorrect,
    'time_spent_ms': timeSpentMs,
  };
}
