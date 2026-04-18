import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kpsslingo/shared/providers/supabase_provider.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error, verificationPending }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(supabaseClientProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;

  AuthNotifier(this._supabase) : super(const AuthState());

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null && response.session == null) {
        state = state.copyWith(status: AuthStatus.verificationPending, errorMessage: 'Lütfen e-posta adresinizi doğrulayın.');
      } else if (response.user != null && response.user!.emailConfirmedAt == null) {
        // Bazı konfigürasyonlarda session dönebilir ama hala doğrulanmamış olabilir
        state = state.copyWith(status: AuthStatus.verificationPending, errorMessage: 'E-posta adresiniz henüz doğrulanmamış.');
      } else {
        state = state.copyWith(status: AuthStatus.authenticated);
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('email not confirmed')) {
        state = state.copyWith(status: AuthStatus.verificationPending, errorMessage: 'Lütfen e-posta adresinizi doğrulayın.');
      } else {
        state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
      }
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Beklenmedik bir hata oluştu');
    }
  }

  Future<void> signUp(String email, String password, String username, String targetExam) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'target_exam': targetExam,
        },
      );
      
      // If email confirmation is enabled, session will be null but user will be present
      if (response.session == null && response.user != null) {
        state = state.copyWith(status: AuthStatus.verificationPending);
      } else {
        state = state.copyWith(status: AuthStatus.authenticated);
      }
    } on AuthException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Kayıt sırasında bir hata oluştu');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> completeOnboarding(DateTime examDate) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    await _supabase
        .from('user_profiles')
        .update({
          'onboarding_complete': true,
          'kpss_exam_date': examDate.toIso8601String(),
        })
        .eq('id', userId);
  }

  Future<void> updateTargetExam(String targetExam) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    await _supabase
        .from('user_profiles')
        .update({'target_exam': targetExam})
        .eq('id', userId);
  }

  Future<void> updateExamDate(DateTime examDate) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    await _supabase
        .from('user_profiles')
        .update({'kpss_exam_date': examDate.toIso8601String()})
        .eq('id', userId);
  }
}
