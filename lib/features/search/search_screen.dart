import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../models/product_model.dart';
import '../../providers/app_providers.dart';
import '../product/product_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey<AnimatedGridState> _gridKey = GlobalKey<AnimatedGridState>();
  final List<String> _trendingTags = [
    'STEM Robots',
    'LEGO Wooden Castle',
    'RC All-Terrain',
    'Plush Teddy Bear',
    'Solar Planetarium',
    'Superhero Figure',
  ];

  bool _isListeningVoice = false;
  RangeValues _priceRange = const RangeValues(0, 5000);
  double _minRating = 0;
  List<ProductModel> _displayedProducts = const [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseProducts = ref.watch(filteredProductsProvider);
    final filteredProducts = baseProducts
        .where((product) =>
            product.price >= _priceRange.start &&
            product.price <= _priceRange.end &&
            product.rating >= _minRating)
        .toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || listEquals(_displayedProducts.map((p) => p.id).toList(), filteredProducts.map((p) => p.id).toList())) {
        return;
      }
      _syncAnimatedGrid(filteredProducts);
    });

    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: TextField(
                          controller: _controller,
                          onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                          decoration: InputDecoration(
                            hintText: 'Search toys, brands, or age groups...',
                            prefixIcon: const Icon(Icons.search_rounded, color: ToyVerseTheme.primaryRoyalBlue),
                            suffixIcon: _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _controller.clear();
                                      ref.read(searchQueryProvider.notifier).state = '';
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _simulateVoiceSearch(context),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: _isListeningVoice ? ToyVerseTheme.accentCoral : ToyVerseTheme.primaryOrange,
                        child: Icon(
                          _isListeningVoice ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trending Searches 🔥',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ToyVerseTheme.textDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showFilterSheet(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: ToyVerseTheme.subtleShadow(opacity: 0.04, blur: 12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune_rounded, size: 15, color: ToyVerseTheme.primaryNavy),
                            const SizedBox(width: 6),
                            Text(
                              'Filters',
                              style: AppTypography.bodyLarge.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ToyVerseTheme.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: _trendingTags.map((tag) {
                    return ActionChip(
                      label: Text(
                        tag,
                        style: AppTypography.bodyLarge.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ToyVerseTheme.textDark,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                      onPressed: () {
                        _controller.text = tag;
                        ref.read(searchQueryProvider.notifier).state = tag;
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredProducts.isEmpty
                    ? Center(
                        child: Text(
                          'No matching toys found 🤖',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 18,
                            color: ToyVerseTheme.textMuted,
                          ),
                        ),
                      )
                    : AnimatedGrid(
                        key: _gridKey,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        initialItemCount: filteredProducts.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index, animation) {
                          final product = filteredProducts[index];
                          return _AnimatedResultCard(
                            product: product,
                            animation: animation,
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

  void _syncAnimatedGrid(List<ProductModel> nextProducts) {
    final animationGrid = _gridKey.currentState;
    if (animationGrid == null) {
      _displayedProducts = List<ProductModel>.from(nextProducts);
      return;
    }

    final previous = List<ProductModel>.from(_displayedProducts);
    final previousIds = previous.map((p) => p.id).toSet();
    final nextIds = nextProducts.map((p) => p.id).toSet();

    for (var index = previous.length - 1; index >= 0; index--) {
      final product = previous[index];
      if (!nextIds.contains(product.id)) {
        animationGrid.removeItem(
          index,
          (context, animation) => _AnimatedResultCard(
            product: product,
            animation: animation,
            isLeaving: true,
          ),
          duration: const Duration(milliseconds: 160),
        );
      }
    }

    for (var index = 0; index < nextProducts.length; index++) {
      final product = nextProducts[index];
      if (!previousIds.contains(product.id)) {
        animationGrid.insertItem(
          index,
          duration: Duration(milliseconds: 180 + (index * 60)),
        );
      }
    }

    _displayedProducts = List<ProductModel>.from(nextProducts);
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.97),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Refine Search',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: ToyVerseTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Price Range',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ToyVerseTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRangeSlider(setModalState),
                    const SizedBox(height: 20),
                    Text(
                      'Minimum Rating',
                      style: AppTypography.bodyLarge.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: ToyVerseTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRatingSlider(setModalState),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ToyVerseTheme.primaryNavy,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(ToyVerseTheme.radiusButton),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pop(context),
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
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPriceRangeSlider(void Function(void Function()) setModalState) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: ToyVerseTheme.primaryRoyalBlue,
        inactiveTrackColor: ToyVerseTheme.bgLightGray,
        thumbColor: Colors.white,
        overlayColor: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.1),
        trackHeight: 8,
        rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
        rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
        tickMarkShape: const RoundSliderTickMarkShape(),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      child: RangeSlider(
        values: _priceRange,
        min: 0,
        max: 5000,
        divisions: 20,
        labels: RangeLabels(
          '₹${_priceRange.start.round()}',
          '₹${_priceRange.end.round()}',
        ),
        onChanged: (value) {
          setState(() {
            _priceRange = value;
          });
          setModalState(() {
            _priceRange = value;
          });
        },
      ),
    );
  }

  Widget _buildRatingSlider(void Function(void Function()) setModalState) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: ToyVerseTheme.accentGold,
        inactiveTrackColor: ToyVerseTheme.bgLightGray,
        thumbColor: Colors.white,
        overlayColor: ToyVerseTheme.accentGold.withValues(alpha: 0.12),
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        showValueIndicator: ShowValueIndicator.onDrag,
      ),
      child: Slider(
        value: _minRating,
        min: 0,
        max: 5,
        divisions: 10,
        label: _minRating.toStringAsFixed(1),
        onChanged: (value) {
          setState(() {
            _minRating = value;
          });
          setModalState(() {
            _minRating = value;
          });
        },
      ),
    );
  }

  void _simulateVoiceSearch(BuildContext context) {
    setState(() => _isListeningVoice = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: ToyVerseTheme.primaryOrange,
                child: Icon(Icons.mic_rounded, size: 44, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                'Listening... Say a toy name 🎙️',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: ToyVerseTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'e.g. "Galactic Robot" or "Wooden Blocks"',
                style: AppTypography.bodyMedium.copyWith(color: ToyVerseTheme.textMuted),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ToyVerseTheme.primaryRoyalBlue,
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: () {
                  setState(() => _isListeningVoice = false);
                  _controller.text = 'Robot';
                  ref.read(searchQueryProvider.notifier).state = 'Robot';
                  Navigator.pop(context);
                },
                child: Text(
                  'Simulate Voice: "Robot"',
                  style: AppTypography.bodyLarge.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => setState(() => _isListeningVoice = false));
  }
}

class _AnimatedResultCard extends StatelessWidget {
  final ProductModel product;
  final Animation<double> animation;
  final bool isLeaving;

  const _AnimatedResultCard({
    required this.product,
    required this.animation,
    this.isLeaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final opacity = isLeaving ? (1 - curve.value).clamp(0.0, 1.0) : curve.value;
        final scale = isLeaving ? 1.0 - (curve.value * 0.22) : 0.86 + (curve.value * 0.14);
        final translate = isLeaving ? (curve.value * 18) : 0.0;

        return Transform.translate(
          offset: Offset(0, translate),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: ProductCard(product: product, width: double.infinity),
            ),
          ),
        );
      },
    );
  }
}

