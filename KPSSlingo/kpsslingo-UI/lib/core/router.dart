import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kpsslingo/features/auth/presentation/screens/login_screen.dart';
import 'package:kpsslingo/features/auth/presentation/screens/register_screen.dart';
import 'package:kpsslingo/features/home/presentation/home_screen.dart';
import 'package:kpsslingo/features/session/presentation/session_screen.dart';
import 'package:kpsslingo/features/result/presentation/result_screen.dart';
import 'package:kpsslingo/features/profile/presentation/screens/profile_screen.dart';
import 'package:kpsslingo/features/leaderboard/presentation/leaderboard_screen.dart';
import 'package:kpsslingo/features/level_up/presentation/level_up_screen.dart';
import 'package:kpsslingo/features/search/presentation/search_screen.dart';
import 'package:kpsslingo/features/onboarding/presentation/onboarding_screen.dart';
import 'package:kpsslingo/features/home/providers/home_providers.dart';
import 'package:kpsslingo/features/auth/providers/auth_provider.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/features/session/models/complete_lesson_result.dart';
import 'package:kpsslingo/features/session/presentation/mistake_review_screen.dart';
import 'package:kpsslingo/features/session/presentation/topic_quiz_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  // NOT watching full userProfileProvider here to prevent full router rebuilds on XP/Heart changes.
  // Instead, we only watch the `onboardingComplete` state so the router re-evaluates when profile loads.
  final onboardingComplete = ref.watch(userProfileProvider.select((profile) => profile.valueOrNull?.onboardingComplete));

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/home';

      // Onboarding Kontrolü
      if (isLoggedIn && (state.matchedLocation == '/home' || state.matchedLocation == '/')) {
        if (onboardingComplete == false) {
          return '/onboarding';
        }
      }

      // Authenticated kullanıcı için izin verilen rotalar dışına çıkmayı engelle
      if (isLoggedIn) {
        const allowedPrefixes = [
          '/home',
          '/search',
          '/leaderboard',
          '/profile',
          '/lesson/',
          '/result',
          '/topic-quiz/',
          '/mistake-review',
          '/level-up',
          '/onboarding',
        ];
        final loc = state.matchedLocation;
        final isAllowed = allowedPrefixes.any((p) => loc == p || loc.startsWith(p));
        if (!isAllowed) return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/auth/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/auth/register', builder: (_, __) => const RegisterScreen()),
      
      // Onboarding
      GoRoute(path: '/onboarding',    builder: (_, __) => const OnboardingScreen()),

      // Shell route for persistent bottom nav
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(path: '/home',        builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/search',      builder: (_, __) => const SearchScreen()),
          GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
          GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Full screen routes
      GoRoute(
        path: '/lesson/:lessonId',
        builder: (_, state) => SessionScreen(
          lessonId: state.pathParameters['lessonId']!,
        ),
      ),
      GoRoute(
        path: '/result',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ResultScreen(
            result: CompleteLessonResult.fromJson(extra['result'] as Map<String, dynamic>),
            lessonId: extra['lesson_id'] as String,
          );
        },
      ),
      GoRoute(
        path: '/level-up',
        builder: (_, state) {
          final level = state.extra as int? ?? 1;
          return LevelUpScreen(newLevel: level);
        },
      ),
      GoRoute(
        path: '/mistake-review',
        builder: (_, __) => const MistakeReviewScreen(),
      ),
      GoRoute(
        path: '/topic-quiz/:topicId',
        builder: (_, state) => TopicQuizScreen(
          topicId: state.pathParameters['topicId']!,
        ),
      ),
    ],
  );
});

// Shell Wrapper
class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/search')) currentIndex = 1;
    if (location.startsWith('/leaderboard')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white54 
            : AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.go('/search'); break;
            case 2: context.go('/leaderboard'); break;
            case 3: context.go('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Arama'),
          BottomNavigationBarItem(icon: Icon(Icons.leaderboard_rounded), label: 'Sıralama'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}
