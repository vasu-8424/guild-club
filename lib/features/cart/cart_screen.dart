import 'dart:math' as math;
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../core/widgets/toy_button.dart';
import '../../providers/app_providers.dart';

class CartEntryMorphData {
  const CartEntryMorphData({required this.originRect});

  final Rect originRect;
}

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, this.morphData});

  final CartEntryMorphData? morphData;

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> with TickerProviderStateMixin {
  bool _isGiftWrapped = false;
  final TextEditingController _couponController = TextEditingController();
  double _appliedDiscount = 0.0;
  String? _appliedCouponCode;

  late final AnimationController _entryMorphController;
  late final Animation<double> _entryMorphAnimation;
  final Set<String> _removingItemIds = <String>{};

  @override
  void initState() {
    super.initState();
    _entryMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _entryMorphAnimation = CurvedAnimation(
      parent: _entryMorphController,
      curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      reverseCurve: Curves.easeOutExpo,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryMorphController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _couponController.dispose();
    _entryMorphController.dispose();
    super.dispose();
  }

  Future<void> _removeItemWithAnimation(String productId) async {
    if (_removingItemIds.contains(productId)) {
      return;
    }
    setState(() => _removingItemIds.add(productId));
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) {
      return;
    }
    ref.read(cartProvider.notifier).removeFromCart(productId);
    setState(() => _removingItemIds.remove(productId));
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalAmountProvider);
    final shippingFee = subtotal > 1500 || subtotal == 0 ? 0.0 : 99.0;
    final giftWrapFee = _isGiftWrapped ? 49.0 : 0.0;
    final finalTotal = (subtotal + shippingFee + giftWrapFee - _appliedDiscount).clamp(0.0, 999999.0);

    return Scaffold(
      body: Stack(
        children: [
          FloatingCloudsBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SpringPressable(
                          onTap: () => context.pop(),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                          ),
                        ),
                        Text(
                          'Shopping Cart 🛒',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: ToyVerseTheme.textDark,
                          ),
                        ),
                        SpringPressable(
                          onTap: cartItems.isEmpty ? null : () => ref.read(cartProvider.notifier).clearCart(),
                          child: Text(
                            'Clear',
                            style: AppTypography.bodyLarge.copyWith(
                              color: ToyVerseTheme.accentCoral,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: cartItems.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: ToyVerseTheme.primaryPurple.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.shopping_cart_outlined, size: 64, color: ToyVerseTheme.primaryPurple),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Your Cart is Empty',
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: ToyVerseTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Sanctioned emotional copy spot for accentScript cursive style
                                Text(
                                  'Explore and add magical toys for your kids ✨',
                                  style: AppTypography.accentScript.copyWith(
                                    fontSize: 18,
                                    color: ToyVerseTheme.primaryPurple,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ToyButton.gold(
                                  text: 'Shop Now →',
                                  width: 180,
                                  onPressed: () => context.go('/'),
                                ),
                              ],
                            ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1, end: 0),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: cartItems.length,
                                  itemBuilder: (context, index) {
                                    final item = cartItems[index];
                                    final isRemoving = _removingItemIds.contains(item.product.id);
                                    return TweenAnimationBuilder<double>(
                                      duration: const Duration(milliseconds: 180),
                                      curve: Curves.easeOutExpo,
                                      tween: Tween<double>(begin: 1, end: isRemoving ? 0 : 1),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.scale(
                                            alignment: Alignment.center,
                                            scale: 0.92 + (0.08 * value),
                                            child: IgnorePointer(
                                              ignoring: isRemoving,
                                              child: child,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.06),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                            BoxShadow(
                                              color: ToyVerseTheme.primaryPurple.withValues(alpha: 0.04),
                                              blurRadius: 18,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: GlassCard(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(16),
                                                child: CachedNetworkImage(
                                                  imageUrl: item.product.imageUrls.first,
                                                  width: 80,
                                                  height: 80,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.product.title,
                                                      style: AppTypography.displayMedium.copyWith(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.w700,
                                                        color: ToyVerseTheme.textDark,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '₹${item.product.price.toInt()} each',
                                                      style: AppTypography.bodyMedium.copyWith(
                                                        fontSize: 12,
                                                        color: ToyVerseTheme.textMuted,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      '₹${item.totalPrice.toInt()}',
                                                      style: AppTypography.priceNumeral.copyWith(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w700,
                                                        color: ToyVerseTheme.primaryOrange,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                children: [
                                                  QuantityStepper(
                                                    quantity: item.quantity,
                                                    onDecrement: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
                                                    onIncrement: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  SpringPressable(
                                                    onTap: () => _removeItemWithAnimation(item.product.id),
                                                    child: Text(
                                                      'Remove',
                                                      style: AppTypography.bodySmall.copyWith(
                                                        color: ToyVerseTheme.accentCoral,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ).animate().fadeIn(duration: 350.ms, delay: (index * 30).ms).slideX(begin: 0.08, end: 0);
                                  },
                                ),
                                const SizedBox(height: 16),
                                GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.card_giftcard_rounded, color: ToyVerseTheme.primaryOrange, size: 30),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Add Gift Wrapping (+₹49)',
                                              style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                                            ),
                                            Text(
                                              'Includes colorful ribbon and greeting card',
                                              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Switch(
                                        value: _isGiftWrapped,
                                        activeThumbColor: ToyVerseTheme.primaryOrange,
                                        onChanged: (val) => setState(() => _isGiftWrapped = val),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GlassCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Promo Code / Coupon', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _couponController,
                                              textCapitalization: TextCapitalization.characters,
                                              decoration: InputDecoration(
                                                hintText: 'e.g. TOYVERSE100',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SpringPressable(
                                            onTap: () {
                                              if (_couponController.text.trim().toUpperCase() == 'TOYVERSE100') {
                                                setState(() {
                                                  _appliedDiscount = 100.0;
                                                  _appliedCouponCode = 'TOYVERSE100';
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Coupon Applied! Saved ₹100'), backgroundColor: ToyVerseTheme.primaryMintGreen),
                                                );
                                              } else {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Use code TOYVERSE100 for ₹100 off.'), backgroundColor: ToyVerseTheme.primaryOrange),
                                                );
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                              decoration: BoxDecoration(
                                                color: ToyVerseTheme.primaryRoyalBlue,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.primaryRoyalBlue, opacity: 0.25, blur: 8),
                                              ),
                                              child: Text('Apply', style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_appliedCouponCode != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Applied: $_appliedCouponCode (-₹${_appliedDiscount.toInt()})',
                                          style: AppTypography.bodyLarge.copyWith(
                                            fontSize: 12,
                                            color: ToyVerseTheme.primaryMintGreen,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GlassCard(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Order Summary', style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 12),
                                      _buildSummaryRow('Subtotal', '₹${subtotal.toInt()}'),
                                      _buildSummaryRow('Delivery Fee', shippingFee == 0 ? 'FREE' : '₹${shippingFee.toInt()}'),
                                      if (_isGiftWrapped) _buildSummaryRow('Gift Packaging', '₹49'),
                                      if (_appliedDiscount > 0) _buildSummaryRow('Promo Discount', '-₹${_appliedDiscount.toInt()}', isGreen: true),
                                      const Divider(height: 24),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Total Amount', style: AppTypography.displayMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
                                          Text(
                                            '₹${finalTotal.toInt()}',
                                            style: AppTypography.priceNumeral.copyWith(fontSize: 22, color: ToyVerseTheme.primaryOrange),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  if (cartItems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: ToyButton(
                        text: 'Proceed to Checkout (₹${finalTotal.toInt()})',
                        gradient: ToyVerseTheme.orangeYellowGradient,
                        onPressed: () => context.push('/checkout'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IgnorePointer(
            ignoring: _entryMorphController.status == AnimationStatus.completed,
            child: AnimatedBuilder(
              animation: _entryMorphAnimation,
              builder: (context, child) {
                final progress = _entryMorphAnimation.value;
                if (progress >= 0.999) {
                  return const SizedBox.shrink();
                }

                final size = MediaQuery.of(context).size;
                final beginRect = widget.morphData?.originRect ?? Rect.fromLTWH(size.width - 60, 26, 36, 36);
                final targetRect = Rect.fromLTWH(0, size.height * 0.16, size.width, size.height * 0.84);
                final currentRect = Rect.lerp(beginRect, targetRect, progress.clamp(0.0, 1.0))!;
                final radius = BorderRadius.lerp(
                  BorderRadius.circular(beginRect.shortestSide / 2),
                  const BorderRadius.vertical(top: Radius.circular(30)),
                  progress,
                )!;

                return Stack(
                  children: [
                    Opacity(
                      opacity: 0.2 * progress,
                      child: Container(color: Colors.black),
                    ),
                    Positioned(
                      left: currentRect.left,
                      top: currentRect.top,
                      width: math.max(1, currentRect.width),
                      height: math.max(1, currentRect.height),
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: _MorphSheetPainter(
                            color: Colors.white.withValues(alpha: 0.9),
                            radius: radius,
                            shadowColor: Colors.black.withValues(alpha: 0.08),
                            blurSigma: 18,
                          ),
                          child: ClipRRect(
                            borderRadius: radius,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 4 + (10 * progress),
                                sigmaY: 4 + (10 * progress),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: ToyVerseTheme.textMuted)),
          Text(value, style: AppTypography.priceNumeral.copyWith(fontSize: 14, color: isGreen ? ToyVerseTheme.primaryMintGreen : ToyVerseTheme.textDark)),
        ],
      ),
    );
  }
}

class _MorphSheetPainter extends CustomPainter {
  const _MorphSheetPainter({
    required this.color,
    required this.radius,
    required this.shadowColor,
    required this.blurSigma,
  });

  final Color color;
  final BorderRadius radius;
  final Color shadowColor;
  final double blurSigma;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndCorners(
      rect,
      topLeft: radius.topLeft,
      topRight: radius.topRight,
      bottomLeft: radius.bottomLeft,
      bottomRight: radius.bottomRight,
    );

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma * 0.5);
    canvas.drawRRect(rrect.shift(const Offset(0, 6)), shadowPaint);

    final fillPaint = Paint()..color = color;
    canvas.drawRRect(rrect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _MorphSheetPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.blurSigma != blurSigma;
  }
}

class QuantityStepper extends StatefulWidget {
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> with TickerProviderStateMixin {
  late final AnimationController _minusController;
  late final AnimationController _plusController;

  @override
  void initState() {
    super.initState();
    _minusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _plusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 120),
    );
  }

  @override
  void dispose() {
    _minusController.dispose();
    _plusController.dispose();
    super.dispose();
  }

  void _runPress(AnimationController controller, VoidCallback action) {
    controller.forward(from: 0.0).then((_) {
      if (mounted) {
        controller.reverse();
      }
    });
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ToyVerseTheme.bgLightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpringPressable(
            onTap: () => _runPress(_minusController, widget.onDecrement),
            child: _StepperActionButton(
              icon: Icons.remove,
              controller: _minusController,
            ),
          ),
          SizedBox(
            width: 26,
            child: Center(
              child: DigitRollText(value: widget.quantity),
            ),
          ),
          SpringPressable(
            onTap: () => _runPress(_plusController, widget.onIncrement),
            child: _StepperActionButton(
              icon: Icons.add,
              controller: _plusController,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperActionButton extends StatelessWidget {
  const _StepperActionButton({
    required this.icon,
    required this.controller,
  });

  final IconData icon;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(controller.value);
        final scale = 1.0 + (0.14 * (1 - (2 * t - 1).abs()));
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class DigitRollText extends StatelessWidget {
  const DigitRollText({super.key, required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutExpo);
        final offset = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(curved);
        return ClipRect(
          child: SlideTransition(
            position: offset,
            child: FadeTransition(opacity: curved, child: child),
          ),
        );
      },
      child: Text(
        '$value',
        key: ValueKey<int>(value),
        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
