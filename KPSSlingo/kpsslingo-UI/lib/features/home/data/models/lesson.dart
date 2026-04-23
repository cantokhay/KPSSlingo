class Lesson {
  final String id;
  final String topicId;
  final String title;
  final int order;
  final String status;
  final int xpReward;
  final String? topicName;

  const Lesson({
    required this.id,
    required this.topicId,
    required this.title,
    required this.order,
    required this.status,
    this.xpReward = 10,
    this.topicName,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Supabase embed: topics objesi olarak gelebilir
    String? topicName;
    final topicsEmbed = json['topics'];
    if (topicsEmbed is Map<String, dynamic>) {
      topicName = topicsEmbed['title'] as String?;
    } else if (json['topic_name'] is String) {
      topicName = json['topic_name'] as String;
    }

    return Lesson(
      id: json['id'] as String,
      topicId: (json['topicId'] ?? json['topic_id']) as String,
      title: json['title'] as String,
      order: json['order'] as int,
      status: json['status'] as String,
      xpReward: json['xp_reward'] as int? ?? 10,
      topicName: topicName,
    );
  }
}
