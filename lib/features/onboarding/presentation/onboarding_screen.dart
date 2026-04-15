import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../../auth/providers/auth_notifier.dart';
import '../../home/providers/home_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  bool _isLastPage = false;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      title: 'KPSS Serüvenine Hoş Geldin!',
      description: 'Türkiye\'nin en interaktif KPSS hazırlık platformu ile tanış. Oyun tadında öğrenme deneyimi seni bekliyor.',
      icon: '🚀',
    ),
    _OnboardingData(
      title: 'AI Destekli Akıllı Sorular',
      description: 'Zayıf olduğun konuları tespit eden ve sana özel içerikler üreten yapay zeka ile eksiklerini hızla kapat.',
      icon: '🤖',
    ),
    _OnboardingData(
      title: 'Serini Koru, Zirveye Çık',
      description: 'Her gün çalışarak serini devam ettir, XP kazan ve liderlik tablosunda yerini al!',
      icon: '🔥',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _isLastPage = index == _pages.length - 1);
            },
            itemBuilder: (context, index) => _OnboardingPage(data: _pages[index]),
          ),
          
          // Alt kısım: Indicator + Buton
          Positioned(
            bottom: 60,
            left: AppDimensions.pageHorizontalPadding,
            right: AppDimensions.pageHorizontalPadding,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: _pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: AppColors.primary,
                    dotColor: Theme.of(context).dividerColor.withOpacity(0.2),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                  ),
                ),
                Gaps.xxl,
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_isLastPage) {
                        await ref.read(authNotifierProvider.notifier).completeOnboarding();
                        ref.invalidate(userProfileProvider);
                        if (mounted) context.go('/home');
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                    child: Text(
                      _isLastPage ? 'HEMEN BAŞLA' : 'SONRAKİ',
                      style: AppTextStyles.labelBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(data.icon, style: const TextStyle(fontSize: 100)),
          Gaps.xxl,
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
          ),
          Gaps.lg,
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String description;
  final String icon;
  _OnboardingData({required this.title, required this.description, required this.icon});
}
