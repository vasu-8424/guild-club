import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/supabase_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/toy_button.dart';
import '../../providers/app_providers.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> with TickerProviderStateMixin {
  final GlobalKey _balancePillKey = GlobalKey();
  final GlobalKey _wheelSourceKey = GlobalKey();
  final GlobalKey _streakSourceKey = GlobalKey();

  late final AnimationController _wheelController;
  late final Animation<double> _wheelRotation;
  late final AnimationController _wheelSettleController;
  late final Animation<double> _wheelSettleScale;
  late final Animation<double> _wheelSettleGlow;

  late final AnimationController _coinCounterController;
  late IntTween _coinValueTween;
  int _displayCoinValue = 0;

  late final AnimationController _streakController;

  final Set<String> _claimedCoupons = <String>{};
  final Map<String, AnimationController> _couponBurstControllers = <String, AnimationController>{};

  final List<_CoinParticle> _particles = <_CoinParticle>[];
  late final AnimationController _particleTicker;

  bool _isSpinning = false;
  bool _hasSpunToday = false;
  double _settledAngle = 0;
  double _spinStartAngle = 0;
  double _spinEndAngle = 0;

  static const List<_WheelReward> _wheelRewards = [
    _WheelReward(label: '+20', coins: 20, color: Color(0xFFFFD86B)),
    _WheelReward(label: '+50', coins: 50, color: Color(0xFF6FE7C8)),
    _WheelReward(label: '+80', coins: 80, color: Color(0xFF92B9FF)),
    _WheelReward(label: '+30', coins: 30, color: Color(0xFFFFB59A)),
    _WheelReward(label: '+60', coins: 60, color: Color(0xFFC8A6FF)),
    _WheelReward(label: '+40', coins: 40, color: Color(0xFFFFE88E)),
  ];

  @override
  void initState() {
    super.initState();

    final initialCoins = ref.read(userProvider).rewardCoins;
    _displayCoinValue = initialCoins;
    _coinValueTween = IntTween(begin: initialCoins, end: initialCoins);

    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _wheelRotation = CurvedAnimation(
      parent: _wheelController,
      curve: const Cubic(0.05, 0.88, 0.18, 1.0),
    );

    _wheelSettleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _wheelSettleScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _wheelSettleController, curve: Curves.easeOutBack),
    );
    _wheelSettleGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _wheelSettleController, curve: Curves.easeOutExpo),
    );

    _coinCounterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 740),
    )
      ..addListener(() {
        final value = _coinValueTween.evaluate(_coinCounterController);
        if (value != _displayCoinValue && mounted) {
          setState(() => _displayCoinValue = value);
        }
      });

    _streakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _particleTicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_tickParticles);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(userProvider);
      _animateCoinCounterTo(user.rewardCoins);

      // Verify today's activity status directly from Supabase
      if (user.id.isNotEmpty) {
        final activity = await SupabaseService.fetchTodayActivity(user.id);
        if (mounted && activity.spunToday) {
          setState(() {
            _hasSpunToday = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _wheelController.dispose();
    _wheelSettleController.dispose();
    _coinCounterController.dispose();
    _streakController.dispose();
    _particleTicker.dispose();
    for (final controller in _couponBurstControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _animateCoinCounterTo(int target) {
    _coinValueTween = IntTween(begin: _displayCoinValue, end: target);
    _coinCounterController
      ..stop()
      ..reset();

    _coinCounterController.forward();
  }

  Rect? _globalRectFromKey(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) {
      return null;
    }
    final render = context.findRenderObject();
    if (render is! RenderBox) {
      return null;
    }
    final topLeft = render.localToGlobal(Offset.zero);
    return topLeft & render.size;
  }

  void _emitCoinTrail({required GlobalKey sourceKey, required int count}) {
    final from = _globalRectFromKey(sourceKey);
    final to = _globalRectFromKey(_balancePillKey);
    if (from == null || to == null) {
      return;
    }

    final start = from.center;
    final end = to.center;
    final rng = math.Random();

    for (var i = 0; i < count; i++) {
      final jitter = Offset(rng.nextDouble() * 18 - 9, rng.nextDouble() * 18 - 9);
      _particles.add(
        _CoinParticle(
          start: start + jitter,
          control: Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 80 - rng.nextDouble() * 40),
          end: end + Offset(rng.nextDouble() * 12 - 6, rng.nextDouble() * 8 - 4),
          duration: 520 + rng.nextInt(180),
          size: 5 + rng.nextDouble() * 3,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
    if (!_particleTicker.isAnimating) {
      _particleTicker.repeat();
    }
  }

  void _tickParticles() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _particles.removeWhere((p) => p.progress(now) >= 1);
    if (_particles.isEmpty && _particleTicker.isAnimating) {
      _particleTicker.stop();
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _claimCoupon(String code, int requiredCoins) {
    if (_claimedCoupons.contains(code)) {
      return;
    }

    final user = ref.read(userProvider);
    if (user.rewardCoins < requiredCoins) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not enough coins to redeem this reward.'),
          backgroundColor: ToyVerseTheme.accentCoral,
        ),
      );
      return;
    }

    ref.read(userProvider.notifier).addCoins(-requiredCoins);
    setState(() {
      _claimedCoupons.add(code);
    });

    _animateCoinCounterTo(ref.read(userProvider).rewardCoins);
    _emitCoinTrail(sourceKey: _streakSourceKey, count: 8);

    final controller = _couponBurstControllers.putIfAbsent(
      code,
      () => AnimationController(vsync: this, duration: const Duration(milliseconds: 560)),
    );
    controller.forward(from: 0);
  }

  Future<void> _spinWheel() async {
    if (_isSpinning) return;

    if (_hasSpunToday) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You've already claimed today's spin! Come back tomorrow for more Guild Coins ✨"),
            backgroundColor: ToyVerseTheme.primaryRed,
          ),
        );
      }
      return;
    }

    setState(() => _isSpinning = true);

    final user = ref.read(userProvider);
    final spinResult = await SupabaseService.claimDailySpin(user.id);

    if (spinResult.alreadySpun) {
      if (mounted) {
        setState(() {
          _hasSpunToday = true;
          _isSpinning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(spinResult.message),
            backgroundColor: ToyVerseTheme.primaryRed,
          ),
        );
      }
      return;
    }

    final wonAmount = spinResult.wonAmount;
    final landingIndex = spinResult.segmentIndex.clamp(0, _wheelRewards.length - 1);
    final newBalance = spinResult.newBalance;

    final segmentAngle = (math.pi * 2) / _wheelRewards.length;
    final targetSegmentCenter = (landingIndex * segmentAngle) + (segmentAngle / 2);
    const pointerAngle = -math.pi / 2;
    final localTarget = (pointerAngle - targetSegmentCenter) % (math.pi * 2);
    final rng = math.Random();
    final turns = 4 + rng.nextDouble() * 2.5;
    final targetAngle = (_settledAngle + turns * math.pi * 2 + localTarget) % (math.pi * 2);

    _spinStartAngle = _settledAngle;
    _spinEndAngle = targetAngle + turns * math.pi * 2;
    _wheelController
      ..stop()
      ..reset();

    await _wheelController.forward();

    _settledAngle = targetAngle;
    _hasSpunToday = true;

    ref.read(userProvider.notifier).setCoins(newBalance);
    _animateCoinCounterTo(newBalance);

    if (mounted) {
      setState(() => _isSpinning = false);
      _showPrizeModal(wonAmount);
    }
  }

  void _showPrizeModal(int wonAmount) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: ToyVerseTheme.primaryRed,
              child: Icon(Icons.stars_rounded, color: Colors.white, size: 44),
            ),
            const SizedBox(height: 14),
            Text(
              'You won +$wonAmount Guild Coins! 🎉',
              style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Coins added & synchronized with your wallet server-side.',
              style: AppTypography.bodyMedium.copyWith(color: ToyVerseTheme.textMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ToyVerseTheme.primaryNavy),
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Great',
                style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkDailyActivityStatus() async {
    if (!SupabaseService.isInitialized || SupabaseService.client == null) return;
    try {
      final user = SupabaseService.client!.auth.currentUser;
      if (user == null) return;
      final today = DateTime.now().toIso8601String().split('T')[0];
      final res = await SupabaseService.client!
          .from('daily_activity')
          .select('spun_today')
          .eq('user_id', user.id)
          .eq('activity_date', today)
          .maybeSingle();

      if (res != null && res['spun_today'] == true && mounted) {
        setState(() => _hasSpunToday = true);
      }
    } catch (_) {}
  }

  Future<void> _handleRefreshWallet() async {
    final user = ref.read(userProvider);
    final freshBalance = await SupabaseService.fetchUserWalletBalance(user.id);
    if (freshBalance != null && mounted) {
      ref.read(userProvider.notifier).setCoins(freshBalance);
      _animateCoinCounterTo(freshBalance);
    }
    await _checkDailyActivityStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    if (_displayCoinValue != user.rewardCoins && !_coinCounterController.isAnimating) {
      _animateCoinCounterTo(user.rewardCoins);
    }

    return Scaffold(
      body: Stack(
        children: [
          FloatingCloudsBackground(
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _handleRefreshWallet,
                color: ToyVerseTheme.primaryRed,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (context.canPop()) ...[
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            'Rewards Playground',
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: ToyVerseTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      key: _balancePillKey,
                      padding: const EdgeInsets.all(20),
                      color: ToyVerseTheme.primaryPurple,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available ToyCoins',
                                style: AppTypography.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.92)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: ToyVerseTheme.primaryYellow, size: 30),
                                  const SizedBox(width: 8),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 260),
                                    transitionBuilder: (child, animation) {
                                      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutExpo);
                                      return SlideTransition(
                                        position: Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(curved),
                                        child: FadeTransition(opacity: curved, child: child),
                                      );
                                    },
                                    child: Text(
                                      '$_displayCoinValue',
                                      key: ValueKey<int>(_displayCoinValue),
                                      style: AppTypography.priceNumeral.copyWith(
                                        fontSize: 33,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SparkleBadge(label: 'VIP PARENT LEVEL 2', backgroundColor: ToyVerseTheme.primaryOrange),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      key: _streakSourceKey,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Login Streak',
                            style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(7, (index) {
                              final filled = index < 5;
                              final start = index * 0.1;
                              final end = math.min(1.0, start + 0.28);
                              final anim = CurvedAnimation(
                                parent: _streakController,
                                curve: Interval(start, end, curve: Curves.easeOutBack),
                              );
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: index == 6 ? 0 : 6),
                                  child: AnimatedBuilder(
                                    animation: anim,
                                    builder: (context, child) {
                                      final t = anim.value;
                                      final progress = filled ? t : t * 0.15;
                                      return Transform.scale(
                                        scale: 0.92 + (0.08 * t),
                                        child: Container(
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: Color.lerp(
                                              Colors.white,
                                              filled ? ToyVerseTheme.primaryMintGreen : Colors.grey.shade200,
                                              progress,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: filled
                                                  ? ToyVerseTheme.primaryMintGreen.withValues(alpha: 0.8)
                                                  : Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'D${index + 1}',
                                              style: AppTypography.priceNumeral.copyWith(
                                                fontSize: 12,
                                                color: filled && t > 0.4 ? Colors.white : ToyVerseTheme.textMuted,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Daily Spin Wheel',
                            style: AppTypography.displayMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 0,
                                child: Container(
                                  width: 0,
                                  height: 0,
                                  decoration: const BoxDecoration(),
                                ),
                              ),
                              Container(
                                key: _wheelSourceKey,
                                width: 220,
                                height: 220,
                                alignment: Alignment.center,
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_wheelController, _wheelSettleController]),
                                  builder: (context, child) {
                                    final spinProgress = _wheelRotation.value;
                                    final spinAngle = _spinStartAngle + ((_spinEndAngle - _spinStartAngle) * spinProgress);
                                    final scale = _wheelSettleScale.value;
                                    final glow = _wheelSettleGlow.value;
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        width: 196,
                                        height: 196,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: ToyVerseTheme.primaryYellow.withValues(alpha: 0.28 * glow),
                                              blurRadius: 30 * glow,
                                              spreadRadius: 6 * glow,
                                            ),
                                            const BoxShadow(color: Colors.black26, blurRadius: 14, offset: Offset(0, 8)),
                                          ],
                                        ),
                                        child: CustomPaint(
                                          painter: _WheelPainter(rotation: spinAngle, rewards: _wheelRewards),
                                          child: const Center(
                                            child: CircleAvatar(
                                              radius: 32,
                                              backgroundColor: Colors.white,
                                              child: Icon(Icons.stars_rounded, color: ToyVerseTheme.primaryNavy, size: 34),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 2,
                                child: Icon(Icons.arrow_drop_down_rounded, size: 38, color: ToyVerseTheme.primaryNavy),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ToyButton(
                            text: _hasSpunToday
                                ? 'Come Back Tomorrow ✨'
                                : (_isSpinning ? 'Spinning...' : 'Spin Now'),
                            gradient: _hasSpunToday ? null : ToyVerseTheme.orangeYellowGradient,
                            color: _hasSpunToday ? Colors.grey.shade400 : null,
                            isLoading: _isSpinning,
                            onPressed: () => _spinWheel(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Coupon Redemption',
                      style: AppTypography.displayMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    _buildVoucherCard(
                      title: 'Flat Rs100 Off Coupon',
                      costLabel: 'Requires 200 ToyCoins',
                      code: 'GUILDCLUB100',
                      requiredCoins: 200,
                    ),
                    _buildVoucherCard(
                      title: 'Free Express Delivery',
                      costLabel: 'Requires 150 ToyCoins',
                      code: 'FREESHIP',
                      requiredCoins: 150,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: CustomPaint(
            painter: _CoinParticlePainter(_particles),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    ),
  );
  }

  Widget _buildVoucherCard({
    required String title,
    required String costLabel,
    required String code,
    required int requiredCoins,
  }) {
    final claimed = _claimedCoupons.contains(code);
    final burstController = _couponBurstControllers.putIfAbsent(
      code,
      () => AnimationController(vsync: this, duration: const Duration(milliseconds: 560)),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _SpringPress(
        onTap: claimed ? null : () => _claimCoupon(code, requiredCoins),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.centerRight,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(costLabel, style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted)),
                    ],
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutBack,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: claimed ? ToyVerseTheme.primaryMintGreen : ToyVerseTheme.primaryRoyalBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      claimed ? 'Claimed' : 'Redeem',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (claimed)
                IgnorePointer(
                  child: AnimatedBuilder(
                    animation: burstController,
                    builder: (context, child) {
                      final t = Curves.easeOutExpo.transform(burstController.value);
                      return Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.4 + t,
                          child: CustomPaint(
                            size: const Size(52, 52),
                            painter: _CheckBurstPainter(progress: t),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpringPress extends StatefulWidget {
  const _SpringPress({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_SpringPress> createState() => _SpringPressState();
}

class _SpringPressState extends State<_SpringPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        scale: _pressed ? 0.96 : 1.0,
        child: widget.child,
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({required this.rotation, required this.rewards});

  final double rotation;
  final List<_WheelReward> rewards;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final segmentAngle = (math.pi * 2) / rewards.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    for (var i = 0; i < rewards.length; i++) {
      final reward = rewards[i];
      final start = -math.pi / 2 + (i * segmentAngle);
      final paint = Paint()..color = reward.color;
      canvas.drawArc(rect, start, segmentAngle, true, paint);

      final labelAngle = start + (segmentAngle / 2);
      final textOffset = Offset(
        center.dx + math.cos(labelAngle) * (radius * 0.62),
        center.dy + math.sin(labelAngle) * (radius * 0.62),
      );

      final span = TextSpan(
        text: reward.label,
        style: AppTypography.priceNumeral.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: ToyVerseTheme.textDark,
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, textOffset - Offset(tp.width / 2, tp.height / 2));
    }

    canvas.restore();

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawCircle(center, radius - 1, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.rewards != rewards;
  }
}

class _CheckBurstPainter extends CustomPainter {
  const _CheckBurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width / 2) * progress;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = ToyVerseTheme.primaryMintGreen.withValues(alpha: 1 - progress);
    canvas.drawCircle(center, radius, ringPaint);

    final particlePaint = Paint()..color = ToyVerseTheme.primaryMintGreen.withValues(alpha: 1 - progress);
    for (var i = 0; i < 8; i++) {
      final a = (math.pi * 2 * i) / 8;
      final p = Offset(center.dx + math.cos(a) * radius, center.dy + math.sin(a) * radius);
      canvas.drawCircle(p, 2.2 * (1 - progress), particlePaint);
    }

    final checkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = ToyVerseTheme.primaryMintGreen.withValues(alpha: progress);
    final path = Path()
      ..moveTo(center.dx - 8, center.dy)
      ..lineTo(center.dx - 2, center.dy + 6)
      ..lineTo(center.dx + 9, center.dy - 6);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant _CheckBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _CoinParticlePainter extends CustomPainter {
  const _CoinParticlePainter(this.particles);

  final List<_CoinParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final particle in particles) {
      final t = particle.progress(now).clamp(0.0, 1.0);
      final p = _quadraticBezier(particle.start, particle.control, particle.end, t);
      final paint = Paint()
        ..color = ToyVerseTheme.primaryYellow.withValues(alpha: 1 - t)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(p, particle.size * (1 - (t * 0.5)), paint);
    }
  }

  Offset _quadraticBezier(Offset a, Offset b, Offset c, double t) {
    final mt = 1 - t;
    return Offset(
      mt * mt * a.dx + 2 * mt * t * b.dx + t * t * c.dx,
      mt * mt * a.dy + 2 * mt * t * b.dy + t * t * c.dy,
    );
  }

  @override
  bool shouldRepaint(covariant _CoinParticlePainter oldDelegate) {
    return true;
  }
}

class _WheelReward {
  const _WheelReward({required this.label, required this.coins, required this.color});

  final String label;
  final int coins;
  final Color color;
}

class _CoinParticle {
  _CoinParticle({
    required this.start,
    required this.control,
    required this.end,
    required this.duration,
    required this.size,
  }) : startTime = DateTime.now().millisecondsSinceEpoch;

  final Offset start;
  final Offset control;
  final Offset end;
  final int duration;
  final double size;
  final int startTime;

  double progress(int nowMs) => (nowMs - startTime) / duration;
}
