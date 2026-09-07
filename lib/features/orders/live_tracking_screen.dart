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
import '../../models/order_model.dart';
import '../../providers/app_providers.dart';

class LiveTrackingScreen extends ConsumerWidget {
  final String orderId;

  const LiveTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Realtime Supabase live stream subscription
    final asyncOrderStream = ref.watch(singleOrderStreamProvider(orderId));
    final localOrders = ref.watch(ordersProvider);

    final OrderModel? order = asyncOrderStream.asData?.value ??
        localOrders.where((o) => o.id == orderId).firstOrNull ??
        (localOrders.isNotEmpty ? localOrders.first : null);

    if (order == null) {
      return Scaffold(
        backgroundColor: ToyVerseTheme.bgWarmWhite,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_searching_rounded, size: 48, color: ToyVerseTheme.textMuted),
                const SizedBox(height: 12),
                Text(
                  'Order not found',
                  style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'ID: $orderId',
                  style: AppTypography.bodySmall.copyWith(color: ToyVerseTheme.textMuted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ToyVerseTheme.primaryNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ToyVerseTheme.bgWarmWhite,
      body: FloatingCloudsBackground(
        child: SafeArea(
          child: Column(
            children: [
              // 1. Frosted Glass Top Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(ToyVerseTheme.radiusNavigation),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.0),
                        boxShadow: [
                          BoxShadow(
                            color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.08),
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
                                      'Order Tracking',
                                      style: AppTypography.displayMedium.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: ToyVerseTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: order.status == OrderStatus.delivered
                                            ? ToyVerseTheme.primaryMintGreen
                                            : ToyVerseTheme.primaryRed,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  order.orderNumber,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: ToyVerseTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SparkleBadge(
                            label: order.status.name.toUpperCase(),
                            backgroundColor: order.status == OrderStatus.delivered
                                ? ToyVerseTheme.primaryMintGreen
                                : ToyVerseTheme.primaryRoyalBlue,
                            fontSize: 9,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Scrollable Tracking Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ETA & Realtime Status Hero Banner
                      _buildEtaBanner(order),

                      const SizedBox(height: 16),

                      // Liquid Progress Stepper Timeline
                      _buildLiquidTimelineCard(order),

                      const SizedBox(height: 16),

                      // Static Fulfillment Route Map Card (Honest Representation)
                      _buildHonestFulfillmentRouteCard(order),

                      const SizedBox(height: 16),

                      // Delivery Partner & Support Contact Card
                      _buildDeliveryPartnerCard(context, order),

                      const SizedBox(height: 16),

                      // Order Items & Delivery Summary
                      _buildOrderSummaryCard(order),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Estimated Delivery Hero Banner
  Widget _buildEtaBanner(OrderModel order) {
    final isDelivered = order.status == OrderStatus.delivered;
    final isCancelled = order.status == OrderStatus.cancelled;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isDelivered
            ? const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : isCancelled
                ? const LinearGradient(
                    colors: [Color(0xFF991B1B), Color(0xFFB91C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : ToyVerseTheme.royalNavyGradient,
        borderRadius: BorderRadius.circular(ToyVerseTheme.radiusProductCard),
        boxShadow: [
          BoxShadow(
            color: (isDelivered ? const Color(0xFF065F46) : ToyVerseTheme.primaryNavy).withValues(alpha: 0.22),
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
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDelivered
                  ? Icons.check_circle_rounded
                  : isCancelled
                      ? Icons.cancel_rounded
                      : Icons.local_shipping_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isDelivered
                          ? 'DELIVERY COMPLETED'
                          : isCancelled
                              ? 'ORDER CANCELLED'
                              : 'ESTIMATED ARRIVAL',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'REALTIME SYNC ⚡',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.estimatedDeliveryFormatted,
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }

  /// Liquid Progress Stepper Timeline Card (5 stages with liquid fill & timestamps)
  Widget _buildLiquidTimelineCard(OrderModel order) {
    final currentStep = order.statusStepIndex;

    final stages = [
      (
        status: OrderStatus.placed,
        title: 'Order Placed',
        subtitle: 'Payment confirmed & registered',
        icon: Icons.receipt_long_rounded,
      ),
      (
        status: OrderStatus.preparing,
        title: 'Preparing & Packed',
        subtitle: 'Carefully packaged at fulfillment center',
        icon: Icons.inventory_2_rounded,
      ),
      (
        status: OrderStatus.dispatched,
        title: 'Dispatched from Hub',
        subtitle: 'Handed over to Guild Club express logistics',
        icon: Icons.local_shipping_rounded,
      ),
      (
        status: OrderStatus.outForDelivery,
        title: 'Out for Delivery',
        subtitle: 'Courier partner is en-route to delivery address',
        icon: Icons.directions_bike_rounded,
      ),
      (
        status: OrderStatus.delivered,
        title: 'Delivered',
        subtitle: 'Safely handed over to recipient',
        icon: Icons.home_rounded,
      ),
    ];

    final progressRatio = currentStep < 0 ? 0.0 : (currentStep / (stages.length - 1)).clamp(0.0, 1.0);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Live Order Timeline',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ToyVerseTheme.textDark,
                ),
              ),
              Text(
                'Stage ${currentStep + 1} of 5',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ToyVerseTheme.primaryRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Liquid Progress Bar Rail
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Track background
                  Container(
                    height: 6,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: ToyVerseTheme.bgLightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Animated Liquid Fill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 6,
                    width: constraints.maxWidth * progressRatio,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [ToyVerseTheme.primaryRoyalBlue, ToyVerseTheme.primaryRed],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: ToyVerseTheme.primaryRed.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // Timeline Step Items
          ...List.generate(stages.length, (idx) {
            final stage = stages[idx];
            final isCompleted = currentStep >= idx;
            final isCurrent = currentStep == idx;
            final timestamp = order.getStatusTimestamp(stage.status);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Avatar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent
                          ? ToyVerseTheme.primaryRed
                          : (isCompleted ? ToyVerseTheme.primaryRoyalBlue : Colors.grey.shade200),
                      boxShadow: isCurrent
                          ? ToyVerseTheme.glowShadow(ToyVerseTheme.primaryRed, opacity: 0.35, blur: 8)
                          : null,
                    ),
                    child: Center(
                      child: Icon(
                        isCompleted ? Icons.check_rounded : stage.icon,
                        color: isCompleted ? Colors.white : Colors.grey.shade500,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Step Texts & Timestamps
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              stage.title,
                              style: AppTypography.displayMedium.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? ToyVerseTheme.primaryRed
                                    : (isCompleted ? ToyVerseTheme.textDark : ToyVerseTheme.textMuted),
                              ),
                            ),
                            if (timestamp != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? ToyVerseTheme.primaryRed.withValues(alpha: 0.1)
                                      : ToyVerseTheme.bgLightGray,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  timestamp,
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: isCurrent ? ToyVerseTheme.primaryRed : ToyVerseTheme.textMuted,
                                  ),
                                ),
                              )
                            else if (isCurrent)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: ToyVerseTheme.primaryOrange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'IN PROGRESS',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: ToyVerseTheme.primaryOrange,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stage.subtitle,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: ToyVerseTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Honest Static Fulfillment Route Map Card (Origin Hub -> Destination Delivery Pin)
  /// Honest Approach: Shows fixed origin hub coordinates and customer destination, without fake moving dots.
  Widget _buildHonestFulfillmentRouteCard(OrderModel order) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fulfillment & Route Details',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ToyVerseTheme.textDark,
                ),
              ),
              const SparkleBadge(
                label: 'HONEST ROUTE MAP 📍',
                backgroundColor: ToyVerseTheme.primaryNavy,
                fontSize: 8,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Static Route Visual Representation
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ToyVerseTheme.bgLightBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                // 1. Origin Hub Pin
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: ToyVerseTheme.primaryRoyalBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ORIGIN FULFILLMENT HUB',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: ToyVerseTheme.primaryRoyalBlue,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.originLocation,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ToyVerseTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Connecting Line
                Padding(
                  padding: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 24,
                      color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.4),
                    ),
                  ),
                ),

                // 2. Destination Pin
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: ToyVerseTheme.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DELIVERY DESTINATION',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: ToyVerseTheme.primaryRed,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.deliveryAddress,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ToyVerseTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Delivery Partner & Support Card
  Widget _buildDeliveryPartnerCard(BuildContext context, OrderModel order) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: ToyVerseTheme.primaryRoyalBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.deliveryPartnerName,
                  style: AppTypography.displayMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: ToyVerseTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Guild Club Logistics Representative',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 11,
                    color: ToyVerseTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          SpringPressable(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling support / partner at ${order.deliveryPartnerPhone}... 📞'),
                  backgroundColor: ToyVerseTheme.primaryNavy,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// Expandable Order Items & Pricing Summary
  Widget _buildOrderSummaryCard(OrderModel order) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${order.items.length})',
            style: AppTypography.displayMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ToyVerseTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ToyVerseTheme.bgLightGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrl != null
                          ? CachedNetworkImage(imageUrl: item.imageUrl!, fit: BoxFit.cover)
                          : const Icon(Icons.toys_rounded, color: ToyVerseTheme.textMuted, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ToyVerseTheme.textDark,
                          ),
                        ),
                        Text(
                          'Qty: ${item.quantity}',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 11,
                            color: ToyVerseTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${item.totalPrice.toInt()}',
                    style: AppTypography.priceNumeral.copyWith(
                      fontSize: 13,
                      color: ToyVerseTheme.textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Paid',
                style: AppTypography.displayMedium.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${order.total.toInt()}',
                style: AppTypography.priceNumeral.copyWith(
                  fontSize: 16,
                  color: ToyVerseTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
