import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/category_model.dart';
import '../../models/listing_model.dart';
import '../../features/categories/subcategory_screen.dart';
import '../../features/categories/category_listing_screen.dart';
import '../../features/categories/listing_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/kids_personalization_screen.dart';
import '../../features/home/main_wrapper_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/orders/live_tracking_screen.dart';
import '../../features/rewards/rewards_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/address/address_picker_screen.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/legal/privacy_policy_screen.dart';
import '../../features/legal/terms_of_service_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => _fadeThroughPage(
        state: state,
        child: const SplashScreen(),
      ),
    ),
    GoRoute(
      path: '/address-picker',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const AddressPickerScreen(),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const OnboardingScreen(),
      ),
    ),
    GoRoute(
      path: '/auth',
      pageBuilder: (context, state) => _fadeThroughPage(
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/kids-setup',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const KidsPersonalizationScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _fadeThroughPage(
        state: state,
        child: const MainWrapperScreen(),
      ),
    ),
    GoRoute(
      path: '/product/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? 'p_1';
        return _smoothPageTransition(
          state: state,
          child: ProductDetailScreen(productId: id),
        );
      },
    ),
    GoRoute(
      path: '/categories',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const CategoriesScreen(),
      ),
    ),
    GoRoute(
      path: '/subcategories/:parentId',
      pageBuilder: (context, state) {
        final parentId = state.pathParameters['parentId'] ?? '';
        final extra = state.extra;
        final parentCategory = extra is CategoryModel ? extra : null;
        return _smoothPageTransition(
          state: state,
          child: SubcategoryScreen(
            parentId: parentId,
            parentName: parentCategory?.name,
          ),
        );
      },
    ),
    GoRoute(
      path: '/category-listings/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final extra = state.extra;
        final category = extra is CategoryModel ? extra : null;
        return _smoothPageTransition(
          state: state,
          child: CategoryListingScreen(
            categoryId: id,
            category: category,
          ),
        );
      },
    ),
    GoRoute(
      path: '/listing/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final extra = state.extra;
        final listing = extra is ListingModel ? extra : null;
        return _smoothPageTransition(
          state: state,
          child: ListingDetailScreen(
            listingId: id,
            listing: listing,
          ),
        );
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const SearchScreen(),
      ),
    ),
    GoRoute(
      path: '/wishlist',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const WishlistScreen(),
      ),
    ),
    GoRoute(
      path: '/cart',
      pageBuilder: (context, state) {
        final extra = state.extra;
        final morphData = extra is CartEntryMorphData ? extra : null;
        return _smoothPageTransition(
          state: state,
          child: CartScreen(morphData: morphData),
        );
      },
    ),
    GoRoute(
      path: '/checkout',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const CheckoutScreen(),
      ),
    ),
    GoRoute(
      path: '/orders',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const OrdersScreen(),
      ),
    ),
    GoRoute(
      path: '/tracking/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id'] ?? 'ord_9001';
        return _smoothPageTransition(
          state: state,
          child: LiveTrackingScreen(orderId: id),
        );
      },
    ),
    GoRoute(
      path: '/rewards',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const RewardsScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const ProfileScreen(),
      ),
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const AdminDashboardScreen(),
      ),
    ),
    GoRoute(
      path: '/privacy-policy',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const PrivacyPolicyScreen(),
      ),
    ),
    GoRoute(
      path: '/terms-of-service',
      pageBuilder: (context, state) => _smoothPageTransition(
        state: state,
        child: const TermsOfServiceScreen(),
      ),
    ),
  ],
);

CustomTransitionPage<void> _fadeThroughPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    opaque: false,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final opacity = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
      );
      return FadeTransition(opacity: opacity, child: child);
    },
  );
}

CustomTransitionPage<void> _smoothPageTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.16, 1.0, 0.3, 1.0),
        reverseCurve: Curves.easeInCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0.06, 0.0),
        end: Offset.zero,
      ).animate(curve);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: offset,
          child: child,
        ),
      );
    },
  );
}
