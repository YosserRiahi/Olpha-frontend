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

  // Seller approval state
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
  AuthState build() => const AuthState(status: AuthStatus.unauthenticated);

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

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  // Called by "Check Status" button on pending screen
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
        status: AuthStatus.authenticated, // keep authenticated, just show error
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
