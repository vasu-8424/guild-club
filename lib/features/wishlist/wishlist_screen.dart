import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';

import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/toy_button.dart';
import '../../models/product_model.dart';
import '../../providers/app_providers.dart';
import '../product/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistProvider);
    final allProducts = ref.watch(productsProvider);
    final favProducts = allProducts.where((p) => wishlist.contains(p.id)).toList();

    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go('/'),
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                      ),
                    ),
                    Text(
                      'Liked Items ❤️ (${favProducts.length})',
                      style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Wishlist share link copied to clipboard! 🔗')),
                        );
                      },
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.share_rounded, color: ToyVerseTheme.primaryRoyalBlue),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _buildWishlistContent(context, ref, favProducts),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWishlistContent(BuildContext context, WidgetRef ref, List<ProductModel> favProducts) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(wishlistProvider.notifier).refreshWishlist();
      },
      child: favProducts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 70, color: ToyVerseTheme.textMuted),
                      const SizedBox(height: 16),
                      Text('Your Wishlist is Empty', style: AppTypography.accentScript.copyWith(fontSize: 26, color: ToyVerseTheme.textMuted)),
                      const SizedBox(height: 8),
                      Text('Explore toys & tap the heart to save favorites!', style: AppTypography.bodyMedium.copyWith(color: ToyVerseTheme.textMuted)),
                      const SizedBox(height: 24),
                      ToyButton(
                        text: 'Explore Toys 🚀',
                        width: 200,
                        onPressed: () => context.go('/'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.54,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: favProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(product: favProducts[index], width: double.infinity);
              },
            ),
    );
  }
}
