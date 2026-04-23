import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_data_provider.dart';
import '../providers/home_providers.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/core/providers/theme_provider.dart';
import 'widgets/streak_banner_section.dart';
import 'widgets/continue_lesson_section.dart';
import 'widgets/topic_list_section.dart';
import 'widgets/daily_quest_card.dart';
import 'widgets/heart_indicator.dart';
import 'widgets/info_banners_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(homeDataProvider),
        child: const CustomScrollView(
          slivers: [
            // 1. Streak Banner
            SliverToBoxAdapter(child: StreakBannerSection()),
            SliverToBoxAdapter(child: Gaps.md),
            
            // 2. Günlük Görev
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimensions.pageHorizontalPadding),
                child: DailyQuestCard(),
              ),
            ),
            SliverToBoxAdapter(child: Gaps.md),
            
            // 3. Bilgi Bannerları (Yüksel, Ligler vb.)
            const SliverToBoxAdapter(child: InfoBannersSection()),
            SliverToBoxAdapter(child: Gaps.md),

            // 3. Devam Et CTA
            SliverToBoxAdapter(child: ContinueLessonSection()),
            SliverToBoxAdapter(child: Gaps.md),
            SliverToBoxAdapter(child: Gaps.lg),

            // 3. Konu Haritası Başlığı
            SliverToBoxAdapter(child: _SectionHeader(title: 'Konu Haritası')),
            SliverToBoxAdapter(child: Gaps.sm),

            // 4. Konu Kartları Listesi
            TopicListSection(),

            // 5. Alt boşluk
            SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.lg),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: GestureDetector(
        onLongPress: () => _showDebugDialog(context),
        child: Text(
          'KPSSlingo',
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ),
      actions: [
        const Center(child: HeartIndicator()),
        const SizedBox(width: AppDimensions.xs),
        // Dark mode toggle
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: anim,
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              key: ValueKey(isDark),
              color: isDark ? Colors.amber : AppColors.primary,
            ),
          ),
          onPressed: () => ref.read(themeProvider.notifier).toggleDarkLight(isDark),
          tooltip: isDark ? 'Açık temaya geç' : 'Koyu temaya geç',
        ),
        // Bildirim çanı
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => _showNotificationsSheet(context),
          tooltip: 'Bildirimler',
        ),
        const SizedBox(width: AppDimensions.sm),
      ],
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }

  void _showDebugDialog(BuildContext context) {
    final offset = ref.read(serverTimeOffsetProvider);
    final heartState = ref.read(heartsProvider);
    final profile = ref.read(userProfileProvider).value;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sistem Bilgisi (Debug)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Server Time Offset: ${offset.inSeconds}s'),
            Text('Client Time: ${DateTime.now().toIso8601String().substring(11, 19)}'),
            Text('Server Time: ${DateTime.now().toUtc().add(offset).toIso8601String().substring(11, 19)}'),
            const Divider(),
            Text('Hearts: ${heartState?.hearts ?? 'N/A'}'),
            Text('Next Regen: ${heartState?.timeUntilNext.inSeconds ?? 0}s'),
            const Divider(),
            Text('Total XP: ${profile?.totalXp ?? 0}'),
            Text('Level: ${profile?.currentLevel ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
}

// ─── Seksyon Başlığı ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageHorizontalPadding),
      child: Text(
        title, 
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Bildirimler Bottom Sheet ─────────────────────────────────────────────────
class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Çekme çubuğu
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),


            // Başlık
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.pageHorizontalPadding,
                vertical: AppDimensions.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_rounded,
                      color: AppColors.primary, size: 22),
                  Gaps.w(8),
                  Text('Bildirimler', style: AppTextStyles.titleMedium),
                ],
              ),
            ),

            const Divider(height: 1),

            // İçerik: henüz bildirim yok state
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
                children: [
                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        const Text('🔔', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz bildirim yok',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yeni dersler, seri hatırlatıcıları ve başarımlar\nburada görünecek.',
                          style: AppTextStyles.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
