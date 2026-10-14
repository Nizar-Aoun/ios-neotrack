import 'dart:async';
import 'dart:io' show Platform;

import 'package:floating/floating.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';
import 'package:taxi_driver_app/features/home/controller/live_tracking_controller.dart';
import 'package:taxi_driver_app/features/home/controller/map_controller.dart';

/// Arms Android OnLeave PiP only while the Live Tracking tab is visible.
///
/// No-op on iOS / web. Owns [Floating] arm/cancel and exposes [isInPip] for UI.
class LiveTrackingPipCoordinator extends GetxController {
  final Floating _floating = Floating();

  /// Wider map window (4:3). Height stays comfortable; Android controls exact pixels.
  static const Rational _pipAspectRatio = Rational(1, 1);

  final RxBool isPipSupported = false.obs;
  final RxBool isInPip = false.obs;
  final RxBool isArmed = false.obs;

  /// Set by [LiveTrackingTab] visibility — false on History / other tabs.
  final RxBool isLiveTrackingVisible = false.obs;

  StreamSubscription<PiPStatus>? _pipSub;
  Worker? _eligibilityWorker;
  Worker? _pipEnteredWorker;

  /// Bumps on every eligibility sync so a slow arm cannot override a later disarm.
  int _syncGeneration = 0;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    if (kIsWeb || !Platform.isAndroid) {
      isPipSupported.value = false;
      return;
    }

    try {
      isPipSupported.value = await _floating.isPipAvailable;
    } catch (e) {
      debugPrint('[LiveTrackingPip] isPipAvailable failed: $e');
      isPipSupported.value = false;
      return;
    }

    if (!isPipSupported.value) return;

    _pipSub = _floating.pipStatusStream.listen((status) {
      isInPip.value = status == PiPStatus.enabled;
      if (status == PiPStatus.automatic) {
        isArmed.value = true;
      } else if (status == PiPStatus.disabled ||
          status == PiPStatus.unavailable) {
        isArmed.value = false;
      }
    });

    final home = Get.find<HomeController>();
    final map = Get.find<MapController>();

    _eligibilityWorker = everAll(
      [
        home.selectedIndex,
        home.tabIndex,
        map.liveTrackingVehicle,
        isPipSupported,
        isLiveTrackingVisible,
      ],
      (_) => unawaited(_syncEligibility()),
    );

    _pipEnteredWorker = ever(isInPip, (bool inPip) {
      if (!inPip) return;
      // Refuse to drive camera if user left Live Tracking.
      if (!_isEligible) return;
      if (!Get.isRegistered<LiveTrackingController>()) return;
      Get.find<LiveTrackingController>().onEnteredPictureInPicture();
    });

    await _syncEligibility();
  }

  /// Called when Live Tracking tab is shown or hidden.
  void setLiveTrackingVisible(bool visible) {
    if (isLiveTrackingVisible.value == visible) return;
    isLiveTrackingVisible.value = visible;
    // Disarm immediately when leaving Live — do not wait on workers alone.
    if (!visible) {
      unawaited(_disarm());
    }
  }

  bool get _isEligible {
    if (kIsWeb || !Platform.isAndroid) return false;
    if (!isPipSupported.value) return false;
    if (!isLiveTrackingVisible.value) return false;
    if (!Get.isRegistered<HomeController>() ||
        !Get.isRegistered<MapController>()) {
      return false;
    }
    final home = Get.find<HomeController>();
    final map = Get.find<MapController>();
    // Map bottom-nav tab + Live inner tab + selected vehicle only.
    return home.selectedIndex.value == 0 &&
        home.tabIndex.value == 0 &&
        map.liveTrackingVehicle.value != null;
  }

  Future<void> _syncEligibility() async {
    final generation = ++_syncGeneration;
    if (_isEligible) {
      await _arm(generation);
    } else {
      await _disarm();
    }
  }

  Future<void> _arm(int generation) async {
    if (!_isEligible) return;
    if (isArmed.value || isInPip.value) return;
    try {
      final status = await _floating.enable(
        const OnLeavePiP(aspectRatio: _pipAspectRatio),
      );
      // A newer sync (e.g. user left Live) must win over this arm.
      if (generation != _syncGeneration || !_isEligible) {
        await _disarm();
        return;
      }
      isArmed.value = status != PiPStatus.unavailable;
      debugPrint('[LiveTrackingPip] armed status=$status');
    } catch (e) {
      debugPrint('[LiveTrackingPip] arm failed: $e');
      isArmed.value = false;
    }
  }

  Future<void> _disarm() async {
    try {
      await _floating.cancelOnLeavePiP();
    } catch (e) {
      debugPrint('[LiveTrackingPip] cancelOnLeavePiP failed: $e');
    }
    isArmed.value = false;
  }

  @override
  void onClose() {
    isLiveTrackingVisible.value = false;
    _eligibilityWorker?.dispose();
    _pipEnteredWorker?.dispose();
    _pipSub?.cancel();
    unawaited(_disarm());
    super.onClose();
  }
}
