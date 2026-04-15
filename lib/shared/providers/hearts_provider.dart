import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/features/auth/providers/auth_provider.dart';
import 'package:kpsslingo/features/home/providers/home_providers.dart';
import '../providers/supabase_provider.dart';

const int kMaxHearts = 10;
const int kRegenIntervalMinutes = 15;
const int kRefillXpCost = 500;

class HeartsState {
  final int hearts;
  final DateTime lastRegen;
  final Duration timeUntilNext;

  HeartsState({
    required this.hearts,
    required this.lastRegen,
    required this.timeUntilNext,
  });

  HeartsState copyWith({
    int? hearts,
    DateTime? lastRegen,
    Duration? timeUntilNext,
  }) {
    return HeartsState(
      hearts: hearts ?? this.hearts,
      lastRegen: lastRegen ?? this.lastRegen,
      timeUntilNext: timeUntilNext ?? this.timeUntilNext,
    );
  }
}

class HeartsNotifier extends StateNotifier<HeartsState?> {
  final Ref ref;
  Timer? _timer;

  HeartsNotifier(this.ref) : super(null) {
    _init();
  }

  void _init() {
    ref.listen(userProfileProvider, (previous, next) {
      if (next is AsyncValue && next.hasValue && next.value != null) {
        final profile = next.value!;
        _updateState(profile.hearts, profile.lastHeartRegen);
        _startTimer();
      }
    });
  }

  void _updateState(int hearts, DateTime lastRegen) {
    final now = DateTime.now();
    final diff = now.difference(lastRegen);
    
    int newHearts = hearts;
    DateTime newLastRegen = lastRegen;
    
    if (newHearts < kMaxHearts) {
      final additionalHearts = diff.inMinutes ~/ kRegenIntervalMinutes;
      if (additionalHearts > 0) {
        newHearts = (newHearts + additionalHearts).clamp(0, kMaxHearts);
        newLastRegen = lastRegen.add(Duration(minutes: additionalHearts * kRegenIntervalMinutes));
        
        if (newHearts == kMaxHearts) {
          newLastRegen = now;
        }
        
        // Veritabanını güncelle
        _syncToDb(newHearts, newLastRegen);
      }
    }

    Duration timeUntilNext = Duration.zero;
    if (newHearts < kMaxHearts) {
      final nextRegen = newLastRegen.add(const Duration(minutes: kRegenIntervalMinutes));
      timeUntilNext = nextRegen.difference(now);
    }

    state = HeartsState(
      hearts: newHearts,
      lastRegen: newLastRegen,
      timeUntilNext: timeUntilNext,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state != null && state!.hearts < kMaxHearts) {
        _updateState(state!.hearts, state!.lastRegen);
      }
    });
  }

  Future<void> useHeart() async {
    if (state == null || state!.hearts <= 0) return;

    final newHearts = state!.hearts - 1;
    final newRegen = state!.hearts == kMaxHearts ? DateTime.now() : state!.lastRegen;

    state = state!.copyWith(hearts: newHearts, lastRegen: newRegen);
    await _syncToDb(newHearts, newRegen);
  }

  Future<void> refillWithXp() async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null || profile.totalXp < kRefillXpCost) return;

    // XP düş
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('user_profiles').update({
      'total_xp': profile.totalXp - kRefillXpCost,
      'hearts': kMaxHearts,
      'last_heart_regen': DateTime.now().toIso8601String(),
    }).eq('id', profile.id);

    // Profile provider'ı tetikle
    ref.invalidate(userProfileProvider);
  }

  Future<void> refillWithAd() async {
    // Mock Reklam Simülasyonu
    await Future.delayed(const Duration(seconds: 2));
    
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('user_profiles').update({
      'hearts': kMaxHearts,
      'last_heart_regen': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    ref.invalidate(userProfileProvider);
  }

  Future<void> _syncToDb(int hearts, DateTime lastRegen) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('user_profiles').update({
      'hearts': hearts,
      'last_heart_regen': lastRegen.toIso8601String(),
    }).eq('id', user.id);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final heartsProvider = StateNotifierProvider<HeartsNotifier, HeartsState?>((ref) {
  return HeartsNotifier(ref);
});
