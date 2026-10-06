import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/supabase_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../models/user_model.dart';
import '../../providers/app_providers.dart';

/// Minimal, clean white canvas splash screen for Guild Club.
/// Features a pure white screen, the centered Guild Club logo emblem, and the title wordmark.
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
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _taglineOpacity;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _routeExitController = AnimationController(
      vsync: this,
      duration: _routeFadeDuration,
    );

    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.7, curve: _revealCurve),
      ),
    );

    _logoOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _titleOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.85, curve: _revealCurve),
    );

    _taglineOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _routeExitController]),
          builder: (context, child) {
            final fadeOut = _isTransitioning ? (1.0 - exitFade) : 1.0;

            return Opacity(
              opacity: fadeOut,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Centered Guild Club Logo Emblem
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoOpacity,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.18),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/app_logo.png',
                                width: 130,
                                height: 130,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Guild Club Title
                      FadeTransition(
                        opacity: _titleOpacity,
                        child: Text(
                          'Guild Club',
                          textAlign: TextAlign.center,
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: ToyVerseTheme.primaryNavy,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Elegant Subtitle
                      FadeTransition(
                        opacity: _taglineOpacity,
                        child: Text(
                          'A considered world of play ✨',
                          textAlign: TextAlign.center,
                          style: AppTypography.accentScript.copyWith(
                            fontSize: 18,
                            color: ToyVerseTheme.textDark.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
