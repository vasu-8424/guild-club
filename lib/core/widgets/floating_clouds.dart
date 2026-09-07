import 'package:flutter/material.dart';
import '../theme/toyverse_theme.dart';

class FloatingCloudsBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final Color? backgroundColor;

  const FloatingCloudsBackground({
    super.key,
    required this.child,
    this.opacity = 0.04,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor ?? ToyVerseTheme.bgWarmWhite,
      child: Stack(
        children: [
          // Subtle top-right ambient studio light glow
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ToyVerseTheme.primaryElectricPurple.withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color: ToyVerseTheme.primaryElectricPurple.withOpacity(opacity),
                    blurRadius: 120,
                    spreadRadius: 60,
                  )
                ],
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}
