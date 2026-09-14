import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/listing_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../models/cart_model.dart';
import '../models/address_model.dart';
import '../models/admin_stats_model.dart';
import '../repositories/mock_toy_data.dart';
import '../core/services/supabase_service.dart';
import '../core/services/address_storage_service.dart';
import '../core/services/child_storage_service.dart';

// User State Provider
final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel> {
  UserNotifier() : super(MockToyData.currentUser) {
    _initUser();
  }

  Future<void> _initUser() async {
    try {
      final cachedChildren = await ChildStorageService.loadLocalChildren();
      if (cachedChildren.isNotEmpty && mounted) {
        state = state.copyWith(children: cachedChildren);
      }
    } catch (_) {}
  }

  void setChildren(List<ChildProfileModel> children) {
    state = state.copyWith(children: children);
    ChildStorageService.saveLocalChildren(children);
  }

  Future<bool> addChild(ChildProfileModel child) async {
    // Immediately update local state so child is visible with zero latency
    final updated = [...state.children.where((c) => c.id != child.id), child];
    state = state.copyWith(children: updated);

    // Save to persistent device storage immediately
    await ChildStorageService.saveLocalChildren(updated);

    // Sync to Supabase in background
    try {
      await SupabaseService.saveChildProfile(state.id, child);
    } catch (_) {}

    return true;
  }

  void updateAvatarUrl(String avatarUrl) {
    state = state.copyWith(avatarUrl: avatarUrl);
  }

  void setUser(UserModel user) {
    // Preserve local children if incoming user model has none
    final existingChildren = state.children;
    final finalChildren = user.children.isNotEmpty
        ? user.children
        : existingChildren;
    state = user.copyWith(children: finalChildren);
  }

  void addCoins(int coins) {
    state = UserModel(
      id: state.id,
      fullName: state.fullName,
      email: state.email,
      phone: state.phone,
      avatarUrl: state.avatarUrl,
      rewardCoins: state.rewardCoins + coins,
      children: state.children,
      isAdmin: state.isAdmin,
    );
  }

  void setCoins(int coins) {
    state = UserModel(
      id: state.id,
      fullName: state.fullName,
      email: state.email,
      phone: state.phone,
      avatarUrl: state.avatarUrl,
      rewardCoins: coins,
      children: state.children,
      isAdmin: state.isAdmin,
    );
  }

  void updateProfile({String? fullName, String? phone}) {
    state = UserModel(
      id: state.id,
      fullName: fullName ?? state.fullName,
      email: state.email,
      phone: phone ?? state.phone,
      avatarUrl: state.avatarUrl,
      rewardCoins: state.rewardCoins,
      children: state.children,
      isAdmin: state.isAdmin,
    );
  }
}

final selectedChildProvider = Provider<ChildProfileModel?>((ref) {
  final user = ref.watch(userProvider);
  return user.children.isNotEmpty ? user.children.first : null;
});

// Category Providers (Dynamic Supabase-driven with offline fallback)
final topLevelCategoriesAsyncProvider = FutureProvider<List<CategoryModel>>((ref) async {
  return await SupabaseService.fetchTopLevelCategories();
});

final subcategoriesFamilyProvider = FutureProvider.family<List<CategoryModel>, String>((ref, parentId) async {
  return await SupabaseService.fetchSubcategories(parentId);
});

final categoryDetailFamilyProvider = FutureProvider.family<CategoryModel?, String>((ref, categoryIdOrSlug) async {
  return await SupabaseService.fetchCategoryByIdOrSlug(categoryIdOrSlug);
});

final categoryListingsFamilyProvider = FutureProvider.family<List<ListingModel>, String>((ref, categoryIdOrSlug) async {
  return await SupabaseService.fetchListingsByCategory(categoryIdOrSlug);
});

final singleListingFamilyProvider = FutureProvider.family<ListingModel?, String>((ref, listingId) async {
  return await SupabaseService.fetchListingById(listingId);
});

// Category Provider (dynamic Supabase-driven with offline fallback)
final categoriesProvider = Provider<List<CategoryModel>>((ref) {
  final asyncCategories = ref.watch(topLevelCategoriesAsyncProvider);
  return asyncCategories.asData?.value ?? MockToyData.categories;
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Products List Provider & Filtered Products Provider
final productsProvider = StateNotifierProvider<ProductsNotifier, List<ProductModel>>((ref) {
  return ProductsNotifier();
});

class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  ProductsNotifier() : super(MockToyData.products) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    try {
      final fetched = await SupabaseService.fetchProducts();
      if (fetched.isNotEmpty) {
        state = fetched;
      }
    } catch (_) {}
  }

  Future<void> refresh() async {
    await loadProducts();
  }

  void addProduct(ProductModel product) {
    state = [product, ...state];
  }

  void updateProduct(ProductModel updated) {
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p
    ];
  }

  void deleteProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }
}

final searchQueryProvider = StateProvider<String>((ref) => '');

final ageFilterProvider = StateProvider<RangeValues>((ref) => const RangeValues(1, 14));

final filteredProductsProvider = Provider<List<ProductModel>>((ref) {
  final products = ref.watch(productsProvider);
  final categorySlug = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final ageRange = ref.watch(ageFilterProvider);

  return products.where((p) {
    final matchesCategory = categorySlug == null ||
        categorySlug.isEmpty ||
        categorySlug == 'all' ||
        p.categorySlug.toLowerCase() == categorySlug.toLowerCase() ||
        p.categorySlug.toLowerCase().contains(categorySlug.toLowerCase());
    final matchesQuery = query.isEmpty ||
        p.title.toLowerCase().contains(query) ||
        p.subtitle.toLowerCase().contains(query) ||
        p.brandName.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query);
    final matchesAge = p.minAge <= ageRange.end && p.maxAge >= ageRange.start;

    return matchesCategory && matchesQuery && matchesAge;
  }).toList();
});

// --- Fetch-On-Login User Data Provider ---

class UserDataState {
  final List<AddressModel> addresses;
  final List<OrderModel> orders;
  final Set<String> wishlistProductIds;
  final List<ChildProfileModel> children;

  const UserDataState({
    required this.addresses,
    required this.orders,
    required this.wishlistProductIds,
    required this.children,
  });

  UserDataState copyWith({
    List<AddressModel>? addresses,
    List<OrderModel>? orders,
    Set<String>? wishlistProductIds,
    List<ChildProfileModel>? children,
  }) {
    return UserDataState(
      addresses: addresses ?? this.addresses,
      orders: orders ?? this.orders,
      wishlistProductIds: wishlistProductIds ?? this.wishlistProductIds,
      children: children ?? this.children,
    );
  }
}

final userDataProvider = FutureProvider<UserDataState>((ref) async {
  final user = ref.watch(userProvider);
  final allProducts = ref.watch(productsProvider);
  final userId = user.id.isNotEmpty ? user.id : 'user_guildclub_1';

  // Parallel fetch fresh data from Supabase: addresses, orders, wishlist, children, avatar
  final results = await Future.wait([
    SupabaseService.fetchUserAddresses(userId),
    SupabaseService.fetchUserOrders(userId, allProducts: allProducts),
    SupabaseService.fetchUserWishlist(userId),
    SupabaseService.fetchUserChildren(userId),
    SupabaseService.fetchUserProfileAvatar(userId),
  ]);

  final fetchedAddresses = results[0] as List<AddressModel>;
  final singleAddressList = fetchedAddresses.isNotEmpty ? [fetchedAddresses.first] : <AddressModel>[];
  final fetchedOrders = results[1] as List<OrderModel>;
  final fetchedWishlist = results[2] as Set<String>;
  final fetchedChildren = results[3] as List<ChildProfileModel>;

  if (fetchedChildren.isNotEmpty) {
    ref.read(userProvider.notifier).setChildren(fetchedChildren);
  }

  final fetchedAvatar = results[4] as String?;
  if (fetchedAvatar != null && fetchedAvatar.isNotEmpty) {
    ref.read(userProvider.notifier).updateAvatarUrl(fetchedAvatar);
  }

  return UserDataState(
    addresses: singleAddressList,
    orders: fetchedOrders,
    wishlistProductIds: fetchedWishlist,
    children: fetchedChildren,
  );
});

// Addresses Provider (Single saved address on device + synced with Supabase)
final addressesProvider = StateNotifierProvider<AddressesNotifier, List<AddressModel>>((ref) {
  return AddressesNotifier(ref);
});

class AddressesNotifier extends StateNotifier<List<AddressModel>> {
  final Ref ref;
  AddressesNotifier(this.ref) : super(const <AddressModel>[]) {
    _initAddresses();
  }

  Future<void> _initAddresses() async {
    // 1. Load user's saved address from device local storage immediately
    final local = await AddressStorageService.loadLocalAddresses();
    if (local.isNotEmpty && mounted) {
      state = [local.first];
      return;
    }
    // 2. If no local address, fetch from Supabase
    final user = ref.read(userProvider);
    final userId = user.id.isNotEmpty ? user.id : 'user_guildclub_1';
    final remote = await SupabaseService.fetchUserAddresses(userId);
    if (remote.isNotEmpty && mounted) {
      state = [remote.first];
      await AddressStorageService.saveLocalAddresses([remote.first]);
    }
  }

  Future<bool> addOrUpdateAddress(AddressModel address) async {
    final currentUserId = ref.read(userProvider).id;
    final targetAddress = address.userId.isEmpty
        ? address.copyWith(userId: currentUserId.isNotEmpty ? currentUserId : 'user_guildclub_1')
        : address;

    // Immediately replace state with single address
    state = [targetAddress];

    // Save single address to device persistent local storage
    await AddressStorageService.saveLocalAddresses([targetAddress]);

    // Sync to Supabase
    try {
      final saved = await SupabaseService.saveAddress(targetAddress);
      if (saved != null && mounted) {
        state = [saved];
        await AddressStorageService.saveLocalAddresses([saved]);
      }
    } catch (_) {}

    return true;
  }

  Future<void> deleteAddress(String addressId) async {
    state = const [];
    await AddressStorageService.deleteLocalAddress(addressId);
  }
}

// Wishlist Provider with Optimistic Updates & Background Sync
final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  return WishlistNotifier(ref);
});

class WishlistNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  WishlistNotifier(this.ref) : super(MockToyData.wishlistProductIds) {
    _initWishlist();
  }

  Future<void> _initWishlist() async {
    try {
      final user = ref.read(userProvider);
      final userId = user.id.isNotEmpty ? user.id : 'user_guildclub_1';
      final remote = await SupabaseService.fetchUserWishlist(userId);
      if (remote.isNotEmpty && mounted) {
        state = remote;
      }
    } catch (_) {}
  }

  Future<void> refreshWishlist() async {
    await _initWishlist();
  }

  Future<bool> toggleWishlist(String productId) async {
    final user = ref.read(userProvider);
    final isCurrentlyAdded = state.contains(productId);

    // 1. Optimistic Update UI
    if (isCurrentlyAdded) {
      state = {...state}..remove(productId);
    } else {
      state = {...state}..add(productId);
    }

    // 2. Sync to Supabase in background
    try {
      final success = await SupabaseService.toggleWishlist(user.id, productId, !isCurrentlyAdded);
      if (!success) {
        // Keep optimistic state locally so user experience is smooth
        return true;
      }
      return true;
    } catch (e) {
      return true;
    }
  }
}

// Cart Provider
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  CartNotifier() : super(const []);

  void addToCart(ProductModel product, {int quantity = 1, String? selectedColor}) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      state[index].quantity += quantity;
      state = [...state];
    } else {
      state = [...state, CartItemModel(product: product, quantity: quantity, selectedColor: selectedColor)];
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
    } else {
      state = [
        for (final item in state)
          if (item.product.id == productId)
            CartItemModel(product: item.product, quantity: quantity, selectedColor: item.selectedColor)
          else
            item
      ];
    }
  }

  void removeFromCart(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }
}

final cartTotalAmountProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0.0, (sum, item) => sum + item.totalPrice);
});

// Orders Provider (Instant Load & Background Sync)
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) {
  return OrdersNotifier(ref);
});

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final Ref ref;
  OrdersNotifier(this.ref) : super(MockToyData.orders) {
    _initOrders();
  }

  Future<void> _initOrders() async {
    try {
      final user = ref.read(userProvider);
      final userId = user.id.isNotEmpty ? user.id : 'user_guildclub_1';
      final allProducts = ref.read(productsProvider);
      final remote = await SupabaseService.fetchUserOrders(userId, allProducts: allProducts);
      if (remote.isNotEmpty && mounted) {
        state = remote;
      }
    } catch (_) {}
  }

  Future<void> refreshOrders() async {
    await _initOrders();
  }

  Future<bool> placeOrder(OrderModel order) async {
    final currentUserId = ref.read(userProvider).id;
    final targetOrder = order.userId.isEmpty ? order.copyWith(userId: currentUserId.isNotEmpty ? currentUserId : 'user_guildclub_1') : order;

    state = [targetOrder, ...state];

    try {
      await SupabaseService.saveOrder(targetOrder);
    } catch (_) {}
    return true;
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final orderIdx = state.indexWhere((o) => o.id == orderId);
    if (orderIdx < 0) return false;

    final existingOrder = state[orderIdx];
    final nowIso = DateTime.now().toIso8601String();
    final updatedHistory = Map<String, String>.from(existingOrder.statusHistory);
    updatedHistory[newStatus.dbValue] = nowIso;

    final updatedOrder = existingOrder.copyWith(
      status: newStatus,
      statusUpdatedAt: DateTime.now(),
      statusHistory: updatedHistory,
    );

    state = [
      for (final o in state)
        if (o.id == orderId) updatedOrder else o
    ];

    try {
      await SupabaseService.updateOrderStatus(
        orderId,
        newStatus,
        currentHistory: existingOrder.statusHistory,
      );
    } catch (_) {}
    return true;
  }
}

/// Realtime live tracking stream provider for a specific order
final singleOrderStreamProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final allProducts = ref.watch(productsProvider);
  final localOrders = ref.watch(ordersProvider);
  final localMatch = localOrders.where((o) => o.id == orderId).firstOrNull;

  // Supabase Realtime stream
  return SupabaseService.streamOrder(orderId, allProducts: allProducts)
      .map((remoteOrder) => remoteOrder ?? localMatch);
});

// Admin Stats Provider
final adminStatsProvider = Provider<AdminStatsModel>((ref) {
  return MockToyData.adminStats;
});
