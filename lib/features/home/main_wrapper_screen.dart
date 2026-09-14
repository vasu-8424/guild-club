import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../core/theme/toyverse_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/floating_dock_nav.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../providers/app_providers.dart';
import '../../providers/location_provider.dart';
import '../cart/cart_screen.dart';
import 'home_feed_view.dart';
import '../categories/categories_screen.dart';
import '../rewards/rewards_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';

class MainWrapperScreen extends ConsumerStatefulWidget {
  const MainWrapperScreen({super.key});

  @override
  ConsumerState<MainWrapperScreen> createState() => _MainWrapperScreenState();
}

class _MainWrapperScreenState extends ConsumerState<MainWrapperScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey _cartIconKey = GlobalKey();
  late final AnimationController _headerController;
  late final AnimationController _coinPulseController;
  int _lastRewardCoins = 0;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _coinPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 260),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final locationNotifier = ref.read(fetchedLocationProvider.notifier);
      await locationNotifier.silentFetch();
      if (!mounted) return;
      final currentState = ref.read(fetchedLocationProvider);
      if (currentState == 'Tap to set location' ||
          currentState == 'Location unavailable') {
        await locationNotifier.requestPermissionAndFetch(context);
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _coinPulseController.dispose();
    super.dispose();
  }
  final List<Widget> _pages = const [
    HomeFeedView(),
    CategoriesScreen(),
    RewardsScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  void _syncCoinPulse(int balance) {
    if (_lastRewardCoins != 0 && balance != _lastRewardCoins) {
      _coinPulseController.forward(from: 0.0);
    }
    _lastRewardCoins = balance;
  }

  void _openCartWithMorph() {
    final renderObject = _cartIconKey.currentContext?.findRenderObject();
    Rect? originRect;
    if (renderObject is RenderBox) {
      final topLeft = renderObject.localToGlobal(Offset.zero);
      originRect = topLeft & renderObject.size;
    }

    context.push(
      '/cart',
      extra: originRect == null ? null : CartEntryMorphData(originRect: originRect),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final user = ref.watch(userProvider);
    final wishlist = ref.watch(wishlistProvider);
    final fetchedLocation = ref.watch(fetchedLocationProvider);
    final addresses = ref.watch(addressesProvider);
    final defaultAddress = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
    final displayLocation = defaultAddress != null
        ? '${defaultAddress.label} • ${defaultAddress.city.isNotEmpty ? defaultAddress.city : defaultAddress.fullAddress}'
        : fetchedLocation;
    final cartCount = cart.fold(0, (sum, item) => sum + item.quantity);
    final wishlistCount = wishlist.length;
    _syncCoinPulse(user.rewardCoins);

    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Page Body View
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(top: 78),
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _pages,
                  ),
                ),
              ),

              Positioned(
                top: 8,
                left: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _headerController,
                  builder: (context, child) {
                    final headerReveal = Curves.easeOutCubic.transform(_headerController.value);
                    return Transform.translate(
                      offset: Offset(0, 12 - (headerReveal * 12)),
                      child: Opacity(
                        opacity: headerReveal.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.84),
                          Colors.white.withValues(alpha: 0.72),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.9),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.10),
                          blurRadius: 18,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: ToyVerseTheme.primaryRed.withValues(alpha: 0.08),
                          blurRadius: 26,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        AnimatedBuilder(
                                          animation: _headerController,
                                          builder: (context, child) {
                                            final reveal = Curves.easeOutCubic.transform(_headerController.value);
                                            return Transform.translate(
                                              offset: Offset(-12 + (reveal * 12), 0),
                                              child: Opacity(
                                                opacity: reveal.clamp(0.0, 1.0),
                                                child: child,
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Guild Club',
                                            style: AppTypography.displayMedium.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: ToyVerseTheme.textDark,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        AnimatedBuilder(
                                          animation: _coinPulseController,
                                          builder: (context, child) {
                                            final pulse = 1.0 + (0.08 * (1.0 - _coinPulseController.value));
                                            return Transform.scale(
                                              scale: pulse,
                                              child: child,
                                            );
                                          },
                                          child: SpringPressable(
                                            onTap: () => context.push('/rewards'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: ToyVerseTheme.primaryRed.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: ToyVerseTheme.primaryRed.withValues(alpha: 0.28),
                                                  width: 0.8,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: ToyVerseTheme.primaryRed.withValues(alpha: 0.16),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.stars_rounded, size: 12, color: ToyVerseTheme.primaryRed),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${user.rewardCoins}',
                                                    style: AppTypography.priceNumeral.copyWith(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: ToyVerseTheme.primaryRed,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    AnimatedBuilder(
                                      animation: _headerController,
                                      builder: (context, child) {
                                        final reveal = Curves.easeOutCubic.transform(_headerController.value);
                                        return Transform.translate(
                                          offset: Offset(-8 + (reveal * 8), 0),
                                          child: Opacity(
                                            opacity: (reveal * 0.8).clamp(0.0, 1.0),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: GestureDetector(
                                        onTap: () => context.push('/address-picker'),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 12, color: ToyVerseTheme.textMuted),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                displayLocation,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTypography.bodySmall.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: ToyVerseTheme.textMuted,
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: ToyVerseTheme.textMuted),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildHeaderIconButton(
                                    icon: Icons.search_rounded,
                                    onTap: () => context.push('/search'),
                                  ),
                                  const SizedBox(width: 8),
                                  badges.Badge(
                                    position: badges.BadgePosition.topEnd(top: -2, end: -2),
                                    badgeContent: Text(
                                      '$wishlistCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    showBadge: wishlistCount > 0,
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor: ToyVerseTheme.primaryRed,
                                      padding: EdgeInsets.all(5),
                                      elevation: 0,
                                    ),
                                    child: _buildHeaderIconButton(
                                      icon: Icons.favorite_border_rounded,
                                      onTap: () => context.push('/wishlist'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  badges.Badge(
                                    position: badges.BadgePosition.topEnd(top: -2, end: -2),
                                    badgeContent: Text(
                                      '$cartCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    showBadge: cartCount > 0,
                                    badgeStyle: const badges.BadgeStyle(
                                      badgeColor: ToyVerseTheme.accentCoral,
                                      padding: EdgeInsets.all(5),
                                      elevation: 0,
                                    ),
                                    child: KeyedSubtree(
                                      key: _cartIconKey,
                                      child: _buildHeaderIconButton(
                                        icon: Icons.shopping_bag_outlined,
                                        onTap: _openCartWithMorph,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. FLOATING DOCK NAVIGATION
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: FloatingDockNav(
                  currentIndex: _currentIndex,
                  onTap: (index) => setState(() => _currentIndex = index),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: ToyVerseTheme.bgLightGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(icon, color: ToyVerseTheme.textDark, size: 18),
        ),
      ),
    );
  }
}
