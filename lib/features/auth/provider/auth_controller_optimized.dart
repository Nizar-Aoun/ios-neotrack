import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/features/auth/data/auth_repository.dart';
import 'package:taxi_driver_app/features/auth/data/auth_service.dart';
import 'package:taxi_driver_app/features/auth/domain/user_model.dart';

/// Optimized auth state model for better type safety and immutability
class AuthStateModel {
  final UserModel? user;
  final String? token;

  const AuthStateModel({
    this.user,
    this.token,
  });

  bool get isAuthenticated => user != null && token != null;
  bool get needsPasswordUpdate =>
      user != null && user!.passwordUpdated == false;

  AuthStateModel copyWith({
    UserModel? user,
    String? token,
  }) {
    return AuthStateModel(
      user: user ?? this.user,
      token: token ?? this.token,
    );
  }

  static const unauthenticated = AuthStateModel();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthStateModel &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          token == other.token;

  @override
  int get hashCode => user.hashCode ^ token.hashCode;
}

/// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Auth Service Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  return AuthRepository(
    authService: authService,
    prefs: prefs,
  );
});

class AuthController extends AsyncNotifier<AuthStateModel> {
  late final AuthRepository _authRepository;

  @override
  Future<AuthStateModel> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    return await _checkAuthStatus();
  }

  /// Check if user is already authenticated on app startup
  Future<AuthStateModel> _checkAuthStatus() async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        final token = await _authRepository.getToken();
        final userData = await _authRepository.getStoredUserData();

        if (token != null && userData != null) {
          return AuthStateModel(
            user: userData,
            token: token,
          );
        } else {
          await _authRepository.clearAuthData();
        }
      }
      return AuthStateModel.unauthenticated;
    } catch (e) {
      return AuthStateModel.unauthenticated;
    }
  }

  /// Login user with optimized state management
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    // Set loading state
    state = const AsyncLoading();

    try {
      final result = await _authRepository.login(
        phone: phone,
        password: password,
      );

      // Update state with authenticated user
      state = AsyncData(
        AuthStateModel(
          user: result.user,
          token: result.token,
        ),
      );
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);

      // Reset to unauthenticated after a brief delay to show error
      Future.delayed(const Duration(milliseconds: 1500), () {
        // Check if the provider is still mounted before updating state
        try {
          state = const AsyncData(AuthStateModel.unauthenticated);
        } catch (_) {
          // Provider was disposed, ignore
        }
      });
    }
  }

  /// Logout user with proper cleanup
  Future<void> logout() async {
    state = const AsyncLoading();

    try {
      await _authRepository.logout();

      state = const AsyncData(AuthStateModel.unauthenticated);
    } catch (e) {
      // Even on error, clear the state to unauthenticated
      state = const AsyncData(AuthStateModel.unauthenticated);
    }
  }

  /// Update password with optimized flow
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Update the user's passwordUpdated flag
      final currentState = state.value;
      if (currentState != null && currentState.user != null) {
        state = AsyncData(
          AuthStateModel(
            user: currentState.user!.copyWith(passwordUpdated: true),
            token: currentState.token,
          ),
        );
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Register FCM token for push notifications
  Future<void> registerFcmToken(String fcmToken) async {
    try {
      await _authRepository.registerFcmToken(fcmToken);
    } catch (e) {
      // FCM registration failed
    }
  }

  /// Unregister FCM token
  Future<void> unregisterFcmToken(String fcmToken) async {
    try {
      await _authRepository.unregisterFcmToken(fcmToken);
    } catch (e) {
      // FCM unregistration failed
    }
  }
}

/// Auth Controller Provider - Optimized with AsyncNotifier
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthStateModel>(() {
  return AuthController();
});

/// Convenience provider for current user with better null safety
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.whenData((state) => state.user).value;
});

/// Convenience provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.whenData((state) => state.isAuthenticated).value ?? false;
});

/// Convenience provider to check if password update is needed
final needsPasswordUpdateProvider = Provider<bool>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.whenData((state) => state.needsPasswordUpdate).value ??
      false;
});

/// Convenience provider for auth token
final authTokenProvider = Provider<String?>((ref) {
  final authState = ref.watch(authControllerProvider);
  return authState.whenData((state) => state.token).value;
});

/// UI State for login screen
class LoginUiState {
  final bool obscurePassword;

  const LoginUiState({
    this.obscurePassword = true,
  });

  LoginUiState copyWith({
    bool? obscurePassword,
  }) {
    return LoginUiState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}
