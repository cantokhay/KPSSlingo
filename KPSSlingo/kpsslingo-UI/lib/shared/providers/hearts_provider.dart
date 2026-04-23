import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/features/auth/providers/auth_provider.dart';
import 'package:kpsslingo/features/home/providers/home_providers.dart';
import '../providers/supabase_provider.dart';

const int kMaxHearts = 15;
const int kRegenIntervalSeconds = 30;
const int kRefillXpCost = 5;

class HeartsState {
  final int hearts;
  final DateTime lastRegen;
  final Duration timeUntilNext;
  final Duration serverTimeOffset;

  HeartsState({
    required this.hearts,
    required this.lastRegen,
    required this.timeUntilNext,
    this.serverTimeOffset = Duration.zero,
  });

  HeartsState copyWith({
    int? hearts,
    DateTime? lastRegen,
    Duration? timeUntilNext,
    Duration? serverTimeOffset,
  }) {
    return HeartsState(
      hearts: hearts ?? this.hearts,
      lastRegen: lastRegen ?? this.lastRegen,
      timeUntilNext: timeUntilNext ?? this.timeUntilNext,
      serverTimeOffset: serverTimeOffset ?? this.serverTimeOffset,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeartsState &&
          runtimeType == other.runtimeType &&
          hearts == other.hearts &&
          lastRegen == other.lastRegen &&
          timeUntilNext.inSeconds == other.timeUntilNext.inSeconds &&
          serverTimeOffset == other.serverTimeOffset;

  @override
  int get hashCode => 
      hearts.hashCode ^ 
      lastRegen.hashCode ^ 
      timeUntilNext.inSeconds.hashCode ^ 
      serverTimeOffset.hashCode;
}

class HeartsNotifier extends Notifier<HeartsState?> {
  Timer? _timer;

  @override
  HeartsState? build() {
    final profileAsync = ref.watch(userProfileProvider);
    
    ref.onDispose(() => _timer?.cancel());

    final profile = profileAsync.value;
    if (profile == null) return null;

    final offset = ref.read(serverTimeOffsetProvider);
    final newState = _calculateLocalState(profile.hearts, profile.lastHeartRegen, offset);

    if (newState.hearts < kMaxHearts) {
      _startTimer();
    } else {
      _timer?.cancel();
    }

    return newState;
  }

  HeartsState _calculateLocalState(int hearts, DateTime lastRegen, Duration offset) {
    final now = DateTime.now().toUtc().add(offset);
    final lastRegenUtc = lastRegen.toUtc();
    final diff = now.difference(lastRegenUtc);
    
    int currentHearts = hearts;
    DateTime currentLastRegen = lastRegenUtc;

    if (currentHearts < kMaxHearts) {
      final additionalHearts = diff.inSeconds ~/ kRegenIntervalSeconds;
      if (additionalHearts > 0) {
        currentHearts = (currentHearts + additionalHearts).clamp(0, kMaxHearts);
        currentLastRegen = lastRegenUtc.add(Duration(seconds: additionalHearts * kRegenIntervalSeconds));
      }
    }

    final timeUntilNext = currentHearts < kMaxHearts 
        ? Duration(seconds: kRegenIntervalSeconds - (diff.inSeconds % kRegenIntervalSeconds))
        : Duration.zero;

    return HeartsState(
      hearts: currentHearts,
      lastRegen: currentLastRegen,
      timeUntilNext: timeUntilNext,
      serverTimeOffset: offset,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state != null) {
        final offset = ref.read(serverTimeOffsetProvider);
        final newState = _calculateLocalState(state!.hearts, state!.lastRegen, offset);
        
        if (newState != state) {
          state = newState;
        }

        if (newState.hearts >= kMaxHearts) {
          timer.cancel();
        }
      }
    });
  }

  Future<void> useHeart() async {
    if (state == null || state!.hearts <= 0) return;

    final supabase = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Sunucu tarafında atomik düşür
    final response = await supabase.rpc('secure_decrement_heart', params: {
      'p_user_id': user.id,
    });

    if (response != null && (response as List).isNotEmpty) {
      final data = response[0];
      final newHearts = data['current_hearts'] as int;
      final newRegen = DateTime.parse(data['last_regen'] as String);
      
      state = state!.copyWith(hearts: newHearts, lastRegen: newRegen);
    }
    
    // Profili tazele ki UI güncel kalsın
    ref.invalidate(userProfileProvider);
  }

  Future<bool> refillWithXp() async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return false;
    
    if (state != null && state!.hearts >= kMaxHearts) return false;
    if (profile.totalXp < kRefillXpCost) return false;

    final supabase = ref.read(supabaseClientProvider);
    final response = await supabase.rpc('refill_hearts_with_xp_v2', params: {
      'p_user_id': profile.id,
      'p_xp_cost': kRefillXpCost,
      'p_max_hearts': kMaxHearts,
    });

    final success = response['success'] as bool? ?? false;
    
    if (success) {
      ref.invalidate(userProfileProvider);
      return true;
    }
    return false;
  }

  Future<void> refillWithAd() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final supabase = ref.read(supabaseClientProvider);
    // Ad refill için de bir RPC oluşturulabilir ama şimdilik doğrudan kısıtlı alana izin vermeyeceğimiz için
    // burayı da sync_user_hearts benzeri bir mantığa çekmeliyiz. 
    // Şimdilik sadece invalidate ederek sunucudan (sync-user-state) gelmesini bekleyebiliriz 
    // veya basit bir RPC ekleyebiliriz.
    
    // Güvenlik için RPC kullanıyoruz:
    await supabase.rpc('sync_user_hearts', params: { 'p_user_id': user.id });

    ref.invalidate(userProfileProvider);
  }
}

final serverTimeOffsetProvider = StateProvider<Duration>((ref) => Duration.zero);

final heartsProvider = NotifierProvider<HeartsNotifier, HeartsState?>(() {
  return HeartsNotifier();
});

