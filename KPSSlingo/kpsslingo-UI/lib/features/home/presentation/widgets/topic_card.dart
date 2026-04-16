import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kpsslingo/features/home/providers/home_providers.dart';
import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import 'package:kpsslingo/features/home/data/models/topic.dart';
import 'package:kpsslingo/features/home/data/models/lesson.dart';
import 'package:kpsslingo/shared/widgets/skeleton.dart';
import 'package:kpsslingo/core/theme/neumorphic_style.dart';

class TopicCard extends ConsumerStatefulWidget {
  final Topic topic;
  const TopicCard({required this.topic, super.key});

  @override
  ConsumerState<TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends ConsumerState<TopicCard>
    with SingleTickerProviderStateMixin {

  bool _isExpanded = false;
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.topicColors[widget.topic.slug] ?? AppColors.primary;
    final lessonsAsync = _isExpanded
        ? ref.watch(lessonsForTopicProvider(widget.topic.id))
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.lg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: NeumorphicStyle.containerDecoration(context, isSelected: _isExpanded),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.md),
                child: Row(
                  children: [
                    Hero(
                      tag: 'topic-icon-${widget.topic.id}',
                      child: Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                        ),
                        child: Center(
                          child: Text(
                            widget.topic.emoji ?? '📚', 
                            style: const TextStyle(fontSize: 26)
                          ),
                        ),
                      ),
                    ),
                    Gaps.w(AppDimensions.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.topic.title, 
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            )
                          ),
                          Gaps.xs,
                          _TopicProgressBar(topicId: widget.topic.id, color: color),
                        ],
                      ),
                    ),
                    Gaps.w(AppDimensions.sm),
                    _isExpanded 
                      ? Icon(Icons.remove_circle_outline_rounded, color: color.withOpacity(0.5))
                      : Icon(Icons.add_circle_outline_rounded, color: color.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const Divider(height: 1),
                  if (_isExpanded && lessonsAsync != null)
                    lessonsAsync.when(
                      data: (lessons) => _LessonItems(lessons: lessons, topicColor: color),
                      loading: () => const _LessonItemsSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicProgressBar extends ConsumerWidget {
  final String topicId;
  final Color color;
  const _TopicProgressBar({required this.topicId, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(topicProgressProvider(topicId));
    
    return progressAsync.when(
      data: (progress) => TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCirc,
        tween: Tween(begin: 0, end: progress),
        builder: (context, value, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Gaps.xs,
            Text(
              '%${(value * 100).toInt()} Tamamlandı',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      loading: () => const LinearProgressIndicator(minHeight: 2),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LessonItems extends StatelessWidget {
  final List<Lesson> lessons;
  final Color topicColor;
  const _LessonItems({required this.lessons, required this.topicColor});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimensions.md),
      itemCount: lessons.length,
      separatorBuilder: (_, __) => Gaps.sm,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        return InkWell(
          onTap: () => context.push('/lesson/${lesson.id}'),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.md, vertical: AppDimensions.sm),
            decoration: BoxDecoration(
              border: Border.all(color: topicColor.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: topicColor.withOpacity(0.1),
                  child: Text('${index + 1}', style: TextStyle(fontSize: 10, color: topicColor, fontWeight: FontWeight.bold)),
                ),
                Gaps.md,
                Expanded(child: Text(lesson.title, style: AppTextStyles.bodyMedium)),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LessonItemsSkeleton extends StatelessWidget {
  const _LessonItemsSkeleton();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.md),
      child: Column(
        children: List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppDimensions.sm),
          child: SkeletonBox(width: double.infinity, height: 40, radius: AppDimensions.radiusSm),
        )),
      ),
    );
  }
}
