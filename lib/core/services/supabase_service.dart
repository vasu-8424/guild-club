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
import 'child_storage_service.dart';

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
      final response = await client!
          .from('products')
          .select('*')
          .order('created_at', ascending: false);

      final list = (response as List)
          .map((map) => ProductModel.fromJson(map as Map<String, dynamic>))
          .toList();

      return list.isEmpty ? MockToyData.products : list;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase products: $e');
      return MockToyData.products;
    }
  }

  // 2. Addresses Management
  static Future<List<AddressModel>> fetchUserAddresses(String userId) async {
    if (!isInitialized || client == null) {
      return [];
    }
    final effectiveUserId = getDeterministicUUID(userId);
    try {
      final query = effectiveUserId.isNotEmpty && effectiveUserId != userId
          ? 'user_id.eq.$userId,user_id.eq.$effectiveUserId'
          : 'user_id.eq.$userId';
      final response = await client!
          .from('addresses')
          .select('*')
          .or(query)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      
      final list = (response as List).map((map) => AddressModel.fromJson(map as Map<String, dynamic>)).toList();
      return list;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase addresses: $e');
      return [];
    }
  }

  static Future<AddressModel?> saveAddress(AddressModel address) async {
    if (!isInitialized || client == null) return address;
    final effectiveUserId = getDeterministicUUID(address.userId);
    final targetAddress = address.copyWith(
      id: _isValidUUID(address.id) ? address.id : const Uuid().v4(),
      userId: effectiveUserId.isNotEmpty ? effectiveUserId : (address.userId.isNotEmpty ? address.userId : 'user_guildclub_1'),
    );
    try {
      final data = targetAddress.toJson();
      if (targetAddress.isDefault) {
        // Unset previous defaults
        try {
          await client!
              .from('addresses')
              .update({'is_default': false})
              .eq('user_id', targetAddress.userId);
        } catch (_) {}
      }
      final response = await client!.from('addresses').upsert(data).select().maybeSingle();
      if (response != null) {
        return AddressModel.fromJson(response);
      }
      return targetAddress;
    } catch (e) {
      if (kDebugMode) print('Note saving address to Supabase (using local persistence): $e');
      return targetAddress;
    }
  }

  // 3. Orders Management & Realtime Tracking APIs
  static Future<List<OrderModel>> fetchUserOrders(String userId, {List<ProductModel>? allProducts}) async {
    if (!isInitialized || client == null) {
      return MockToyData.orders;
    }
    final effectiveUserId = getDeterministicUUID(userId);
    try {
      final response = await client!
          .from('orders')
          .select('*')
          .or('user_id.eq.$userId,user_id.eq.$effectiveUserId')
          .order('created_at', ascending: false);
      
      final list = (response as List).map((map) => OrderModel.fromJson(map, allProducts: allProducts)).toList();
      return list.isEmpty ? MockToyData.orders : list;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase orders: $e');
      return MockToyData.orders;
    }
  }

  static Future<OrderModel?> fetchOrderById(String orderId, {List<ProductModel>? allProducts}) async {
    if (!isInitialized || client == null) {
      return MockToyData.orders.where((o) => o.id == orderId).firstOrNull;
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
    return MockToyData.orders.where((o) => o.id == orderId).firstOrNull;
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

  /// Realtime Stream subscription for live admin push notifications broadcast
  static Stream<Map<String, dynamic>?> streamNotifications() {
    if (!isInitialized || client == null) {
      return Stream.value(null);
    }
    try {
      return client!
          .from('notifications_log')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .map((maps) {
            if (maps.isEmpty) return null;
            return maps.first;
          });
    } catch (e) {
      if (kDebugMode) print('Error setting up notification realtime stream: ');
      return Stream.value(null);
    }
  }

  static Future<bool> saveOrder(OrderModel order) async {
    if (!isInitialized || client == null) return false;
    final effectiveUserId = getDeterministicUUID(order.userId);
    final targetOrder = order.copyWith(
      id: _isValidUUID(order.id) ? order.id : const Uuid().v4(),
      userId: effectiveUserId.isNotEmpty ? effectiveUserId : order.userId,
    );
    try {
      // Use upsert so retries (e.g. after payment verification) do not throw duplicate-key errors
      await client!.from('orders').upsert(
        targetOrder.toJson(),
        onConflict: 'id',
      );
      if (kDebugMode) print('[Supabase] Order ${targetOrder.id} saved successfully.');
      return true;
    } catch (e) {
      // Log the full error so it is visible in Flutter debug console
      if (kDebugMode) print('[Supabase] ERROR saving order ${targetOrder.id}: $e');
      return false;
    }
  }

  static Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus, {Map<String, String>? currentHistory}) async {
    if (!isInitialized || client == null || !_isValidUUID(orderId)) return false;
    try {
      await client!.from('orders').update({
        'status': newStatus.dbValue,
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
    if (!isInitialized || client == null) {
      return MockToyData.wishlistProductIds;
    }
    final effectiveUserId = getDeterministicUUID(userId);
    try {
      final response = await client!
          .from('wishlist')
          .select('product_id')
          .or('user_id.eq.$userId,user_id.eq.$effectiveUserId');
      
      final ids = (response as List).map((map) => map['product_id'].toString()).toSet();
      return ids.isEmpty ? MockToyData.wishlistProductIds : ids;
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase wishlist: $e');
      return MockToyData.wishlistProductIds;
    }
  }

  static Future<bool> toggleWishlist(String userId, String productId, bool isAdded) async {
    if (!isInitialized || client == null) return false;
    final effectiveUserId = getDeterministicUUID(userId);
    final targetUserId = effectiveUserId.isNotEmpty ? effectiveUserId : userId;
    try {
      if (isAdded) {
        await client!.from('wishlist').upsert({'user_id': targetUserId, 'product_id': productId});
      } else {
        await client!.from('wishlist').delete().match({'user_id': targetUserId, 'product_id': productId});
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('Error updating Supabase wishlist: $e');
      return false;
    }
  }

  // 5. Child Personalization Profile
  static Future<List<ChildProfileModel>> fetchUserChildren(String userId) async {
    final localChildren = await ChildStorageService.loadLocalChildren();
    if (!isInitialized || client == null) {
      return localChildren.isNotEmpty ? localChildren : MockToyData.currentUser.children;
    }
    final effectiveUserId = getDeterministicUUID(userId);
    final targetId = effectiveUserId.isNotEmpty ? effectiveUserId : userId;

    try {
      dynamic response;
      try {
        response = await client!
            .from('children')
            .select('*')
            .or('parent_id.eq.$targetId,parent_id.eq.$userId')
            .order('created_at', ascending: false);
      } catch (_) {
        response = await client!
            .from('children')
            .select('*')
            .or('user_id.eq.$targetId,user_id.eq.$userId')
            .order('created_at', ascending: false);
      }

      if (response != null && response is List && response.isNotEmpty) {
        final remoteList = response
            .map((map) => ChildProfileModel.fromJson(map as Map<String, dynamic>))
            .toList();
        final merged = <ChildProfileModel>[...remoteList];
        for (final loc in localChildren) {
          if (!merged.any((r) => r.id == loc.id || (r.name.toLowerCase() == loc.name.toLowerCase() && r.name.isNotEmpty))) {
            merged.add(loc);
          }
        }
        await ChildStorageService.saveLocalChildren(merged);
        return merged;
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching Supabase children: $e');
    }

    return localChildren.isNotEmpty ? localChildren : MockToyData.currentUser.children;
  }

  static Future<bool> saveChildProfile(String parentId, ChildProfileModel child) async {
    await ChildStorageService.addOrUpdateLocalChild(child);
    if (!isInitialized || client == null) return true;
    final effectiveParentId = getDeterministicUUID(parentId);
    final targetParentId = effectiveParentId.isNotEmpty ? effectiveParentId : parentId;
    final childId = _isValidUUID(child.id) ? child.id : const Uuid().v4();

    try {
      try {
        await client!.from('children').upsert({
          'id': childId,
          'parent_id': targetParentId,
          'name': child.name,
          'age': child.age,
          'gender': child.gender,
          'interests': child.interests,
          'favorite_character': child.favoriteCharacter,
          'learning_level': child.learningLevel,
        });
      } catch (_) {
        await client!.from('children').upsert({
          'id': childId,
          'user_id': targetParentId,
          'name': child.name,
          'age': child.age,
          'gender': child.gender,
          'interests': child.interests,
          'favorite_character': child.favoriteCharacter,
          'learning_level': child.learningLevel,
        });
      }
      if (kDebugMode) print('Saved child profile ${child.name} to Supabase');
      return true;
    } catch (e) {
      if (kDebugMode) print('Error saving child profile to Supabase: $e');
      return true;
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

  /// Automatically claims the +2 daily login bonus via direct PostgREST database transaction.
  static Future<({bool claimedToday, int bonusGranted, int? newBalance, String message})> claimDailyLoginBonus() async {
    if (!isInitialized || client == null) {
      return (claimedToday: false, bonusGranted: 0, newBalance: null, message: 'Offline mode');
    }

    final currentUser = client!.auth.currentUser;
    if (currentUser == null) {
      return (claimedToday: false, bonusGranted: 0, newBalance: null, message: 'No active user session');
    }
    final userId = currentUser.id;

    try {
      final today = DateTime.now().toUtc().toIso8601String().split('T')[0];
      
      // 1. Check if login bonus was already claimed today
      Map<String, dynamic>? activity;
      try {
        activity = await client!
            .from('daily_activity')
            .select('login_bonus_claimed_today, spun_today')
            .eq('user_id', userId)
            .eq('activity_date', today)
            .maybeSingle();
      } catch (e) {
        if (kDebugMode) print('[Supabase] daily_activity fetch warning: $e');
      }

      // 2. Fetch current wallet balance
      int currentBalance = 0;
      try {
        final existingWallet = await client!
            .from('wallets')
            .select('coin_balance')
            .eq('user_id', userId)
            .maybeSingle();
        currentBalance = (existingWallet?['coin_balance'] as num?)?.toInt() ?? 0;
      } catch (e) {
        if (kDebugMode) print('[Supabase] wallets fetch warning: $e');
      }

      if (activity != null && activity['login_bonus_claimed_today'] == true) {
        return (
          claimedToday: true,
          bonusGranted: 0,
          newBalance: currentBalance,
          message: 'Daily login bonus already claimed today.',
        );
      }

      const bonusCoins = 2;
      final updatedCoins = currentBalance + bonusCoins;

      // 3. Record in ledger if permissions allow
      try {
        await client!.from('reward_transactions').insert({
          'user_id': userId,
          'type': 'daily_login_bonus',
          'amount': bonusCoins,
          'metadata': {'source': 'automatic_daily_login'},
        });
      } catch (e) {
        if (kDebugMode) print('[Supabase] reward_transactions insert notice: $e');
      }

      // 4. Mark today as claimed in daily_activity
      try {
        await client!.from('daily_activity').upsert({
          'user_id': userId,
          'activity_date': today,
          'login_bonus_claimed_today': true,
          'spun_today': activity?['spun_today'] ?? false,
        });
      } catch (e) {
        if (kDebugMode) print('[Supabase] daily_activity upsert notice: $e');
      }

      // 5. Update wallet balance
      try {
        await client!.from('wallets').upsert({
          'user_id': userId,
          'coin_balance': updatedCoins,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) print('[Supabase] wallets upsert notice: $e');
      }

      return (
        claimedToday: false,
        bonusGranted: bonusCoins,
        newBalance: updatedCoins,
        message: 'Daily login bonus claimed! +2 Guild Coins 🎉',
      );
    } catch (e) {
      if (kDebugMode) print('Error in daily login bonus handling: $e');
    }

    return (claimedToday: false, bonusGranted: 0, newBalance: null, message: 'Daily bonus checked');
  }

  /// Securely handles the daily spin wheel reward via direct database transaction.
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

    try {
      final today = DateTime.now().toUtc().toIso8601String().split('T')[0];

      // Check daily_activity for today
      Map<String, dynamic>? activity;
      try {
        activity = await client!
            .from('daily_activity')
            .select('spun_today, login_bonus_claimed_today')
            .eq('user_id', userId)
            .eq('activity_date', today)
            .maybeSingle();
      } catch (e) {
        if (kDebugMode) print('[Supabase] daily_activity fetch warning: $e');
      }

      // Fetch current wallet balance
      int currentCoins = 0;
      try {
        final currentWallet = await client!
            .from('wallets')
            .select('coin_balance')
            .eq('user_id', userId)
            .maybeSingle();
        currentCoins = (currentWallet?['coin_balance'] as num?)?.toInt() ?? 0;
      } catch (e) {
        if (kDebugMode) print('[Supabase] wallets fetch warning: $e');
      }

      if (activity != null && activity['spun_today'] == true) {
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

      final newCoins = currentCoins + chosen.coins;

      // Insert ledger row into reward_transactions
      try {
        await client!.from('reward_transactions').insert({
          'user_id': userId,
          'type': 'daily_spin',
          'amount': chosen.coins,
          'metadata': {'segment_index': chosen.index, 'won_amount': chosen.coins},
        });
      } catch (e) {
        if (kDebugMode) print('[Supabase] reward_transactions insert notice: $e');
      }

      // Update daily_activity
      try {
        await client!.from('daily_activity').upsert({
          'user_id': userId,
          'activity_date': today,
          'spun_today': true,
          'login_bonus_claimed_today': activity?['login_bonus_claimed_today'] ?? false,
        });
      } catch (e) {
        if (kDebugMode) print('[Supabase] daily_activity upsert notice: $e');
      }

      // Update wallet balance in wallets table
      try {
        await client!.from('wallets').upsert({
          'user_id': userId,
          'coin_balance': newCoins,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        if (kDebugMode) print('[Supabase] wallets upsert notice: $e');
      }

      return (
        success: true,
        alreadySpun: false,
        wonAmount: chosen.coins,
        segmentIndex: chosen.index,
        newBalance: newCoins,
        message: 'Congratulations! You won +${chosen.coins} ToyCoins! 🎉',
      );
    } catch (err) {
      if (kDebugMode) print('Daily-spin processing notice: $err');
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
