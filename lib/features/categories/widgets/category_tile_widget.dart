import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/toyverse_theme.dart';
import '../../../core/widgets/spring_widgets.dart';
import '../../../models/category_model.dart';

/// Unified Category & Subcategory Tile Component.
///
/// Features:
/// - Clean pure white background with soft rounded corners (20px radius).
/// - Prominent, large 3D illustrated icon occupying the tile.
/// - Centered label text below the tile with clean multi-line wrapping.
/// - Magnetic spring press feedback and smooth entrance motion.
class CategoryTileWidget extends StatelessWidget {
  final CategoryModel category;
  final int index;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? width;
  final double? height;
  final bool isGridMode;

  const CategoryTileWidget({
    super.key,
    required this.category,
    this.index = 0,
    this.onTap,
    this.isSelected = false,
    this.width,
    this.height,
    this.isGridMode = true,
  });

  Widget _buildFallbackIcon() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(
        category.icon,
        size: 36,
        color: ToyVerseTheme.primaryRoyalBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final illustrationAsset = category.illustrationAsset;
    final hasRemoteBanner = category.bannerUrl.isNotEmpty &&
        (category.bannerUrl.startsWith('http://') || category.bannerUrl.startsWith('https://'));

    return SpringPressable(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Clean White Tile Box with Large 3D Icon or Banner
            AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: ToyVerseTheme.primaryRed, width: 2.0)
                      : Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: ToyVerseTheme.primaryNavy.withValues(alpha: isSelected ? 0.12 : 0.04),
                      blurRadius: isSelected ? 12 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: Center(
                  child: illustrationAsset != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            illustrationAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) => hasRemoteBanner
                                ? CachedNetworkImage(
                                    imageUrl: category.bannerUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => _buildFallbackIcon(),
                                  )
                                : _buildFallbackIcon(),
                          ),
                        )
                      : (hasRemoteBanner
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: category.bannerUrl,
                                fit: BoxFit.cover,
                                errorWidget: (c, u, e) => _buildFallbackIcon(),
                              ),
                            )
                          : _buildFallbackIcon()),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 2. Centered Category Label Below Tile (Clean 2-line wrap)
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? ToyVerseTheme.primaryRed : ToyVerseTheme.textDark,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (40 + index * 25).ms).slideY(begin: 0.06, end: 0);
  }
}
