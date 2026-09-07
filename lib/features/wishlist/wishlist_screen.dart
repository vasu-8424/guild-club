import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_typography.dart';
import 'package:shimmer/shimmer.dart';

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
    final asyncUserData = ref.watch(userDataProvider);
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
                      onPressed: () => context.pop(),
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                      ),
                    ),
                    Text(
                      'Wishlist ❤️ (${favProducts.length})',
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
                child: asyncUserData.when(
                  loading: () => _buildShimmerGrid(),
                  error: (e, s) => _buildWishlistContent(context, ref, favProducts),
                  data: (data) => _buildWishlistContent(context, ref, favProducts),
                ),
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
        ref.invalidate(userDataProvider);
        await ref.read(userDataProvider.future);
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

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.54,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
