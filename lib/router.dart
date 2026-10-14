import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:taxi_driver_app/features/statistique/statistique_feature.dart';
import 'package:taxi_driver_app/features/profile/presentation/profile_screen.dart';
import 'package:taxi_driver_app/features/profile/profile_providers.dart';
import 'package:taxi_driver_app/features/wallet/presentation/screens/ride_details_screen.dart';
import 'package:taxi_driver_app/features/wallet/presentation/wallet_screen.dart';
import 'package:taxi_driver_app/features/wallet/presentation/bindings/wallet_binding.dart';
import 'package:taxi_driver_app/features/wallet/presentation/bindings/ride_details_binding.dart';
import 'package:taxi_driver_app/features/auth/presentation/login_screen.dart';
import 'package:taxi_driver_app/features/auth/presentation/privacy_policy_page.dart';
import 'package:taxi_driver_app/features/auth/presentation/forgot_password_phone_screen.dart';
import 'package:taxi_driver_app/features/auth/presentation/forgot_password_otp_screen.dart';
import 'package:taxi_driver_app/features/auth/presentation/forgot_password_reset_screen.dart';
import 'package:taxi_driver_app/features/auth/binding/auth_binding.dart';
import 'package:taxi_driver_app/features/home/presentation/home_screen.dart';
import 'package:taxi_driver_app/features/home/home_binding.dart';
import 'package:taxi_driver_app/features/notifications/presentation/notifications_screen.dart';
import 'package:taxi_driver_app/features/notifications/binding/notification_binding.dart';
import 'screens/splash_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/update_screen.dart';
import 'package:taxi_driver_app/features/shifts/presentation/shifts_screen.dart';
import 'package:taxi_driver_app/features/shifts/shifts_binding.dart';

abstract class Routes {
  static const splash = '/';
  static const root = '/root';
  static const login = '/login';
  static const privacyPolicy = '/privacy-policy';
  static const createPassword = '/create-password';
  static const forgotPasswordPhone = '/forgot-password-phone';
  static const forgotPasswordOtp = '/forgot-password-otp';
  static const forgotPasswordReset = '/forgot-password-reset';
  static const home = '/home';
  static const rideDetails = '/ride-details';
  static const wallet = '/wallet';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const stats = '/stats';
  static const dashcam = '/dashcam';
  static const offline = '/offline';
  static const update = '/update';
  static const shifts = '/shifts';
}

class AppPages {
  static final pages = <GetPage<dynamic>>[
    GetPage(
      name: Routes.splash,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.login,
      page: () => LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.privacyPolicy,
      page: () => const PrivacyPolicyPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.forgotPasswordPhone,
      page: () => const ForgotPasswordPhoneScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.forgotPasswordOtp,
      page: () => const ForgotPasswordOtpScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.forgotPasswordReset,
      page: () => const ForgotPasswordResetScreen(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
      // middlewares: [ConnectivityMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.rideDetails,
      page: () => const RideDetailsScreen(),
      binding: RideDetailsBinding(),
      fullscreenDialog: true,
      transition: Transition.cupertino,
    ),
    GetPage(
      name: Routes.wallet,
      page: () => const WalletScreen(
        cars: [],
        baseUrl: '',
      ),
      binding: WalletBinding(baseUrl: ''), // Binding will be initialized here
      // middlewares: [ConnectivityMiddleware()],
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsScreen(),
      binding: NotificationBinding(),
      // middlewares: [ConnectivityMiddleware()],
      transition: Transition.downToUp,
    ),
    GetPage(
      name: Routes.profile,
      page: () => const ProfileScreenNew(),
      binding: ProfileBinding(),
      // middlewares: [ConnectivityMiddleware()],
      transition: Transition.rightToLeftWithFade,
    ),
    GetPage(
      name: Routes.dashcam,
      page: () => const DashboardScreen(),
      // middlewares: [ConnectivityMiddleware()],
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.shifts,
      page: () => ShiftsScreen(carId: (Get.arguments as Map?)?['carId'] ?? ''),
      binding: ShiftBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.offline,
      page: () => const OfflineScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: Routes.update,
      page: () => const UpdateScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}

class AppRouter {
  static String get initialRoute => Routes.splash;

  static Route<dynamic>? onUnknownRoute(RouteSettings settings) {
    return GetPageRoute(
      settings: settings,
      page: () => const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}
