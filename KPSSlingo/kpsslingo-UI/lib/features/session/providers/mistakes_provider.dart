import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';

final mistakesCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase
      .from('user_mistakes')
      .select('id')
      .eq('user_id', user.id);
      
  return (response as List).length;
});
