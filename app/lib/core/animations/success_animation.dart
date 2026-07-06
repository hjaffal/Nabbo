import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A satisfying checkmark animation for successful actions like
/// approving items, marking tasks done, or capturing content.
class SuccessAnimation extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const SuccessAnimation({
    super.key,
    this.size = 80,
    this.color = AppColors.vibrantTeal,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SuccessPainter(
              progress: _controller.value,
              color: widget.color,
            ),
          );
        },
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  final double progress;
  final Color color;

  _SuccessPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Circle drawing (0-0.5 of progress)
    final circleProgress = (progress * 2).clamp(0.0, 1.0);
    if (circleProgress > 0) {
      final circlePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * circleProgress,
        false,
        circlePaint,
      );
    }

    // Fill fade-in (0.4-0.6)
    final fillProgress = ((progress - 0.4) / 0.2).clamp(0.0, 1.0);
    if (fillProgress > 0) {
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.1 * fillProgress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius, fillPaint);
    }

    // Checkmark drawing (0.45-1.0 of progress)
    final checkProgress = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      // Start, middle, end of checkmark
      final startX = size.width * 0.28;
      final startY = size.height * 0.52;
      final midX = size.width * 0.44;
      final midY = size.height * 0.66;
      final endX = size.width * 0.72;
      final endY = size.height * 0.38;

      path.moveTo(startX, startY);

      if (checkProgress <= 0.5) {
        // First segment (start → mid)
        final t = checkProgress * 2;
        path.lineTo(
          startX + (midX - startX) * t,
          startY + (midY - startY) * t,
        );
      } else {
        // Full first segment + second segment
        path.lineTo(midX, midY);
        final t = (checkProgress - 0.5) * 2;
        path.lineTo(
          midX + (endX - midX) * t,
          midY + (endY - midY) * t,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SuccessPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
