import 'package:get/get.dart';
import 'package:taxi_driver_app/services/car_service.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/features/auth/data/auth_repository.dart';
import 'package:taxi_driver_app/features/auth/data/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/models/user.dart' as app_user;
import 'package:flutter/foundation.dart';
import 'package:taxi_driver_app/features/home/application/live_tracking_pip_coordinator.dart';

class HomeController extends GetxController {
  final CarService _carService;
  HomeController({required CarService carService}) : _carService = carService;

  // Reactive state
  final RxInt selectedIndex =
      RxInt(-1); // Will be set based on wallet permission
  final RxInt tabIndex = 0.obs; // live/history inside map tab
  final RxBool isLoadingCars = true.obs;
  final RxList<Map<String, dynamic>> cars = <Map<String, dynamic>>[].obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  /// Initialize or refresh the controller state
  Future<void> _initialize() async {
    await _restoreUserDataIfNeeded();
    await fetchUserCars(); // Load cars first to determine car type
    _setInitialTab(); // Then set tab based on car type
  }

  /// Public method to refresh state after login
  Future<void> refreshAfterLogin() async {
    await _initialize();
  }

  /// Clear all state when user logs out
  void clearState() {
    cars.clear();
    error.value = null;
    isLoadingCars.value = true;
    selectedIndex.value = -1;
    tabIndex.value = 0;
  }

  /// Returns true if any of the user's cars is a Taxi
  bool get hasTaxiCar {
    return cars.any(
        (car) => (car['car_type']?.toString().toLowerCase() ?? '') == 'taxi');
  }

  /// Set initial tab based on wallet permission and car type
  void _setInitialTab() {
    final userController = Get.find<UserController>();
    final hasWallet = userController.user.value?.permissions.wallet ?? false;
    if (hasTaxiCar) {
      // Taxi users: start on Accueil (indice de performance)
      // Accueil is index 2 with wallet permission, index 1 without
      selectedIndex.value = hasWallet ? 2 : 1;
    } else {
      // Louage / Autre users: start directly on GPS screen
      selectedIndex.value = 0;
    }
  }

  /// Restore user data from storage if UserController is empty
  /// This fixes the issue where on web refresh, the GetX controller persists
  /// but loses its reactive values
  Future<void> _restoreUserDataIfNeeded() async {
    try {
      final userController = Get.find<UserController>();

      // Check if user data is missing (happens on web refresh)
      if (userController.user.value == null) {
        final prefs = Get.find<SharedPreferences>();
        final authService = AuthService();
        final authRepository = AuthRepository(
          authService: authService,
          prefs: prefs,
        );

        final userData = await authRepository.getStoredUserData();

        if (userData != null) {
          // Convert to app User model and restore
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
                      distance: userData.preferences.freeStatusAlert!.distance,
                      duration: userData.preferences.freeStatusAlert!.duration,
                    )
                  : null,
              stopAlert: userData.preferences.stopAlert,
              openDoor: userData.preferences.openDoor,
              geoForcingAlert: userData.preferences.geoForcingAlert != null
                  ? app_user.GeoForcingAlert(
                      latitude: userData.preferences.geoForcingAlert!.latitude,
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
        }
      } else {
      }
    } catch (e) {
    }
  }

  void selectTab(int index) {
    selectedIndex.value = index;
    // Leaving the Map tab must never keep Live PiP armed.
    if (index != 0 && Get.isRegistered<LiveTrackingPipCoordinator>()) {
      Get.find<LiveTrackingPipCoordinator>().setLiveTrackingVisible(false);
    }
  }

  void switchInnerTab(int index) {
    tabIndex.value = index;
    if (index != 0 && Get.isRegistered<LiveTrackingPipCoordinator>()) {
      Get.find<LiveTrackingPipCoordinator>().setLiveTrackingVisible(false);
    }
  }

  Future<void> fetchUserCars() async {
    try {
      isLoadingCars.value = true;
      error.value = null;
      final response = await _carService.getUserCars();
      final list =
          (response['cars'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      cars.assignAll(list);
    } catch (e) {
      cars.clear();
      error.value = e.toString();
    } finally {
      isLoadingCars.value = false;
    }
  }
}
