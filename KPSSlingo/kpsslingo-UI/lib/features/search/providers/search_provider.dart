import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';
import '../../home/data/models/lesson.dart';

final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<Lesson>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || query.length < 2) return [];
  
  final supabase = ref.watch(supabaseClientProvider);
  
  // Hem başlıkta hem de açıklamada ara
  final data = await supabase
      .from('lessons')
      .select()
      .or('title.ilike.%$query%,description.ilike.%$query%')
      .eq('status', 'published')
      .limit(20);
      
  return (data as List).map((e) => Lesson.fromJson(e)).toList();
});
