import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxi_driver_app/features/auth/provider/auth_controller_optimized.dart';
import 'package:taxi_driver_app/router.dart';

/// GetX Middleware for protecting routes that require authentication
/// This middleware checks if the user is authenticated before allowing access to protected routes
class AuthMiddleware extends GetMiddleware {
  final ProviderContainer container;

  AuthMiddleware({required this.container});

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    // Get the current auth state from Riverpod
    final authState = container.read(authControllerProvider);

    // Check if auth state is loading
    if (authState.isLoading) {
      // Wait for auth check to complete
      return null;
    }

    // Check if user is authenticated
    final isAuthenticated =
        authState.whenData((state) => state.isAuthenticated).value ?? false;

    // If trying to access protected route but not authenticated, redirect to login
    if (!isAuthenticated && route != Routes.login) {
      return const RouteSettings(name: Routes.login);
    }

    // If authenticated and trying to access login, redirect to home
    if (isAuthenticated && route == Routes.login) {
      return const RouteSettings(name: Routes.home);
    }

    // Allow navigation
    return null;
  }
}

/// Middleware to redirect authenticated users away from auth screens
class LoginRedirectMiddleware extends GetMiddleware {
  final ProviderContainer container;

  LoginRedirectMiddleware({required this.container});

  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final authState = container.read(authControllerProvider);

    // If still loading, don't redirect yet
    if (authState.isLoading) {
      return null;
    }

    final isAuthenticated =
        authState.whenData((state) => state.isAuthenticated).value ?? false;
    final needsPasswordUpdate =
        authState.whenData((state) => state.needsPasswordUpdate).value ?? false;

    // If authenticated and password needs update, go to create password screen
    if (isAuthenticated &&
        needsPasswordUpdate &&
        route != Routes.createPassword) {
      return const RouteSettings(name: Routes.createPassword);
    }

    // If authenticated and on auth screens, redirect to home
    if (isAuthenticated &&
        !needsPasswordUpdate &&
        (route == Routes.login || route == Routes.createPassword)) {
      return const RouteSettings(name: Routes.home);
    }

    return null;
  }
}

/// Helper extension to check if a route requires authentication
extension RouteGuard on String {
  bool get requiresAuth {
    return this != Routes.login && this != Routes.createPassword;
  }
}

/// Provider for creating middleware instances with access to Riverpod container
class AuthMiddlewareFactory {
  final ProviderContainer container;

  AuthMiddlewareFactory(this.container);

  AuthMiddleware createAuthMiddleware() {
    return AuthMiddleware(container: container);
  }

  LoginRedirectMiddleware createLoginRedirectMiddleware() {
    return LoginRedirectMiddleware(container: container);
  }
}
