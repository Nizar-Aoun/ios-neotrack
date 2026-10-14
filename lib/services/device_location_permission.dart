import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum DeviceLocationAccess {
  granted,
  denied,
  serviceDisabled,
}

/// Device GPS permission (not the backend `permissions.gps` flag).
class DeviceLocationPermission {
  DeviceLocationPermission._();

  static Future<DeviceLocationAccess> ensureAccess() async {
    if (kIsWeb) {
      debugPrint('[location] web — skip native permission check');
      return DeviceLocationAccess.granted;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('[location] serviceEnabled=$serviceEnabled');
    if (!serviceEnabled) {
      return DeviceLocationAccess.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    debugPrint('[location] checkPermission=$permission');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      debugPrint('[location] requestPermission=$permission');
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return DeviceLocationAccess.granted;
    }

    debugPrint('[location] treated as denied ($permission)');
    return DeviceLocationAccess.denied;
  }

  static Future<bool> isGranted() async {
    if (kIsWeb) return true;
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<void> openSettings({required bool serviceDisabled}) {
    if (serviceDisabled) {
      return Geolocator.openLocationSettings();
    }
    return Geolocator.openAppSettings();
  }
}
