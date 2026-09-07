import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/toyverse_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 12.0,
    this.opacity = 0.85,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final defaultRadius = borderRadius ?? BorderRadius.circular(ToyVerseTheme.radiusSmallCard);
    final cardColor = color ?? Colors.white.withOpacity(opacity);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: defaultRadius,
        border: Border.all(
          color: Colors.grey.shade200.withOpacity(0.6),
          width: 0.8,
        ),
        boxShadow: ToyVerseTheme.subtleShadow(opacity: 0.03, blur: 14),
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: defaultRadius,
        child: InkWell(
          borderRadius: defaultRadius,
          onTap: onTap,
          splashColor: ToyVerseTheme.primaryElectricPurple.withOpacity(0.08),
          highlightColor: ToyVerseTheme.primaryRoyalBlue.withOpacity(0.04),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: defaultRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}
