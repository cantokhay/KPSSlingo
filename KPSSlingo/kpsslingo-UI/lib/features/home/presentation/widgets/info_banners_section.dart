import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class InfoBannersSection extends StatelessWidget {
  const InfoBannersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.pageHorizontalPadding),
        children: [
          _InfoBanner(
            title: 'Ligleri Keşfet',
            subtitle: 'En iyiler arasına gir',
            icon: '🏆',
            color: Colors.amber.shade700,
            onTap: () => _showComingSoon(context, 'Ligler', 'Ligler çok yakında! Rakiplerini eleyip en üst lige tırmanmaya hazır ol.'),
          ),
          Gaps.w(AppDimensions.md),
          _InfoBanner(
            title: 'Liderlik Tablosu',
            subtitle: 'Sıralamanı gör',
            icon: '📊',
            color: AppColors.primary,
            onTap: () => context.go('/leaderboard'),
          ),
          Gaps.w(AppDimensions.md),
          _InfoBanner(
            title: 'Hemen Yüksel',
            subtitle: 'Hedeflerini tamamla',
            icon: '🚀',
            color: AppColors.accent,
            onTap: () => _showComingSoon(context, 'KPSSlingo Pro', 'Haftalık hedeflerini tamamla ve KPSSlingo Pro özelliklerine erken erişim şansı yakala!'),
          ),
          Gaps.w(AppDimensions.md),
          _InfoBanner(
            title: 'Soru Arama',
            subtitle: 'Tüm soruları tara',
            icon: '🔍',
            color: Colors.teal,
            onTap: () => context.go('/search'),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusLg)),
        ),
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            Gaps.lg,
            const Text('✨', style: TextStyle(fontSize: 40)),
            Gaps.md,
            Text(title, style: AppTextStyles.titleLarge),
            Gaps.sm,
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            Gaps.xl,
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anladım'),
              ),
            ),
            Gaps.md,
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final VoidCallback onTap;

  const _InfoBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(AppDimensions.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Gaps.w(AppDimensions.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelBold.copyWith(color: color, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
