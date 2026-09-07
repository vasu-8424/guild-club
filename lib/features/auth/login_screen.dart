import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/supabase_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoggingIn = false;
  bool _typingCompleted = false;
  late final AnimationController _idleFloatController;

  @override
  void initState() {
    super.initState();
    // Subtle, restrained idle floating / bobbing loop (3-second duration)
    _idleFloatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idleFloatController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    HapticFeedback.lightImpact();
    setState(() => _isLoggingIn = true);

    try {
      // --- Step 1: Try native Google Sign-In (Android with Play Services) ---
      final googleAccount = await SupabaseService.signInWithGoogleNative();
      final supabaseUser = SupabaseService.currentUser;

      if (supabaseUser != null) {
        _loginWithSupabaseUser(supabaseUser);
        return;
      }

      if (googleAccount != null) {
        final deterministicId = SupabaseService.getDeterministicUUID(googleAccount.id);
        ref.read(userProvider.notifier).setUser(
          UserModel(
            id: deterministicId,
            fullName: googleAccount.displayName ?? googleAccount.email.split('@').first,
            email: googleAccount.email,
            phone: '',
            avatarUrl: googleAccount.photoUrl ?? '',
            rewardCoins: 250,
            children: [],
          ),
        );
        ref.invalidate(userDataProvider);
        if (mounted) {
          setState(() => _isLoggingIn = false);
          context.go('/');
        }
        return;
      }

      // --- Step 2: Supabase OAuth (same-tab redirect on web, system browser on mobile) ---
      if (SupabaseService.isInitialized && SupabaseService.client != null) {
        late final StreamSubscription<AuthState> sub;
        sub = SupabaseService.client!.auth.onAuthStateChange.listen((data) async {
          final event = data.event;
          if (event == AuthChangeEvent.signedIn) {
            sub.cancel();
            final user = SupabaseService.client!.auth.currentUser;
            if (user != null && mounted) {
              _loginWithSupabaseUser(user);
            }
          }
        });

        final launched = await SupabaseService.client!.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? Uri.base.origin : 'io.supabase.toyverse://login-callback',
          queryParams: {'prompt': 'select_account'},
          authScreenLaunchMode:
              kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
        );

        if (!launched && mounted) {
          sub.cancel();
          setState(() => _isLoggingIn = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not initiate Google sign-in. Please check connection.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() => _isLoggingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supabase is running in offline mode. Please verify .env keys.'),
            backgroundColor: Color(0xFF6B21A8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingIn = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in notice: ${e.toString().split('\n').first}'),
            backgroundColor: const Color(0xFFE11D48),
          ),
        );
      }
    }
  }

  Future<void> _loginWithSupabaseUser(User supabaseUser) async {
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
        children: [],
      ),
    );
    ref.invalidate(userDataProvider);

    if (mounted && loginBonusPayload.bonusGranted > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loginBonusPayload.message),
          backgroundColor: ToyVerseTheme.primaryMintGreen,
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoggingIn = false);
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 750;

    return Scaffold(
      backgroundColor: ToyVerseTheme.primaryRed,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // 1. TOP HERO 3D CHARACTER SECTION (~46-50% Height)
                    Expanded(
                      flex: isCompact ? 48 : 52,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          AnimatedBuilder(
                            animation: _idleFloatController,
                            builder: (context, child) {
                              // Gentle vertical bobbing (-5px to +5px) with smooth sine curve
                              final double dy = (-5.0 + 10.0 * _idleFloatController.value);
                              return Transform.translate(
                                offset: Offset(0, dy),
                                child: child,
                              );
                            },
                            child: Image.asset(
                              'assets/images/auth_hero_character.png',
                              fit: BoxFit.contain,
                              alignment: Alignment.bottomCenter,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/login_hero.png',
                                  fit: BoxFit.contain,
                                  alignment: Alignment.bottomCenter,
                                );
                              },
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 650.ms, curve: Curves.easeOutCubic).scale(
                            begin: const Offset(0.94, 0.94),
                            end: const Offset(1.0, 1.0),
                            duration: 700.ms,
                            curve: Curves.easeOutBack,
                          ),
                    ),

                    const SizedBox(height: 12),

                    // 2. MIDDLE SECTION: CURSIVE ACCENT + TYPEWRITER HEADLINE + SUBLINE
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cursive Accent Line
                        Text(
                          'where imagination plays ✨',
                          textAlign: TextAlign.center,
                          style: AppTypography.accentScript.copyWith(
                            fontSize: isCompact ? 18 : 21,
                            color: Colors.white.withValues(alpha: 0.92),
                            letterSpacing: 0.3,
                          ),
                        ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

                        const SizedBox(height: 8),

                        // Animated Typewriter Headline
                        _TypewriterHeadline(
                          text: 'Welcome to Guild Club',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: isCompact ? 26 : 31,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.6,
                            height: 1.15,
                          ),
                          charDuration: const Duration(milliseconds: 44),
                          onComplete: () {
                            if (mounted && !_typingCompleted) {
                              setState(() => _typingCompleted = true);
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        // Subline (Fades in after headline completes typing)
                        AnimatedOpacity(
                          opacity: _typingCompleted ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          child: Text(
                            'Curated toys, early learning & child development',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              fontSize: isCompact ? 13 : 14.5,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withValues(alpha: 0.90),
                              letterSpacing: 0.1,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 3. BOTTOM SECTION: REFINED REFINED GOOGLE SIGN-IN PILL BUTTON
                    Expanded(
                      flex: isCompact ? 26 : 28,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Centered Refined Pill Button
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 275),
                              child: _MagneticGoogleButton(
                                isLoading: _isLoggingIn,
                                onPressed: _isLoggingIn ? null : _handleGoogleSignIn,
                                googleMark: _buildGoogleGLogo(),
                              ),
                            ),
                          ).animate().fadeIn(duration: 500.ms, delay: 350.ms).slideY(
                                begin: 0.2,
                                end: 0,
                                curve: Curves.easeOutCubic,
                              ),

                          SizedBox(height: isCompact ? 16 : 24),
                        ],
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

  /// Authentic 4-color Vector Google 'G' Logo
  Widget _buildGoogleGLogo() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        size: const Size(20, 20),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Typewriter Animation for the Headline
class _TypewriterHeadline extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration charDuration;
  final VoidCallback? onComplete;

  const _TypewriterHeadline({
    required this.text,
    required this.style,
    this.charDuration = const Duration(milliseconds: 44),
    this.onComplete,
  });

  @override
  State<_TypewriterHeadline> createState() => _TypewriterHeadlineState();
}

class _TypewriterHeadlineState extends State<_TypewriterHeadline> {
  int _displayedCount = 0;
  Timer? _typingTimer;
  Timer? _cursorTimer;
  bool _showCursor = true;
  int _cursorBlinkCount = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  void _startTyping() {
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _typingTimer = Timer.periodic(widget.charDuration, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_displayedCount < widget.text.length) {
          setState(() => _displayedCount++);
        } else {
          timer.cancel();
          widget.onComplete?.call();
          _startCursorBlink();
        }
      });
    });
  }

  void _startCursorBlink() {
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 420), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _showCursor = !_showCursor;
        _cursorBlinkCount++;
      });
      if (_cursorBlinkCount >= 5) {
        timer.cancel();
        setState(() => _showCursor = false);
      }
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _cursorTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleText = widget.text.substring(0, _displayedCount);
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(text: visibleText, style: widget.style),
          if (_showCursor)
            TextSpan(
              text: ' |',
              style: widget.style.copyWith(
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}

/// Refined Magnetic Google Sign-In Pill Button with Spring & Breath Feedback
class _MagneticGoogleButton extends StatefulWidget {
  const _MagneticGoogleButton({
    required this.isLoading,
    required this.onPressed,
    required this.googleMark,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final Widget googleMark;

  @override
  State<_MagneticGoogleButton> createState() => _MagneticGoogleButtonState();
}

class _MagneticGoogleButtonState extends State<_MagneticGoogleButton>
    with TickerProviderStateMixin {
  static const _buttonSpring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 22,
  );
  late final AnimationController _pressController;
  late final AnimationController _hoverController;
  late final AnimationController _breathController;
  Offset _magneticOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 280),
    );
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pressController.dispose();
    _hoverController.dispose();
    _breathController.dispose();
    super.dispose();
  }

  void _press() {
    _pressController.animateWith(
      SpringSimulation(_buttonSpring, _pressController.value, 1.0, 0.0),
    );
  }

  void _release() {
    _pressController.animateWith(
      SpringSimulation(_buttonSpring, _pressController.value, 0.0, 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return MouseRegion(
          onEnter: (_) => _hoverController.forward(),
          onExit: (_) {
            _hoverController.reverse();
            setState(() => _magneticOffset = Offset.zero);
          },
          child: Listener(
            onPointerHover: (event) {
              final center = Offset(constraints.maxWidth / 2, 25);
              final delta = event.localPosition - center;
              setState(() => _magneticOffset = Offset(
                    (delta.dx * 0.035).clamp(-3.5, 3.5).toDouble(),
                    (delta.dy * 0.025).clamp(-1.8, 1.8).toDouble(),
                  ));
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: widget.onPressed == null ? null : (_) => _press(),
              onTapCancel: widget.onPressed == null ? null : _release,
              onTapUp: widget.onPressed == null
                  ? null
                  : (_) {
                      _release();
                      widget.onPressed!();
                    },
              child: Semantics(
                button: true,
                enabled: widget.onPressed != null,
                label: 'Continue with Google',
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _pressController,
                    _hoverController,
                    _breathController,
                  ]),
                  builder: (context, child) {
                    final press = _pressController.value;
                    final hover = _hoverController.value;
                    final breath = _breathController.value;
                    final pressedScale = 1.0 - (press * 0.03);

                    return Transform.translate(
                      offset: _magneticOffset * hover,
                      child: Transform.scale(
                        scale: pressedScale + (hover * 0.008),
                        child: Container(
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.16 + breath * 0.06),
                                blurRadius: 14 + breath * 6,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: const Color(0xFF881337).withValues(alpha: 0.22 + breath * 0.12),
                                blurRadius: 18 + breath * 8,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: widget.isLoading
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    widget.googleMark,
                                    const SizedBox(width: 10),
                                    Text(
                                      'Continue with Google',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Color(0xFF64748B),
                                      size: 16,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Pixel-Perfect Official 4-Color Vector Google 'G' Logo Painter
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 48x48 official viewport scaling
    final double scale = size.width / 48.0;
    canvas.save();
    canvas.scale(scale, scale);

    final Paint paint = Paint()..style = PaintingStyle.fill;

    // 1. Blue segment (Right bar & vertical arc)
    paint.color = const Color(0xFF4285F4);
    final bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.6, 20.0)
      ..lineTo(24.0, 20.0)
      ..lineTo(24.0, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.5, 32.16, 36.2)
      ..lineTo(39.89, 42.2)
      ..cubicTo(44.4, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, paint);

    // 2. Green segment (Bottom arc)
    paint.color = const Color(0xFF34A853);
    final greenPath = Path()
      ..moveTo(24.0, 48.0)
      ..cubicTo(30.48, 48.0, 35.93, 45.87, 39.89, 42.2)
      ..lineTo(32.16, 36.2)
      ..cubicTo(30.01, 37.65, 27.24, 38.5, 24.0, 38.5)
      ..cubicTo(17.74, 38.5, 12.43, 34.28, 10.53, 28.59)
      ..lineTo(2.56, 34.78)
      ..cubicTo(6.6, 42.63, 14.66, 48.0, 24.0, 48.0)
      ..close();
    canvas.drawPath(greenPath, paint);

    // 3. Yellow segment (Bottom left arc)
    paint.color = const Color(0xFFFBBC05);
    final yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.6, 9.77, 24.0)
      ..cubicTo(9.77, 22.4, 10.05, 20.86, 10.53, 19.41)
      ..lineTo(2.56, 13.22)
      ..cubicTo(0.92, 16.46, 0.0, 20.12, 0.0, 24.0)
      ..cubicTo(0.0, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 4. Red segment (Top arc)
    paint.color = const Color(0xFFEA4335);
    final redPath = Path()
      ..moveTo(24.0, 9.5)
      ..cubicTo(27.54, 9.5, 30.71, 10.72, 33.21, 13.1)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.9, 2.38, 30.47, 0.0, 24.0, 0.0)
      ..cubicTo(14.66, 0.0, 6.6, 5.37, 2.56, 13.22)
      ..lineTo(10.53, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.5, 24.0, 9.5)
      ..close();
    canvas.drawPath(redPath, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
