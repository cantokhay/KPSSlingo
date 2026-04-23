import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/features/auth/providers/auth_provider.dart';
import 'package:kpsslingo/features/auth/providers/auth_notifier.dart';
import 'package:kpsslingo/features/profile/providers/profile_provider.dart';
import 'package:kpsslingo/core/providers/theme_provider.dart';
import 'package:kpsslingo/core/theme/neumorphic_style.dart';
import '../../../../shared/widgets/app_date_picker.dart';
import '../../../../shared/widgets/skeleton.dart';
import '../../../auth/providers/auth_notifier.dart';
import '../../../../features/home/providers/home_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);
    final user = ref.watch(currentUserProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProfileProvider);
          ref.invalidate(profileStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildHeader(context, user),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  statsAsync.when(
                    data: (stats) => _StatsGrid(stats: stats),
                    loading: () => const _StatsGridSkeleton(),
                    error: (e, __) => Text('Hata: $e'),
                  ),
                  Gaps.xl,
                  _MenuSection(
                    title: 'Hesap Ayarları',
                    items: [
                      _MenuItem(
                        icon: Icons.person_outline_rounded, 
                        label: 'Bilgilerimi Güncelle',
                        onTap: () => _showComingSoon(context, 'Profil Güncelleme'),
                      ),
                      _MenuItem(
                        icon: Icons.school_outlined, 
                        label: 'Sınav Hedefim',
                        trailing: userProfileAsync.when(
                          data: (profile) => Text(
                            _getLevelLabel(profile?.targetExam),
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                          ),
                          loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                        ),
                        onTap: () => _showLevelSelection(context, ref, userProfileAsync.valueOrNull?.targetExam),
                      ),
                      _MenuItem(
                        icon: Icons.calendar_month_rounded, 
                        label: 'Sınav Tarihim',
                        trailing: userProfileAsync.when(
                          data: (profile) => Text(
                            _formatDate(profile?.kpssExamDate),
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary),
                          ),
                          loading: () => const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          error: (_, __) => const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                        ),
                        onTap: () => _showDatePicker(context, ref, userProfileAsync.valueOrNull?.kpssExamDate),
                      ),
                      _MenuItem(
                        icon: Icons.notifications_none_rounded, 
                        label: 'Bildirimler',
                        onTap: () => _showComingSoon(context, 'Bildirim Ayarları'),
                      ),
                      _MenuItem(
                        icon: Icons.security_rounded, 
                        label: 'Güvenlik',
                        onTap: () => _showComingSoon(context, 'Güvenlik Ayarları'),
                      ),
                    ],
                  ),
                  Gaps.lg,
                  _MenuSection(
                    title: 'Uygulama',
                    items: [
                      const _DarkModeToggle(),
                      _MenuItem(
                        icon: Icons.star_outline_rounded, 
                        label: 'Uygulamayı Puanla',
                        onTap: () => _showComingSoon(context, 'Puanlama'),
                      ),
                      _MenuItem(
                        icon: Icons.help_outline_rounded, 
                        label: 'Yardım & Destek',
                        onTap: () => _showComingSoon(context, 'Destek'),
                      ),
                      _MenuItem(
                        icon: Icons.info_outline_rounded, 
                        label: 'Hakkımızda',
                        onTap: () => _showComingSoon(context, 'Hakkımızda'),
                      ),
                    ],
                  ),
                  Gaps.xxl,
                  TextButton.icon(
                    onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: const Text('Çıkış Yap', style: TextStyle(color: AppColors.error)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(AppDimensions.md),
                    ),
                  ),
                  Gaps.xxxl,
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildHeader(BuildContext context, user) {
    return SliverAppBar(
      expandedHeight: 220,
      backgroundColor: AppColors.primary,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, Color(0xFF1E3A8A)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Gaps.xl,
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, size: 50, color: AppColors.primary),
              ),
              Gaps.md,
              Text(
                user?.email?.split('@')[0] ?? 'Yükleniyor...',
                style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
              ),
              Text(
                'Öğrenci',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature yakında sizlerle!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  String _getLevelLabel(String? level) {
    switch (level) {
      case 'lisans': return 'Lisans';
      case 'onlisans': return 'Önlisans';
      case 'ortaogretim': return 'Ortaöğretim';
      default: return 'Belirlenmedi';
    }
  }

  void _showLevelSelection(BuildContext context, WidgetRef ref, String? currentLevel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sınav Hedefini Seç', style: AppTextStyles.headlineSmall),
            Gaps.md,
            _buildLevelOption(context, ref, 'Lisans', 'lisans', currentLevel == 'lisans'),
            _buildLevelOption(context, ref, 'Önlisans', 'onlisans', currentLevel == 'onlisans'),
            _buildLevelOption(context, ref, 'Ortaöğretim', 'ortaogretim', currentLevel == 'ortaogretim'),
            Gaps.xl,
          ],
        ),
      ),
    );
  }

  Widget _buildLevelOption(BuildContext context, WidgetRef ref, String label, String value, bool isSelected) {
    return ListTile(
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
      onTap: () async {
        Navigator.pop(context);
        await ref.read(authNotifierProvider.notifier).updateTargetExam(value);
        ref.invalidate(userProfileProvider);
      },
    );
  }

  void _showDatePicker(BuildContext context, WidgetRef ref, DateTime? currentDate) async {
    final picked = await AppDatePicker.show(
      context,
      initialDate: currentDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      title: 'Sınav Tarihini Güncelle',
    );

    if (picked != null) {
      await ref.read(authNotifierProvider.notifier).updateExamDate(picked);
      ref.invalidate(userProfileProvider);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Seçilmedi';
    return "${date.day}/${date.month}/${date.year}";
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 600;
        final crossAxisCount = isLargeScreen ? 4 : 2;
        // Adjust aspect ratio to give more vertical space on narrow screens
        final aspectRatio = isLargeScreen ? 2.5 : 1.7;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppDimensions.sm,
          crossAxisSpacing: AppDimensions.sm,
          childAspectRatio: aspectRatio,
          children: [
            _StatCard(label: 'TOPLAM XP', value: '${stats['xp']}', icon: Icons.bolt_rounded, color: Colors.amber),
            _StatCard(label: 'SEVİYE', value: '${stats['level']}', icon: Icons.auto_awesome_rounded, color: Colors.purple),
            _StatCard(label: 'DERSLER', value: '${stats['completed_lessons']}', icon: Icons.menu_book_rounded, color: Colors.blue),
            _StatCard(label: 'SERİ', value: '${stats['streak']} Gün', icon: Icons.local_fire_department_rounded, color: Colors.orange),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.sm,
        vertical: AppDimensions.md,
      ),
      decoration: NeumorphicStyle.containerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              Gaps.w(4),
              Expanded(
                child: Text(
                  label, 
                  style: AppTextStyles.labelBold.copyWith(
                    fontSize: 9, 
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value, 
              style: AppTextStyles.headlineSmall.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkModeToggle extends ConsumerWidget {
  const _DarkModeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
        color: isDark ? Colors.amber : AppColors.textSecondary,
      ),
      title: Text('Karanlık Mod', style: AppTextStyles.bodyLarge),
      trailing: Switch.adaptive(
        value: isDark,
        onChanged: (_) => ref.read(themeProvider.notifier).toggleDarkLight(isDark),
        activeColor: AppColors.primary,
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.labelBold.copyWith(color: AppColors.primary)),
        Gaps.sm,
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  const _MenuItem({
    required this.icon, 
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
