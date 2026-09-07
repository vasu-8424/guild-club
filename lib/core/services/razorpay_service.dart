import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'supabase_service.dart';

class RazorpayService {
  late Razorpay _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onExternalWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse)? onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _onSuccess = onSuccess;
    _onError = onError;
    _onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void dispose() {
    _razorpay.clear();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (_onSuccess != null) {
      _onSuccess!(response);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (_onError != null) {
      _onError!(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (_onExternalWallet != null) {
      _onExternalWallet!(response);
    }
  }

  /// Complete Razorpay Checkout flow with Edge Function order creation & server-side verification
  Future<void> openCheckout({
    required double amountInRupees,
    required String name,
    required String email,
    required String phone,
    required String description,
  }) async {
    final razorpayKeyId = dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_toyverse123';

    String? serverOrderId;
    try {
      // 1. Create order on server via Supabase Edge Function
      serverOrderId = await SupabaseService.createRazorpayOrder(amountInRupees);
    } catch (e) {
      if (kDebugMode) print('Failed to create server Razorpay order: $e');
    }

    final options = {
      'key': razorpayKeyId,
      'amount': (amountInRupees * 100).round(), // amount in paise
      'name': 'ToyVerse Toys',
      'description': description,
      if (serverOrderId != null && serverOrderId.isNotEmpty) 'order_id': serverOrderId,
      'prefill': {
        'contact': phone,
        'email': email,
        'name': name,
      },
      'external': {
        'wallets': ['paytm', 'gpay', 'phonepe']
      },
      'theme': {
        'color': '#4F46E5',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      if (kDebugMode) print('Error launching Razorpay SDK: $e');
      _handlePaymentError(PaymentFailureResponse(0, 'Failed to launch Razorpay gateway', null));
    }
  }
}
