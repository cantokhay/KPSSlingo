import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class HeartsOutDialog extends ConsumerWidget {
  const HeartsOutDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💔', style: TextStyle(fontSize: 64)),
            Gaps.md,
            Text('Canın Bitti!', style: AppTextStyles.headlineSmall),
            Gaps.sm,
            Text(
              'Öğrenmeye devam etmek için canlarını doldurman gerekiyor.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            Gaps.xl,
            
            // Refill with XP
            _RefillOption(
              title: 'XP ile Doldur',
              subtitle: '500 XP harcayarak tüm canlarını yenile',
              icon: Icons.flash_on_rounded,
              color: AppColors.xpGold,
              onTap: () async {
                await ref.read(heartsProvider.notifier).refillWithXp();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            Gaps.md,
            
            // Refill with Ad (Simulation)
            _RefillOption(
              title: 'Reklam İzle',
              subtitle: 'Kısa bir video izle ve can kazan',
              icon: Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              onTap: () async {
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );
                await ref.read(heartsProvider.notifier).refillWithAd();
                if (context.mounted) {
                  Navigator.pop(context); // Close loading
                  Navigator.pop(context); // Close hearts dialog
                }
              },
            ),
            Gaps.lg,
            
            TextButton(
              onPressed: () => context.go('/home'),
              child: Text(
                'Dinlenmeye Çık',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefillOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RefillOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.md),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          color: color.withOpacity(0.05),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            Gaps.w(AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleSmall),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
