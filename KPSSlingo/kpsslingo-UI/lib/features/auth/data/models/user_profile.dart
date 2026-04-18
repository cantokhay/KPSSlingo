class UserProfile {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int totalXp;
  final int currentLevel;
  final int hearts;
  final DateTime lastHeartRegen;
  final bool onboardingComplete;
  final String? targetExam;
  final DateTime? kpssExamDate;

  const UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.totalXp,
    required this.currentLevel,
    required this.hearts,
    required this.lastHeartRegen,
    this.onboardingComplete = false,
    this.targetExam,
    this.kpssExamDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        username: json['username'] as String,
        fullName: json['fullName'] ?? json['full_name'] as String?,
        avatarUrl: json['avatarUrl'] ?? json['avatar_url'] as String?,
        totalXp: json['totalXp'] ?? json['total_xp'] as int? ?? 0,
        currentLevel: json['currentLevel'] ?? json['current_level'] as int? ?? 1,
        hearts: json['hearts'] as int? ?? 10,
        lastHeartRegen: DateTime.parse(json['last_heart_regen'] as String? ?? DateTime.now().toIso8601String()),
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
        targetExam: json['target_exam'] as String?,
        kpssExamDate: json['kpss_exam_date'] != null ? DateTime.parse(json['kpss_exam_date'] as String) : null,
      );
}
