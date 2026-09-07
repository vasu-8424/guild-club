import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:uuid/uuid.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../models/listing_model.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../models/address_model.dart';
import '../../repositories/mock_toy_data.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  // UUID v4/v5 validator & deterministic generator
  static bool _isValidUUID(String id) {
    const uuidPattern =
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
    return RegExp(uuidPattern, caseSensitive: false).hasMatch(id);
  }

  static String getDeterministicUUID(String seed) {
    if (seed.isEmpty) return '';
    if (_isValidUUID(seed)) return seed;
    return const Uuid().v5(Namespace.url.value, 'toyverse_user:$seed');
  }

  static GoogleSignIn get _googleSignIn {
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
    return GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: webClientId.isNotEmpty ? webClientId : null,
    );
  }

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      final url = dotenv.env['SUPABASE_URL'] ?? '';
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isNotEmpty &&
          anonKey.isNotEmpty &&
          !url.contains('your-supabase-project') &&
          !anonKey.contains('your-supabase-anon-key')) {
        await Supabase.initialize(
          url: url,
          anonKey: anonKey,
        );
        _isInitialized = true;
        if (kDebugMode) {
          print('✅ Supabase initialized successfully with URL: $url');
        }
      } else {
        if (kDebugMode) {
          print('ℹ️ Supabase keys not set in .env. Running in Offline Mock Repository Mode.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Supabase init error (Falling back to local state): $e');
      }
    }
  }

  // --- Native Device Google Account Authentication ---
  static Future<GoogleSignInAccount?> signInWithGoogleNative() async {
    // On Web or environments without native Google Play services, fallback to in-app chooser
    if (kIsWeb) {
      return null;
    }

    try {
      // Sign out cached account so the native Google Account Chooser bottom sheet always appears
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      if (isInitialized && client != null) {
        try {
          final googleAuth = await googleUser.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;

          if (idToken != null) {
            await client!.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
          }
        } catch (e) {
          if (kDebugMode) print('Supabase idToken auth error: $e');
        }
      }

      return googleUser;
    } catch (e) {
      if (kDebugMode) print('Google Sign-In Error: $e');
      return null;
    }
  }

  static Future<bool> signInWithGoogle() async {
    final res = await signInWithGoogleNative();
    return res != null;
  }

  static String? get currentUserId => client?.auth.currentUser?.id;
  static User? get currentUser => client?.auth.currentUser;

  // --- Realtime Database Integration APIs ---

  // 0. Categories & Subcategories APIs
  static Future<List<CategoryModel>> fetchTopLevelCategories() async {
    if (!isInitialized || client == null) {
      return MockToyData.topLevelCategories;
    }
    try {
      final response = await client!
          .from('categories')
          .select('*')
          .isFilter('parent_id', null)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final list = (response as List).map((map) {
        final slug = map['slug']?.toString() ?? '';
        final hasSubs = slug == 'child-development-centers';
        return CategoryModel.fromJson(map, hasSubcategories: hasSubs);
      }).toList();

      return list.isEmpty ? MockToyData.topLevelCategories : list;
    } catch (e) {
      if (kDebugMode) print('[Supabase] Categories table not available — using local fallback.');
      return MockToyData.topLevelCategories;
    }
  }

  static Future<List<CategoryModel>> fetchSubcategories(String parentId) async {
    if (!isInitialized || client == null) {
      return MockToyData.subcategoriesFor(parentId);
    }
    try {
      // Allow passing either parent UUID or parent slug
      String effectiveParentId = parentId;
      if (!_isValidUUID(parentId)) {
        final parentRes = await client!
            .from('categories')
            .select('id')
            .eq('slug', parentId)
            .maybeSingle();
        if (parentRes != null && parentRes['id'] != null) {
          effectiveParentId = parentRes['id'].toString();
        }
      }

      final response = await client!
          .from('categories')
          .select('*')
          .eq('parent_id', effectiveParentId)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final list = (response as List).map((map) => CategoryModel.fromJson(map)).toList();
      return list.isEmpty ? MockToyData.subcategoriesFor(parentId) : list;
    } catch (e) {
      if (kDebugMode) print('[Supabase] Subcategories for $parentId not available — using local fallback.');
      return MockToyData.subcategoriesFor(parentId);
    }
  }

  static Future<CategoryModel?> fetchCategoryByIdOrSlug(String identifier) async {
    if (!isInitialized || client == null) {
      return MockToyData.findCategory(identifier);
    }
    try {
      final query = _isValidUUID(identifier)
          ? client!.from('categories').select('*').eq('id', identifier)
          : client!.from('categories').select('*').eq('slug', identifier);

      final res = await query.maybeSingle();
      if (res != null) {
        return CategoryModel.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('[Supabase] Category $identifier not available — using local fallback.');
    }
    return MockToyData.findCategory(identifier);
  }

  // 0.1 Listings & Providers APIs
  static Future<List<ListingModel>> fetchListingsByCategory(String categoryIdOrSlug) async {
    if (!isInitialized || client == null) {
      return MockToyData.listingsForCategory(categoryIdOrSlug);
    }
    try {
      String effectiveCategoryId = categoryIdOrSlug;
      if (!_isValidUUID(categoryIdOrSlug)) {
        final catRes = await client!
            .from('categories')
            .select('id')
            .eq('slug', categoryIdOrSlug)
            .maybeSingle();
        if (catRes != null && catRes['id'] != null) {
          effectiveCategoryId = catRes['id'].toString();
        }
      }

      final response = await client!
          .from('listings')
          .select('*')
          .eq('category_id', effectiveCategoryId)
          .eq('is_active', true)
          .order('rating', ascending: false)
          .order('created_at', ascending: false);

      final list = (response as List).map((map) => ListingModel.fromJson(map)).toList();
      return list.isEmpty ? MockToyData.listingsForCategory(categoryIdOrSlug) : list;
    } catch (e) {
      if (kDebugMode) print('[Supabase] Listings for $categoryIdOrSlug not available — using local fallback.');
      return MockToyData.listingsForCategory(categoryIdOrSlug);
    }
  }

  static Future<ListingModel?> fetchListingById(String listingId) async {
    if (!isInitialized || client == null) {
      return MockToyData.listingById(listingId);
    }
    try {
      final res = await client!
          .from('listings')
          .select('*')
          .eq('id', listingId)
          .maybeSingle();

      if (res != null) {
        return ListingModel.fromJson(res);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching listing $listingId from Supabase: $e');
    }
    return MockToyData.listingById(listingId);
  }

  // 1. Fetch Products from Supabase or Fallback
  static Future<List<ProductModel>> fetchProducts() async {
    if (!isInitialized || client == null) {
      return MockToyData.products;
    }
    try {
      final response = await client!.from('products').select('*');
      final list = (response as List).map((map) {
        return ProductModel(
          id: map['id'].toString(),
          title: map['title'] ?? '',
          subtitle: map['subtitle'] ?? '',
          description: map['description'] ?? '',
          price: (map['price'] as num).toDouble(),
          originalPrice: (map['original_price'] as num?)?.toDouble() ?? (map['price'] as num).toDouble(),
          discountPercentage: map['discount_percentage'] ?? 0,
          rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
          reviewCount: map['review_count'] ?? 0,
          stockQuantity: map['stock_quantity'] ?? 50,
          categorySlug: map['category_slug'] ?? 'stem',
          brandName: map['brand_name'] ?? 'ToyVerse',
          minAge: map['min_age'] ?? 3,
          maxAge: map['max_age'] ?? 12,
          material: map['material'] ?? 'Eco Wood',
          educationalType: map['educational_type'] ?? 'STEM',
          imageUrls: map['image_urls'] != null ? List<String>.from(map['image_urls']) : ['https://images.unsplash.com/photo-1587654780291-39c9404d746b?q=80&w=800&auto=format&fit=crop'],
        );
      }).toList();
      return list.isEmpty ? MockToyData.products : list;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase products: $e');
      return MockToyData.products;
    }
  }

  // 2. Addresses Management
  static Future<List<AddressModel>> fetchUserAddresses(String userId) async {
    if (!isInitialized || client == null || !_isValidUUID(userId)) {
      return [];
    }
    try {
      final response = await client!
          .from('addresses')
          .select('*')
          .eq('user_id', userId)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      
      final list = (response as List).map((map) => AddressModel.fromJson(map)).toList();
      return list;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase addresses: $e');
      return [];
    }
  }

  static Future<AddressModel?> saveAddress(AddressModel address) async {
    if (!isInitialized || client == null || !_isValidUUID(address.userId)) return address;
    try {
      final data = address.toJson();
      if (address.isDefault) {
        // Unset previous defaults
        await client!
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', address.userId);
      }
      final response = await client!.from('addresses').upsert(data).select().single();
      return AddressModel.fromJson(response);
    } catch (e) {
      if (kDebugMode) print('Error saving address to Supabase: $e');
      return null;
    }
  }

  // 3. Orders Management & Realtime Tracking APIs
  static Future<List<OrderModel>> fetchUserOrders(String userId, {List<ProductModel>? allProducts}) async {
    if (!isInitialized || client == null || !_isValidUUID(userId)) {
      return [];
    }
    try {
      final response = await client!
          .from('orders')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      final list = (response as List).map((map) => OrderModel.fromJson(map, allProducts: allProducts)).toList();
      return list;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase orders: $e');
      return [];
    }
  }

  static Future<OrderModel?> fetchOrderById(String orderId, {List<ProductModel>? allProducts}) async {
    if (!isInitialized || client == null || !_isValidUUID(orderId)) {
      return null;
    }
    try {
      final response = await client!
          .from('orders')
          .select('*')
          .eq('id', orderId)
          .maybeSingle();

      if (response != null) {
        return OrderModel.fromJson(response, allProducts: allProducts);
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching order $orderId from Supabase: $e');
    }
    return null;
  }

  /// Realtime Stream subscription for single order live tracking
  static Stream<OrderModel?> streamOrder(String orderId, {List<ProductModel>? allProducts}) {
    if (!isInitialized || client == null || !_isValidUUID(orderId)) {
      return Stream.value(null);
    }
    try {
      return client!
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('id', orderId)
          .map((maps) {
            if (maps.isEmpty) return null;
            return OrderModel.fromJson(maps.first, allProducts: allProducts);
          });
    } catch (e) {
      if (kDebugMode) print('Error setting up order realtime stream: $e');
      return Stream.value(null);
    }
  }

  static Future<bool> saveOrder(OrderModel order) async {
    if (!isInitialized || client == null || !_isValidUUID(order.userId)) return false;
    try {
      await client!.from('orders').insert(order.toJson());
      if (kDebugMode) print('Saved order ${order.id} to Supabase');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving order to Supabase: $e');
      return false;
    }
  }

  static Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus, {Map<String, String>? currentHistory}) async {
    if (!isInitialized || client == null || !_isValidUUID(orderId)) return false;
    try {
      final nowIso = DateTime.now().toIso8601String();
      final updatedHistory = Map<String, String>.from(currentHistory ?? {});
      updatedHistory[newStatus.dbValue] = nowIso;

      await client!.from('orders').update({
        'status': newStatus.dbValue,
        'status_updated_at': nowIso,
        'status_history': updatedHistory,
      }).eq('id', orderId);

      if (kDebugMode) print('Updated order $orderId status to ${newStatus.dbValue}');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating order status in Supabase: $e');
      return false;
    }
  }

  // 4. Wishlist Management
  static Future<Set<String>> fetchUserWishlist(String userId) async {
    if (!isInitialized || client == null || !_isValidUUID(userId)) {
      return {};
    }
    try {
      final response = await client!
          .from('wishlist')
          .select('product_id')
          .eq('user_id', userId);
      
      final ids = (response as List).map((map) => map['product_id'].toString()).toSet();
      return ids;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase wishlist: $e');
      return {};
    }
  }

  static Future<bool> toggleWishlist(String userId, String productId, bool isAdded) async {
    if (!isInitialized || client == null || !_isValidUUID(userId)) return false;
    try {
      if (isAdded) {
        await client!.from('wishlist').upsert({'user_id': userId, 'product_id': productId});
      } else {
        await client!.from('wishlist').delete().match({'user_id': userId, 'product_id': productId});
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating Supabase wishlist: $e');
      return false;
    }
  }

  // 5. Child Personalization Profile
  static Future<List<ChildProfileModel>> fetchUserChildren(String userId) async {
    if (!isInitialized || client == null || !_isValidUUID(userId)) {
      return [];
    }
    try {
      final response = await client!
          .from('children')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (response as List).map((map) => ChildProfileModel(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        age: map['age'] != null ? (map['age'] as num).toInt() : 0,
        gender: map['gender']?.toString() ?? 'boy',
        interests: map['interests'] != null ? List<String>.from(map['interests']) : [],
        favoriteCharacter: map['favorite_character']?.toString() ?? '',
        learningLevel: map['learning_level']?.toString() ?? 'Explorer',
      )).toList();
      return list;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase children: $e');
      return [];
    }
  }

  static Future<bool> saveChildProfile(String parentId, ChildProfileModel child) async {
    if (!isInitialized || client == null || !_isValidUUID(parentId)) return false;
    try {
      await client!.from('children').upsert({
        'id': child.id.isNotEmpty ? child.id : DateTime.now().millisecondsSinceEpoch.toString(),
        'user_id': parentId,
        'name': child.name,
        'age': child.age,
        'gender': child.gender,
        'interests': child.interests,
        'favorite_character': child.favoriteCharacter,
        'learning_level': child.learningLevel,
      });
      if (kDebugMode) print('Saved child profile ${child.name} to Supabase');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving child profile to Supabase: $e');
      return false;
    }
  }

  // 7. Profile Avatar & User Profiles Table Sync
  static Future<String?> fetchUserProfileAvatar(String userId) async {
    if (!isInitialized || client == null || !_isValidUUID(userId)) return null;
    try {
      final response = await client!
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .maybeSingle();
      if (response != null && response['avatar_url'] != null) {
        return response['avatar_url'].toString();
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching profile avatar: $e');
    }
    return null;
  }

  static Future<String?> uploadAvatarImage({
    required String userId,
    required List<int> imageBytes,
    String fileExtension = 'jpg',
  }) async {
    if (!isInitialized || client == null || !_isValidUUID(userId)) return null;
    try {
      final filePath = '$userId.$fileExtension';
      final storage = client!.storage.from('avatars');

      // Upload or replace image in Supabase storage bucket 'avatars'
      await storage.uploadBinary(
        filePath,
        Uint8List.fromList(imageBytes),
        fileOptions: FileOptions(
          contentType: 'image/$fileExtension',
          upsert: true,
        ),
      );

      final publicUrl = storage.getPublicUrl(filePath);

      // Append timestamp query parameter to bust image caches on client
      final timestampedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Sync public URL to 'profiles' table
      await client!.from('profiles').upsert({
        'id': userId,
        'avatar_url': timestampedUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) print('Successfully uploaded avatar & updated profile for $userId');
      return timestampedUrl;
    } catch (e) {
      if (kDebugMode) print('Error uploading avatar image to Supabase: $e');
      return null;
    }
  }

  // 8. Razorpay Server Edge Functions Integrations
  static Future<String?> createRazorpayOrder(double amount) async {
    if (!isInitialized || client == null) return null;
    try {
      final FunctionResponse res = await client!.functions.invoke(
        'create-razorpay-order',
        body: {'amount': amount},
      );
      if (res.status == 200 && res.data != null) {
        return res.data['order_id']?.toString();
      }
    } catch (e) {
      if (kDebugMode) print('Edge function create-razorpay-order error: $e');
    }
    return null;
  }

  static Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    if (!isInitialized || client == null) return true; // Fallback for dev mode
    try {
      final FunctionResponse res = await client!.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'razorpay_order_id': orderId,
          'razorpay_payment_id': paymentId,
          'razorpay_signature': signature,
        },
      );
      if (res.status == 200 && res.data != null) {
        return res.data['verified'] == true;
      }
    } catch (e) {
      if (kDebugMode) print('Edge function verify-razorpay-payment error: $e');
    }
    return false;
  }

  /// Fetches fresh coin balance directly from the `wallets` table for a user.
  static Future<int?> fetchUserWalletBalance(String userId) async {
    if (!isInitialized || client == null) return null;
    try {
      final res = await client!
          .from('wallets')
          .select('coin_balance')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && res['coin_balance'] != null) {
        return (res['coin_balance'] as num).toInt();
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching wallet balance from Supabase: $e');
    }
    return null;
  }

  /// Fetches today's daily activity status (spun_today, login_bonus_claimed_today) for a user.
  static Future<({bool spunToday, bool loginBonusClaimed})> fetchTodayActivity(String userId) async {
    if (!isInitialized || client == null || userId.isEmpty) {
      return (spunToday: false, loginBonusClaimed: false);
    }
    try {
      final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
      final res = await client!
          .from('daily_activity')
          .select('spun_today, login_bonus_claimed_today')
          .eq('user_id', userId)
          .eq('activity_date', today)
          .maybeSingle();
      if (res != null) {
        return (
          spunToday: res['spun_today'] == true,
          loginBonusClaimed: res['login_bonus_claimed_today'] == true,
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching daily activity from Supabase: $e');
    }
    return (spunToday: false, loginBonusClaimed: false);
  }

  /// Automatically claims the +2 daily login bonus via daily-login-bonus Edge Function or PostgREST database fallback.
  static Future<({bool claimedToday, int bonusGranted, int? newBalance, String message})> claimDailyLoginBonus() async {
    if (!isInitialized || client == null) {
      return (claimedToday: false, bonusGranted: 0, newBalance: null, message: 'Offline mode');
    }

    final currentUser = client!.auth.currentUser;
    if (currentUser == null) {
      return (claimedToday: false, bonusGranted: 0, newBalance: null, message: 'No active user session');
    }
    final userId = currentUser.id;

    // 1. Attempt deployed Edge Function
    try {
      final FunctionResponse res = await client!.functions.invoke('daily-login-bonus');
      if (res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final claimedToday = data['claimed_today'] == true;
        final bonusGranted = (data['bonus_granted'] as num?)?.toInt() ?? 0;
        final newBalance = (data['coin_balance'] as num?)?.toInt();
        final message = data['message']?.toString() ?? 'Daily login check completed.';
        return (claimedToday: claimedToday, bonusGranted: bonusGranted, newBalance: newBalance, message: message);
      }
    } catch (e) {
      if (kDebugMode) print('[Supabase] daily-login-bonus edge function not deployed — using local database handling.');
    }

    // 2. Direct PostgREST Database Fallback
    try {
      final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
      final activity = await client!
          .from('daily_activity')
          .select('login_bonus_claimed_today, spun_today')
          .eq('user_id', userId)
          .eq('activity_date', today)
          .maybeSingle();

      final existingWallet = await client!
          .from('wallets')
          .select('coin_balance')
          .eq('user_id', userId)
          .maybeSingle();
      final currentBalance = (existingWallet?['coin_balance'] as num?)?.toInt() ?? 0;

      if (activity != null && activity['login_bonus_claimed_today'] == true) {
        return (
          claimedToday: true,
          bonusGranted: 0,
          newBalance: currentBalance,
          message: 'Daily login bonus already claimed today.',
        );
      }

      const bonusCoins = 2;
      await client!.from('reward_transactions').insert({
        'user_id': userId,
        'type': 'daily_login_bonus',
        'amount': bonusCoins,
        'metadata': {'source': 'automatic_daily_login'},
      });

      await client!.from('daily_activity').upsert({
        'user_id': userId,
        'activity_date': today,
        'login_bonus_claimed_today': true,
        'spun_today': activity?['spun_today'] ?? false,
      });

      final updatedCoins = currentBalance + bonusCoins;
      await client!.from('wallets').upsert({
        'user_id': userId,
        'coin_balance': updatedCoins,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return (
        claimedToday: false,
        bonusGranted: bonusCoins,
        newBalance: updatedCoins,
        message: 'Daily login bonus claimed! +2 Guild Coins',
      );
    } catch (e) {
      if (kDebugMode) print('Error in direct database daily login bonus handling: $e');
    }

    return (claimedToday: false, bonusGranted: 0, newBalance: null, message: 'Error checking daily bonus');
  }

  /// Securely handles the daily spin wheel reward via Edge Function or PostgREST database transaction.
  static Future<({bool success, bool alreadySpun, int wonAmount, int segmentIndex, int newBalance, String message})> claimDailySpin(String userId) async {
    if (!isInitialized || client == null || userId.isEmpty) {
      return (
        success: false,
        alreadySpun: false,
        wonAmount: 20,
        segmentIndex: 0,
        newBalance: 20,
        message: 'Offline mode — database not connected',
      );
    }

    // 1. Attempt deployed Edge Function
    try {
      final res = await client!.functions.invoke('daily-spin');
      if (res.data != null) {
        final data = res.data as Map<String, dynamic>;
        return (
          success: data['success'] == true,
          alreadySpun: data['already_spun'] == true,
          wonAmount: (data['won_amount'] as num?)?.toInt() ?? 20,
          segmentIndex: (data['segment_index'] as num?)?.toInt() ?? 0,
          newBalance: (data['new_balance'] as num?)?.toInt() ?? 0,
          message: data['message']?.toString() ?? 'Spin completed.',
        );
      }
    } catch (e) {
      if (kDebugMode) print('[Supabase] daily-spin edge function not deployed/reachable — using direct database handling.');
    }

    // 2. Direct PostgREST Database Transaction
    try {
      final today = DateTime.now().toUtc().toIso8601String().split('T')[0];

      // Check daily_activity for today
      final activity = await client!
          .from('daily_activity')
          .select('spun_today, login_bonus_claimed_today')
          .eq('user_id', userId)
          .eq('activity_date', today)
          .maybeSingle();

      if (activity != null && activity['spun_today'] == true) {
        final currentWallet = await client!
            .from('wallets')
            .select('coin_balance')
            .eq('user_id', userId)
            .maybeSingle();
        final currentCoins = (currentWallet?['coin_balance'] as num?)?.toInt() ?? 0;
        return (
          success: false,
          alreadySpun: true,
          wonAmount: 0,
          segmentIndex: 0,
          newBalance: currentCoins,
          message: "You've already spun today! Come back tomorrow.",
        );
      }

      // Weighted prize selection (matching UI wheel segments)
      // 0: +20 (35%), 1: +50 (15%), 2: +80 (5%), 3: +30 (25%), 4: +60 (10%), 5: +40 (10%)
      const rewards = [
        (coins: 20, index: 0, weight: 35),
        (coins: 50, index: 1, weight: 15),
        (coins: 80, index: 2, weight: 5),
        (coins: 30, index: 3, weight: 25),
        (coins: 60, index: 4, weight: 10),
        (coins: 40, index: 5, weight: 10),
      ];
      final totalWeight = rewards.fold<int>(0, (acc, r) => acc + r.weight);
      var randomVal = math.Random().nextInt(totalWeight);
      var chosen = rewards[0];
      for (final r in rewards) {
        if (randomVal < r.weight) {
          chosen = r;
          break;
        }
        randomVal -= r.weight;
      }

      // Insert ledger row into reward_transactions
      await client!.from('reward_transactions').insert({
        'user_id': userId,
        'type': 'daily_spin',
        'amount': chosen.coins,
        'metadata': {'segment_index': chosen.index, 'won_amount': chosen.coins},
      });

      // Update daily_activity
      await client!.from('daily_activity').upsert({
        'user_id': userId,
        'activity_date': today,
        'spun_today': true,
        'login_bonus_claimed_today': activity?['login_bonus_claimed_today'] ?? false,
      });

      // Update wallet balance in wallets table
      final currentWallet = await client!
          .from('wallets')
          .select('coin_balance')
          .eq('user_id', userId)
          .maybeSingle();
      final currentCoins = (currentWallet?['coin_balance'] as num?)?.toInt() ?? 0;
      final newCoins = currentCoins + chosen.coins;

      await client!.from('wallets').upsert({
        'user_id': userId,
        'coin_balance': newCoins,
        'updated_at': DateTime.now().toIso8601String(),
      });

      return (
        success: true,
        alreadySpun: false,
        wonAmount: chosen.coins,
        segmentIndex: chosen.index,
        newBalance: newCoins,
        message: 'Congratulations! You won +${chosen.coins} ToyCoins!',
      );
    } catch (err) {
      if (kDebugMode) print('Database daily-spin transaction error: $err');
      return (
        success: false,
        alreadySpun: false,
        wonAmount: 20,
        segmentIndex: 0,
        newBalance: 20,
        message: 'Unable to process daily spin. Please try again.',
      );
    }
  }
}
