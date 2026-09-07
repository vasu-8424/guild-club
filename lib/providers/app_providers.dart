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

// User State Provider
final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  return UserNotifier();
});

class UserNotifier extends StateNotifier<UserModel> {
  UserNotifier() : super(MockToyData.currentUser);

  void setChildren(List<ChildProfileModel> children) {
    state = UserModel(
      id: state.id,
      fullName: state.fullName,
      email: state.email,
      phone: state.phone,
      avatarUrl: state.avatarUrl,
      rewardCoins: state.rewardCoins,
      children: children,
      isAdmin: state.isAdmin,
    );
  }

  Future<bool> addChild(ChildProfileModel child) async {
    final previousChildren = state.children;
    state = UserModel(
      id: state.id,
      fullName: state.fullName,
      email: state.email,
      phone: state.phone,
      avatarUrl: state.avatarUrl,
      rewardCoins: state.rewardCoins,
      children: [...state.children, child],
      isAdmin: state.isAdmin,
    );

    final success = await SupabaseService.saveChildProfile(state.id, child);
    if (!success) {
      // Revert on failure
      state = UserModel(
        id: state.id,
        fullName: state.fullName,
        email: state.email,
        phone: state.phone,
        avatarUrl: state.avatarUrl,
        rewardCoins: state.rewardCoins,
        children: previousChildren,
        isAdmin: state.isAdmin,
      );
      return false;
    }
    return true;
  }

  void updateAvatarUrl(String avatarUrl) {
    state = UserModel(
      id: state.id,
      fullName: state.fullName,
      email: state.email,
      phone: state.phone,
      avatarUrl: avatarUrl,
      rewardCoins: state.rewardCoins,
      children: state.children,
      isAdmin: state.isAdmin,
    );
  }

  void setUser(UserModel user) {
    state = user;
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

// Legacy Category Provider (fallback list)
final categoriesProvider = Provider<List<CategoryModel>>((ref) {
  return MockToyData.categories;
});

final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Products List Provider & Filtered Products Provider
final productsProvider = StateNotifierProvider<ProductsNotifier, List<ProductModel>>((ref) {
  return ProductsNotifier();
});

class ProductsNotifier extends StateNotifier<List<ProductModel>> {
  ProductsNotifier() : super(MockToyData.products);

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
    final matchesCategory = categorySlug == null || p.categorySlug == categorySlug;
    final matchesQuery = query.isEmpty ||
        p.title.toLowerCase().contains(query) ||
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

  if (user.id.isEmpty) {
    return const UserDataState(
      addresses: [],
      orders: [],
      wishlistProductIds: {},
      children: [],
    );
  }

  // Parallel fetch fresh data from Supabase: addresses, orders, wishlist, children, avatar
  final results = await Future.wait([
    SupabaseService.fetchUserAddresses(user.id),
    SupabaseService.fetchUserOrders(user.id, allProducts: allProducts),
    SupabaseService.fetchUserWishlist(user.id),
    SupabaseService.fetchUserChildren(user.id),
    SupabaseService.fetchUserProfileAvatar(user.id),
  ]);

  final fetchedChildren = results[3] as List<ChildProfileModel>;
  if (fetchedChildren.isNotEmpty) {
    ref.read(userProvider.notifier).setChildren(fetchedChildren);
  }

  final fetchedAvatar = results[4] as String?;
  if (fetchedAvatar != null && fetchedAvatar.isNotEmpty) {
    ref.read(userProvider.notifier).updateAvatarUrl(fetchedAvatar);
  }

  return UserDataState(
    addresses: results[0] as List<AddressModel>,
    orders: results[1] as List<OrderModel>,
    wishlistProductIds: results[2] as Set<String>,
    children: fetchedChildren,
  );
});

// Addresses Provider
final addressesProvider = StateNotifierProvider<AddressesNotifier, List<AddressModel>>((ref) {
  final asyncUserData = ref.watch(userDataProvider);
  final initialList = asyncUserData.asData?.value.addresses ?? const <AddressModel>[];
  return AddressesNotifier(initialList, ref);
});

class AddressesNotifier extends StateNotifier<List<AddressModel>> {
  final Ref ref;
  AddressesNotifier(super.initialState, this.ref);

  Future<bool> addOrUpdateAddress(AddressModel address) async {
    final previousState = state;
    final currentUserId = ref.read(userProvider).id;
    final targetAddress = address.userId.isEmpty ? address.copyWith(userId: currentUserId) : address;

    if (targetAddress.isDefault) {
      state = [
        for (final a in state) a.copyWith(isDefault: false),
      ];
    }
    state = [targetAddress, ...state];

    final saved = await SupabaseService.saveAddress(targetAddress);
    if (saved != null) {
      state = [
        for (final a in state)
          if (a.id == targetAddress.id || a.id.isEmpty) saved else a
      ];
      ref.invalidate(userDataProvider);
      return true;
    } else {
      // Revert optimistic state on failure
      state = previousState;
      return false;
    }
  }
}

// Wishlist Provider with Optimistic Updates & Failure Rollback
final wishlistProvider = StateNotifierProvider<WishlistNotifier, Set<String>>((ref) {
  final asyncUserData = ref.watch(userDataProvider);
  final initialSet = asyncUserData.asData?.value.wishlistProductIds ?? const <String>{};
  return WishlistNotifier(initialSet, ref);
});

class WishlistNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  WishlistNotifier(super.initialState, this.ref);

  Future<bool> toggleWishlist(String productId) async {
    final user = ref.read(userProvider);
    final isCurrentlyAdded = state.contains(productId);

    // 1. Optimistic Update UI
    if (isCurrentlyAdded) {
      state = {...state}..remove(productId);
    } else {
      state = {...state}..add(productId);
    }

    // 2. Sync to Supabase
    try {
      final success = await SupabaseService.toggleWishlist(user.id, productId, !isCurrentlyAdded);
      if (!success) {
        // Rollback on failure
        if (isCurrentlyAdded) {
          state = {...state}..add(productId);
        } else {
          state = {...state}..remove(productId);
        }
        return false;
      }
      return true;
    } catch (e) {
      if (isCurrentlyAdded) {
        state = {...state}..add(productId);
      } else {
        state = {...state}..remove(productId);
      }
      return false;
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

// Orders Provider
final ordersProvider = StateNotifierProvider<OrdersNotifier, List<OrderModel>>((ref) {
  final asyncUserData = ref.watch(userDataProvider);
  final initialOrders = asyncUserData.asData?.value.orders ?? const <OrderModel>[];
  return OrdersNotifier(initialOrders, ref);
});

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final Ref ref;
  OrdersNotifier(super.initialState, this.ref);

  Future<bool> placeOrder(OrderModel order) async {
    final currentUserId = ref.read(userProvider).id;
    final targetOrder = order.userId.isEmpty ? order.copyWith(userId: currentUserId) : order;

    state = [targetOrder, ...state];

    final success = await SupabaseService.saveOrder(targetOrder);
    if (success) {
      ref.invalidate(userDataProvider);
      return true;
    } else {
      // Keep optimistic order locally so tracking screen can work even offline
      return true;
    }
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

    final success = await SupabaseService.updateOrderStatus(
      orderId,
      newStatus,
      currentHistory: existingOrder.statusHistory,
    );

    if (success) {
      ref.invalidate(userDataProvider);
    }
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
