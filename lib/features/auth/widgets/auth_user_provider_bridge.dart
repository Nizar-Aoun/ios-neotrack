import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:taxi_driver_app/features/auth/provider/auth_controller_optimized.dart';
import 'package:taxi_driver_app/providers/user_provider.dart';
import 'package:taxi_driver_app/models/user.dart' as legacy;
import 'package:taxi_driver_app/features/auth/domain/user_model.dart';

/// Bridge widget that connects the new Riverpod auth system with the old Provider-based UserProvider
/// This ensures that legacy components that depend on UserProvider still work correctly
class AuthUserProviderBridge extends ConsumerWidget {
  final Widget child;

  const AuthUserProviderBridge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to auth state changes
    ref.listen<AsyncValue<AuthStateModel>>(
      authControllerProvider,
      (previous, next) {
        final userProvider = legacy_provider.Provider.of<UserProvider>(
          context,
          listen: false,
        );

        next.when(
          data: (authState) {
            if (authState.isAuthenticated && authState.user != null) {
              // Convert UserModel to legacy User model and update UserProvider
              final legacyUser = _convertUserModelToUser(authState.user!);
              userProvider.setUser(legacyUser);
            } else {
              // Clear user when not authenticated
              userProvider.setUser(null);
            }
          },
          loading: () {
            // Don't clear user during loading to avoid UI flicker
          },
          error: (error, stack) {
            // Clear user on auth error
            userProvider.setUser(null);
          },
        );
      },
    );

    return child;
  }

  /// Convert the new UserModel to the legacy User model
  legacy.User _convertUserModelToUser(UserModel userModel) {
    return legacy.User(
      id: userModel.id,
      fname: userModel.fname,
      lname: userModel.lname,
      email: userModel.email,
      cin: userModel.cin,
      dob: userModel.dob,
      countryCode: userModel.countryCode,
      phone: userModel.phone,
      profilePhoto: userModel.profilePhoto,
      cars: userModel.cars,
      isActive: userModel.isActive,
      lastTimeOnline: userModel.lastTimeOnline,
      permissions: legacy.UserPermissions(
        gps: userModel.permissions.gps,
        wallet: userModel.permissions.wallet,
        booking: userModel.permissions.booking,
        cam: userModel.permissions.cam,
        ads: userModel.permissions.ads,
      ),
      preferences: legacy.UserPreferences(
        freeStatusAlert: legacy.FreeStatusAlert(
          distance: userModel.preferences.freeStatusAlert?.distance,
          duration: userModel.preferences.freeStatusAlert?.duration,
        ),
        speedAlert: userModel.preferences.speedAlert,
        stopAlert: userModel.preferences.stopAlert,
        openDoor: userModel.preferences.openDoor,
      ),
      createdAt: userModel.createdAt,
      passwordUpdated: userModel.passwordUpdated, isOnline: userModel.isOnline,
    );
  }
}
