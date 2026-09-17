import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static const String storeOriginAddress =
      'Essen Marvella apartments, A block, 410, Suchitra Rd, Sriram Nagar, Jeedimetla, Hyderabad, Telangana 500055 (Landmark: Post Office)';
  static const double storeOriginLat = 17.5168;
  static const double storeOriginLng = 78.4735;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Realtime Supabase live stream subscription (syncs with Admin Panel)
    final asyncOrderStream = ref.watch(singleOrderStreamProvider(orderId));
    final localOrders = ref.watch(ordersProvider);
    final addresses = ref.watch(addressesProvider);
    final defaultAddr = addresses.isNotEmpty ? addresses.first : null;

    final OrderModel? rawOrder = asyncOrderStream.asData?.value ??
        localOrders.where((o) => o.id == orderId).firstOrNull ??
        (localOrders.isNotEmpty ? localOrders.first : null);

    if (rawOrder == null) {
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

    // Resolve accurate destination address and live GPS coordinates
    final resolvedDestLat = rawOrder.resolvedDestinationLat;
    final resolvedDestLng = rawOrder.resolvedDestinationLng;
    final resolvedDeliveryAddress = (rawOrder.deliveryAddressText != null &&
            rawOrder.deliveryAddressText!.isNotEmpty &&
            !rawOrder.deliveryAddressText!.toLowerCase().contains('default delivery'))
        ? rawOrder.deliveryAddressText!
        : (rawOrder.address?.fullAddress != null && rawOrder.address!.fullAddress.isNotEmpty
            ? rawOrder.address!.fullAddress
            : (defaultAddr?.fullAddress ?? rawOrder.deliveryAddress));

    final order = rawOrder.copyWith(
      destinationLat: resolvedDestLat,
      destinationLng: resolvedDestLng,
      deliveryAddressText: resolvedDeliveryAddress,
    );

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
                            onTap: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/orders');
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
                                      width: 8,
                                      height: 8,
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

                      // Interactive Live Delivery Route Map (From Essen Marvella to Customer)
                      _buildLiveRouteMapCard(context, order),

                      const SizedBox(height: 16),

                      // Liquid Progress Stepper Timeline
                      _buildLiquidTimelineCard(order),

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
                Wrap(
                  spacing: 6,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ADMIN SYNC ⚡',
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

  /// Live Interactive Route Map Card (Origin Store -> Customer Address with Visual Trajectory)
  Widget _buildLiveRouteMapCard(BuildContext context, OrderModel order) {
    final destLat = order.resolvedDestinationLat;
    final destLng = order.resolvedDestinationLng;

    // Calculate real distance from Essen Marvella (Jeedimetla Hub) to customer destination
    final distanceKm = _calculateDistanceKm(storeOriginLat, storeOriginLng, destLat, destLng);
    final isLocal = order.isLocalToHyderabad || distanceKm < 45.0;
    final distanceDisplay = distanceKm > 0
        ? '${distanceKm.toStringAsFixed(1)} km (${isLocal ? "Local Delivery" : "Express Outstation"})'
        : 'Local Hyderabad Delivery';

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Live Delivery Route Map',
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ToyVerseTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SparkleBadge(
                label: distanceDisplay,
                backgroundColor: isLocal ? ToyVerseTheme.primaryNavy : ToyVerseTheme.primaryPurple,
                fontSize: 9,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Visual Animated Map Canvas
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF0FDF4),
                    Colors.white,
                    const Color(0xFFEFF6FF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.2)),
              ),
              child: Stack(
                children: [
                  // Custom Road Grid & Highway Spline Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LiveRoutePainter(
                        status: order.status,
                      ),
                    ),
                  ),

                  // Origin Hub Badge (Top-Left)
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ToyVerseTheme.primaryRoyalBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'ORIGIN: JEEDIMETLA HUB',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                'Essen Marvella, Suchitra Rd',
                                style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Destination Badge (Bottom-Right)
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ToyVerseTheme.primaryRed,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: ToyVerseTheme.primaryRed.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'DELIVERY DESTINATION',
                                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                              ),
                              Text(
                                order.deliveryAddress.length > 20
                                    ? '${order.deliveryAddress.substring(0, 20)}...'
                                    : order.deliveryAddress,
                                style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Live Status Indicator in Center
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            order.status == OrderStatus.delivered
                                ? Icons.check_circle_rounded
                                : Icons.route_rounded,
                            size: 13,
                            color: order.status == OrderStatus.delivered
                                ? ToyVerseTheme.primaryMintGreen
                                : ToyVerseTheme.primaryRoyalBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusDescription(order.status),
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
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
          ),

          const SizedBox(height: 14),

          // Structured Origin & Destination Cards
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // 1. Origin Store Hub Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store_mall_directory_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: const [
                              Text(
                                'DISPATCH STORE & HUB',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: ToyVerseTheme.primaryRoyalBlue,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SparkleBadge(label: 'HUB GPS 17.5168, 78.4735', backgroundColor: ToyVerseTheme.primaryNavy, fontSize: 7),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            storeOriginAddress,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ToyVerseTheme.textDark,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Connecting Navigation Line
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 4, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 2,
                      height: 20,
                      decoration: BoxDecoration(
                        color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),

                // 2. Customer Destination Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: ToyVerseTheme.primaryRed.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: ToyVerseTheme.primaryRed, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 3,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'ORDERED DELIVERY LOCATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: ToyVerseTheme.primaryRed,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              SparkleBadge(
                                label: 'GPS: ${destLat.toStringAsFixed(4)}, ${destLng.toStringAsFixed(4)} • ${order.isLocalToHyderabad ? "Hyderabad/TS" : "Andhra/Outstation"}',
                                backgroundColor: ToyVerseTheme.primaryPurple,
                                fontSize: 7,
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            order.deliveryAddress,
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ToyVerseTheme.textDark,
                              height: 1.3,
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

          const SizedBox(height: 12),

          // Open in Google Maps Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.white,
              ),
              onPressed: () => _openGoogleMapsRoute(
                originLat: storeOriginLat,
                originLng: storeOriginLng,
                destLat: destLat,
                destLng: destLng,
                destAddress: order.deliveryAddress,
              ),
              icon: const Icon(Icons.navigation_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 18),
              label: Text(
                'Open Full Route in Google Maps 🗺️',
                style: AppTypography.bodyLarge.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ToyVerseTheme.primaryRoyalBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Received at Jeedimetla Hub';
      case OrderStatus.preparing:
        return 'Packing & Quality Check at Hub';
      case OrderStatus.dispatched:
        return 'In Transit on Suchitra Highway';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery to Your Location';
      case OrderStatus.delivered:
        return 'Delivered at Doorstep';
      case OrderStatus.cancelled:
        return 'Order Cancelled';
    }
  }

  static double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) * (1 - math.cos((lon2 - lon1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  static Future<void> _openGoogleMapsRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
    required String destAddress,
  }) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$destLat,$destLng&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(destAddress)}');
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Liquid Progress Stepper Timeline Card (5 stages with liquid fill & timestamps)
  Widget _buildLiquidTimelineCard(OrderModel order) {
    final currentStep = order.statusStepIndex;

    final stages = [
      (
        status: OrderStatus.placed,
        title: 'Order Placed',
        subtitle: 'Confirmed & registered at Jeedimetla Hub',
        icon: Icons.receipt_long_rounded,
      ),
      (
        status: OrderStatus.preparing,
        title: 'Preparing & Packed',
        subtitle: 'Packaged at Essen Marvella Hub',
        icon: Icons.inventory_2_rounded,
      ),
      (
        status: OrderStatus.dispatched,
        title: 'Dispatched from Hub',
        subtitle: 'En route via Guild Club express logistics',
        icon: Icons.local_shipping_rounded,
      ),
      (
        status: OrderStatus.outForDelivery,
        title: 'Out for Delivery',
        subtitle: 'Courier partner is arriving at delivery location',
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
                  Container(
                    height: 6,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: ToyVerseTheme.bgLightGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
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

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                stage.title,
                                style: AppTypography.displayMedium.copyWith(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? ToyVerseTheme.primaryRed
                                      : (isCompleted ? ToyVerseTheme.textDark : ToyVerseTheme.textMuted),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
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

/// Custom Route Map Painter depicting road spline trajectory and live vehicle position
class _LiveRoutePainter extends CustomPainter {
  final OrderStatus status;

  _LiveRoutePainter({required this.status});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid / Road Texture Background
    final gridPaint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 20; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 20; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Highway Connecting Spline Path (From Top-Left Store to Bottom-Right Destination)
    final start = Offset(size.width * 0.18, size.height * 0.35);
    final control1 = Offset(size.width * 0.40, size.height * 0.18);
    final control2 = Offset(size.width * 0.55, size.height * 0.82);
    final end = Offset(size.width * 0.82, size.height * 0.65);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(control1.dx, control1.dy, control2.dx, control2.dy, end.dx, end.dy);

    // Highway Road Bed
    final roadBedPaint = Paint()
      ..color = ToyVerseTheme.primaryNavy.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, roadBedPaint);

    // Dynamic Route Line
    final routePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          ToyVerseTheme.primaryRoyalBlue,
          ToyVerseTheme.primaryRed,
        ],
      ).createShader(Rect.fromPoints(start, end))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, routePaint);

    // 3. Origin Point (Store) Marker
    final originCenter = start;
    final originHaloPaint = Paint()
      ..color = ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(originCenter, 14, originHaloPaint);

    final originDotPaint = Paint()
      ..color = ToyVerseTheme.primaryRoyalBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(originCenter, 7, originDotPaint);

    final originInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(originCenter, 3.5, originInnerPaint);

    // 4. Destination Point Marker
    final destCenter = end;
    final destHaloPaint = Paint()
      ..color = ToyVerseTheme.primaryRed.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destCenter, 14, destHaloPaint);

    final destDotPaint = Paint()
      ..color = ToyVerseTheme.primaryRed
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destCenter, 7, destDotPaint);

    final destInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destCenter, 3.5, destInnerPaint);

    // 5. Courier Position along spline (Interpolated by Order Status)
    double progress = 0.0;
    switch (status) {
      case OrderStatus.placed:
        progress = 0.05;
        break;
      case OrderStatus.preparing:
        progress = 0.20;
        break;
      case OrderStatus.dispatched:
        progress = 0.52;
        break;
      case OrderStatus.outForDelivery:
        progress = 0.85;
        break;
      case OrderStatus.delivered:
        progress = 0.98;
        break;
      case OrderStatus.cancelled:
        progress = 0.05;
        break;
    }

    // Evaluate cubic bezier at parameter t = progress
    final t = progress;
    final u = 1 - t;
    final courierX = u * u * u * start.dx +
        3 * u * u * t * control1.dx +
        3 * u * t * t * control2.dx +
        t * t * t * end.dx;
    final courierY = u * u * u * start.dy +
        3 * u * u * t * control1.dy +
        3 * u * t * t * control2.dy +
        t * t * t * end.dy;

    final courierPos = Offset(courierX, courierY);

    // Draw Courier Vehicle Pulse & Avatar
    final vehicleGlow = Paint()
      ..color = (status == OrderStatus.delivered ? ToyVerseTheme.primaryMintGreen : ToyVerseTheme.primaryOrange)
          .withValues(alpha: 0.35);
    canvas.drawCircle(courierPos, 16, vehicleGlow);

    final vehicleBody = Paint()
      ..color = (status == OrderStatus.delivered ? ToyVerseTheme.primaryMintGreen : ToyVerseTheme.primaryOrange)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(courierPos, 9, vehicleBody);

    final vehicleCore = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(courierPos, 4, vehicleCore);
  }

  @override
  bool shouldRepaint(covariant _LiveRoutePainter oldDelegate) =>
      oldDelegate.status != status;
}
