import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_providers.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/shared/widgets/skeleton.dart';
import 'topic_card.dart';
import 'mistake_review_card.dart';

class TopicListSection extends ConsumerWidget {
  const TopicListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(topicsProvider);

    return topicsAsync.when(
      data: (topics) => SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index < topics.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pageHorizontalPadding,
                  vertical: AppDimensions.xs,
                ),
                child: TopicCard(topic: topics[index]),
              );
            } else {
              // Son elemandan sonra hata kartını ekle
              return const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.pageHorizontalPadding,
                ),
                child: MistakeReviewCard(),
              );
            }
          },
          childCount: topics.length + 1,
        ),
      ),
      loading: () => const SliverToBoxAdapter(child: _TopicListSkeleton()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

class _TopicListSkeleton extends StatelessWidget {
  const _TopicListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontalPadding,
      ),
      child: Column(
        children: List.generate(
          5,
          (index) => const Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.sm),
            child: SkeletonBox(
              width: double.infinity,
              height: 76,
              radius: AppDimensions.radiusMd,
            ),
          ),
        ),
      ),
    );
  }
}
