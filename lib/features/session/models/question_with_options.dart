class QuestionOption {
  final String id;
  final String questionId;
  final String label;   // 'A', 'B', 'C', 'D', 'E'
  final String body;

  const QuestionOption({
    required this.id,
    required this.questionId,
    required this.label,
    required this.body,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) => QuestionOption(
    id: json['id'] as String,
    questionId: json['question_id'] as String,
    label: json['label'] as String,
    body: json['body'] as String,
  );
}

class QuestionWithOptions {
  final String id;
  final String lessonId;
  final String body;
  final String? explanation;
  final String correctOption;
  final List<QuestionOption> options;

  const QuestionWithOptions({
    required this.id,
    required this.lessonId,
    required this.body,
    this.explanation,
    required this.correctOption,
    required this.options,
  });

  factory QuestionWithOptions.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['question_options'] as List<dynamic>? ?? [];
    final options = rawOptions
        .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return QuestionWithOptions(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      body: json['body'] as String,
      explanation: json['explanation'] as String?,
      correctOption: json['correct_option'] as String,
      options: options,
    );
  }
}
