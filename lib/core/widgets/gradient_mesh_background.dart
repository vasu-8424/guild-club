import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/toyverse_theme.dart';

/// A reusable animated gradient-mesh background featuring soft, drifting 3-stop
/// Heraldic Red & Navy Blue mesh gradients over a 75-second loop.
class GradientMeshBackground extends StatefulWidget {
  final Widget child;
  final Duration animationDuration;

  const GradientMeshBackground({
    super.key,
    required this.child,
    this.animationDuration = const Duration(seconds: 75),
  });

  @override
  State<GradientMeshBackground> createState() => _GradientMeshBackgroundState();
}

class _GradientMeshBackgroundState extends State<GradientMeshBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientMeshPainter(progress: _controller.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _GradientMeshPainter extends CustomPainter {
  final double progress;

  _GradientMeshPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Fill base background with off-white studio surface
    final basePaint = Paint()..color = ToyVerseTheme.bgWarmWhite;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), basePaint);

    final double t = progress * 2 * math.pi;

    // Drifting Blob 1: Soft Crest Red Accent
    final dx1 = size.width * (0.3 + 0.2 * math.sin(t));
    final dy1 = size.height * (0.2 + 0.15 * math.cos(t * 0.8));
    final radius1 = math.max(size.width, size.height) * 0.55;
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          ToyVerseTheme.primaryRed.withValues(alpha: 0.06),
          const Color(0xFFFFF1F2).withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx1, dy1), radius: radius1));
    canvas.drawCircle(Offset(dx1, dy1), radius1, paint1);

    // Drifting Blob 2: Soft Deep Navy Blue
    final dx2 = size.width * (0.7 - 0.25 * math.cos(t * 0.9));
    final dy2 = size.height * (0.6 + 0.2 * math.sin(t * 1.1));
    final radius2 = math.max(size.width, size.height) * 0.6;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.06),
          const Color(0xFFEFF6FF).withValues(alpha: 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx2, dy2), radius: radius2));
    canvas.drawCircle(Offset(dx2, dy2), radius2, paint2);

    // Drifting Blob 3: Soft Cobalt Slate
    final dx3 = size.width * (0.4 + 0.3 * math.sin(t * 0.7));
    final dy3 = size.height * (0.8 - 0.2 * math.cos(t * 1.2));
    final radius3 = math.max(size.width, size.height) * 0.5;
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          ToyVerseTheme.primaryBlueLight.withValues(alpha: 0.05),
          const Color(0xFFF0F4F8).withValues(alpha: 0.02),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(dx3, dy3), radius: radius3));
    canvas.drawCircle(Offset(dx3, dy3), radius3, paint3);
  }

  @override
  bool shouldRepaint(covariant _GradientMeshPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
