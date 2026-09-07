import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/gradient_mesh_background.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../providers/app_providers.dart';
import '../../repositories/mock_toy_data.dart';
import '../categories/widgets/category_tile_widget.dart';
import '../product/product_card.dart';
import 'widgets/hero_video_carousel.dart';

class HomeFeedView extends ConsumerStatefulWidget {
  const HomeFeedView({super.key});

  @override
  ConsumerState<HomeFeedView> createState() => _HomeFeedViewState();
}

class _HomeFeedViewState extends ConsumerState<HomeFeedView> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    final user = ref.watch(userProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final hasChildData = selectedChild != null || user.children.isNotEmpty;
    final childProfile = selectedChild ?? (user.children.isNotEmpty ? user.children.first : null);

    return GradientMeshBackground(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 95),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TAPPABLE DEDICATED SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => context.push('/search'),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search toys, schools, therapy services...',
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13.5,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 18),

            // 2. HERO PROMOTIONAL VIDEO CAROUSEL (Clear breathing room)
            const HeroVideoCarousel(),

            const SizedBox(height: 28),

            // 3. EXPLORE CATEGORIES (3-Column Grid on Clean White Studio Container)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(ToyVerseTheme.radiusHeroCard),
                border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                boxShadow: [
                  BoxShadow(
                    color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unified Section Header: Explore Categories + See All Link
                  _SectionHeader(
                    title: 'Explore Categories',
                    onSeeAll: () => context.push('/categories'),
                  ),

                  const SizedBox(height: 18),

                  // 3-Column Top-Level Categories Grid
                  ref.watch(topLevelCategoriesAsyncProvider).when(
                        loading: () => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.64,
                          ),
                          itemCount: 6,
                          itemBuilder: (context, index) => Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        error: (err, stack) => const SizedBox.shrink(),
                        data: (categories) => GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.64,
                          ),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            final cat = categories[index];
                            final isSelected = _selectedCategory == cat.id;

                            return CategoryTileWidget(
                              category: cat,
                              index: index,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() => _selectedCategory = cat.id);
                                if (cat.hasSubcategories || cat.slug == 'child-development-centers') {
                                  context.push('/subcategories/${cat.id}', extra: cat);
                                } else {
                                  context.push('/category-listings/${cat.id}', extra: cat);
                                }
                              },
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // 4. PERSONALIZED RECOMMENDATION SECTION (Rendered only when child data is present)
            if (hasChildData && childProfile != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SectionHeader(
                  title: 'Handpicked for ${childProfile.name} 🎁',
                  onSeeAll: () => context.push('/kids-setup'),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 290,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index])
                        .animate()
                        .fadeIn(duration: 350.ms, delay: (100 + index * 30).ms)
                        .slideX(begin: 0.08, end: 0);
                  },
                ),
              ),
              const SizedBox(height: 28),
            ] else ...[
              // Compact Setup Prompt if no child profile data exists
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => context.push('/kids-setup'),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ToyVerseTheme.primaryRed,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: ToyVerseTheme.glowShadow(
                            ToyVerseTheme.primaryRed,
                            opacity: 0.25,
                            blur: 8,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.child_care_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personalize for Your Child 🎯',
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: ToyVerseTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add age & interests for tailored toy discovery',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 12,
                                color: ToyVerseTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ToyVerseTheme.textMuted),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 28),
            ],

            // 5. DAILY SPIN & WIN REWARDS BANNER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                onTap: () => context.push('/rewards'),
                padding: const EdgeInsets.all(18),
                color: ToyVerseTheme.primaryNavy,
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 40),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Spin & Win Coins 🎰',
                            style: AppTypography.displayMedium.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Spin & win up to ₹500 discount vouchers!',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 450.ms, delay: 150.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // 6. TRENDING NOW & BEST SELLERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _SectionHeader(
                title: 'Trending Now 🔥',
                onSeeAll: () => context.push('/categories'),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 290,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: MockToyData.products.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: MockToyData.products[index])
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (150 + index * 30).ms)
                      .slideX(begin: 0.08, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unified Section Header Component for Consistent Screen Rhythm
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTypography.displayMedium.copyWith(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: ToyVerseTheme.textDark,
            letterSpacing: -0.3,
          ),
        ),
        SpringPressable(
          onTap: onSeeAll,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'See All',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: ToyVerseTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: ToyVerseTheme.primaryRed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
