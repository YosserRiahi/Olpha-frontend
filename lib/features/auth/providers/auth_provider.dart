import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_services.dart';

export '../../../core/services/auth_services.dart' show UserRole, SellerStatus;

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.user,
    this.error,
  });

  bool get isSeller => user?.role == UserRole.SELLER;
  bool get isBuyer  => user?.role == UserRole.BUYER;
  bool get isAdmin  => user?.role == UserRole.ADMIN;

  bool get isSellerApproved => isSeller && user?.sellerStatus == SellerStatus.APPROVED;
  bool get isSellerPending  => isSeller && user?.sellerStatus == SellerStatus.PENDING;
  bool get isSellerRejected => isSeller && user?.sellerStatus == SellerStatus.REJECTED;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _authService = AuthService();

  @override
  AuthState build() {
    // Schedule async session restore — never block the UI thread
    Future.microtask(_init);
    return const AuthState(status: AuthStatus.initial);
  }

  // ── Auto session restore ──────────────────────────────────────────────────
  // Called once on startup. Reads stored token and calls GET /auth/me so we
  // always have the *live* sellerStatus from the DB — no stale JWT data.
  Future<void> _init() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final result = await _authService.refreshMe();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: result.user,
      );
    } catch (_) {
      // Token expired or server unreachable — treat as logged out
      await _authService.clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _authService.login(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<bool> register(
      String email, String password, String? name, UserRole role) async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // ── Refresh status (manual fallback on pending screen) ───────────────────
  Future<void> refreshMe() async {
    state = state.copyWith(status: AuthStatus.loading, clearError: true);
    try {
      final result = await _authService.refreshMe();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: result.user,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
