import 'package:flutter/material.dart';

import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import 'package:kpsslingo/core/theme/gaps.dart';

class StatCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool animateValue;
  final int targetValue;

  const StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.animateValue,
    required this.targetValue,
    super.key,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<int> _counter;

  @override
  void initState() {
    super.initState();
    if (widget.animateValue) {
      _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _counter = IntTween(begin: 0, end: widget.targetValue)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    if (widget.animateValue) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.md,
        horizontal: AppDimensions.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)), 
      ),
      child: Column(
        children: [
          Icon(widget.icon, color: widget.iconColor, size: 28),
          Gaps.xs,
          widget.animateValue
              ? AnimatedBuilder(
                  animation: _counter,
                  builder: (_, __) => Text(
                    widget.icon == Icons.bolt_rounded
                        ? '+${_counter.value}'
                        : '${_counter.value}',
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: widget.iconColor,
                    ),
                  ),
                )
              : Text(
                  widget.value,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: widget.iconColor,
                  ),
                ),
          Gaps.xs,
          Text(widget.label,
              style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
