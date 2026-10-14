import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/features/auth/data/auth_repository.dart';
import 'package:taxi_driver_app/features/auth/data/auth_service.dart';
import 'package:taxi_driver_app/features/auth/domain/user_model.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/models/user.dart' as app_user;
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/services/firebase_messaging_service.dart';

import '../../../l10n/app_localizations.dart';
import '../../home/controller/home_controller.dart';

/// GetX Auth Controller for managing authentication state
class AuthControllerGetX extends GetxController {
  late final AuthRepository _authRepository;
  late final AppLocalizations l10n;
  // Observable state
  final Rx<UserModel?> _user = Rx<UserModel?>(null);
  final RxString _token = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  UserModel? get user => _user.value;
  String get token => _token.value;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isAuthenticated => _user.value != null && _token.value.isNotEmpty;
  bool get needsPasswordUpdate =>
      _user.value != null && _user.value!.passwordUpdated == false;

  String _readableErrorMessage(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
  }

  /// Set error message
  void setError(String message) {
    _errorMessage.value = message;
  }

  /// Clear error message
  void clearError() {
    _errorMessage.value = '';
  }

  @override
  void onInit() {
    super.onInit();
    _initializeAuthRepository();
    _checkAuthStatus();
  }

  /// Initialize auth repository
  void _initializeAuthRepository() {
    final prefs = Get.find<SharedPreferences>();
    final authService = AuthService();
    _authRepository = AuthRepository(
      authService: authService,
      prefs: prefs,
    );
  }

  /// Check if user is already authenticated on app startup
  Future<void> _checkAuthStatus() async {
    try {
      _isLoading.value = true;

      final isAuth = await _authRepository.isAuthenticated();

      if (isAuth) {
        final token = await _authRepository.getToken();
        final userData = await _authRepository.getStoredUserData();

        if (token != null && userData != null) {
          _user.value = userData;
          _token.value = token;

          // Set user in UserController for app-wide access (including permissions)
          try {
            final userController = Get.find<UserController>();
            // Convert UserModel to app User model
            final appUser = app_user.User(
              id: userData.id,
              fname: userData.fname,
              lname: userData.lname,
              email: userData.email,
              cin: userData.cin,
              dob: userData.dob,
              countryCode: userData.countryCode,
              phone: userData.phone,
              cars: userData.cars,
              isActive: userData.isActive,
              createdAt: userData.createdAt,
              lastTimeOnline: userData.lastTimeOnline,
              permissions: app_user.UserPermissions(
                gps: userData.permissions.gps,
                wallet: userData.permissions.wallet,
                booking: userData.permissions.booking,
                cam: userData.permissions.cam,
                ads: userData.permissions.ads,
              ),
              profilePhoto: userData.profilePhoto,
              preferences: app_user.UserPreferences(
                speedAlert: userData.preferences.speedAlert,
                freeStatusAlert: userData.preferences.freeStatusAlert != null
                    ? app_user.FreeStatusAlert(
                        distance:
                            userData.preferences.freeStatusAlert!.distance,
                        duration:
                            userData.preferences.freeStatusAlert!.duration,
                      )
                    : null,
                stopAlert: userData.preferences.stopAlert,
                openDoor: userData.preferences.openDoor,
                geoForcingAlert: userData.preferences.geoForcingAlert != null
                    ? app_user.GeoForcingAlert(
                        latitude:
                            userData.preferences.geoForcingAlert!.latitude,
                        longitude:
                            userData.preferences.geoForcingAlert!.longitude,
                        radius: userData.preferences.geoForcingAlert!.radius,
                      )
                    : null,
              ),
              passwordUpdated: userData.passwordUpdated,
              isOnline: userData.isOnline,
            );
            userController.setUser(appUser);
          } catch (e) {
            // Error setting user in UserController
          }

          // Navigate based on auth state
          if (needsPasswordUpdate) {
            Get.offAllNamed(Routes.createPassword);
          } else {
            Get.offAllNamed(Routes.home);
          }

          if (Get.isRegistered<FirebaseMessagingService>()) {
            try {
              await Get.find<FirebaseMessagingService>()
                  .syncFcmTokenWithBackend();
            } catch (_) {
              // Do not block authenticated session restore on FCM sync failure
            }
          }
        } else {
          await _authRepository.clearAuthData();
        }
      }
    } catch (e) {
      // Error checking auth status
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login user
  Future<void> login({
    required String phone,
    required String password,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final result = await _authRepository.login(
        phone: phone,
        password: password,
      );

      _user.value = result.user;
      _token.value = result.token;

      // Set user in UserController for app-wide access (including permissions)
      try {
        final userController = Get.find<UserController>();
        // Convert UserModel to app User model
        final appUser = app_user.User(
          id: result.user.id,
          fname: result.user.fname,
          lname: result.user.lname,
          email: result.user.email,
          cin: result.user.cin,
          dob: result.user.dob,
          countryCode: result.user.countryCode,
          phone: result.user.phone,
          cars: result.user.cars,
          isActive: result.user.isActive,
          createdAt: result.user.createdAt,
          lastTimeOnline: result.user.lastTimeOnline,
          permissions: app_user.UserPermissions(
            gps: result.user.permissions.gps,
            wallet: result.user.permissions.wallet,
            booking: result.user.permissions.booking,
            cam: result.user.permissions.cam,
            ads: result.user.permissions.ads,
          ),
          profilePhoto: result.user.profilePhoto,
          preferences: app_user.UserPreferences(
            speedAlert: result.user.preferences.speedAlert,
            freeStatusAlert: result.user.preferences.freeStatusAlert != null
                ? app_user.FreeStatusAlert(
                    distance: result.user.preferences.freeStatusAlert!.distance,
                    duration: result.user.preferences.freeStatusAlert!.duration,
                  )
                : null,
            stopAlert: result.user.preferences.stopAlert,
            openDoor: result.user.preferences.openDoor,
            geoForcingAlert: result.user.preferences.geoForcingAlert != null
                ? app_user.GeoForcingAlert(
                    latitude: result.user.preferences.geoForcingAlert!.latitude,
                    longitude:
                        result.user.preferences.geoForcingAlert!.longitude,
                    radius: result.user.preferences.geoForcingAlert!.radius,
                  )
                : null,
          ),
          passwordUpdated: result.user.passwordUpdated,
          isOnline: result.user.isOnline,
        );
        userController.setUser(appUser);
      } catch (e) {
        // Error setting user in UserController
      }

      // Refresh HomeController state after login
      try {
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          await homeController.refreshAfterLogin();
        }
      } catch (e) {
        // Error refreshing HomeController
      }

      // Register current FCM token after authenticated login
      // Navigate based on password status
      if (needsPasswordUpdate) {
        Get.offAllNamed(Routes.createPassword, arguments: password);
      } else {
        Get.offAllNamed(Routes.home);
      }

      if (Get.isRegistered<FirebaseMessagingService>()) {
        try {
          await Get.find<FirebaseMessagingService>().syncFcmTokenWithBackend();
        } catch (_) {
          // Login already succeeded; keep session and ignore token sync failure
        }
      }
    } catch (e) {
      final message = _readableErrorMessage(e);
      print('AuthController login catch: $e');
      print('AuthController snackbar message: $message');
      _errorMessage.value = message;

      // Show error snackbar
      if (Get.context != null) {
        CustomSnackBar.error(
          title: AppLocalizations.of(Get.context!).translate('loginFailed'),
          message: message,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Clear local auth state without calling the logout API.
  /// Used when refresh fails and the session is revoked.
  void forceUnauthenticated() {
    _user.value = null;
    _token.value = '';
    _errorMessage.value = '';
    _isLoading.value = false;
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _isLoading.value = true;

      if (Get.isRegistered<FirebaseMessagingService>()) {
        try {
          await Get.find<FirebaseMessagingService>().unregisterFcmToken();
        } catch (_) {
          // Never block logout on token unregistration issues
        }
      }

      await _authRepository.logout();

      _user.value = null;
      _token.value = '';
      _errorMessage.value = '';

      // Clear UserController
      try {
        if (Get.isRegistered<UserController>()) {
          final userController = Get.find<UserController>();
          userController.clearUser();
        }
      } catch (e) {
        // Error clearing UserController
      }

      // Reset HomeController state
      try {
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          homeController.clearState();
        }
      } catch (e) {
        // Error clearing HomeController
      }

      Get.offAllNamed(Routes.login);
    } catch (e) {
      _errorMessage.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Update password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _authRepository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // Update user's passwordUpdated flag
      if (_user.value != null) {
        _user.value = _user.value!.copyWith(passwordUpdated: true);

        // Save updated user data
        final prefs = Get.find<SharedPreferences>();
        await prefs.setString('user_data', _user.value!.toJson().toString());
      }

      CustomSnackBar.success(
        title: l10n.translate('Success'),
        message: l10n.translate('passwordUpdatedSuccessfully'),
      );

      return true;
    } catch (e) {
      _errorMessage.value = e.toString();

      CustomSnackBar.error(
        title: l10n.translate('Error'),
        message: l10n.translate('Error'),
      );

      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Register FCM token for push notifications
  Future<void> registerFcmToken(String fcmToken) async {
    try {
      await _authRepository.registerFcmToken(fcmToken);
    } catch (e) {
      // FCM token registration error
    }
  }

  /// Check whether the forgot-password account has an email address
  Future<String?> checkPasswordResetIdentifier(String phone) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      return await _authRepository.checkPasswordResetIdentifier(phone);
    } catch (e) {
      final message = _readableErrorMessage(e);
      _errorMessage.value = message;

      if (Get.context != null) {
        CustomSnackBar.error(
          title: AppLocalizations.of(Get.context!).translate('Error'),
          message: message,
        );
      }

      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Unregister FCM token
  Future<void> unregisterFcmToken(String fcmToken) async {
    try {
      await _authRepository.unregisterFcmToken(fcmToken);
    } catch (e) {
      // FCM token unregistration error
    }
  }

  /// Request OTP for password reset
  Future<void> requestPasswordResetOtp({String? phone, String? email}) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _authRepository.requestPasswordResetOtp(
        phone: phone,
        email: email,
      );

      if (Get.context != null) {
        CustomSnackBar.success(
          title: AppLocalizations.of(Get.context!).translate('Success'),
          message: AppLocalizations.of(Get.context!)
                  .translate('otpSentSuccessfully') ??
              'OTP sent successfully',
        );
      }
    } catch (e) {
      final message = _readableErrorMessage(e);
      _errorMessage.value = message;

      if (Get.context != null) {
        CustomSnackBar.error(
          title: AppLocalizations.of(Get.context!).translate('Error'),
          message: message,
        );
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Verify OTP for password reset
  Future<String> verifyPasswordResetOtp({
    String? phone,
    String? email,
    required String otp,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      final resetToken = await _authRepository.verifyPasswordResetOtp(
        phone: phone,
        email: email,
        otp: otp,
      );

      if (Get.context != null) {
        CustomSnackBar.success(
          title: AppLocalizations.of(Get.context!).translate('Success'),
          message: AppLocalizations.of(Get.context!)
                  .translate('otpVerifiedSuccessfully') ??
              'OTP verified successfully',
        );
      }

      return resetToken;
    } catch (e) {
      final message = _readableErrorMessage(e);
      _errorMessage.value = message;

      if (Get.context != null) {
        CustomSnackBar.error(
          title: AppLocalizations.of(Get.context!).translate('Error'),
          message: message,
        );
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Reset password using reset token
  Future<void> resetPasswordWithToken({
    String? phone,
    String? email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      _isLoading.value = true;
      _errorMessage.value = '';

      await _authRepository.resetPassword(
        phone: phone,
        email: email,
        resetToken: resetToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (Get.context != null) {
        CustomSnackBar.success(
          title: AppLocalizations.of(Get.context!).translate('Success'),
          message: AppLocalizations.of(Get.context!)
                  .translate('passwordResetSuccessfully') ??
              'Password updated successfully',
        );
      }
    } catch (e) {
      final message = _readableErrorMessage(e);
      _errorMessage.value = message;

      if (Get.context != null) {
        CustomSnackBar.error(
          title: AppLocalizations.of(Get.context!).translate('Error'),
          message: message,
        );
      }
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Extract readable error message from exception

  @override
  void onClose() {
    // Clean up resources
    super.onClose();
  }
}
