import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../models/product_model.dart';
import '../../providers/app_providers.dart';
import '../../repositories/mock_toy_data.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with TickerProviderStateMixin {
  late final PageController _imageController;
  int _selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  /// Resolves the solid background color for the top panel based on product brand/category
  Color _resolvePanelColor(ProductModel product) {
    final key = '${product.categorySlug}_${product.id}'.toLowerCase();
    if (key.contains('play') || key.contains('school') || key.contains('c1000000-0000-0000-0000-000000000001')) {
      return const Color(0xFF1E3A8A); // Royal Navy Blue
    } else if (key.contains('child') || key.contains('c1000000-0000-0000-0000-000000000002')) {
      return const Color(0xFFB91C1C); // Heraldic Crest Red
    } else if (key.contains('interior') || key.contains('c1000000-0000-0000-0000-000000000004')) {
      return const Color(0xFF0F172A); // Obsidian Midnight Navy
    } else if (key.contains('speech') || key.contains('special') || key.contains('occupational')) {
      return const Color(0xFF047857); // Deep Sage Emerald
    }
    // Default fallback to signature Crest Red
    return const Color(0xFFB91C1C);
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => MockToyData.products.first,
    );

    final wishlist = ref.watch(wishlistProvider);
    final isFavorite = wishlist.contains(product.id);
    final cart = ref.watch(cartProvider);
    final cartItemCount = cart.fold<int>(0, (sum, item) => sum + item.quantity);

    final panelColor = _resolvePanelColor(product);
    final size = MediaQuery.of(context).size;
    final topPanelHeight = size.height * 0.52;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: [
            // 1. TOP SOLID COLOR PANEL (Product Image + Carousel)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topPanelHeight + 30, // Slight overflow behind bottom sheet
              child: Container(
                color: panelColor,
                child: SafeArea(
                  bottom: false,
                  child: Stack(
                    children: [
                      // Product Image Swipe Carousel
                      Positioned.fill(
                        top: 50,
                        bottom: 40,
                        child: PageView.builder(
                          controller: _imageController,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _selectedImageIndex = index);
                          },
                          itemCount: product.imageUrls.isNotEmpty ? product.imageUrls.length : 1,
                          itemBuilder: (context, index) {
                            final imageUrl = product.imageUrls.isNotEmpty
                                ? product.imageUrls[index]
                                : 'https://images.unsplash.com/photo-1558060370-d644479cb6f7?q=80&w=800';

                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => const Center(
                                    child: Icon(
                                      Icons.toys_rounded,
                                      size: 80,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ).animate().fadeIn(duration: 500.ms).scale(
                              begin: const Offset(0.92, 0.92),
                              end: const Offset(1, 1),
                              duration: 600.ms,
                              curve: Curves.easeOutBack,
                            ),
                      ),

                      // Minimal Page Dot Indicators (if multiple images exist)
                      if (product.imageUrls.length > 1)
                        Positioned(
                          bottom: 48,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(product.imageUrls.length, (index) {
                              final isSelected = _selectedImageIndex == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isSelected ? 18 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),

                      // Top Navigation Bar (Back Arrow + Cart Bag Button)
                      Positioned(
                        top: 10,
                        left: 20,
                        right: 20,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button (Flat circular button with magnetic press)
                            _CircularIconButton(
                              icon: Icons.arrow_back_rounded,
                              onPressed: () => context.pop(),
                            ),

                            // Cart / Bag Button (Flat circular button with item badge)
                            _CircularIconButton(
                              icon: Icons.shopping_bag_outlined,
                              badgeCount: cartItemCount,
                              onPressed: () => context.push('/cart'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. OVERLAPPING WHITE BOTTOM SHEET (Product Info + Action Row)
            Positioned(
              top: topPanelHeight,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 24,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Scrollable Product Details Content
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & Price Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title & Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.title,
                                        style: AppTypography.displayMedium.copyWith(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF0F172A),
                                          letterSpacing: -0.6,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        product.subtitle.isNotEmpty
                                            ? product.subtitle
                                            : '${product.brandName} · Official Toy',
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 14),

                                // Right-Aligned Price Numeral
                                Text(
                                  '₹${product.price.toInt()}',
                                  style: AppTypography.priceNumeral.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Badges Row (Age, Rating, In-Stock)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                // Star Rating Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 15,
                                        color: Color(0xFFD97706),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${product.rating} (${product.reviewCount})',
                                        style: AppTypography.bodyLarge.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF92400E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Age Recommendation Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'Ages ${product.ageBadgeText}',
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ),

                                // In Stock Status
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'In Stock',
                                    style: AppTypography.bodyLarge.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF15803D),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Description Paragraph
                            Text(
                              product.description.isNotEmpty
                                  ? product.description
                                  : 'Premium high-durability educational toy crafted for children to inspire creative problem solving, sensory motor skills, and imaginative storytelling in a safe and engaging manner.',
                              style: AppTypography.bodyMedium.copyWith(
                                fontSize: 14,
                                height: 1.55,
                                color: const Color(0xFF475569),
                                letterSpacing: 0.1,
                              ),
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // Fixed Bottom Action Bar (Wishlist + Add to Cart)
                    Container(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        14,
                        24,
                        MediaQuery.of(context).padding.bottom + 14,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFF1F5F9),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 1. Wishlist Square Button (Magnetic Pop Heart)
                          _SquareWishlistButton(
                            isFavorite: isFavorite,
                            onToggle: () {
                              HapticFeedback.lightImpact();
                              ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
                            },
                          ),

                          const SizedBox(width: 14),

                          // 2. Large Add to Cart Button (reusing existing shape-morph animation)
                          Expanded(
                            child: _AddToCartButton(
                              label: 'Add to Cart',
                              onPressed: () {
                                ref.read(cartProvider.notifier).addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${product.title} added to Cart! 🛒',
                                      style: AppTypography.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: ToyVerseTheme.primaryMintGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(
                    begin: 0.15,
                    end: 0,
                    duration: 650.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimalist Circular Navigation Button on the Top Panel
class _CircularIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  const _CircularIconButton({
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  State<_CircularIconButton> createState() => _CircularIconButtonState();
}

class _CircularIconButtonState extends State<_CircularIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _pressController.forward(),
      onTapCancel: () => _pressController.reverse(),
      onTapUp: (_) {
        _pressController.reverse();
        HapticFeedback.lightImpact();
        widget.onPressed();
      },
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          final scale = 1.0 - (_pressController.value * 0.08);
          return Transform.scale(
            scale: scale,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (widget.badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFB91C1C),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Center(
                        child: Text(
                          widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Square Wishlist Heart Button with Magnetic Pop Spring Feedback
class _SquareWishlistButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;

  const _SquareWishlistButton({
    required this.isFavorite,
    required this.onToggle,
  });

  @override
  State<_SquareWishlistButton> createState() => _SquareWishlistButtonState();
}

class _SquareWishlistButtonState extends State<_SquareWishlistButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void didUpdateWidget(covariant _SquareWishlistButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFavorite != oldWidget.isFavorite && widget.isFavorite) {
      _popController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedBuilder(
        animation: _popController,
        builder: (context, child) {
          final pop = _popController.value;
          final scale = 1.0 + math.sin(pop * math.pi) * 0.22;

          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: widget.isFavorite
                  ? const Color(0xFFFEE2E2)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isFavorite
                    ? const Color(0xFFFCA5A5)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Transform.scale(
              scale: scale,
              child: Icon(
                widget.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: widget.isFavorite
                    ? const Color(0xFFB91C1C)
                    : const Color(0xFF64748B),
                size: 24,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Add to Cart Button Reusing Shape-Morphing Sequence (Pill → Spinner → Checkmark → Collapse)
class _AddToCartButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const _AddToCartButton({required this.label, required this.onPressed});

  @override
  State<_AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<_AddToCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _didFire = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _trigger() {
    if (_didFire) {
      return;
    }
    _didFire = true;
    _controller.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _didFire = false);
      }
    });
    HapticFeedback.mediumImpact();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = Curves.easeInOutCubic.transform(_controller.value);
        final spinnerAlpha = (progress >= 0.32 && progress <= 0.64) ? 1.0 : 0.0;
        final checkAlpha = progress >= 0.66
            ? (1.0 - ((progress - 0.66) / 0.34)).clamp(0.0, 1.0)
            : 0.0;
        final completePill =
            progress > 0.8 ? (1.0 - ((progress - 0.8) / 0.2)).clamp(0.0, 1.0) : 0.0;

        return GestureDetector(
          onTap: _trigger,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Loading Spinner State
                Opacity(
                  opacity: spinnerAlpha,
                  child: const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),

                // Success Checkmark State
                Opacity(
                  opacity: checkAlpha,
                  child: Transform.scale(
                    scale: 1.0 + (1.0 - progress) * 0.4,
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),

                // Default Button Label State
                Opacity(
                  opacity: (1.0 - spinnerAlpha - checkAlpha - completePill).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
