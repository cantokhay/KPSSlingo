import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class LevelUpScreen extends StatefulWidget {
  final int newLevel;
  const LevelUpScreen({required this.newLevel, super.key});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> {
  @override
  void initState() {
    super.initState();
    // Otomatik kapanma
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie Animation (Celebration)
              SizedBox(
                height: 300,
                child: Lottie.network(
                  'https://assets9.lottiefiles.com/packages/lf20_tou96omf.json', // Trophy
                  repeat: false,
                ),
              ),
              Gaps.lg,
              Text(
                'TEBRİKLER!',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
              ),
              Gaps.sm,
              Text(
                'Yeni bir seviyeye ulaştın!',
                style: AppTextStyles.titleMedium,
              ),
              Gaps.xl,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'YENİ SEVİYE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${widget.newLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 64,
                      ),
                    ),
                  ],
                ),
              ),
              Gaps.xxl,
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                ),
                child: Text('HARİKA!', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
