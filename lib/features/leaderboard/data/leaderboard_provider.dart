import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';

// Leaderboard entry model
class LeaderboardEntry {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int totalXp;
  final int currentLevel;
  final int rank;

  const LeaderboardEntry({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.totalXp,
    required this.currentLevel,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, int rank) =>
      LeaderboardEntry(
        id:           json['id'] as String,
        username:     json['username'] as String,
        fullName:     json['full_name'] as String?,
        avatarUrl:    json['avatar_url'] as String?,
        totalXp:      (json['total_xp'] as num).toInt(),
        currentLevel: (json['current_level'] as num).toInt(),
        rank:         rank,
      );
}

// Gerçek zamanlı XP sıralaması — top 50
final leaderboardProvider =
    FutureProvider.autoDispose<List<LeaderboardEntry>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final data = await supabase
      .from('user_profiles')
      .select('id, username, full_name, avatar_url, total_xp, current_level')
      .order('total_xp', ascending: false)
      .limit(50);

  return (data as List)
      .asMap()
      .entries
      .map((e) => LeaderboardEntry.fromJson(
            e.value as Map<String, dynamic>,
            e.key + 1,
          ))
      .toList();
});
