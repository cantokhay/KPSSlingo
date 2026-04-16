import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';
import 'package:kpsslingo/core/theme/gaps.dart';
import '../../session/models/complete_lesson_result.dart';
import 'widgets/action_buttons.dart';
import 'widgets/animated_score_circle.dart';
import 'widgets/grade_header.dart';
import 'widgets/stat_row.dart';

class ResultScreen extends StatefulWidget {
  final CompleteLessonResult result;
  final String lessonId;

  const ResultScreen({
    required this.result,
    required this.lessonId,
    super.key,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _master;
  late ConfettiController _confettiController;

  late final Animation<double> _headerAnim;
  late final Animation<double> _scoreAnim;
  late final Animation<double> _statsAnim;
  late final Animation<double> _ctaAnim;

  @override
  void initState() {
    super.initState();

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _headerAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.07, 0.35, curve: Curves.easeOutBack),
    );
    _scoreAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.23, 0.75, curve: Curves.easeOut),
    );
    _statsAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.60, 0.90, curve: Curves.easeOut),
    );
    _ctaAnim = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.85, 1.0, curve: Curves.easeOut),
    );

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    _master.forward().then((_) {
      if (widget.result.score >= 70) {
        _confettiController.play();
      }
      
      // Level Up Simülasyonu
      if (widget.result.score >= 90) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) context.push('/level-up', extra: 2);
        });
      }
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grade = widget.result.grade;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.pageHorizontalPadding,
                  vertical: AppDimensions.lg,
                ),
                child: Column(
                  children: [
                    Gaps.lg,
                    GradeHeader(grade: grade),
                    Gaps.xl,
                    AnimatedScoreCircle(
                      score: widget.result.score,
                      animation: _scoreAnim,
                      grade: grade,
                    ),
                    Gaps.xl,
                    StatRow(result: widget.result),
                    Gaps.xxl,
                    ActionButtons(
                      lessonId: widget.lessonId,
                      score: widget.result.score,
                    ),
                    Gaps.lg,
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
