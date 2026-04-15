class Streak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActivityDate;

  const Streak({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActivityDate,
  });

  factory Streak.fromJson(Map<String, dynamic> json) => Streak(
        id: json['id'] as String,
        userId: json['userId'] ?? json['user_id'] as String,
        currentStreak: json['currentStreak'] ?? json['current_streak'] as int,
        longestStreak: json['longestStreak'] ?? json['longest_streak'] as int,
        lastActivityDate: json['lastActivityDate'] != null || json['last_activity_date'] != null
            ? DateTime.parse(json['lastActivityDate'] ?? json['last_activity_date'])
            : null,
      );
}
