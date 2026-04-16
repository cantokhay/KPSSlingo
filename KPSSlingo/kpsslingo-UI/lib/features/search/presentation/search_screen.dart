import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../providers/search_provider.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.05) 
                : Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white12 
                  : Colors.black12,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ders veya konu ara...',
              border: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
          ),
        ),
      ),
      body: resultsAsync.when(
        data: (lessons) {
          if (query.isEmpty) {
            return const _SearchEmptyState(
              icon: '🔍',
              title: 'Hemen aramaya başla',
              subtitle: 'Örn: "Cumhuriyet Dönemi", "Matematik"...',
            );
          }
          if (lessons.isEmpty) {
            return const _SearchEmptyState(
              icon: '😕',
              title: 'Sonuç bulunamadı',
              subtitle: 'Farklı kelimelerle tekrar deneyebilirsin.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontalPadding),
            itemCount: lessons.length,
            separatorBuilder: (_, __) => Gaps.sm,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary),
                  title: Text(lesson.title, style: AppTextStyles.labelBold),
                  subtitle: Text('${lesson.xpReward} XP', style: AppTextStyles.bodySmall),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled),
                  onTap: () => context.push('/lesson/${lesson.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Bir hata oluştu: $e')),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  const _SearchEmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 64)),
          Gaps.md,
          Text(title, style: AppTextStyles.titleMedium),
          Gaps.xs,
          Text(subtitle, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
