import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/models/user_profile.dart';
import '../data/models/lesson.dart';
import '../data/models/topic.dart';
import '../data/models/streak.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';
import 'package:kpsslingo/core/local/isar_service.dart';
import 'package:kpsslingo/core/local/isar_schemas.dart';

// 1. Streak
final streakProvider = FutureProvider.autoDispose<Streak?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseClientProvider);
  final data = await supabase
      .from('streaks')
      .select()
      .eq('user_id', user.id)
      .maybeSingle();
  return data != null ? Streak.fromJson(data) : null;
});

// 2. User Profile (XP, level + HEART SYNC)
final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseClientProvider);

  try {
    // 2. ADIMDA YAPTIĞIMIZ SYNC FONKSİYONUNU ÇAĞIRAN MANTIK
    // Not: Bu rpc değil, Edge Function çağrısıdır.
    final response = await supabase.functions.invoke('sync-user-state');
    
    if (response.data != null) {
      return UserProfile.fromJson(response.data['profile']);
    }
  } catch (e) {
    // İnternet yoksa eski usul çek (veya Isar'dan al)
    print('Sync error, falling back: $e');
  }

  final data = await supabase
      .from('user_profiles')
      .select('id, username, full_name, avatar_url, total_xp, current_level, onboarding_complete, hearts, last_heart_regen, target_exam')
      .eq('id', user.id)
      .single();
  return UserProfile.fromJson(data);
});

// 3. Konu Listesi (OFFLINE SUPPORT)
final topicsProvider = FutureProvider.autoDispose<List<Topic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final isarService = IsarService.instance;

  try {
    final data = await supabase
        .from('topics')
        .select()
        .eq('status', 'active')
        .order('order');
    
    final topics = (data as List).map((e) => Topic.fromJson(e)).toList();

    // Isar'a kaydet (cache all)
    final cached = topics.map((t) => CachedTopic()
      ..uuid = t.id
      ..slug = t.slug
      ..title = t.title
      ..description = t.description
      ..iconUrl = t.iconUrl
      ..order = t.order
    ).toList();
    await isarService.saveTopics(cached);

    return topics;
  } catch (e) {
    print('Home topics fetch error, using cache: $e');
    // Offline ise Isar'dan dön
    final cached = await isarService.getAllTopics();
    return cached.map((c) => Topic(
      id: c.uuid,
      slug: c.slug,
      title: c.title,
      description: c.description,
      iconUrl: c.iconUrl,
      order: c.order,
    )).toList();
  }
});

// 4. Belirli Konunun Dersleri (lazy)
final lessonsForTopicProvider = FutureProvider.autoDispose
    .family<List<Lesson>, String>((ref, topicId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final data = await supabase
      .from('lessons')
      .select()
      .eq('topic_id', topicId)
      .eq('status', 'published')
      .order('order');
  return (data as List).map((e) => Lesson.fromJson(e)).toList();
});

// 5. Sonraki Ders
final nextLessonProvider = FutureProvider.autoDispose<Lesson?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = ref.watch(supabaseClientProvider);

  final completed = await supabase
      .from('user_progress')
      .select('lesson_id')
      .eq('user_id', user.id)
      .eq('status', 'completed');

  final completedIds = (completed as List).map((e) => e['lesson_id'] as String).toList();

  final allLessons = await supabase
      .from('lessons')
      .select('*, questions(count)')
      .eq('status', 'published')
      .eq('questions.status', 'published')
      .order('order');

  final nextLessons = (allLessons as List)
      .where((l) {
        final quesCount = (l['questions'] as List).isNotEmpty ? l['questions'][0]['count'] as int : 0;
        return !completedIds.contains(l['id']) && quesCount > 0;
      })
      .toList();

  if (nextLessons.isEmpty) return null;
  return Lesson.fromJson(nextLessons.first);
});

// 6. Konu İlerleme Yüzdesi
final topicProgressProvider = FutureProvider.autoDispose
    .family<double, String>((ref, topicId) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0.0;
  final supabase = ref.watch(supabaseClientProvider);

  final total = await supabase
      .from('lessons')
      .select('id')
      .eq('topic_id', topicId)
      .eq('status', 'published');

  final totalCount = (total as List).length;
  if (totalCount == 0) return 0.0;

  final lessonIds = total.map((e) => e['id'] as String).toList();

  final completed = await supabase
      .from('user_progress')
      .select('lesson_id')
      .eq('user_id', user.id)
      .eq('status', 'completed');

  final completedCount = (completed as List)
      .map((e) => e['lesson_id'] as String)
      .where((id) => lessonIds.contains(id))
      .length;

  return completedCount / totalCount;
});

// 7. Günlük Görev (3 Farklı Ders Tamamla/Tekrarla)
final dailyQuestProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final supabase = ref.watch(supabaseClientProvider);

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  // Bugün soru çözülen benzersiz derslerin sayısını al
  final response = await supabase
      .from('user_question_answers')
      .select('lesson_id')
      .eq('user_id', user.id)
      .gte('answered_at', startOfDay.toIso8601String());

  final lessonIds = (response as List).map((e) => e['lesson_id'] as String).toSet();
  return lessonIds.length;
});

// 8. Günlük XP (Bugün Kazanılan)
final dailyXpProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  final supabase = ref.watch(supabaseClientProvider);

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);

  // Bugün tamamlanan derslerden gelen XP'leri topla
  // Basitlik için her ders 10 XP diyelim (xp_reward veritabanında var ama 
  // her soru çözümü için de puan verilebilir).
  // Mevcut yapıda user_question_answers sayısına göre hesaplayalım.
  final response = await supabase
      .from('user_question_answers')
      .select('id')
      .eq('user_id', user.id)
      .eq('is_correct', true)
      .gte('answered_at', startOfDay.toIso8601String());

  // Her doğru cevap 2 XP
  return (response as List).length * 2;
});

// 8. Tamamlanan Ders ID'leri (Checkmark için)
final completedLessonIdsProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final supabase = ref.watch(supabaseClientProvider);

  final data = await supabase
      .from('user_progress')
      .select('lesson_id')
      .eq('user_id', user.id)
      .eq('status', 'completed');

  return (data as List).map((e) => e['lesson_id'] as String).toList();
});
