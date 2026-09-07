import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../models/product_model.dart';
import '../../providers/app_providers.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    this.width,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> with TickerProviderStateMixin {
  // Reused SpringSimulation parameters matching login_screen.dart (stiffness 300, damping 20)
  static const _cardSpring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 20,
  );

  bool _isHovered = false;
  late final AnimationController _pressController;
  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    )..forward();
  }

  @override
  void dispose() {
    _pressController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _onPressDown() {
    _pressController.animateWith(
      SpringSimulation(_cardSpring, _pressController.value, 1.0, 0.0),
    );
  }

  void _onPressUp() {
    _pressController.animateWith(
      SpringSimulation(_cardSpring, _pressController.value, 0.0, 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = ref.watch(wishlistProvider);
    final isFavorite = wishlist.contains(widget.product.id);
    final product = widget.product;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _entryController]),
        builder: (context, child) {
          final press = _pressController.value.clamp(0.0, 1.0);
          final entry = Curves.easeOutCubic.transform(_entryController.value);
          final cardScale = 1.0 - (press * 0.03); // Scale 0.97 on press
          final imageZoomScale = 1.0 + (press * 0.04) + (_isHovered ? 0.04 : 0.0); // Image zoom 1.0 -> 1.04

          return Transform.translate(
            offset: Offset(0, 12 - (entry * 12)),
            child: Opacity(
              opacity: entry.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: cardScale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0),
                  width: widget.width ?? 195,
                  margin: const EdgeInsets.only(right: 14, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ToyVerseTheme.radiusProductCard),
                    border: Border.all(
                      color: _isHovered
                          ? ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.35)
                          : Colors.grey.shade200.withValues(alpha: 0.8),
                      width: _isHovered ? 1.2 : 0.8,
                    ),
                    boxShadow: _isHovered
                        ? ToyVerseTheme.glowShadow(ToyVerseTheme.primaryNavy, opacity: 0.14, blur: 22)
                        : [
                            BoxShadow(
                              color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.06),
                              blurRadius: 16,
                              spreadRadius: 0,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: ToyVerseTheme.primaryPurple.withValues(alpha: 0.04),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ToyVerseTheme.radiusProductCard),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) => _onPressDown(),
                      onTapUp: (_) {
                        _onPressUp();
                        context.push('/product/${product.id}');
                      },
                      onTapCancel: () => _onPressUp(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(ToyVerseTheme.radiusProductCard),
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 125,
                                  width: double.infinity,
                                  color: ToyVerseTheme.bgLightGray,
                                  child: Transform.scale(
                                    scale: imageZoomScale,
                                    child: CachedNetworkImage(
                                      imageUrl: product.imageUrls.first,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Shimmer.fromColors(
                                        baseColor: Colors.grey.shade200,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) => const Icon(
                                        Icons.toys_rounded,
                                        size: 38,
                                        color: ToyVerseTheme.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.18),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.08),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        stops: const [0.0, 0.4, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (product.discountPercentage > 0)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      gradient: ToyVerseTheme.coralGlowGradient,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.accentCoral, opacity: 0.35, blur: 8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
                                        const SizedBox(width: 2),
                                        Text(
                                          '-${product.discountPercentage}%',
                                          style: AppTypography.bodySmall.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: GestureDetector(
                                      onTap: () => ref.read(wishlistProvider.notifier).toggleWishlist(product.id),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: isFavorite
                                              ? ToyVerseTheme.accentCoral.withValues(alpha: 0.15)
                                              : Colors.white.withValues(alpha: 0.85),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isFavorite
                                                ? ToyVerseTheme.accentCoral.withValues(alpha: 0.4)
                                                : Colors.white.withValues(alpha: 0.9),
                                            width: 1.0,
                                          ),
                                          boxShadow: isFavorite
                                              ? ToyVerseTheme.glowShadow(ToyVerseTheme.accentCoral, opacity: 0.25, blur: 8)
                                              : ToyVerseTheme.subtleShadow(opacity: 0.04, blur: 8),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: isFavorite ? ToyVerseTheme.accentCoral : ToyVerseTheme.textDark,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: _GlassBadge(label: product.ageBadgeText, icon: Icons.child_care_rounded),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.brandName.toUpperCase(),
                                  style: AppTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                    color: ToyVerseTheme.primaryRoyalBlue,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: ToyVerseTheme.textDark,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: ToyVerseTheme.accentGold.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 12, color: ToyVerseTheme.accentGold),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${product.rating}',
                                            style: AppTypography.bodyMedium.copyWith(
                                              fontWeight: FontWeight.w800,
                                              color: ToyVerseTheme.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '(${product.reviewCount})',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: ToyVerseTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '₹${product.price.toInt()}',
                                          style: AppTypography.priceNumeral.copyWith(
                                            fontSize: 17,
                                            color: ToyVerseTheme.textDark,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                        if (product.originalPrice > product.price)
                                          Text(
                                            '₹${product.originalPrice.toInt()}',
                                            style: AppTypography.priceNumeral.copyWith(
                                              fontSize: 10,
                                              color: ToyVerseTheme.textMuted,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        gradient: ToyVerseTheme.royalNavyGradient,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.primaryNavy, opacity: 0.25, blur: 8),
                                      ),
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            ref.read(cartProvider.notifier).addToCart(product);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Added "${product.title}" to Cart',
                                                        style: AppTypography.bodyLarge.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: ToyVerseTheme.primaryNavy,
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                duration: const Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                                        ),
                                      ),
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
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _GlassBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
