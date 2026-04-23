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
    final optionsList = rawOptions
        .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
        .toList();
    
    // Şık metni aynı olan mükerrer kayıtları temizle
    final seenBodies = <String>{};
    final uniqueOptions = <QuestionOption>[];
    for (var opt in optionsList) {
      final cleanBody = opt.body.trim();
      if (seenBodies.add(cleanBody)) {
        uniqueOptions.add(opt);
      }
    }
    
    final options = uniqueOptions..sort((a, b) => a.label.compareTo(b.label));

    // Handle correct_option from questions table OR joined question_answers table
    String? correctOpt;
    if (json['correct_option'] != null) {
      correctOpt = json['correct_option'] as String;
    } else if (json['question_answers'] != null) {
      // If joined as single
      if (json['question_answers'] is Map) {
        correctOpt = json['question_answers']['correct_option'] as String?;
      } 
      // If joined as list (sometimes happens in PostgREST)
      else if (json['question_answers'] is List && (json['question_answers'] as List).isNotEmpty) {
        correctOpt = json['question_answers'][0]['correct_option'] as String?;
      }
    }

    return QuestionWithOptions(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      body: json['body'] as String,
      explanation: json['explanation'] as String?,
      correctOption: correctOpt ?? 'A', // Fallback to 'A' if still null
      options: options,
    );
  }

  QuestionWithOptions copyWith({
    String? id,
    String? lessonId,
    String? body,
    String? explanation,
    String? correctOption,
    List<QuestionOption>? options,
  }) {
    return QuestionWithOptions(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      body: body ?? this.body,
      explanation: explanation ?? this.explanation,
      correctOption: correctOption ?? this.correctOption,
      options: options ?? this.options,
    );
  }
}
