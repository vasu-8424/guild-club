import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../core/widgets/toy_button.dart';
import '../../models/listing_model.dart';
import '../../providers/app_providers.dart';

class ListingDetailScreen extends ConsumerStatefulWidget {
  final String listingId;
  final ListingModel? listing;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    this.listing,
  });

  @override
  ConsumerState<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends ConsumerState<ListingDetailScreen> {
  int _selectedPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final listingAsync = ref.watch(singleListingFamilyProvider(widget.listingId));
    final listing = widget.listing ?? listingAsync.asData?.value;

    if (listing == null && listingAsync.isLoading) {
      return const Scaffold(
        backgroundColor: ToyVerseTheme.bgWarmWhite,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ToyVerseTheme.primaryRoyalBlue),
          ),
        ),
      );
    }

    if (listing == null) {
      return Scaffold(
        backgroundColor: ToyVerseTheme.bgWarmWhite,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: ToyVerseTheme.textMuted),
                const SizedBox(height: 12),
                Text('Listing not found', style: AppTypography.displayMedium.copyWith(fontSize: 16)),
                const SizedBox(height: 16),
                ToyButton(
                  text: 'Go Back',
                  width: 140,
                  height: 40,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/categories');
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allPhotos = [
      listing.primaryPhotoUrl,
      ...listing.galleryUrls.where((u) => u != listing.primaryPhotoUrl),
    ];

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
                            child: Text(
                              listing.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ToyVerseTheme.textDark,
                              ),
                            ),
                          ),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: ToyVerseTheme.bgLightGray,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Icon(Icons.share_outlined, color: ToyVerseTheme.textDark, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Scrollable Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Photo Display
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(ToyVerseTheme.radiusHeroCard),
                          boxShadow: [
                            BoxShadow(
                              color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(ToyVerseTheme.radiusHeroCard),
                          child: CachedNetworkImage(
                            imageUrl: allPhotos[_selectedPhotoIndex.clamp(0, allPhotos.length - 1)],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: ToyVerseTheme.bgLightBlue,
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

                      // Gallery Thumbnails
                      if (allPhotos.length > 1) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: allPhotos.length,
                            itemBuilder: (context, idx) {
                              final isSelected = _selectedPhotoIndex == idx;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedPhotoIndex = idx),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 60,
                                  height: 60,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? ToyVerseTheme.primaryRed : Colors.transparent,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: allPhotos[idx],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Title & Badges
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (listing.isVerified) ...[
                                  const SparkleBadge(
                                    label: 'VERIFIED PROVIDER ✓',
                                    backgroundColor: ToyVerseTheme.primaryRoyalBlue,
                                    fontSize: 9,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                Text(
                                  listing.name,
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: ToyVerseTheme.textDark,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Rating Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFD97706)),
                                    const SizedBox(width: 4),
                                    Text(
                                      listing.rating.toStringAsFixed(1),
                                      style: AppTypography.displayMedium.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${listing.reviewCount} reviews',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Key Info Highlights (Glass Cards with Heraldic Soft Shadows)
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.location_on_rounded,
                              iconColor: ToyVerseTheme.primaryRed,
                              title: 'Address & Distance',
                              value: '${listing.address}, ${listing.city}${listing.distanceKm != null ? ' (${listing.distanceKm} km away)' : ''}',
                            ),
                            const Divider(height: 22),
                            _buildInfoRow(
                              icon: Icons.payments_outlined,
                              iconColor: ToyVerseTheme.primaryRoyalBlue,
                              title: 'Fee / Pricing Range',
                              value: listing.priceRange.isNotEmpty ? listing.priceRange : 'Available on request',
                            ),
                            if (listing.ageGroup.isNotEmpty) ...[
                              const Divider(height: 22),
                              _buildInfoRow(
                                icon: Icons.child_care_rounded,
                                iconColor: ToyVerseTheme.primaryNavy,
                                title: 'Age Group Suitability',
                                value: listing.ageGroup,
                              ),
                            ],
                            if (listing.operatingHours.isNotEmpty) ...[
                              const Divider(height: 22),
                              _buildInfoRow(
                                icon: Icons.schedule_rounded,
                                iconColor: ToyVerseTheme.primaryRedLight,
                                title: 'Operating Hours',
                                value: listing.operatingHours,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Full Description
                      Text(
                        'About this Center / Program',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ToyVerseTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        listing.description.isNotEmpty
                            ? listing.description
                            : 'Dedicated program certified for excellence and personalized attention.',
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 14,
                          height: 1.55,
                          color: ToyVerseTheme.textDark.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // 3. Sticky Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (listing.whatsapp.isNotEmpty) ...[
              Expanded(
                child: ToyButton(
                  text: 'WhatsApp Chat 💬',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                  ),
                  height: 48,
                  fontSize: 13,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening WhatsApp for ${listing.phone}...'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ToyButton(
                text: 'Call Center 📞',
                gradient: ToyVerseTheme.royalNavyGradient,
                height: 48,
                fontSize: 13,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Connecting to ${listing.phone}...'),
                      backgroundColor: ToyVerseTheme.primaryNavy,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ToyVerseTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ToyVerseTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
