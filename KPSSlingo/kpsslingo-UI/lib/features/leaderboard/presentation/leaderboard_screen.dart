import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/leaderboard_provider.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/features/auth/providers/auth_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUser      = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Sıralama', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              Gaps.md,
              Text('Sıralama yüklenemedi', style: AppTextStyles.titleMedium),
              Gaps.sm,
              Text(e.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 64)),
                  Gaps.md,
                  Text('Henüz sıralama yok', style: AppTextStyles.titleMedium),
                  Gaps.sm,
                  Text('İlk dersi tamamla ve liderlik tablosuna gir!',
                      style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Kısa başlık baneri
              SliverToBoxAdapter(
                child: _LeaderboardHeader(entries: entries),
              ),

              // Tam liste
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final entry   = entries[i];
                    final isMe    = entry.id == currentUser?.id;
                    return _LeaderboardTile(entry: entry, isCurrentUser: isMe);
                  },
                  childCount: entries.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),
    );
  }
}

// ─── Top 3 Podium Başlık ─────────────────────────────────────────────────────
class _LeaderboardHeader extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const _LeaderboardHeader({required this.entries});

  @override
  Widget build(BuildContext context) {
    final top = entries.take(3).toList();

    return Container(
      margin: const EdgeInsets.all(AppDimensions.md),
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.lg, horizontal: AppDimensions.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top.length >= 2)
            _PodiumItem(entry: top[1], height: 70),
          if (top.isNotEmpty)
            _PodiumItem(entry: top[0], height: 95, isFirst: true),
          if (top.length >= 3)
            _PodiumItem(entry: top[2], height: 55),
        ],
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final double height;
  final bool isFirst;

  const _PodiumItem({
    required this.entry,
    required this.height,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final medal  = entry.rank <= 3 ? medals[entry.rank - 1] : '${entry.rank}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(medal, style: TextStyle(fontSize: isFirst ? 28 : 22)),
        Gaps.xs,
        CircleAvatar(
          radius: isFirst ? 28 : 22,
          backgroundColor: Colors.white24,
          child: Text(
            entry.username.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: isFirst ? 22 : 16,
            ),
          ),
        ),
        Gaps.xs,
        Text(
          entry.username,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isFirst ? 13 : 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${entry.totalXp} XP',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        Gaps.xs,
        Container(
          width: isFirst ? 64 : 52,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(isFirst ? 0.25 : 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ),
      ],
    );
  }
}

// ─── Sıralama Satırı ─────────────────────────────────────────────────────────
class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  const _LeaderboardTile({required this.entry, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final medals  = ['🥇', '🥈', '🥉'];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(isDark ? 0.15 : 0.08)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.1),
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Sıra numarası / madalya
          SizedBox(
            width: 36,
            child: isTop3
                ? Text(medals[entry.rank - 1],
                    style: const TextStyle(fontSize: 20),
                    textAlign: TextAlign.center)
                : Text(
                    '#${entry.rank}',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
          Gaps.w(12),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              entry.username.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          Gaps.w(12),

          // Kullanıcı adı + seviye
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.username,
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                    ),
                    if (isCurrentUser) ...[
                      Gaps.w(6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'Sen',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  'Seviye ${entry.currentLevel}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),

          // XP
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.totalXp}',
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: 16,
                  color: AppColors.xpGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'XP',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
