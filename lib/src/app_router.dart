import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/seller_pending_screen.dart';
import '../features/auth/presentation/screens/seller_rejected_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/seller/presentation/screens/seller_shell_screen.dart';
import '../features/seller/presentation/screens/edit_shop_screen.dart';
import '../features/products/presentation/screens/add_edit_product_screen.dart';
import '../features/ai/presentation/screens/ai_test_page.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/shops/presentation/screens/shop_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/login',          builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',         builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/home',           builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/seller-pending',   builder: (_, __) => const SellerPendingScreen()),
      GoRoute(path: '/seller-rejected',  builder: (_, __) => const SellerRejectedScreen()),
      GoRoute(path: '/seller-dashboard', builder: (_, __) => const SellerShellScreen()),
      GoRoute(path: '/seller-shop-edit', builder: (_, __) => const EditShopScreen()),
      GoRoute(
        path: '/seller-products/add',
        builder: (_, __) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/seller-products/edit/:id',
        builder: (_, state) =>
            AddEditProductScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(path: '/onboarding',       builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/ai-test',        builder: (_, __) => const AiTestPage()),
      GoRoute(
        path: '/shops/:id',
        builder: (_, state) =>
            ShopDetailScreen(shopId: state.pathParameters['id']!),
      ),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final auth = _ref.read(authProvider);
    final isAuthenticated = auth.status == AuthStatus.authenticated;
    final loc = state.matchedLocation;
    final isAuthRoute = loc == '/login' || loc == '/signup';

    // Still initialising — session restore in progress, don't redirect yet
    if (auth.status == AuthStatus.initial) return null;

    // Not logged in → always go to login
    if (!isAuthenticated && !isAuthRoute) return '/login';

    if (isAuthenticated && auth.isSeller) {
      // Rejected seller
      if (auth.isSellerRejected && loc != '/seller-rejected') return '/seller-rejected';
      // Pending seller
      if (auth.isSellerPending && loc != '/seller-pending') return '/seller-pending';
      // Approved seller — send to dashboard if on auth or buyer routes
      if (auth.isSellerApproved && (isAuthRoute || loc == '/home')) return '/seller-dashboard';
    }

    // Logged in buyer → away from auth routes
    if (isAuthenticated && auth.isBuyer && isAuthRoute) return '/home';

    // Any other authenticated user on auth routes → home
    if (isAuthenticated && isAuthRoute) return '/home';

    return null;
  }
}
