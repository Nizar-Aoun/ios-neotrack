import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/services/connectivity_service.dart';
import 'package:taxi_driver_app/router.dart';

/// Connectivity Controller - Manages network connectivity state
class ConnectivityController extends GetxController
    with WidgetsBindingObserver {
  final RxBool isConnected = true.obs;
  final RxBool hasGoodConnection = true.obs;
  final Rx<NetworkQuality> currentQuality = NetworkQuality.excellent.obs;
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isNavigatingToOffline = false;
  bool _isAppResuming = false;
  bool _isAppInBackground = false;
  DateTime? _lastPauseTime;
  String? _previousRoute;

  ConnectivityService get connectivityService => _connectivityService;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _connectivityService.addListener(_onConnectivityChanged);
    isConnected.value = _connectivityService.isConnected;
    hasGoodConnection.value = _connectivityService.hasGoodConnection;
    currentQuality.value = _connectivityService.currentQuality;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.removeListener(_onConnectivityChanged);
    _connectivityService.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App going to background - record the time and set flag
      _lastPauseTime = DateTime.now();
      _isAppInBackground = true;
    } else if (state == AppLifecycleState.resumed) {
      // App coming back from background
      _isAppInBackground = false;
      _handleAppResume();
    }
  }

  Future<void> _handleAppResume() async {
    // Set flag to prevent showing offline screen during resume check
    _isAppResuming = true;

    // Force check connectivity immediately when app resumes
    await _connectivityService.forceCheckConnectivity();

    // Update local state
    isConnected.value = _connectivityService.isConnected;
    hasGoodConnection.value = _connectivityService.hasGoodConnection;
    currentQuality.value = _connectivityService.currentQuality;

    // If connection is good when app resumes, redirect away from offline screen
    if (hasGoodConnection.value) {
      final currentRoute = Get.currentRoute;
      if (currentRoute == Routes.offline) {
        // We're on offline screen but connection is good - go back to previous route
        final routeToGo = _previousRoute ?? Routes.home;
        _previousRoute = null;

        // Redirect immediately
        Get.offAllNamed(routeToGo);
      }
    }

    // Small delay before allowing offline navigation again
    await Future.delayed(const Duration(milliseconds: 500));
    _isAppResuming = false;
  }

  void _onConnectivityChanged() {
    final hadGoodConnection = hasGoodConnection.value;

    isConnected.value = _connectivityService.isConnected;
    hasGoodConnection.value = _connectivityService.hasGoodConnection;
    currentQuality.value = _connectivityService.currentQuality;

    // Handle connection state changes
    // Only trigger offline mode when hasGoodConnection is false (after 10 second delay)
    if (!hasGoodConnection.value) {
      // Lost connection or poor quality - redirect to offline screen
      _handleConnectionLoss();
    } else if (hadGoodConnection != hasGoodConnection.value &&
        hasGoodConnection.value) {
      // Connection restored - redirect to splash to reinitialize
      _handleConnectionRestored();
    }
  }

  void _handleConnectionLoss() {
    // Skip offline navigation for web platform
    if (kIsWeb) return;

    // Skip if app is resuming from background - wait for resume check to complete
    if (_isAppResuming) return;

    if (_isNavigatingToOffline) return;

    final currentRoute = Get.currentRoute;
    if (currentRoute == Routes.offline || currentRoute == Routes.splash) {
      return;
    }

    // Store the current route before going offline
    _previousRoute = currentRoute;

    _isNavigatingToOffline = true;

    // Navigate to offline screen
    Get.offAllNamed(Routes.offline);

    // Reset flag after navigation
    Future.delayed(const Duration(milliseconds: 500), () {
      _isNavigatingToOffline = false;
    });
  }

  void _handleConnectionRestored() {
    // Skip for web platform
    if (kIsWeb) return;

    if (_isNavigatingToOffline) return;
    if (_isAppResuming) return;

    final currentRoute = Get.currentRoute;

    // Only redirect if we're on the offline screen
    if (currentRoute == Routes.offline) {
      // Go back to the previous route if available, otherwise go to home
      final routeToGo = _previousRoute ?? Routes.home;

      // Clear the previous route
      _previousRoute = null;

      // Navigate back to the stored route or home
      Get.offAllNamed(routeToGo);
    }
  }

  /// Force check connectivity
  Future<void> forceCheck() async {
    await _connectivityService.forceCheckConnectivity();
  }

  /// Check network quality
  Future<NetworkQuality> checkQuality() async {
    return await _connectivityService.checkNetworkQuality();
  }
}
