import 'dart:io' show Platform;

import 'package:floating/floating.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/features/statistique/statistique_feature.dart';
import 'package:taxi_driver_app/features/home/presentation/map_screen.dart';
import 'package:taxi_driver_app/features/home/presentation/widgets/bottom_navigation_bar.dart';
import 'package:taxi_driver_app/features/home/presentation/widgets/app_header.dart';
import 'package:taxi_driver_app/features/wallet/presentation/wallet_screen.dart';
import 'package:taxi_driver_app/features/wallet/presentation/bindings/wallet_binding.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/features/help/help_binding.dart';
import 'package:taxi_driver_app/features/help/provider/help_controller.dart';
import 'package:taxi_driver_app/features/home/application/live_tracking_pip_coordinator.dart';
import 'package:taxi_driver_app/features/home/map_binding.dart';
import 'package:taxi_driver_app/features/home/controller/map_controller.dart';
import 'package:taxi_driver_app/services/permission_service.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';
import 'package:taxi_driver_app/features/help/presentation/help_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  static Stream<PiPStatus> get _pipStatusStream {
    if (kIsWeb || !Platform.isAndroid) {
      return Stream<PiPStatus>.value(PiPStatus.disabled);
    }
    return Floating().pipStatusStream;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 650;
    return StreamBuilder<PiPStatus>(
      stream: _pipStatusStream,
      initialData: PiPStatus.disabled,
      builder: (context, pipSnapshot) {
        final inPip = pipSnapshot.data == PiPStatus.enabled;
        return Obx(() {
          final cars = controller.cars;
          final selected = controller.selectedIndex.value;

          // Calculate the total number of tabs
          final totalTabs =
              PermissionService.hasWalletPermission(context) ? 4 : 3;

          // Ensure selectedIndex in range (but skip if still initializing)
          if (selected >= totalTabs && selected >= 0) {
            final hasWallet = PermissionService.hasWalletPermission(context);
            controller.selectTab(hasWallet ? 2 : 1); // Default to Accueil
          }

          // Show loading while initializing
          if (selected < 0) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            body: Stack(
              children: [
                // Main content - Build ONLY the selected tab
                _buildSelectedTabLazy(selected, cars, isSmallScreen, context),

                // App header — hidden in Picture-in-Picture
                if (!inPip)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AppHeader(
                      isSmallScreen: isSmallScreen,
                      currentTabIndex: selected,
                      onTabChanged: (index) {
                        if (selected == 0) {
                          controller.switchInnerTab(index);
                        }
                      },
                    ),
                  ),
              ],
            ),
            bottomNavigationBar: inPip
                ? null
                : HomeBottomNavigationBar(
                    isSmallScreen: isSmallScreen,
                  ),
          );
        });
      },
    );
  }

  /// Build only the currently selected tab to prevent eager initialization
  /// Uses a cache system to prevent recreating widgets unnecessarily
  Widget _buildSelectedTabLazy(
    int index,
    List<Map<String, dynamic>> cars,
    bool isSmallScreen,
    BuildContext context,
  ) {
    // Adjust index based on wallet permission
    final hasWallet = PermissionService.hasWalletPermission(context);

    if (index == 0) {
      // Map tab
      return _LazyMapScreenWrapper(key: const ValueKey('map'));
    } else if (index == 1 && hasWallet) {
      // Wallet tab (only if permission exists)
      return _LazyWalletScreenWrapper(
        key: const ValueKey('wallet'),
        cars: cars,
        baseUrl: Env.apiUrl,
      );
    } else if ((index == 2 && hasWallet) || (index == 1 && !hasWallet)) {
      // Dashcam tab
      return _LazyDashcamScreenWrapper(key: const ValueKey('dashcam'));
    } else if ((index == 3 && hasWallet) || (index == 2 && !hasWallet)) {
      // Help tab
      return _LazyHelpScreenWrapper(key: const ValueKey('help'));
    }

    // Fallback to Map tab
    return _LazyMapScreenWrapper(key: const ValueKey('map'));
  }
}

/// Lazy wrapper for Map Screen - initializes MapBinding when accessed
class _LazyMapScreenWrapper extends StatefulWidget {
  const _LazyMapScreenWrapper({super.key});

  @override
  State<_LazyMapScreenWrapper> createState() => _LazyMapScreenWrapperState();
}

class _LazyMapScreenWrapperState extends State<_LazyMapScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize MapBinding if not already registered
    if (!Get.isRegistered<MapController>()) {
      MapBinding().dependencies();
    } else if (!Get.isRegistered<LiveTrackingPipCoordinator>()) {
      Get.put(LiveTrackingPipCoordinator());
    }
  }

  @override
  void dispose() {
    // Cancel PiP OnLeave before tearing down map controllers.
    if (Get.isRegistered<LiveTrackingPipCoordinator>()) {
      Get.delete<LiveTrackingPipCoordinator>(force: true);
    }
    if (Get.isRegistered<MapController>()) {
      Get.delete<MapController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MapScreen();
  }
}

/// Lazy wrapper for Wallet Screen - initializes WalletBinding when accessed
class _LazyWalletScreenWrapper extends StatefulWidget {
  final List<Map<String, dynamic>> cars;
  final String baseUrl;

  const _LazyWalletScreenWrapper({
    super.key,
    required this.cars,
    required this.baseUrl,
  });

  @override
  State<_LazyWalletScreenWrapper> createState() =>
      _LazyWalletScreenWrapperState();
}

class _LazyWalletScreenWrapperState extends State<_LazyWalletScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize WalletBinding if not already registered
    if (!Get.isRegistered<WalletController>()) {
      WalletBinding(baseUrl: widget.baseUrl).dependencies();
    }
  }

  @override
  void dispose() {
    // Clean up controllers when leaving this tab
    if (Get.isRegistered<WalletController>()) {
      Get.delete<WalletController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WalletScreen(
      cars: widget.cars,
      baseUrl: widget.baseUrl,
    );
  }
}

/// Lazy wrapper for Help Screen - initializes HelpBinding when accessed
class _LazyHelpScreenWrapper extends StatefulWidget {
  const _LazyHelpScreenWrapper({super.key});

  @override
  State<_LazyHelpScreenWrapper> createState() => _LazyHelpScreenWrapperState();
}

class _LazyHelpScreenWrapperState extends State<_LazyHelpScreenWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize HelpBinding if not already registered
    if (!Get.isRegistered<HelpController>()) {
      HelpBinding().dependencies();
    }
  }

  @override
  void dispose() {
    // Clean up controllers when leaving this tab
    if (Get.isRegistered<HelpController>()) {
      Get.delete<HelpController>(force: true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const HelpScreen();
  }
}

/// Lazy wrapper for Dashcam Screen
class _LazyDashcamScreenWrapper extends StatefulWidget {
  const _LazyDashcamScreenWrapper({super.key});

  @override
  State<_LazyDashcamScreenWrapper> createState() =>
      _LazyDashcamScreenWrapperState();
}

class _LazyDashcamScreenWrapperState extends State<_LazyDashcamScreenWrapper> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
