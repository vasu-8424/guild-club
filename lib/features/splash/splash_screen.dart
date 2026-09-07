import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/supabase_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';

/// Single continuous canvas splash screen for Guild Club.
/// Features a deep navy obsidian background, a radial-masked heraldic crest emblem reveal,
/// a non-clipped Outfit "Guild Club" wordmark, and an accentScript tagline.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _revealCurve = Cubic(0.16, 1.0, 0.3, 1.0);
  static const Duration _routeFadeDuration = Duration(milliseconds: 380);

  late final AnimationController _entranceController;
  late final AnimationController _routeExitController;
  late final Animation<double> _maskReveal;
  late final Animation<double> _mascotLift;
  late final Animation<double> _wordmarkOpacity;
  late final Animation<double> _taglineOpacity;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1560),
    )..forward();

    _routeExitController = AnimationController(
      vsync: this,
      duration: _routeFadeDuration,
    );

    _maskReveal = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.05, 0.65, curve: _revealCurve),
    );

    _mascotLift = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.10, 0.75, curve: _revealCurve),
      ),
    );

    _wordmarkOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.45, 0.85, curve: _revealCurve),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    );

    _checkSessionAndNavigate();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _routeExitController.dispose();
    super.dispose();
  }

  Future<void> _routeWithCrossFade(String destination) async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);
    await _routeExitController.forward();
    if (!mounted) return;
    context.go(destination);
  }

  Future<void> _checkSessionAndNavigate() async {
    // 1.6s total display before smooth cross-fade transition
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      final supabaseUser = SupabaseService.client!.auth.currentUser;
      if (supabaseUser != null) {
        final meta = supabaseUser.userMetadata ?? {};
        final freshBalance = await SupabaseService.fetchUserWalletBalance(supabaseUser.id);
        final loginBonusPayload = await SupabaseService.claimDailyLoginBonus();
        final finalCoins = loginBonusPayload.newBalance ?? freshBalance ?? 0;

        ref.read(userProvider.notifier).setUser(
              UserModel(
                id: supabaseUser.id,
                fullName: meta['full_name']?.toString() ??
                    meta['name']?.toString() ??
                    supabaseUser.email?.split('@').first ??
                    'Member',
                email: supabaseUser.email ?? '',
                phone: supabaseUser.phone ?? '',
                avatarUrl: meta['avatar_url']?.toString() ??
                    meta['picture']?.toString() ??
                    '',
                rewardCoins: finalCoins,
                children: const [],
              ),
            );

        if (mounted && loginBonusPayload.bonusGranted > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loginBonusPayload.message),
              backgroundColor: ToyVerseTheme.primaryMintGreen,
            ),
          );
        }

        if (mounted) await _routeWithCrossFade('/');
        return;
      }
    }

    if (mounted) await _routeWithCrossFade('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final exitFade = Curves.easeOutExpo.transform(_routeExitController.value);

    return Scaffold(
      backgroundColor: ToyVerseTheme.bgWarmWhite,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          color: ToyVerseTheme.bgWarmWhite,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_entranceController, _routeExitController]),
            builder: (context, child) {
              final breathe = 0.5 + 0.5 * math.sin(_entranceController.value * math.pi);
              final fadeOut = _isTransitioning ? (1.0 - exitFade) : 1.0;

              return Opacity(
                opacity: fadeOut,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // 1. Pure Radial-Gradient Ambient Light Wash (Upper Third)
                    // Primary Red Ambient Glow (Closer, brighter, extends off-screen top-left)
                    Positioned(
                      top: -120 + breathe * 12,
                      left: -80 + breathe * 8,
                      child: _RadialAmbientGlow(
                        color: ToyVerseTheme.primaryRed,
                        size: 440,
                        centerOpacity: 0.52 + breathe * 0.05,
                      ),
                    ),

                    // Secondary Red Ambient Glow (Further, dimmer, extends off-screen top-right for depth)
                    Positioned(
                      top: -60 - breathe * 10,
                      left: 110 - breathe * 6,
                      child: _RadialAmbientGlow(
                        color: ToyVerseTheme.primaryRed,
                        size: 360,
                        centerOpacity: 0.40 + breathe * 0.04,
                      ),
                    ),

                    // 2. Single Restrained Blue Accent Glow (Soft accent light behind/near shield area)
                    Positioned(
                      top: 40 + breathe * 8,
                      left: 70 + breathe * 6,
                      child: _RadialAmbientGlow(
                        color: ToyVerseTheme.primaryRoyalBlue,
                        size: 200,
                        centerOpacity: 0.32 + breathe * 0.03,
                      ),
                    ),

                    // 3. Heraldic Crest Particle Trail
                    Center(
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(320, 300),
                          painter: _HeraldicParticleTrail(_maskReveal.value),
                        ),
                      ),
                    ),

                    // 4. Centered Guild Club Heraldic Crest Emblem (Single Hero Visual, No Floating Panels)
                    Align(
                      alignment: const Alignment(0, -0.22),
                      child: Transform.translate(
                        offset: Offset(0, _mascotLift.value),
                        child: ClipPath(
                          clipper: _RadialRevealClipper(_maskReveal.value),
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ToyVerseTheme.primaryRed.withValues(alpha: 0.38),
                                  blurRadius: 48,
                                  spreadRadius: 8,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.28),
                                  blurRadius: 32,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: CustomPaint(
                              painter: _GuildClubCrestEmblemPainter(progress: _maskReveal.value),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 5. "Guild Club" Wordmark & Tagline on Same Canvas
                    Align(
                      alignment: const Alignment(0, 0.54),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Unconstrained Continuous Wordmark (Zero Character Clipping / Detachment)
                            _UnconstrainedWordmark(reveal: _wordmarkOpacity.value),
                            const SizedBox(height: 12),
                            // Red Glowing Divider Accent Line
                            Transform.scale(
                              scaleX: _wordmarkOpacity.value,
                              child: Container(
                                width: 68,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  gradient: ToyVerseTheme.coralGlowGradient,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.primaryRed, opacity: 0.6, blur: 10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            // Tagline in accentScript style (High contrast dark navy)
                            Opacity(
                              opacity: _taglineOpacity.value,
                              child: Transform.translate(
                                offset: Offset(0, 10 * (1 - _taglineOpacity.value)),
                                child: Text(
                                  'A considered world of play ✨',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.accentScript.copyWith(
                                    fontSize: 18,
                                    color: ToyVerseTheme.textDark.withValues(alpha: 0.88),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Pure RadialGradient ambient light glow without any flat fills or Gaussian blur filters.
/// Naturally fades from center color at moderate opacity to 0% opacity at the outer boundary.
class _RadialAmbientGlow extends StatelessWidget {
  const _RadialAmbientGlow({
    required this.color,
    required this.size,
    required this.centerOpacity,
  });

  final Color color;
  final double size;
  final double centerOpacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: centerOpacity.clamp(0.0, 1.0)),
                color.withValues(alpha: (centerOpacity * 0.72).clamp(0.0, 1.0)),
                color.withValues(alpha: (centerOpacity * 0.38).clamp(0.0, 1.0)),
                color.withValues(alpha: (centerOpacity * 0.12).clamp(0.0, 1.0)),
                color.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.28, 0.58, 0.84, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadialRevealClipper extends CustomClipper<Path> {
  const _RadialRevealClipper(this.progress);

  final double progress;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height) / 2;
    final currentRadius = maxRadius * progress;

    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: currentRadius));
  }

  @override
  bool shouldReclip(covariant _RadialRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}

/// Unconstrained continuous Wordmark ensuring letter glyphs (including 'b' in 'Club')
/// render with 100% natural font kerning, zero clipping, and zero detached character rendering.
class _UnconstrainedWordmark extends StatelessWidget {
  const _UnconstrainedWordmark({required this.reveal});

  final double reveal;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: reveal.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - reveal.clamp(0.0, 1.0))),
        child: Text(
          'Guild Club',
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: AppTypography.displayLarge.copyWith(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: ToyVerseTheme.textDark,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

/// Custom-drawn Guild Club Heraldic Crest & Shield Emblem (White line-art + Heraldic Red Accent).
class _GuildClubCrestEmblemPainter extends CustomPainter {
  final double progress;

  _GuildClubCrestEmblemPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Deep Glass Background Disc
    final bgPaint = Paint()
      ..color = ToyVerseTheme.primaryNavy.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius - 2, bgPaint);

    // 2. Outer Glass Ring with Subtle Red/Blue Accent
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white.withValues(alpha: 0.3);
    canvas.drawCircle(center, radius - 4, ringPaint);

    // 3. Heraldic Shield Outline (White Line-Art)
    final shieldPath = Path();
    final sw = size.width * 0.52;
    final sh = size.height * 0.58;
    final left = center.dx - sw / 2;
    final top = center.dy - sh / 2 + 4;
    final right = left + sw;
    final bottom = top + sh;

    shieldPath.moveTo(left, top);
    shieldPath.lineTo(right, top);
    shieldPath.lineTo(right, top + sh * 0.45);
    shieldPath.cubicTo(right, bottom - 10, center.dx + 10, bottom, center.dx, bottom + 8);
    shieldPath.cubicTo(center.dx - 10, bottom, left, bottom - 10, left, top + sh * 0.45);
    shieldPath.close();

    // Shield Fill & Stroke
    final shieldFill = Paint()..color = ToyVerseTheme.primaryBlue.withValues(alpha: 0.6);
    canvas.drawPath(shieldPath, shieldFill);

    final shieldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawPath(shieldPath, shieldStroke);

    // 4. Central Guild Crown / Star Emblem with Heraldic Red Fill Accent
    final redAccentPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = ToyVerseTheme.primaryRed;

    final starPath = Path();
    final starCenter = Offset(center.dx, center.dy - 2);
    const outerRadius = 18.0;
    const innerRadius = 8.5;
    for (int i = 0; i < 5; i++) {
      double outerAngle = (i * 72 - 90) * math.pi / 180;
      double innerAngle = (i * 72 + 36 - 90) * math.pi / 180;
      if (i == 0) {
        starPath.moveTo(starCenter.dx + outerRadius * math.cos(outerAngle), starCenter.dy + outerRadius * math.sin(outerAngle));
      } else {
        starPath.lineTo(starCenter.dx + outerRadius * math.cos(outerAngle), starCenter.dy + outerRadius * math.sin(outerAngle));
      }
      starPath.lineTo(starCenter.dx + innerRadius * math.cos(innerAngle), starCenter.dy + innerRadius * math.sin(innerAngle));
    }
    starPath.close();

    canvas.drawPath(starPath, redAccentPaint);

    final starStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white;
    canvas.drawPath(starPath, starStroke);
  }

  @override
  bool shouldRepaint(covariant _GuildClubCrestEmblemPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Particle Trail running behind the Heraldic Crest
class _HeraldicParticleTrail extends CustomPainter {
  const _HeraldicParticleTrail(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final settled = ((progress - 0.2) / 0.8).clamp(0.0, 1.0);
    for (var index = 0; index < 7; index++) {
      final phase = (settled - index * 0.09).clamp(0.0, 1.0);
      if (phase <= 0) continue;
      final radius = 3.0 - index * 0.26;
      final x = size.width * (0.34 + index * 0.046) - phase * 16;
      final y = size.height * (0.64 - index * 0.048) +
          math.sin((phase + index) * math.pi) * 12;
      final paint = Paint()
        ..color = Color.lerp(
          ToyVerseTheme.primaryRedLight,
          ToyVerseTheme.primaryRoyalBlue,
          index / 7,
        )!
            .withValues(alpha: (1 - phase) * 0.5);
      canvas.drawCircle(Offset(x, y), radius, paint);
      canvas.drawCircle(
        Offset(x, y),
        radius * 2.6,
        Paint()
          ..color = paint.color.withValues(alpha: (paint.color.a * 0.25).clamp(0.0, 1.0))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeraldicParticleTrail oldDelegate) =>
      oldDelegate.progress != progress;
}
