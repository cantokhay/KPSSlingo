import 'package:flutter/material.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class ExitSessionDialog extends StatelessWidget {
  const ExitSessionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      backgroundColor: Theme.of(context).cardColor,
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.md),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 32,
            ),
          ),
          Gaps.md,
          Text(
            'Dersten çıkmak istiyor musun?',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall,
          ),
        ],
      ),
      content: Text(
        'Eğer şimdi çıkarsan bu dersteki ilerlemen ve kazandığın puanlar kaydedilmeyecek.',
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMedium,
      ),
      actionsPadding: const EdgeInsets.all(AppDimensions.md),
      actions: [
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                child: const Text('DERSE DEVAM ET'),
              ),
            ),
            Gaps.sm,
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: AppDimensions.md),
                ),
                child: const Text('EVET, ŞİMDİ ÇIK'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
