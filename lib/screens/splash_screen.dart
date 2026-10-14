import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/features/auth/data/auth_repository.dart';
import 'package:taxi_driver_app/features/auth/data/auth_service.dart'
    as auth_service;
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/core/controllers/connectivity_controller.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/models/user.dart' as app_user;
import 'package:taxi_driver_app/services/checkForUpdate_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // First check connectivity (skip for web platform)
      if (!kIsWeb && Get.isRegistered<ConnectivityController>()) {
        final connectivityController = Get.find<ConnectivityController>();
        await connectivityController.forceCheck();

        // If no connection or poor quality, redirect to offline screen
        if (!connectivityController.isConnected.value ||
            !connectivityController.hasGoodConnection.value) {
          Get.offAllNamed(Routes.offline);
          return;
        }
      }

      // final service = CheckForUpdateService();
      // final isUpToDate = await service.checkForUpdate();
      // if (!isUpToDate) {
      //   Get.offAllNamed(Routes.update);
      //   return;
      // }

      // Navigate immediately without delay

      final prefs = Get.find<SharedPreferences>();
      final authService = auth_service.AuthService();
      final authRepository = AuthRepository(
        authService: authService,
        prefs: prefs,
      );
      final userController = Get.find<UserController>();

      final isAuth = await authRepository.isAuthenticated();
      if (isAuth) {
        final token = await authRepository.getToken();
        final userData = await authRepository.getStoredUserData();
        if (token != null && userData != null) {
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
            passwordUpdated: userData.passwordUpdated, isOnline: userData.isOnline,
          );

          userController.setUser(appUser);
          Get.offAllNamed(Routes.home);
        } else {
          await authRepository.clearAuthData();
          userController.clearUser();
          Get.offAllNamed(Routes.login);
        }
      } else {
        userController.clearUser();
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      Get.offAllNamed(Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return an empty transparent container - navigation happens immediately
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
