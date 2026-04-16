import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_providers.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/shared/widgets/skeleton.dart';
import '../../data/models/streak.dart';

class StreakBannerSection extends ConsumerWidget {
  const StreakBannerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync   = ref.watch(streakProvider);
    final profileAsync  = ref.watch(userProfileProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ).copyWith(top: AppDimensions.sm),
      child: streakAsync.when(
        data: (streak) => _StreakBannerCard(
          streak: streak,
          totalXp: profileAsync.valueOrNull?.totalXp ?? 0,
        ),
        loading: () => const _StreakBannerSkeleton(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

// ─── Ana Kart ─────────────────────────────────────────────────────────────────
class _StreakBannerCard extends StatefulWidget {
  final Streak? streak;
  final int totalXp;

  const _StreakBannerCard({this.streak, required this.totalXp});

  @override
  State<_StreakBannerCard> createState() => _StreakBannerCardState();
}

class _StreakBannerCardState extends State<_StreakBannerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // Demo XP — gerçek uygulamada user_progress'ten alınabilir
  static const int _currentDailyXp = 17;
  static const int _dailyGoalXp    = 20;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentStreak = widget.streak?.currentStreak ?? 0;
    final lastActivity  = widget.streak?.lastActivityDate;

    return AnimatedBuilder(
      animation: _glowAnim,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E4DF4), Color(0xFF6C85FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              // Neumorphic Outer Soft Shadow
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(5, 5),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 20,
                offset: Offset(-5, -5),
              ),
              // Glow Shadow
              BoxShadow(
                color: const Color(0xFF2E4DF4).withOpacity(0.3 * _glowAnim.value),
                blurRadius: 15 * _glowAnim.value,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: child,
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Üst Satır: Seri + Takvim ───────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol: alev + seri sayısı
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AnimatedFlame(controller: _glowCtrl),
                    Gaps.w(8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$currentStreak Günlük',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Seri! 🔥',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sağ: Haftalık seri takvimi
              Flexible(
                child: _WeeklyStreakCalendar(
                  currentStreak:  currentStreak,
                  lastActivity:   lastActivity,
                ),
              ),
            ],
          ),

          Gaps.h(12),

          // ── Alt: XP Progress ───────────────────────────────────────────────
          _XpProgressBar(
            current: _currentDailyXp,
            goal: _dailyGoalXp,
          ),
        ],
      ),
    );
  }
}

// ─── Animasyonlu Alev İkonu ───────────────────────────────────────────────────
class _AnimatedFlame extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedFlame({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final scale = 1.0 + 0.08 * math.sin(controller.value * math.pi);
        return Transform.scale(
          scale: scale,
          child: const Text('🔥', style: TextStyle(fontSize: 30)),
        );
      },
    );
  }
}

// ─── Haftalık Seri Takvimi (son 7 gün) ───────────────────────────────────────
class _WeeklyStreakCalendar extends StatelessWidget {
  final int currentStreak;
  final DateTime? lastActivity;

  const _WeeklyStreakCalendar({
    required this.currentStreak,
    required this.lastActivity,
  });

  @override
  Widget build(BuildContext context) {
    final today   = DateTime.now();
    final days    = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

    // Son 7 gün listesi (bugün dahil)
    final last7 = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    // Kaç gün active: currentStreak kadar son günden geriye say
    final activeFrom = lastActivity != null
        ? lastActivity!.subtract(Duration(days: currentStreak - 1))
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Bu Hafta',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white54,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        Gaps.h(4),
        LayoutBuilder(
          builder: (context, constraints) {
            // Ekran genişliğine göre padding ayarla
            final horizontalPadding = constraints.maxWidth < 360 ? 1.0 : 2.0;
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: last7.map((day) {
                final isActive = lastActivity != null &&
                    activeFrom != null &&
                    !day.isBefore(activeFrom) &&
                    !day.isAfter(lastActivity!.add(const Duration(days: 1)));

                final isToday = day.year == today.year &&
                    day.month == today.month &&
                    day.day == today.day;

                final dayLabel = days[day.weekday - 1];

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    children: [
                      // Daire
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? AppColors.xpGold
                              : Colors.white.withOpacity(0.15),
                          border: isToday && !isActive
                              ? Border.all(color: Colors.white54, width: 1.5)
                              : null,
                        ),
                        child: isActive
                            ? const Center(
                                child: Icon(Icons.check_rounded,
                                    color: Colors.white, size: 13),
                              )
                            : null,
                      ),
                      Gaps.h(3),
                      // Gün kısaltması
                      Text(
                        dayLabel,
                        style: TextStyle(
                          color: isActive ? AppColors.xpGold : Colors.white38,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─── XP İlerleme Çubuğu ──────────────────────────────────────────────────────
class _XpProgressBar extends StatelessWidget {
  final int current;
  final int goal;
  const _XpProgressBar({required this.current, required this.goal});

  @override
  Widget build(BuildContext context) {
    final pct = (current / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Etiketler
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Günlük Hedef',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            Row(
              children: [
                Text(
                  '$current',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.xpGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                Text(
                  ' / $goal XP',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),

        Gaps.h(6),

        // Progress bar — düz ve temiz
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(100),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Dolu kısım
              FractionallySizedBox(
                widthFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.xpGold, Color(0xFFFFB300)],
                    ),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.xpGold.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
              // Parlama efekti
              if (pct > 0.05)
                Positioned(
                  top: 1,
                  left: 4,
                  child: Container(
                    height: 3,
                    width: 20 * pct,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Tamamlandı mesajı
        if (pct >= 1.0) ...[
          Gaps.h(4),
          Text(
            '🎉 Bugünkü hedefini tamamladın!',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.xpGold,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────────────────
class _StreakBannerSkeleton extends StatelessWidget {
  const _StreakBannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(
      width: double.infinity,
      height: 118,
      radius: AppDimensions.radiusMd,
    );
  }
}
