import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';

final profileStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return {};
  final supabase = ref.watch(supabaseClientProvider);

  // 1. Toplam XP ve Seviye
  final profileData = await supabase
      .from('user_profiles')
      .select('xp, level, kpss_exam_date')
      .eq('id', user.id)
      .single();

  // 2. Tamamlanan Ders Sayısı
  final completedResponse = await supabase
      .from('user_progress')
      .select('id')
      .eq('user_id', user.id)
      .eq('status', 'completed');
  final completedCountValue = (completedResponse as List).length;

  // 3. Mevcut Seri (Streak)
  final streakData = await supabase
      .from('streaks')
      .select('current_streak')
      .eq('user_id', user.id)
      .maybeSingle();

  return {
    'xp': profileData['xp'] ?? 0,
    'level': profileData['level'] ?? 1,
    'exam_date': profileData['kpss_exam_date'],
    'completed_lessons': completedCountValue,
    'streak': streakData != null ? streakData['current_streak'] : 0,
  };
});
