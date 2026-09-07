import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/toyverse_theme.dart';

class ToyButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final double height;
  final double? width;
  final double fontSize;
  final Color textColor;
  final bool isSecondary;
  final Color? glowColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;

  const ToyButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.color,
    this.icon,
    this.isLoading = false,
    this.height = 50,
    this.width,
    this.fontSize = 14,
    this.textColor = Colors.white,
    this.isSecondary = false,
    this.glowColor,
    this.borderRadius,
    this.padding,
  });

  // Factory constructors for instant ultra-premium button styles
  factory ToyButton.gold({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double height = 50,
    double? width,
    double fontSize = 14,
  }) {
    return ToyButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      height: height,
      width: width,
      fontSize: fontSize,
      gradient: ToyVerseTheme.goldGradient,
      glowColor: ToyVerseTheme.accentGold,
      textColor: Colors.white,
    );
  }

  factory ToyButton.secondary({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double height = 50,
    double? width,
    double fontSize = 14,
  }) {
    return ToyButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      height: height,
      width: width,
      fontSize: fontSize,
      isSecondary: true,
      textColor: ToyVerseTheme.textDark,
    );
  }

  factory ToyButton.outline({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    double height = 50,
    double? width,
    double fontSize = 14,
    Color borderColor = ToyVerseTheme.primaryNavy,
  }) {
    return ToyButton(
      text: text,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      height: height,
      width: width,
      fontSize: fontSize,
      color: Colors.transparent,
      textColor: borderColor,
      isSecondary: false,
    );
  }

  @override
  State<ToyButton> createState() => _ToyButtonState();
}

class _ToyButtonState extends State<ToyButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? ToyVerseTheme.radiusButton;
    final defaultGradient = widget.gradient ?? ToyVerseTheme.royalNavyGradient;
    final bgColor = widget.color ?? ToyVerseTheme.primaryNavy;
    final isTransparent = widget.color == Colors.transparent;

    List<BoxShadow> shadows;
    if (isTransparent) {
      shadows = [];
    } else if (widget.isSecondary) {
      shadows = ToyVerseTheme.subtleShadow(opacity: 0.04, blur: 12);
    } else if (widget.glowColor != null) {
      shadows = ToyVerseTheme.glowShadow(widget.glowColor!, opacity: 0.35, blur: 16);
    } else {
      shadows = ToyVerseTheme.premiumShadow(blur: 16, offset: const Offset(0, 4));
    }

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isLoading && widget.onPressed != null) widget.onPressed!();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? EdgeInsets.symmetric(
            horizontal: widget.width != null ? 12 : 24,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isSecondary ? Colors.white : (isTransparent ? Colors.transparent : (widget.gradient == null && widget.color != null ? bgColor : null)),
            gradient: widget.isSecondary || isTransparent ? null : (widget.color != null && widget.gradient == null ? null : defaultGradient),
            borderRadius: BorderRadius.circular(effectiveRadius),
            border: widget.isSecondary
                ? Border.all(color: Colors.grey.shade300.withValues(alpha: 0.8), width: 1.0)
                : (isTransparent
                    ? Border.all(color: widget.textColor.withValues(alpha: 0.4), width: 1.2)
                    : Border.all(color: Colors.white.withValues(alpha: 0.22), width: 0.9)),
            boxShadow: shadows,
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: widget.isSecondary ? ToyVerseTheme.textDark : widget.textColor,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          color: widget.isSecondary ? ToyVerseTheme.textDark : widget.textColor,
                          size: widget.fontSize + 4,
                        ),
                        const SizedBox(width: 6),
                      ],
                      Flexible(
                        child: Text(
                          widget.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w700,
                            color: widget.isSecondary ? ToyVerseTheme.textDark : widget.textColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
