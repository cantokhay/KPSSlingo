import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/data/models/user_profile.dart';
import '../data/models/lesson.dart';
import '../data/models/topic.dart';
import '../data/models/streak.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
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
    final response = await supabase.functions.invoke('sync-user-state');
    
    if (response.data != null && response.data['profile'] != null) {
      // Server zamanı ile farkı hesapla
      if (response.data['server_time'] != null) {
        final serverTime = DateTime.parse(response.data['server_time'] as String);
        final now = DateTime.now().toUtc();
        final offset = serverTime.difference(now);
        
        // Offset'i sessizce güncelle
        Future.microtask(() {
          ref.read(serverTimeOffsetProvider.notifier).state = offset;
        });
      }

      return UserProfile.fromJson(response.data['profile']);
    }
  } catch (e) {
    // Edge function failed, fallback to direct DB fetch
  }

  final data = await supabase
      .from('user_profiles')
      .select('*')
      .eq('id', user.id)
      .maybeSingle();

  if (data == null) {
    // Profil hala yoksa (trigger yetişmemiş olabilir), bir kez daha sync denenebilir veya null dönebilir.
    // Şimdilik null dönüyoruz, UI bunu ele almalı.
    return null;
  }
  return UserProfile.fromJson(data);
});


// 3. Konu Listesi (OFFLINE SUPPORT)
final topicsProvider = FutureProvider.autoDispose<List<Topic>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final isarService = IsarService.instance;

  try {
    final data = await supabase
        .from('topics')
        .select('*')
        .eq('status', 'active')
        .order('order');
    
    final topics = (data as List).map((e) => Topic.fromJson(e)).toList();

    // Explicitly sort just in case
    topics.sort((a, b) => a.order.compareTo(b.order));

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
      .select('*')
      .eq('topic_id', topicId)
      .eq('status', 'published')
      .order('order');
  return (data as List).map((e) => Lesson.fromJson(e)).toList();
});

// 5. Sonraki Ders
final nextLessonProvider = FutureProvider.autoDispose<Lesson?>((ref) async {
  try {
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

    if (nextLessons.isEmpty) {
      return null;
    }
    return Lesson.fromJson(nextLessons.first);
  } catch (e, stack) {
    return null;
  }
});

// 6. Konu İlerleme Yüzdesi
final topicProgressProvider = FutureProvider.autoDispose
    .family<double, String>((ref, topicId) async {
  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) return 0.0;
    final supabase = ref.watch(supabaseClientProvider);

    // 1. Konudaki toplam yayınlanmış soru sayısını al
    final totalQuestionsResponse = await supabase
        .from('questions')
        .select('id, lessons!inner(topic_id)')
        .eq('status', 'published')
        .eq('lessons.topic_id', topicId);

    final totalQuestions = (totalQuestionsResponse as List).length;

    if (totalQuestions == 0) return 0.0;

    final answeredResponse = await supabase
        .from('user_question_answers')
        .select('question_id, lessons!inner(topic_id)')
        .eq('user_id', user.id)
        .eq('is_correct', true)
        .eq('lessons.topic_id', topicId);

    final answeredQuestions = (answeredResponse as List).length;
    final progress = (answeredQuestions / totalQuestions).clamp(0.0, 1.0);

    return progress;
  } catch (e, stack) {
    return 0.0;
  }
});

// 7. Günlük Görev (3 Farklı Test Tamamla/Tekrarla)
final dailyQuestProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) return 0;
    final supabase = ref.watch(supabaseClientProvider);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toUtc();

    // Bugün tamamlanan testleri (ders, konu testi, hata tekrarı) say
    final response = await supabase
        .from('xp_transactions')
        .select('id')
        .eq('user_id', user.id)
        .inFilter('reason', ['lesson_completion', 'topic_quiz', 'mistake_review'])
        .gte('created_at', startOfDay.toIso8601String());

    return (response as List).length;
  } catch (e) {
    return 0;
  }
});

// 8. Günlük XP (Bugün Kazanılan - İşlem Geçmişinden)
final dailyXpProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    final user = ref.watch(currentUserProvider);
    if (user == null) return 0;
    final supabase = ref.watch(supabaseClientProvider);

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toUtc();

    // Bugün kazanılan tüm pozitif XP kalemlerini topla
    final response = await supabase
        .from('xp_transactions')
        .select('amount')
        .eq('user_id', user.id)
        .gt('amount', 0)
        .gte('created_at', startOfDay.toIso8601String());

    final total = (response as List).fold<int>(0, (sum, item) {
      return sum + (item['amount'] as int);
    });

    return total;
  } catch (e) {
    return 0;
  }
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
