import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/features/profile/data/user_repository.dart';
import 'package:taxi_driver_app/features/profile/domain/profile_model.dart';
import 'package:taxi_driver_app/models/user.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/firebase_messaging_service.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';

/// Profile controller using GetX
class ProfileController extends GetxController {
  final UserRepository _repository;

  ProfileController({required UserRepository repository})
      : _repository = repository;

  /// Reactive state
  final Rx<ProfileState> state = const ProfileState().obs;

  /// Tracks which authenticated user profile is currently initialized.
  String? _initializedUserId;

  /// Helper to get auth token and userId
  Future<(String token, String userId)?> _getAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final auth = AuthService(prefs);
    final token = await auth.getToken();
    final userId = await auth.getUserId();
    if (token == null || userId == null) return null;
    return (token, userId);
  }

  /// Initialize profile data for the current authenticated user.
  Future<void> initialize() async {
    final auth = await _getAuth();

    // Auth not ready yet (e.g., app startup before first login).
    if (auth == null) {
      _initializedUserId = null;
      return;
    }

    // Skip duplicate initialization for the same authenticated user.
    if (_initializedUserId == auth.$2) return;

    try {
      final user = await _repository.getCurrentUser(auth.$1, auth.$2);
      state.update((s) {
        if (s == null) return;
        state.value = s.copyWith(user: user);
      });

      if (Get.isRegistered<UserController>()) {
        final userController = Get.find<UserController>();
        userController.setUser(user);
      }

      _initializedUserId = auth.$2;
    } finally {
      await loadCars();
    }
  }

  /// Load cars
  Future<void> loadCars() async {
    state.value = state.value.copyWith(isLoadingCars: true, clearError: true);
    try {
      final cars = await _repository.loadCars();

      List<Map<String, dynamic>> carPrefsList = [];
      String? preferencesError;
      try {
        carPrefsList = await _repository.getCarPreferences();
      } catch (e) {
        preferencesError = e.toString();
      }

      // Build per-car preferences map from /api/cars/preferences response
      final prefsMap = <String, UserPreferences>{};
      for (final item in carPrefsList) {
        final carId = item['car_id']?.toString() ?? '';
        if (carId.isNotEmpty && item['preferences'] != null) {
          try {
            prefsMap[carId] = UserPreferences.fromJson(
                item['preferences'] as Map<String, dynamic>);
          } catch (_) {}
        }
      }

      state.value = state.value.copyWith(
        cars: cars,
        carPreferences: prefsMap,
        isLoadingCars: false,
        errorMessage: preferencesError,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        isLoadingCars: false,
        errorMessage: 'Failed to load cars: $e',
      );
    }
  }

  /// Upload profile photo
  Future<void> uploadProfilePhoto(Uint8List bytes, String filename) async {
    state.value =
        state.value.copyWith(isUploadingPhoto: true, clearError: true);
    try {
      await _repository.uploadProfilePhoto(bytes, filename);
      // Refresh user after upload
      final auth = await _getAuth();
      if (auth != null) {
        final user = await _repository.getCurrentUser(auth.$1, auth.$2);
        state.value = state.value.copyWith(user: user);

        // Update UserController to refresh the profile picture in AppHeader
        final userController = Get.find<UserController>();
        userController.setUser(user);
      }
    } catch (e) {
      state.value = state.value.copyWith(
        errorMessage: 'profilePhotoUploadFailed',
      );
      rethrow;
    } finally {
      state.value = state.value.copyWith(isUploadingPhoto: false);
    }
  }

  /// Remove profile photo
  Future<void> removeProfilePhoto() async {
    state.value = state.value.copyWith(isRemovingPhoto: true, clearError: true);
    try {
      await _repository.removeProfilePhoto();
      // Refresh user after removal
      final auth = await _getAuth();
      if (auth != null) {
        final user = await _repository.getCurrentUser(auth.$1, auth.$2);
        state.value = state.value.copyWith(user: user);

        // Update UserController to refresh the profile picture in AppHeader
        final userController = Get.find<UserController>();
        userController.setUser(user);
      }
    } catch (e) {
      state.value = state.value.copyWith(
        errorMessage: 'profilePhotoRemoveFailed',
      );
      rethrow;
    } finally {
      state.value = state.value.copyWith(isRemovingPhoto: false);
    }
  }

  /// Update preferences
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    state.value =
        state.value.copyWith(isUpdatingPreferences: true, clearError: true);
    try {
      await _repository.updatePreferences(preferences);
      // Refresh user to reflect preference changes
      final auth = await _getAuth();
      if (auth != null) {
        final user = await _repository.getCurrentUser(auth.$1, auth.$2);
        state.value = state.value.copyWith(user: user);
      }
    } catch (e) {
      state.value = state.value.copyWith(
        errorMessage: 'Failed to update preferences: $e',
      );
      rethrow;
    } finally {
      state.value = state.value.copyWith(isUpdatingPreferences: false);
    }
  }

  /// Update password
  Future<void> updatePassword(PasswordUpdateData data) async {
    state.value =
        state.value.copyWith(isUpdatingPassword: true, clearError: true);
    try {
      await _repository.updatePassword(
        oldPassword: data.oldPassword,
        newPassword: data.newPassword,
      );
    } catch (e) {
      state.value = state.value.copyWith(
        errorMessage: 'Failed to update password: $e',
      );
      rethrow;
    } finally {
      state.value = state.value.copyWith(isUpdatingPassword: false);
    }
  }

  /// Update first and/or last name.
  Future<void> updateProfileInfo({String? fname, String? lname}) async {
    state.value =
        state.value.copyWith(isUpdatingProfile: true, clearError: true);
    try {
      await _repository.updateProfile(fname: fname, lname: lname);
      final auth = await _getAuth();
      if (auth != null) {
        final user = await _repository.getCurrentUser(auth.$1, auth.$2);
        state.value = state.value.copyWith(user: user);

        if (Get.isRegistered<UserController>()) {
          final userController = Get.find<UserController>();
          userController.setUser(user);
        }
      }
    } catch (e) {
      state.value = state.value.copyWith(
        errorMessage: 'Failed to update profile: $e',
      );
      rethrow;
    } finally {
      state.value = state.value.copyWith(isUpdatingProfile: false);
    }
  }

  /// Request an OTP to change the phone number or email address.
  Future<void> requestProfileChangeOtp({String? phone, String? email}) async {
    state.value =
        state.value.copyWith(isUpdatingContact: true, clearError: true);
    try {
      await _repository.requestProfileChangeOtp(phone: phone, email: email);
    } catch (e) {
      state.value = state.value.copyWith(
        errorMessage: 'Failed to request OTP: $e',
      );
      rethrow;
    } finally {
      state.value = state.value.copyWith(isUpdatingContact: false);
    }
  }

  /// Verify the OTP and persist the new phone number or email address.
  Future<void> verifyProfileChangeOtp({
    String? phone,
    String? email,
    required String otp,
  }) async {
    state.value =
        state.value.copyWith(isUpdatingContact: true, clearError: true);
    try {
      await _repository.verifyProfileChangeOtp(
        phone: phone,
        email: email,
        otp: otp,
      );

      final auth = await _getAuth();
      if (auth != null) {
        final user = await _repository.getCurrentUser(auth.$1, auth.$2);
        state.value = state.value.copyWith(user: user);

        if (Get.isRegistered<UserController>()) {
          final userController = Get.find<UserController>();
          userController.setUser(user);
        }
      }
    } catch (e) {
      state.value = state.value.copyWith(
        errorMessage: 'Failed to verify OTP: $e',
      );
      rethrow;
    } finally {
      state.value = state.value.copyWith(isUpdatingContact: false);
    }
  }

  /// Update car-specific preferences
  Future<void> updateCarPreferences(
      String carId, Map<String, dynamic> prefs) async {
    // Optimistically update local state immediately so the UI reflects the
    // change without waiting for the network round-trip.
    final previousPreferences =
        Map<String, UserPreferences>.from(state.value.carPreferences);
    final updatedMap =
        Map<String, UserPreferences>.from(state.value.carPreferences);
    final existing = updatedMap[carId] ?? UserPreferences();
    final merged = <String, dynamic>{...existing.toJson(), ...prefs};
    updatedMap[carId] = UserPreferences.fromJson(merged);
    state.value = state.value.copyWith(carPreferences: updatedMap);

    try {
      await _repository.updateCarPreferences(carId, prefs);
    } catch (e) {
      // Revert optimistic update on failure
      state.value = state.value.copyWith(
        carPreferences: previousPreferences,
        errorMessage: 'Failed to update car preferences: $e',
      );
      rethrow;
    }
  }

  /// Remote stop car
  Future<void> remoteStopCar(String carId) async {
    state.value = state.value.copyWith(clearError: true);
    try {
      await _repository.remoteStopCar(carId);
      // Update local cars list so RemoteStartCard becomes enabled immediately
      final updatedCars = state.value.cars.map((car) {
        if (car['car_id']?.toString() == carId) {
          return {...car, 'action': 'stop'};
        }
        return car;
      }).toList();
      state.value = state.value.copyWith(cars: updatedCars);
    } catch (e) {
      state.value =
          state.value.copyWith(errorMessage: 'Failed to stop car: $e');
      rethrow;
    }
  }

  /// Remote start car
  Future<void> remoteStartCar(String carId) async {
    state.value = state.value.copyWith(clearError: true);
    try {
      await _repository.remoteStartCar(carId);
      // Update local cars list so RemoteStopCard becomes enabled immediately
      final updatedCars = state.value.cars.map((car) {
        if (car['car_id']?.toString() == carId) {
          return {...car, 'action': 'go'};
        }
        return car;
      }).toList();
      state.value = state.value.copyWith(cars: updatedCars);
    } catch (e) {
      state.value =
          state.value.copyWith(errorMessage: 'Failed to start car: $e');
      rethrow;
    }
  }

  /// Handle logout - Clear all cache and redirect to login
  Future<void> logout() async {
    try {
      // Unregister FCM token to disable push notifications
      try {
        final firebaseService = Get.find<FirebaseMessagingService>();
        await firebaseService.unregisterFcmToken();
      } catch (e) {
        // Continue with logout even if FCM unregistration fails
      }

      final prefs = await SharedPreferences.getInstance();

      // Clear all shared preferences (token, user data, etc.)
      await prefs.clear();

      // Clear UserController
      try {
        if (Get.isRegistered<UserController>()) {
          final userController = Get.find<UserController>();
          userController.clearUser();
        }
      } catch (e) {
      }

      // Reset HomeController state
      try {
        if (Get.isRegistered<HomeController>()) {
          final homeController = Get.find<HomeController>();
          homeController.clearState();
        }
      } catch (e) {
      }

      // Reset state
      state.value = const ProfileState();
      _initializedUserId = null;

      // Navigate to login screen and remove all previous routes
      // Use named route to ensure AuthBinding is properly initialized
      Get.offAllNamed('/login');
    } catch (e) {
      state.value = state.value.copyWith(errorMessage: 'Failed to logout: $e');
      rethrow;
    }
  }

  @override
  void onClose() {
    _initializedUserId = null;
    super.onClose();
  }

  /// Clear error message
  void clearError() {
    state.value = state.value.copyWith(clearError: true);
  }
}
