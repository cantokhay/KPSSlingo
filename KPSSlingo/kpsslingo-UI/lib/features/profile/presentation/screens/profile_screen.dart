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

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(profileStatsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: CustomScrollView(
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
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppDimensions.md,
      crossAxisSpacing: AppDimensions.md,
      childAspectRatio: 1.6,
      children: [
        _StatCard(label: 'TOPLAM XP', value: '${stats['xp']}', icon: Icons.bolt_rounded, color: Colors.amber),
        _StatCard(label: 'SEVİYE', value: '${stats['level']}', icon: Icons.auto_awesome_rounded, color: Colors.purple),
        _StatCard(label: 'DERSLER', value: '${stats['completed_lessons']}', icon: Icons.menu_book_rounded, color: Colors.blue),
        _StatCard(label: 'SERİ', value: '${stats['streak']} Gün', icon: Icons.local_fire_department_rounded, color: Colors.orange),
      ],
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.md),
      decoration: NeumorphicStyle.containerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              Gaps.w(4),
              Text(
                label, 
                style: AppTextStyles.labelBold.copyWith(
                  fontSize: 10, 
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.headlineSmall),
        ],
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
  const _MenuItem({
    required this.icon, 
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
