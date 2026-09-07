import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/spring_widgets.dart';
import '../../models/order_model.dart';
import '../../providers/app_providers.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  final Set<String> _expandedOrderIds = {};
  late final TabController _tabController;
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['All', 'Active', 'Delivered', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterOrders(List<OrderModel> allOrders) {
    switch (_selectedTabIndex) {
      case 1: // Active
        return allOrders
            .where((o) =>
                o.status == OrderStatus.placed ||
                o.status == OrderStatus.preparing ||
                o.status == OrderStatus.dispatched ||
                o.status == OrderStatus.outForDelivery)
            .toList();
      case 2: // Delivered
        return allOrders.where((o) => o.status == OrderStatus.delivered).toList();
      case 3: // Cancelled
        return allOrders.where((o) => o.status == OrderStatus.cancelled).toList();
      default: // All
        return allOrders;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncUserData = ref.watch(userDataProvider);
    final allOrders = ref.watch(ordersProvider);
    final filteredOrders = _filterOrders(allOrders);

    return Scaffold(
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Frosted Glass Top Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (context.canPop()) ...[
                                SpringPressable(
                                  onTap: () => context.pop(),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: ToyVerseTheme.bgLightGray,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: ToyVerseTheme.textDark),
                                  ),
                                ),
                              ],
                              Text(
                                'My Orders 📦',
                                style: AppTypography.displayMedium.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: ToyVerseTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          SpringPressable(
                            onTap: () => ref.invalidate(userDataProvider),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.refresh_rounded, color: ToyVerseTheme.primaryNavy, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 8),

              // Tab Switcher with Pill Morph Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _selectedTabIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            _tabController.animateTo(index);
                            setState(() => _selectedTabIndex = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: isSelected ? ToyVerseTheme.primaryNavy : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: isSelected
                                  ? ToyVerseTheme.glowShadow(ToyVerseTheme.primaryNavy, opacity: 0.25, blur: 10)
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                _tabs[index],
                                style: AppTypography.bodyMedium.copyWith(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : ToyVerseTheme.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 12),

              // Orders List Body
              Expanded(
                child: asyncUserData.when(
                  loading: () => _buildShimmerOrderList(),
                  error: (err, stack) => _buildOrdersList(filteredOrders),
                  data: (data) => _buildOrdersList(filteredOrders),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userDataProvider);
        await ref.read(userDataProvider.future);
      },
      child: orders.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ToyVerseTheme.primaryPurple.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inbox_rounded, size: 54, color: ToyVerseTheme.primaryPurple),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No orders placed yet ✨',
                        style: AppTypography.accentScript.copyWith(
                          fontSize: 24,
                          color: ToyVerseTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your ordered toys will show up here live.',
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          color: ToyVerseTheme.textMuted,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1, end: 0),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final isExpanded = _expandedOrderIds.contains(order.id);

                return SpringPressable(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedOrderIds.remove(order.id);
                      } else {
                        _expandedOrderIds.add(order.id);
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: ToyVerseTheme.primaryPurple.withValues(alpha: 0.04),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: GlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                order.orderNumber,
                                style: AppTypography.displayMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SparkleBadge(
                                label: order.status.name.toUpperCase(),
                                backgroundColor: order.status == OrderStatus.delivered
                                    ? ToyVerseTheme.primaryMintGreen
                                    : ToyVerseTheme.primaryOrange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Placed on: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted),
                          ),
                          const SizedBox(height: 12),

                          // Item Thumbnails Row
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: order.items.length,
                              itemBuilder: (context, itemIdx) {
                                final item = order.items[itemIdx];
                                final imgUrl = item.imageUrl ?? (item.product?.imageUrls.isNotEmpty == true ? item.product!.imageUrls.first : null);
                                return Container(
                                  margin: const EdgeInsets.only(right: 10),
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: ToyVerseTheme.bgLightGray,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: imgUrl != null
                                        ? CachedNetworkImage(imageUrl: imgUrl, fit: BoxFit.cover)
                                        : const Icon(Icons.toys_rounded, color: ToyVerseTheme.textMuted),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Total & Expand Toggle Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total: ₹${order.totalAmount.toInt()} (${order.items.length} items)',
                                style: AppTypography.displayMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold, color: ToyVerseTheme.textDark),
                              ),
                              Row(
                                children: [
                                  Text(
                                    isExpanded ? 'Hide details' : 'View details',
                                    style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: ToyVerseTheme.primaryRoyalBlue),
                                  ),
                                  Icon(
                                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                    color: ToyVerseTheme.primaryRoyalBlue,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // Expandable Amazon-Style Details View
                          if (isExpanded) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Order Items', style: AppTypography.displayMedium.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ...order.items.map((it) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text('${it.title} (x${it.quantity})', style: AppTypography.bodyMedium.copyWith(fontSize: 13))),
                                        Text('₹${it.totalPrice.toInt()}', style: AppTypography.priceNumeral.copyWith(fontSize: 13)),
                                      ],
                                    ),
                                  )),
                                  const SizedBox(height: 10),
                                  Text('Delivery Address', style: AppTypography.displayMedium.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(order.deliveryAddress, style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: ToyVerseTheme.textMuted)),
                                  const SizedBox(height: 14),
                                  SpringPressable(
                                    onTap: () => context.push('/tracking/${order.id}'),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: ToyVerseTheme.primaryNavy,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: ToyVerseTheme.glowShadow(ToyVerseTheme.primaryNavy, opacity: 0.25, blur: 10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.navigation_rounded, color: Colors.white, size: 16),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Track Live Delivery 🚚',
                                            style: AppTypography.bodyLarge.copyWith(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 350.ms, delay: (index * 30).ms).slideY(begin: 0.08, end: 0);
              },
            ),
    );
  }

  Widget _buildShimmerOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: 140,
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
