import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/supabase_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../models/product_model.dart';
import '../../providers/app_providers.dart';
import 'widgets/room_fit_modal.dart';

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
  ProductModel? _directProduct;
  bool _isLoadingDirect = false;

  @override
  void initState() {
    super.initState();
    _imageController = PageController();
    _fetchProductIfNeeded();
  }

  Future<void> _fetchProductIfNeeded() async {
    final products = ref.read(productsProvider);
    final exists = products.any((p) => p.id == widget.productId);
    if (!exists && SupabaseService.isInitialized && SupabaseService.client != null) {
      setState(() => _isLoadingDirect = true);
      try {
        final response = await SupabaseService.client!
            .from('products')
            .select('*')
            .eq('id', widget.productId)
            .maybeSingle();

        if (response != null && mounted) {
          setState(() {
            _directProduct = ProductModel.fromJson(response);
            _isLoadingDirect = false;
          });
        } else if (mounted) {
          setState(() => _isLoadingDirect = false);
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingDirect = false);
      }
    }
  }

  @override
  void dispose() {
    _imageController.dispose();
    super.dispose();
  }

  /// Resolves the studio background color for the hero product image area
  LinearGradient _resolveHeroGradient(ProductModel product) {
    final key = '${product.categorySlug}_${product.id}'.toLowerCase();
    if (key.contains('play') || key.contains('school')) {
      return const LinearGradient(
        colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (key.contains('child')) {
      return const LinearGradient(
        colors: [Color(0xFF991B1B), Color(0xFF450A0A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (key.contains('interior')) {
      return const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final categories = ref.watch(categoriesProvider);

    final product = products.where((p) => p.id == widget.productId).firstOrNull ??
        _directProduct;

    final wishlist = ref.watch(wishlistProvider);
    final isFavorite = product != null ? wishlist.contains(product.id) : false;
    final cart = ref.watch(cartProvider);
    final cartItemCount = cart.fold<int>(0, (sum, item) => sum + item.quantity);

    if (product == null) {
      if (_isLoadingDirect) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(ToyVerseTheme.primaryRed),
            ),
          ),
        );
      }

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF94A3B8)),
              const SizedBox(height: 16),
              Text(
                'Product Not Found',
                style: AppTypography.titleLarge.copyWith(color: const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              Text(
                'This item is no longer available in the database.',
                style: AppTypography.bodyMedium.copyWith(color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final isRoomFitEligible = product.isRoomFitSupported(categories);
    final heroGradient = _resolveHeroGradient(product);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. UNIFIED NATURAL SCROLL VIEW (Image + Details scroll together)
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. HERO PRODUCT IMAGE STUDIO SECTION (Scrolls away with page)
                Container(
                  width: double.infinity,
                  height: 380,
                  decoration: BoxDecoration(
                    gradient: heroGradient,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Product Image Carousel
                      Positioned.fill(
                        top: 70,
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
                                : '';

                            if (imageUrl.isEmpty) {
                              return const Center(
                                child: Icon(Icons.toys_rounded, size: 72, color: Colors.white70),
                              );
                            }

                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                                      size: 72,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Carousel Dot Indicators
                      if (product.imageUrls.length > 1)
                        Positioned(
                          bottom: 18,
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
                                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),

                // B. PRODUCT DETAILS EDITORIAL BODY (Continuous flow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Title, Subtitle & Price
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.title,
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.4,
                                    height: 1.2,
                                  ),
                                ),
                                if (product.subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    product.subtitle,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${product.price.toInt()}',
                                style: AppTypography.priceNumeral.copyWith(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (product.originalPrice > product.price) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '₹${product.originalPrice.toInt()}',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    decoration: TextDecoration.lineThrough,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // 2. Refined Meta Badges (Rating, Age, Stock)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Rating Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFDE68A), width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, size: 15, color: Color(0xFFD97706)),
                                const SizedBox(width: 4),
                                Text(
                                  '${product.rating} (${product.reviewCount})',
                                  style: AppTypography.bodySmall.copyWith(
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
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                            ),
                            child: Text(
                              'Ages ${product.ageBadgeText}',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),

                          // In Stock Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  'In Stock',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 3. Description Paragraph
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'High-quality equipment crafted with premium durability and safety standards for schools, therapy centers, and homes.',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 14,
                          height: 1.55,
                          color: const Color(0xFF334155),
                        ),
                      ),

                      // 4. AI Room Fit Advisor Card (Prominently featured on all products)
                      if (isRoomFitEligible) ...[
                        const SizedBox(height: 22),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          size: 18,
                                          color: Color(0xFF38BDF8),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'AI Room Fit Advisor',
                                        style: AppTypography.titleMedium.copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      'GEMINI VISION',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF34D399),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Upload a photo of your room to get intelligent space analysis, lighting optimization, and child safety clearances.',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              if (product.dimensions != null && product.dimensions!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.straighten_rounded, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Approx. Dimensions: ${product.dimensions}',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => RoomFitModal.show(context, product),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF0F172A),
                                    padding: const EdgeInsets.symmetric(vertical: 13),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 17,
                                    color: Color(0xFF0F172A),
                                  ),
                                  label: Text(
                                    'Launch AI Room Placement Advisor 📷',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      // 5. Hyderabad Fulfillment & Dispatch Policy
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.local_shipping_rounded,
                                    size: 18,
                                    color: ToyVerseTheme.primaryRoyalBlue,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Delivery & Dispatch Policy',
                                  style: AppTypography.titleMedium.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: ToyVerseTheme.primaryRoyalBlue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: const Color(0xFF334155),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Dispatched from: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                        TextSpan(text: 'Guild Club Store, Hyderabad'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFEA580C)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: const Color(0xFF334155),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Hyderabad Local: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                        TextSpan(text: '2 to 3 days delivery'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.public_rounded, size: 16, color: Color(0xFF0F172A)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: const Color(0xFF334155),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Out of Hyderabad: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                        TextSpan(text: '7 to 8 working days delivery'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFF16A34A)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontSize: 12,
                                        color: const Color(0xFF334155),
                                      ),
                                      children: const [
                                        TextSpan(text: 'Free Delivery: ', style: TextStyle(fontWeight: FontWeight.w700)),
                                        TextSpan(text: 'On all orders above ₹499 (GST 5% included at checkout)'),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Generous bottom spacing so all content scrolls cleanly above fixed bottom bar
                      const SizedBox(height: 110),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. FLOATING TOP NAVIGATION BAR (Back Button + Cart Bag)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircularIconButton(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                    _CircularIconButton(
                      icon: Icons.shopping_bag_outlined,
                      badgeCount: cartItemCount,
                      onPressed: () => context.push('/cart'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. FIXED BOTTOM ACTION BAR (Wishlist + Add to Cart)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).padding.bottom + 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _SquareWishlistButton(
                    isFavorite: isFavorite,
                    onToggle: () {
                      HapticFeedback.lightImpact();
                      ref.read(wishlistProvider.notifier).toggleWishlist(product.id);
                    },
                  ),
                  const SizedBox(width: 14),
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
                            backgroundColor: const Color(0xFF15803D),
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
          ),
        ],
      ),
    );
  }
}

/// Minimalist Circular Navigation Button
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

/// Luxury Add to Cart Button Reusing Shape-Morphing Sequence
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
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
