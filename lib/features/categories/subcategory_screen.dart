import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../providers/app_providers.dart';
import 'widgets/category_tile_widget.dart';

class SubcategoryScreen extends ConsumerWidget {
  final String parentId;
  final String? parentName;

  const SubcategoryScreen({
    super.key,
    required this.parentId,
    this.parentName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoriesFamilyProvider(parentId));
    final parentCategoryAsync = ref.watch(categoryDetailFamilyProvider(parentId));

    final resolvedParentName = parentName ??
        parentCategoryAsync.asData?.value?.name ??
        (parentId.contains('child') ? 'Child Development Centers' : 'Services');

    return Scaffold(
      backgroundColor: ToyVerseTheme.bgWarmWhite,
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Glass Header with BackdropFilter & Parent Breadcrumb
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
                            onTap: () => context.pop(),
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
                                Row(
                                  children: [
                                    Text(
                                      'Categories',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: ToyVerseTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, size: 12, color: ToyVerseTheme.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sub-services',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: ToyVerseTheme.primaryRed,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  resolvedParentName,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.displayMedium.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ToyVerseTheme.textDark,
                                    letterSpacing: -0.4,
                                  ),
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

              // Overview Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: ToyVerseTheme.royalNavyGradient,
                    borderRadius: BorderRadius.circular(ToyVerseTheme.radiusProductCard),
                    boxShadow: [
                      BoxShadow(
                        color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SparkleBadge(
                              label: 'SPECIALIZED CARE 🩺',
                              backgroundColor: ToyVerseTheme.primaryRed,
                              fontSize: 9,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pediatric Therapy & Support',
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select a specialized discipline below to view verified centers and certified practitioners.',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.84),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),

              const SizedBox(height: 16),

              // Subcategories Grid (Reusing CategoryTileWidget)
              Expanded(
                child: subcategoriesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(ToyVerseTheme.primaryRoyalBlue),
                    ),
                  ),
                  error: (err, stack) => Center(
                    child: Text('Error loading subcategories: $err'),
                  ),
                  data: (subcategories) {
                    if (subcategories.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.category_outlined, size: 54, color: ToyVerseTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No subcategories found',
                              style: AppTypography.displayMedium.copyWith(fontSize: 16, color: ToyVerseTheme.textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.64,
                      ),
                      itemCount: subcategories.length,
                      itemBuilder: (context, index) {
                        final subCat = subcategories[index];
                        return CategoryTileWidget(
                          category: subCat,
                          index: index,
                          onTap: () {
                            context.push(
                              '/category-listings/${subCat.id}',
                              extra: subCat,
                            );
                          },
                        );
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
}
