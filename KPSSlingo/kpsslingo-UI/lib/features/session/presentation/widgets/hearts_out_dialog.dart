import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/shared/providers/hearts_provider.dart';
import 'package:kpsslingo/features/home/providers/home_providers.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class HeartsOutDialog extends ConsumerWidget {
  const HeartsOutDialog({super.key});

  static bool _isShowing = false;

  static Future<void> show(BuildContext context, WidgetRef ref) async {
    if (_isShowing) return;
    
    // Son bir kontrol: Canlar gerçekten 0 mı? 
    // (Yarış durumlarını önlemek için)
    final currentHearts = ref.read(heartsProvider)?.hearts ?? 15;
    if (currentHearts > 0) return;

    _isShowing = true;
    try {
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'HeartsOut',
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, anim1, anim2) => const HeartsOutDialog(),
        transitionBuilder: (context, anim1, anim2, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: FadeTransition(opacity: anim1, child: child),
          );
        },
      );
    } finally {
      _isShowing = false;
    }
  }

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
            Stack(
              alignment: Alignment.center,
              children: [
                const Text('💔', style: TextStyle(fontSize: 64)),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${ref.watch(heartsProvider)?.hearts ?? 0}/15',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
              subtitle: '5 XP harcayarak tüm canlarını yenile',
              icon: Icons.flash_on_rounded,
              color: AppColors.xpGold,
              onTap: () async {
                final heartsState = ref.read(heartsProvider);
                if (heartsState != null && heartsState.hearts >= 15) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Canların zaten dolu!')),
                  );
                  if (context.mounted) Navigator.pop(context);
                  return;
                }

                final success = await ref.read(heartsProvider.notifier).refillWithXp();
                
                if (success) {
                  if (context.mounted) Navigator.pop(context);
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Yetersiz XP!')),
                    );
                  }
                }
              },
            ),
            Gaps.md,
            
            // Refill with Ad — şu an aktif değil
            _RefillOption(
              title: 'Reklam İzle',
              subtitle: 'Kısa bir video izle ve can kazan',
              icon: Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              onTap: () {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reklam özelliği yakında aktif olacak.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            Gaps.lg,
            
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text(
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
