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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 90)); // Default fallback
  bool _dateInitialized = false;

  final Map<String, DateTime> _defaultExamDates = {
    'lisans': DateTime(2026, 7, 20),
    'onlisans': DateTime(2026, 9, 5),
    'ortaogretim': DateTime(2026, 10, 18),
  };

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
          PageView(
            controller: _controller,
            onPageChanged: (index) {
              setState(() => _isLastPage = index == _pages.length);
            },
            children: [
              ..._pages.map((p) => _OnboardingPage(data: p)),
              _DateSelectionPage(
                selectedDate: _selectedDate,
                onDateChanged: (date) => setState(() => _selectedDate = date),
              ),
            ],
          ),
          
          Positioned(
            bottom: 60,
            left: AppDimensions.pageHorizontalPadding,
            right: AppDimensions.pageHorizontalPadding,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _controller,
                  count: _pages.length + 1,
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
                        await ref.read(authNotifierProvider.notifier).completeOnboarding(_selectedDate);
                        ref.invalidate(userProfileProvider);
                        if (mounted) context.go('/home');
                      } else {
                        // Eğer son sayfaya (tarih seçimi) geçiyorsak, profil bilgisine göre tarihi init et
                        if (_controller.page?.round() == _pages.length - 1 && !_dateInitialized) {
                          final profile = ref.read(userProfileProvider).valueOrNull;
                          if (profile != null) {
                            setState(() {
                              _selectedDate = _defaultExamDates[profile.targetExam] ?? _selectedDate;
                              _dateInitialized = true;
                            });
                          }
                        }
                        
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

class _DateSelectionPage extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const _DateSelectionPage({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = "${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sınav Tarihin',
            style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary),
          ),
          Gaps.sm,
          Text(
            'Hedefine ne kadar kaldığını takip edelim.\nSeçtiğin sınav türüne göre tahmini tarih ayarlandı.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          Gaps.xxl,
          
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: AppColors.primary,
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onDateChanged(picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 48, color: AppColors.primary),
                  Gaps.md,
                  Text(
                    dateStr,
                    style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                  Gaps.xs,
                  Text(
                    'Tarihi Değiştirmek İçin Dokun',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return names[month];
  }
}



class _OnboardingData {
  final String title;
  final String description;
  final String icon;
  _OnboardingData({required this.title, required this.description, required this.icon});
}

