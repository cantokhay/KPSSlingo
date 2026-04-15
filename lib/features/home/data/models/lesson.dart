class Lesson {
  final String id;
  final String topicId;
  final String title;
  final int order;
  final String status;
  final int xpReward;

  const Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.order,
    required this.status,
    this.xpReward = 10,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        topicId: (json['topicId'] ?? json['topic_id']) as String,
        title: json['title'] as String,
        order: json['order'] as int,
        status: json['status'] as String,
        xpReward: json['xp_reward'] as int? ?? 10,
      );
}
