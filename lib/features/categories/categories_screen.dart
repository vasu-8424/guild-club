import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../providers/app_providers.dart';
import '../product/product_card.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  LinearGradient _getCategoryGradient(String slug, bool isSelected) {
    if (!isSelected) {
      return LinearGradient(
        colors: [
          Colors.white,
          Colors.grey.shade50,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    switch (slug) {
      case 'stem':
        return const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'wooden':
        return const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'plush':
        return const LinearGradient(
          colors: [Color(0xFFF43F5E), Color(0xFFFB7185)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'creative':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'action':
        return const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'puzzles':
        return const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return ToyVerseTheme.royalNavyGradient;
    }
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'stem':
        return Icons.science_rounded;
      case 'wooden':
        return Icons.forest_rounded;
      case 'plush':
        return Icons.pets_rounded;
      case 'creative':
        return Icons.palette_rounded;
      case 'action':
        return Icons.rocket_launch_rounded;
      case 'puzzles':
        return Icons.extension_rounded;
      default:
        return Icons.toys_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final products = ref.watch(filteredProductsProvider);
    final ageRange = ref.watch(ageFilterProvider);
    final canPop = Navigator.canPop(context);

    final content = Column(
      children: [
        // App Header Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              if (canPop) ...[
                SpringPressable(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: ToyVerseTheme.bgLightGray,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: ToyVerseTheme.textDark, size: 16),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  'Explore Categories 🎨',
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ToyVerseTheme.textDark,
                  ),
                ),
              ),
              SpringPressable(
                onTap: () => _showFilterSheet(context, ref),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ToyVerseTheme.primaryNavy,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.primaryNavy, opacity: 0.2, blur: 10),
                  ),
                  child: const Center(
                    child: Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Choreographed Category Chips (Horizontal Scroll with Gradient & Custom Vectors)
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAllTile = index == 0;
              final cat = isAllTile ? null : categories[index - 1];
              final isSelected = isAllTile ? (selectedCategory == null) : (selectedCategory == cat?.slug);
              final tileGradient = _getCategoryGradient(cat?.slug ?? 'all', isSelected);
              final tileIcon = isAllTile ? Icons.grid_view_rounded : _getCategoryIcon(cat?.slug ?? '');
              final tileLabel = isAllTile ? 'All Toys' : cat!.name;

              return SpringPressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isAllTile) {
                    ref.read(selectedCategoryProvider.notifier).state = null;
                  } else {
                    ref.read(selectedCategoryProvider.notifier).state = cat!.slug;
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(right: 12, top: 4, bottom: 6),
                  width: 105,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: tileGradient,
                    borderRadius: BorderRadius.circular(ToyVerseTheme.radiusSmallCard),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.grey.shade200.withValues(alpha: 0.8),
                      width: isSelected ? 1.2 : 0.8,
                    ),
                    boxShadow: isSelected
                        ? ToyVerseTheme.glowShadow(ToyVerseTheme.primaryNavy, opacity: 0.18, blur: 14)
                        : [
                            BoxShadow(
                              color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.22)
                              : ToyVerseTheme.primaryNavy.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tileIcon,
                          color: isSelected ? Colors.white : ToyVerseTheme.primaryNavy,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tileLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : ToyVerseTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 350.ms, delay: (index * 24).ms).slideX(begin: 0.1, end: 0);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Filter Summary Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              SpringPressable(
                onTap: () => _showFilterSheet(context, ref),
                child: SparkleBadge(
                  label: 'Ages ${ageRange.start.toInt()}-${ageRange.end.toInt()} Yrs',
                  icon: Icons.filter_alt_rounded,
                  backgroundColor: ToyVerseTheme.primaryNavy,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Showing ${products.length} toys',
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ToyVerseTheme.textMuted,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 160.ms),

        const SizedBox(height: 8),

        // Product Grid using Shared ProductCard (with magnetic press, zoom & soft shadows)
        Expanded(
          child: products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off_rounded, size: 54, color: ToyVerseTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No toys found for selected filters',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 17,
                          color: ToyVerseTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 90),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.54,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(
                      product: products[index],
                      width: double.infinity,
                    ).animate().fadeIn(duration: 350.ms, delay: (index * 24).ms).slideY(begin: 0.08, end: 0);
                  },
                ),
        ),
      ],
    );

    if (canPop) {
      return Scaffold(
        backgroundColor: ToyVerseTheme.bgWarmWhite,
        body: SafeArea(child: content),
      );
    }

    return content;
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              final ageRange = ref.watch(ageFilterProvider);
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(ToyVerseTheme.radiusNavigation)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Refine Toy Filters',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ToyVerseTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Child Age Group (Years)',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ToyVerseTheme.textDark,
                      ),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: ToyVerseTheme.primaryNavy,
                        inactiveTrackColor: ToyVerseTheme.bgLightGray,
                        overlayColor: ToyVerseTheme.primaryNavy.withValues(alpha: 0.12),
                        thumbColor: Colors.white,
                        trackHeight: 8,
                        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
                        showValueIndicator: ShowValueIndicator.onDrag,
                      ),
                      child: RangeSlider(
                        values: ageRange,
                        min: 1,
                        max: 14,
                        divisions: 13,
                        labels: RangeLabels('${ageRange.start.toInt()} Yrs', '${ageRange.end.toInt()} Yrs'),
                        onChanged: (val) {
                          ref.read(ageFilterProvider.notifier).state = val;
                          setStateModal(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SpringPressable(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: ToyVerseTheme.primaryNavy,
                          borderRadius: BorderRadius.circular(ToyVerseTheme.radiusButton),
                          boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.primaryNavy, opacity: 0.25, blur: 12),
                        ),
                        child: Center(
                          child: Text(
                            'Apply Filters',
                            style: AppTypography.bodyLarge.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
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
      },
    );
  }
}
