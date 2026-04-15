import 'package:flutter/material.dart';

import 'package:kpsslingo/core/theme/app_colors.dart';
import 'package:kpsslingo/core/theme/app_text_styles.dart';
import '../../../session/models/complete_lesson_result.dart';

class AnimatedScoreCircle extends StatelessWidget {
  final int score;
  final Animation<double> animation;
  final ResultGrade grade;

  const AnimatedScoreCircle({
    required this.score,
    required this.animation,
    required this.grade,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final animatedScore = (score * animation.value).round();

        return SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Arka plan dairesi
              CustomPaint(
                size: const Size(180, 180),
                painter: _ScoreArcPainter(
                  progress: animation.value * (score / 100),
                  trackColor: Theme.of(context).dividerColor.withOpacity(0.1),
                  arcColor: grade.color,
                  strokeWidth: 14,
                ),
              ),
              // Merkezdeki sayı
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$animatedScore',
                    style: AppTextStyles.displayLarge.copyWith(
                      fontSize: 48,
                      color: grade.color,
                    ),
                  ),
                  Text(
                    '%',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreArcPainter extends CustomPainter {
  final double progress;    // 0.0 - 1.0
  final Color trackColor;
  final Color arcColor;
  final double strokeWidth;

  const _ScoreArcPainter({
    required this.progress,
    required this.trackColor,
    required this.arcColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    const startAngle = -90 * (3.14159 / 180);  // Saat 12'den başla
    const fullSweep = 2 * 3.14159;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Arka plan halkası
    canvas.drawCircle(center, radius, trackPaint);

    // İlerleme yayı
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        fullSweep * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreArcPainter old) =>
      old.progress != progress || old.arcColor != arcColor;
}
