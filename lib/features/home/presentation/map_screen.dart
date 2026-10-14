import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/features/home/application/live_tracking_pip_coordinator.dart';
import 'package:taxi_driver_app/features/home/controller/map_controller.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';
import 'package:taxi_driver_app/features/home/controller/live_tracking_controller.dart';
import 'package:taxi_driver_app/features/home/controller/history_tracking_controller.dart';
import 'package:taxi_driver_app/features/home/presentation/widgets/live_tracking_tab.dart';
import 'package:taxi_driver_app/features/home/presentation/widgets/history_tracking_tab.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mapController = Get.find<MapController>();
    final homeController = Get.find<HomeController>();
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 650;

    return Obx(() {
      // Show loading overlay with smooth fade
      if (mapController.isLoading.value) {
        return Container(
          color: AppColors.backgroundColor,
          child: const Center(
            child: LoadingGif(
              width: 60,
              height: 60,
            ),
          ),
        );
      }

      // Show error overlay
      if (mapController.hasError.value) {
        return _buildErrorOverlay(context, l10n, mapController);
      }
      // Show no cars overlay
      if (mapController.noCarsAvailable.value) {
        return _buildNoCarsOverlay(context, l10n, mapController);
      }

      // Main content - tabs with smooth animated transitions
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: RepaintBoundary(
          key: ValueKey('tab_${homeController.tabIndex.value}'),
          child: homeController.tabIndex.value == 0
              ? _LazyLiveTrackingTabWrapper(
                  isSmallScreen: isSmallScreen,
                )
              : _LazyHistoryTrackingTabWrapper(
                  key: ValueKey('history_${mapController.historyTabKey.value}'),
                  isSmallScreen: isSmallScreen,
                ),
        ),
      );
    });
  }

  Widget _buildErrorOverlay(
      BuildContext context, AppLocalizations? l10n, MapController controller) {
    return Container(
      color: AppColors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.white,
                ),
                const SizedBox(height: 16),
                Obx(() => Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    )),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => controller.refreshVehicles(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoCarsOverlay(
      BuildContext context, AppLocalizations? l10n, MapController controller) {
    return Container(
      color: AppColors.black.withOpacity(0.5),
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/icons8-taxi-94.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n?.translate('noVehiclesAvailable') ??
                      'No vehicles available',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n?.translate('noVehiclesAvailableMessage') ??
                      'There are currently no vehicles assigned to your account. Please contact support for assistance.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => controller.refreshVehicles(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Persistent wrapper for Live Tracking Tab
/// Keeps LiveTrackingController alive across tab switches
class _LazyLiveTrackingTabWrapper extends StatefulWidget {
  final bool isSmallScreen;

  const _LazyLiveTrackingTabWrapper({
    required this.isSmallScreen,
  });

  @override
  State<_LazyLiveTrackingTabWrapper> createState() =>
      _LazyLiveTrackingTabWrapperState();
}

class _LazyLiveTrackingTabWrapperState
    extends State<_LazyLiveTrackingTabWrapper> {
  bool _initialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _setLiveTrackingVisible(true);
    _initializeController();
  }

  @override
  void dispose() {
    // Leaving Live (e.g. History) must cancel PiP arming immediately.
    _setLiveTrackingVisible(false);
    // ✅ DO NOT DELETE the controller - keep it alive for instant return
    // WebSocket stays connected in the background
    super.dispose();
  }

  void _setLiveTrackingVisible(bool visible) {
    if (!Get.isRegistered<LiveTrackingPipCoordinator>()) return;
    Get.find<LiveTrackingPipCoordinator>().setLiveTrackingVisible(visible);
  }

  Future<void> _initializeController() async {
    if (!_initialized && !_isInitializing) {
      _isInitializing = true;

      // Only create controller if it doesn't exist
      if (!Get.isRegistered<LiveTrackingController>()) {
        // Initialize controller asynchronously
        await Future.microtask(() {
          Get.put<LiveTrackingController>(LiveTrackingController());
        });
      } else {
        final controller = Get.find<LiveTrackingController>();

        // ✅ Auto-reconnect if connection was lost while in history tab
        if (!controller.isLoading.value && controller.error.value != null) {
          await controller.reconnectAfterTabSwitch();
        }

        // ✅ Auto-center map on car location on initial load or return
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (controller.carPosition.value != null) {
            controller.centerOnCarInitial();
          }
        });
      }

      if (mounted) {
        setState(() {
          _initialized = true;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Show content immediately - no loading screen
    if (!_initialized || !Get.isRegistered<LiveTrackingController>()) {
      return Container(
        color: AppColors.backgroundColor,
        child: const Center(
          child: SizedBox.shrink(), // Instant appearance
        ),
      );
    }

    return LiveTrackingTab(
      isSmallScreen: widget.isSmallScreen,
    );
  }
}

/// Lazy wrapper for History Tracking Tab
/// Initializes HistoryTrackingController only when this tab is first accessed
class _LazyHistoryTrackingTabWrapper extends StatefulWidget {
  final bool isSmallScreen;

  const _LazyHistoryTrackingTabWrapper({
    super.key,
    required this.isSmallScreen,
  });

  @override
  State<_LazyHistoryTrackingTabWrapper> createState() =>
      _LazyHistoryTrackingTabWrapperState();
}

class _LazyHistoryTrackingTabWrapperState
    extends State<_LazyHistoryTrackingTabWrapper> {
  bool _initialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void dispose() {
    // Completely delete the controller when this tab is disposed
    if (Get.isRegistered<HistoryTrackingController>()) {
      Get.delete<HistoryTrackingController>(force: true);
    }
    super.dispose();
  }

  Future<void> _initializeController() async {
    if (!_initialized && !_isInitializing) {
      _isInitializing = true;

      // Always create a fresh controller
      if (Get.isRegistered<HistoryTrackingController>()) {
        // Delete existing instance first
        Get.delete<HistoryTrackingController>(force: true);
      }

      // Initialize controller asynchronously
      await Future.microtask(() {
        Get.put<HistoryTrackingController>(HistoryTrackingController());
      });

      if (mounted) {
        setState(() {
          _initialized = true;
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show placeholder while initializing to prevent grey loading box
    if (!_initialized || !Get.isRegistered<HistoryTrackingController>()) {
      return Container(
        color: AppColors.backgroundColor,
        child: const Center(
          child: SizedBox.shrink(), // No loading indicator - instant appearance
        ),
      );
    }

    return HistoryTrackingTab(
      isSmallScreen: widget.isSmallScreen,
    );
  }
}
