import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../core/widgets/toy_button.dart';
import '../../models/category_model.dart';
import '../../models/listing_model.dart';
import '../../providers/app_providers.dart';

class CategoryListingScreen extends ConsumerWidget {
  final String categoryId;
  final CategoryModel? category;

  const CategoryListingScreen({
    super.key,
    required this.categoryId,
    this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(categoryListingsFamilyProvider(categoryId));
    final categoryAsync = ref.watch(categoryDetailFamilyProvider(categoryId));

    final resolvedCategory = category ?? categoryAsync.asData?.value;
    final title = resolvedCategory?.name ?? 'Category Listings';

    return Scaffold(
      backgroundColor: ToyVerseTheme.bgWarmWhite,
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Glass Header with BackdropFilter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          SpringPressable(
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/categories');
                              }
                            },
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: ToyVerseTheme.bgLightGray,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(Icons.arrow_back_ios_new_rounded, color: ToyVerseTheme.textDark, size: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ToyVerseTheme.textDark,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                listingsAsync.when(
                                  data: (listings) => Text(
                                    '${listings.length} verified listings available',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: ToyVerseTheme.textMuted,
                                    ),
                                  ),
                                  loading: () => Text(
                                    'Finding nearby centers...',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      color: ToyVerseTheme.textMuted,
                                    ),
                                  ),
                                  error: (_, __) => const SizedBox.shrink(),
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

              const SizedBox(height: 8),

              // 2. Listings List / Designed Empty State
              Expanded(
                child: listingsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ToyVerseTheme.primaryRoyalBlue),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Error loading listings: $err'),
                  ),
                  data: (listings) {
                    if (listings.isEmpty) {
                      return _buildDesignedEmptyState(context, title);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return _buildScannableListingCard(context, listing, index);
                      },
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

  /// Scannable, uncluttered listing card as specified:
  /// Primary photo, name, rating + review count, distance/city, price_range, verified badge.
  Widget _buildScannableListingCard(BuildContext context, ListingModel listing, int index) {
    return SpringPressable(
      onTap: () {
        context.push('/listing/${listing.id}', extra: listing);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ToyVerseTheme.radiusProductCard),
          border: Border.all(
            color: Colors.grey.shade200.withValues(alpha: 0.8),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.06),
              blurRadius: 16,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Photo + Distance Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(ToyVerseTheme.radiusProductCard)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: listing.primaryPhotoUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: ToyVerseTheme.bgLightBlue,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(ToyVerseTheme.primaryRoyalBlue),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: ToyVerseTheme.bgLightBlue,
                        child: const Icon(Icons.broken_image_rounded, color: ToyVerseTheme.textMuted, size: 36),
                      ),
                    ),
                  ),
                ),

                // Gradient Overlay at bottom of photo
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(ToyVerseTheme.radiusProductCard)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.35),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Verified Badge (top-left)
                if (listing.isVerified)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'VERIFIED',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Distance / City Badge (bottom-left)
                Positioned(
                  bottom: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          listing.distanceKm != null
                              ? '${listing.distanceKm} km • ${listing.city}'
                              : listing.city,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Card Body (Name, Rating + Reviews, Price Range)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          listing.name,
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: ToyVerseTheme.textDark,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Rating Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                            const SizedBox(width: 3),
                            Text(
                              listing.rating.toStringAsFixed(1),
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF92400E),
                              ),
                            ),
                            Text(
                              ' (${listing.reviewCount})',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 9.5,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Divider
                  Divider(color: Colors.grey.shade100, height: 1),

                  const SizedBox(height: 10),

                  // Footer: Price Range Tag + View Details Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (listing.priceRange.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.payments_outlined, size: 14, color: ToyVerseTheme.primaryRed),
                            const SizedBox(width: 4),
                            Text(
                              listing.priceRange,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ToyVerseTheme.textDark,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ToyVerseTheme.primaryRoyalBlue,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded, size: 13, color: ToyVerseTheme.primaryRoyalBlue),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (index * 40).ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildDesignedEmptyState(BuildContext context, String categoryName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Ambient Emblem
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.primaryRoyalBlue, opacity: 0.2, blur: 18),
                  ),
                  child: const Icon(Icons.explore_off_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 32),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SparkleBadge(
              label: 'COMING SOON TO YOUR AREA 📍',
              backgroundColor: ToyVerseTheme.primaryNavy,
              fontSize: 9,
            ),
            const SizedBox(height: 14),
            Text(
              'No Listings Yet in $categoryName',
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ToyVerseTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'We are actively onboarding verified partners and certified specialists in this category.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: ToyVerseTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ToyButton(
              text: 'Explore Other Categories →',
              width: 220,
              height: 46,
              fontSize: 13,
              gradient: ToyVerseTheme.royalNavyGradient,
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 450.ms).scale(begin: const Offset(0.94, 0.94), end: const Offset(1.0, 1.0)),
    );
  }
}
