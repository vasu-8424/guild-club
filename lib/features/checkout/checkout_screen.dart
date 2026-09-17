import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/razorpay_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/toyverse_theme.dart';
import '../../core/widgets/floating_clouds.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/sparkle_badge.dart';
import '../../core/widgets/toy_button.dart';
import '../../models/address_model.dart';
import '../../models/order_model.dart';
import '../../providers/app_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> with TickerProviderStateMixin {
  int _selectedAddressIndex = 0;
  String _selectedPaymentMethod = 'Razorpay UPI (GPay/PhonePe)';

  final TextEditingController _giftNoteController = TextEditingController(text: 'Happy Birthday Leo! Love Mom & Dad');
  final TextEditingController _couponController = TextEditingController();

  double _appliedDiscount = 0.0;
  String? _appliedCouponCode;
  bool _isProcessingPayment = false;

  late RazorpayService _razorpayService;
  late final AnimationController _successCelebrationController;
  late final AnimationController _confirmationRevealController;

  bool _showSuccessCelebration = false;
  bool _showConfirmationOverlay = false;
  OrderModel? _confirmedOrder;
  String? _confirmedPaymentLabel;

  @override
  void initState() {
    super.initState();
    _successCelebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _confirmationRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _razorpayService = RazorpayService();
    _razorpayService.initialize(
      onSuccess: _onRazorpaySuccess,
      onError: _onRazorpayError,
      onExternalWallet: _onRazorpayExternalWallet,
    );
  }

  @override
  void dispose() {
    _giftNoteController.dispose();
    _couponController.dispose();
    _successCelebrationController.dispose();
    _confirmationRevealController.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code == 'GUILDCLUB100' || code == 'TOYVERSE100') {
      setState(() {
        _appliedDiscount = 100.0;
        _appliedCouponCode = code;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon applied. Saved â‚¹100.'),
          backgroundColor: ToyVerseTheme.primaryMintGreen,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Use code GUILDCLUB100 for â‚¹100 off.'),
        backgroundColor: ToyVerseTheme.primaryOrange,
      ),
    );
  }



  ({double discountedSubtotal, double deliveryFee, double gst, double total}) _calculateTotals(double subtotal) {
    final rawDiscountedSubtotal = subtotal - _appliedDiscount;
    final discountedSubtotal = rawDiscountedSubtotal < 0 ? 0.0 : rawDiscountedSubtotal;
    final deliveryFee = discountedSubtotal >= 499 || discountedSubtotal == 0 ? 0.0 : 49.0;
    final gst = discountedSubtotal * 0.05;
    final total = discountedSubtotal + deliveryFee + gst;
    return (
      discountedSubtotal: discountedSubtotal,
      deliveryFee: deliveryFee,
      gst: gst,
      total: total,
    );
  }

  Future<void> _presentSuccessFlow({
    required OrderModel order,
    required bool celebrate,
    required String paymentLabel,
  }) async {
    if (celebrate) {
      setState(() => _showSuccessCelebration = true);
      await _successCelebrationController.forward(from: 0);
      if (!mounted) {
        return;
      }
      setState(() => _showSuccessCelebration = false);
    }

    setState(() {
      _confirmedOrder = order;
      _confirmedPaymentLabel = paymentLabel;
      _showConfirmationOverlay = true;
    });
    _confirmationRevealController.forward(from: 0);
  }

  Future<void> _onRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() => _isProcessingPayment = true);

    final cartItems = ref.read(cartProvider);
    final subtotal = ref.read(cartTotalAmountProvider);
    final user = ref.read(userProvider);
    final addresses = ref.read(addressesProvider);
    final selectedAddress = addresses.isNotEmpty && _selectedAddressIndex < addresses.length ? addresses[_selectedAddressIndex] : null;
    final totals = _calculateTotals(subtotal);

    bool verified = true;
    if (response.orderId != null && response.paymentId != null && response.signature != null) {
      verified = await SupabaseService.verifyRazorpayPayment(
        orderId: response.orderId!,
        paymentId: response.paymentId!,
        signature: response.signature!,
      );
    }

    if (!mounted) {
      return;
    }

    if (!verified) {
      setState(() => _isProcessingPayment = false);
      _showPaymentErrorDialog('Payment verification failed on server. Please contact support.');
      return;
    }

    final newOrderId = const Uuid().v4();
    final newOrder = OrderModel(
      id: newOrderId,
      userId: user.id,
      addressId: selectedAddress?.id,
      address: selectedAddress,
      deliveryAddressText: selectedAddress?.fullAddress,
      destinationLat: selectedAddress?.latitude,
      destinationLng: selectedAddress?.longitude,
      originLocation: 'Essen Marvella apartments, A block, 410, Suchitra Rd, Sriram Nagar, Jeedimetla, Hyderabad, Telangana 500055 (Landmark: Post Office)',
      originLat: 17.5168,
      originLng: 78.4735,
      items: cartItems
          .map(
            (item) => OrderItemModel(
              productId: item.product.id,
              title: item.product.title,
              quantity: item.quantity,
              unitPrice: item.product.price,
              imageUrl: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null,
              product: item.product,
            ),
          )
          .toList(),
      subtotal: totals.discountedSubtotal,
      total: totals.total,
      gstAmount: totals.gst,
      deliveryFee: totals.deliveryFee,
      discountAmount: _appliedDiscount,
      paymentMethod: 'Razorpay UPI / Card',
      razorpayPaymentId: response.paymentId ?? 'pay_mock_123',
      razorpayOrderId: response.orderId ?? 'order_mock_123',
      status: OrderStatus.placed,
      statusUpdatedAt: DateTime.now(),
      statusHistory: {
        'placed': DateTime.now().toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    ref.read(ordersProvider.notifier).placeOrder(newOrder);
    ref.read(cartProvider.notifier).clearCart();
    ref.read(userProvider.notifier).addCoins(100);

    setState(() => _isProcessingPayment = false);

    await _presentSuccessFlow(
      order: newOrder,
      celebrate: true,
      paymentLabel: response.paymentId == null ? 'PAYMENT_SUCCESS' : response.paymentId!,
    );
  }

  void _onRazorpayError(PaymentFailureResponse response) {
    setState(() => _isProcessingPayment = false);
    _showPaymentErrorDialog('Payment failed (${response.code}): ${response.message}');
  }

  void _onRazorpayExternalWallet(ExternalWalletResponse response) {
    setState(() => _isProcessingPayment = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirecting to ${response.walletName}...')),
    );
  }

  void _showPaymentErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Payment issue',
          style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          message,
          style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: ToyVerseTheme.textDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Retry payment',
              style: AppTypography.bodyLarge.copyWith(color: ToyVerseTheme.primaryNavy, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processCODOrder({
    required double subtotal,
    required List cartItems,
    required AddressModel? address,
  }) async {
    final user = ref.read(userProvider);
    final totals = _calculateTotals(subtotal);

    final newOrderId = const Uuid().v4();
    final newOrder = OrderModel(
      id: newOrderId,
      userId: user.id,
      addressId: address?.id,
      address: address,
      deliveryAddressText: address?.fullAddress,
      destinationLat: address?.latitude,
      destinationLng: address?.longitude,
      originLocation: 'Essen Marvella apartments, A block, 410, Suchitra Rd, Sriram Nagar, Jeedimetla, Hyderabad, Telangana 500055 (Landmark: Post Office)',
      originLat: 17.5168,
      originLng: 78.4735,
      items: cartItems
          .map(
            (item) => OrderItemModel(
              productId: item.product.id,
              title: item.product.title,
              quantity: item.quantity,
              unitPrice: item.product.price,
              imageUrl: item.product.imageUrls.isNotEmpty ? item.product.imageUrls.first : null,
              product: item.product,
            ),
          )
          .toList(),
      subtotal: totals.discountedSubtotal,
      total: totals.total,
      gstAmount: totals.gst,
      deliveryFee: totals.deliveryFee,
      discountAmount: _appliedDiscount,
      paymentMethod: 'Cash on Delivery',
      status: OrderStatus.placed,
      statusUpdatedAt: DateTime.now(),
      statusHistory: {
        'placed': DateTime.now().toIso8601String(),
      },
      createdAt: DateTime.now(),
    );

    ref.read(ordersProvider.notifier).placeOrder(newOrder);
    ref.read(cartProvider.notifier).clearCart();
    ref.read(userProvider.notifier).addCoins(50);

    await _presentSuccessFlow(
      order: newOrder,
      celebrate: false,
      paymentLabel: 'Cash on Delivery',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartTotalAmountProvider);
    final addresses = ref.watch(addressesProvider);
    final user = ref.watch(userProvider);
    final totals = _calculateTotals(subtotal);

    final selectedAddress = addresses.isNotEmpty && _selectedAddressIndex < addresses.length
        ? addresses[_selectedAddressIndex]
        : (addresses.isNotEmpty ? addresses.first : null);

    return Scaffold(
      body: Stack(
        children: [
          FloatingCloudsBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => context.canPop() ? context.pop() : context.go('/cart'),
                          icon: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.arrow_back_rounded, color: ToyVerseTheme.textDark),
                          ),
                        ),
                        Text(
                          'Checkout',
                          style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Delivery Address', style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                                    _CalmPress(
                                      onTap: () async {
                                        final newAddr = await context.push<AddressModel>('/address-picker');
                                        if (newAddr != null && mounted) {
                                          setState(() => _selectedAddressIndex = 0);
                                        }
                                      },
                                      child: Text(
                                        addresses.isEmpty ? '+ Add Address' : 'Change / + Add New',
                                        style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: ToyVerseTheme.primaryRoyalBlue),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (selectedAddress == null)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_off_rounded, color: ToyVerseTheme.textMuted),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'No delivery address set. Tap Change / + Add New to set location.',
                                            style: AppTypography.bodyMedium.copyWith(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  _CalmPress(
                                    onTap: () async {
                                      final newAddr = await context.push<AddressModel>('/address-picker');
                                      if (newAddr != null && mounted) {
                                        setState(() => _selectedAddressIndex = 0);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: ToyVerseTheme.primaryRoyalBlue,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.location_on_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Wrap(
                                                  spacing: 6,
                                                  crossAxisAlignment: WrapCrossAlignment.center,
                                                  children: [
                                                    Text(selectedAddress.label, style: AppTypography.bodyLarge.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                                                    const SparkleBadge(label: 'DELIVERY PIN', backgroundColor: ToyVerseTheme.primaryNavy, fontSize: 8),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  selectedAddress.fullAddress,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: ToyVerseTheme.textDark),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.edit_location_alt_rounded, size: 18, color: ToyVerseTheme.primaryRoyalBlue),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (selectedAddress != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: ToyVerseTheme.primaryNavy.withValues(alpha: 0.15)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.my_location_rounded, color: ToyVerseTheme.primaryNavy, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'GPS: ${selectedAddress.latitude.toStringAsFixed(4)}, ${selectedAddress.longitude.toStringAsFixed(4)} â€¢ ${selectedAddress.city}',
                                            style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: ToyVerseTheme.primaryNavy),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Shop Origin & Delivery Timeline Notice
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.2)),
                              boxShadow: [
                                BoxShadow(
                                  color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ToyVerseTheme.primaryRoyalBlue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: ToyVerseTheme.primaryRoyalBlue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Guild Club Hub, Essen Marvella, Suchitra Rd, Jeedimetla, Hyderabad',
                                        style: AppTypography.bodyLarge.copyWith(fontSize: 13, fontWeight: FontWeight.w800, color: ToyVerseTheme.primaryNavy),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Landmark: Post Office â€¢ Hyderabad Local: 2â€“3 Days â€¢ Outside: 7â€“8 Days',
                                        style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: ToyVerseTheme.textDark, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Coupon', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                _PressSurface(
                                  child: TextField(
                                    controller: _couponController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. GUILDCLUB100',
                                      filled: true,
                                      fillColor: Colors.white,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _CalmPress(
                                      onTap: _applyCoupon,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: ToyVerseTheme.primaryRoyalBlue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text('Apply', style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    if (_appliedCouponCode != null)
                                      Expanded(
                                        child: Text(
                                          'Applied: $_appliedCouponCode (-â‚¹${_appliedDiscount.toInt()})',
                                          style: AppTypography.bodyMedium.copyWith(color: ToyVerseTheme.primaryMintGreen, fontWeight: FontWeight.w700),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Personal Gift Note (Optional)', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _giftNoteController,
                                  style: AppTypography.accentScript.copyWith(fontSize: 18, color: ToyVerseTheme.textDark),
                                  decoration: InputDecoration(
                                    hintText: 'Write a special message for the child...',
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Payment Method', style: AppTypography.displayMedium.copyWith(fontSize: 18, fontWeight: FontWeight.w800)),
                                    const SparkleBadge(label: 'SECURE', backgroundColor: ToyVerseTheme.primaryMintGreen),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _buildPaymentOption('Razorpay UPI (GPay/PhonePe)', Icons.account_balance_wallet_rounded, 'Instant payment'),
                                _buildPaymentOption('Credit / Debit Cards', Icons.credit_card_rounded, 'Visa, Mastercard, RuPay'),
                                _buildPaymentOption('NetBanking / Wallets', Icons.account_balance_rounded, 'All major banks'),
                                _buildPaymentOption('Cash on Delivery', Icons.payments_rounded, 'Pay on delivery'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GlassCard(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                _buildSummaryRow('Subtotal', totals.discountedSubtotal),
                                if (_appliedDiscount > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Promo Discount', style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: ToyVerseTheme.primaryMintGreen, fontWeight: FontWeight.w600)),
                                        Text(
                                          '-â‚¹${_appliedDiscount.toStringAsFixed(0)}',
                                          style: AppTypography.priceNumeral.copyWith(fontSize: 15, color: ToyVerseTheme.primaryMintGreen, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Wrap(
                                          spacing: 6,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text('Delivery Fee', style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: ToyVerseTheme.textMuted)),
                                            if (totals.deliveryFee == 0)
                                              const SparkleBadge(label: 'FREE > â‚¹499', backgroundColor: ToyVerseTheme.primaryMintGreen, fontSize: 8),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        totals.deliveryFee == 0 ? 'FREE' : 'â‚¹${totals.deliveryFee.toStringAsFixed(0)}',
                                        style: AppTypography.priceNumeral.copyWith(
                                          fontSize: 15,
                                          color: totals.deliveryFee == 0 ? ToyVerseTheme.primaryMintGreen : ToyVerseTheme.textDark,
                                          fontWeight: totals.deliveryFee == 0 ? FontWeight.w800 : FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildSummaryRow('GST (5%)', totals.gst),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total', style: AppTypography.displayMedium.copyWith(fontSize: 20, fontWeight: FontWeight.w800)),
                                    Text(
                                      'â‚¹${totals.total.toStringAsFixed(0)}',
                                      style: AppTypography.priceNumeral.copyWith(fontSize: 22, color: ToyVerseTheme.primaryOrange),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: ToyButton(
                      text: 'Pay â‚¹${totals.total.toStringAsFixed(0)}',
                      gradient: ToyVerseTheme.orangeYellowGradient,
                      isLoading: _isProcessingPayment,
                      onPressed: () {
                        if (cartItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Your cart is empty.')),
                          );
                          return;
                        }

                        if (_selectedPaymentMethod == 'Cash on Delivery') {
                          _processCODOrder(subtotal: subtotal, cartItems: cartItems, address: selectedAddress);
                          return;
                        }

                        setState(() => _isProcessingPayment = true);
                        _razorpayService.openCheckout(
                          amountInRupees: totals.total,
                          name: user.fullName,
                          email: user.email,
                          phone: user.phone,
                          description: 'Guild Club Order Payment',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showSuccessCelebration)
            Positioned.fill(
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _successCelebrationController, curve: Curves.easeOutExpo),
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.92),
                  child: Center(
                    child: SizedBox(
                      width: 260,
                      height: 260,
                      child: Lottie.network(
                        'https://assets10.lottiefiles.com/packages/lf20_obhph3sh.json',
                        controller: _successCelebrationController,
                        repeat: false,
                        fit: BoxFit.contain,
                        errorBuilder: (context, _, __) => const Icon(
                          Icons.check_circle_rounded,
                          size: 120,
                          color: ToyVerseTheme.primaryMintGreen,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (_showConfirmationOverlay && _confirmedOrder != null)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.22),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(22),
                child: AnimatedBuilder(
                  animation: _confirmationRevealController,
                  builder: (context, child) {
                    final reveal = Curves.easeOutExpo.transform(_confirmationRevealController.value);
                    return Transform.translate(
                      offset: Offset(0, 28 * (1 - reveal)),
                      child: Opacity(opacity: reveal, child: child),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: GlassCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            radius: 34,
                            backgroundColor: ToyVerseTheme.primaryMintGreen,
                            child: Icon(Icons.check_rounded, color: Colors.white, size: 44),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Order confirmed',
                            textAlign: TextAlign.center,
                            style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Payment: ${_confirmedPaymentLabel ?? 'Success'}',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 13, color: ToyVerseTheme.textMuted, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ToyVerseTheme.primaryRoyalBlue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onPressed: () {
                                final orderId = _confirmedOrder!.id;
                                setState(() => _showConfirmationOverlay = false);
                                context.go('/tracking/$orderId');
                              },
                              child: Text(
                                'Track Order',
                                style: AppTypography.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(fontSize: 14, color: ToyVerseTheme.textMuted)),
          Text(
            'â‚¹${amount.toStringAsFixed(0)}',
            style: AppTypography.priceNumeral.copyWith(fontSize: 15, color: ToyVerseTheme.textDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, String subtitle) {
    final isSelected = _selectedPaymentMethod == title;
    return _CalmPress(
      onTap: () => setState(() => _selectedPaymentMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? ToyVerseTheme.primaryOrange.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? ToyVerseTheme.primaryOrange : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? ToyVerseTheme.primaryOrange : ToyVerseTheme.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge.copyWith(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: ToyVerseTheme.textMuted)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: ToyVerseTheme.primaryOrange),
          ],
        ),
      ),
    );
  }
}

class _CalmPress extends StatefulWidget {
  const _CalmPress({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_CalmPress> createState() => _CalmPressState();
}

class _CalmPressState extends State<_CalmPress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutExpo,
        scale: _pressed ? 0.98 : 1.0,
        child: widget.child,
      ),
    );
  }
}

class _PressSurface extends StatefulWidget {
  const _PressSurface({required this.child});

  final Widget child;

  @override
  State<_PressSurface> createState() => _PressSurfaceState();
}

class _PressSurfaceState extends State<_PressSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutExpo,
        scale: _pressed ? 0.99 : 1.0,
        child: widget.child,
      ),
    );
  }
}
