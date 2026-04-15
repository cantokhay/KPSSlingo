import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/streak.dart';
import '../../auth/data/models/user_profile.dart';
import '../data/models/topic.dart';
import '../data/models/lesson.dart';
import 'home_providers.dart';

class HomeData {
  final Streak? streak;
  final UserProfile? profile;
  final List<Topic> topics;
  final Lesson? nextLesson;

  const HomeData({
    required this.streak,
    required this.profile,
    required this.topics,
    required this.nextLesson,
  });
}

final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final results = await Future.wait([
    ref.watch(streakProvider.future),
    ref.watch(userProfileProvider.future),
    ref.watch(topicsProvider.future),
    ref.watch(nextLessonProvider.future),
  ]);

  return HomeData(
    streak: results[0] as Streak?,
    profile: results[1] as UserProfile?,
    topics: results[2] as List<Topic>,
    nextLesson: results[3] as Lesson?,
  );
});
