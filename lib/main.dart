import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/core/auth/session_manager.dart';
import 'package:taxi_driver_app/core/auth/token_store.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/car_service.dart';
import 'package:taxi_driver_app/services/user_service.dart';
import 'package:taxi_driver_app/features/profile/data/user_repository.dart';
import 'package:taxi_driver_app/features/profile/application/profile_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:taxi_driver_app/services/notification_service.dart';
import 'package:taxi_driver_app/services/firebase_messaging_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:taxi_driver_app/core/theme/app_theme.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:taxi_driver_app/utils/image_cache_helper.dart';

// Import GetX Controllers
import 'package:taxi_driver_app/core/controllers/language_controller.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/core/controllers/connectivity_controller.dart';
import 'package:taxi_driver_app/core/controllers/tab_controller.dart'
    as app_tab;
import 'package:taxi_driver_app/features/notifications/provider/notification_controller.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';
import 'package:taxi_driver_app/features/shifts/shifts_binding.dart';

// Global navigator key for navigation from anywhere in the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure edge-to-edge for Android 15+ compatibility
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

  // Configure image cache for optimal map tile performance
  ImageCacheHelper.configureImageCache();

  // Initialize Firebase first
  // For web, Firebase is initialized via the script in index.html
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAJwvPHxiMA9WaBpevo2TAFkM1707aeLHY",
        authDomain: "neotrack-91425.firebaseapp.com",
        projectId: "neotrack-91425",
        storageBucket: "neotrack-91425.firebasestorage.app",
        messagingSenderId: "1040651729001",
        appId: "1:1040651729001:web:3ab2ec5f55c7e4a6f0caf8",
        measurementId: "G-41FX0P0GVP",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Initialize SQLite for desktop platforms
  if (kIsWeb == false &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize services and register them with GetX
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);

  final tokenStore = TokenStore(prefs: prefs);
  await tokenStore.init();
  Get.put<TokenStore>(tokenStore, permanent: true);

  final sessionManager = SessionManager(tokenStore: tokenStore);
  Get.put<SessionManager>(sessionManager, permanent: true);

  final apiClient = ApiClient(sessionManager: sessionManager);
  Get.put<ApiClient>(apiClient, permanent: true);

  final authService = AuthService(
    prefs,
    tokenStore: tokenStore,
    sessionManager: sessionManager,
  );
  Get.put<AuthService>(authService, permanent: true);

  final carService = CarService(authService);
  Get.put<CarService>(carService, permanent: true);

  final notificationService = NotificationService(authService);
  Get.put<NotificationService>(notificationService, permanent: true);

  final firebaseMessagingService = FirebaseMessagingService(authService);
  Get.put<FirebaseMessagingService>(firebaseMessagingService, permanent: true);

  // Prepare UserRepository for Profile feature
  final userRepository = UserRepository(
    userService: UserService(authService),
    carService: carService,
  );
  Get.put<UserRepository>(userRepository, permanent: true);

  // Initialize Profile Controller
  Get.put<ProfileController>(
    ProfileController(repository: userRepository),
    permanent: true,
  );

  // Initialize GetX Controllers
  Get.put<LanguageController>(LanguageController(), permanent: true);
  Get.put<UserController>(UserController(), permanent: true);
  Get.put<ConnectivityController>(ConnectivityController(), permanent: true);
  Get.put<app_tab.AppTabController>(app_tab.AppTabController(),
      permanent: true);

  // Initialize HomeController globally so it's available to all screens
  final homeController = HomeController(carService: carService);
  Get.put<HomeController>(homeController, permanent: true);
  // Initialize Shift feature
  ShiftBinding().dependencies();

  final notificationController = NotificationController();
  notificationController.init(notificationService, authService);
  Get.put<NotificationController>(notificationController, permanent: true);

  // Initialize profile data at startup so header avatar is available on home
  Get.find<ProfileController>().initialize();

  // Set the navigator key for Firebase messaging service
  FirebaseMessagingService.setNavigatorKey(navigatorKey);

  // Initialize Firebase messaging
  await firebaseMessagingService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(() => GetMaterialApp(
          navigatorKey: navigatorKey,
          title: 'NEOS Driver',
          getPages: AppPages.pages,
          initialRoute: Routes.splash,
          theme: AppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('ar'),
          ],
          locale: languageController.currentLocale.value,
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale != null) {
              for (final supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            return supportedLocales.first;
          },
          debugShowCheckedModeBanner: false,
        ));
  }
}
