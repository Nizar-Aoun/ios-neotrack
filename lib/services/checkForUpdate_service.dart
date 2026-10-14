import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:in_app_update/in_app_update.dart';
import 'package:taxi_driver_app/config/env.dart';

enum InAppUpdateOutcome {
  /// Update downloaded and installed (or Play UI took over).
  success,

  /// No Play in-app update available (debug build, iOS, etc.).
  unavailable,

  /// User cancelled the Play update flow.
  userCanceled,

  /// Check/download failed.
  failed,
}

class CheckForUpdateService {
  /// Returns `true` when the installed app version is up to date.
  Future<bool> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = '${packageInfo.version}+${packageInfo.buildNumber}';
    final url = Env.appVersionCheckEndpoint(version);

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isUpToDate'] == true;
      }
    } catch (_) {}
    // Fail open: do not block the app when the version API is unreachable.
    return true;
  }

  bool get _supportsInAppUpdate =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Downloads and installs the update via Google Play In-App Updates.
  /// Prefer immediate (blocking) update; fall back to flexible if needed.
  Future<InAppUpdateOutcome> performAutomaticUpdate() async {
    if (!_supportsInAppUpdate) {
      return InAppUpdateOutcome.unavailable;
    }

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return InAppUpdateOutcome.unavailable;
      }

      if (info.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        return _mapResult(result);
      }

      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
          return InAppUpdateOutcome.success;
        }
        return _mapResult(result);
      }

      return InAppUpdateOutcome.unavailable;
    } catch (_) {
      return InAppUpdateOutcome.failed;
    }
  }

  InAppUpdateOutcome _mapResult(AppUpdateResult result) {
    switch (result) {
      case AppUpdateResult.success:
        return InAppUpdateOutcome.success;
      case AppUpdateResult.userDeniedUpdate:
        return InAppUpdateOutcome.userCanceled;
      case AppUpdateResult.inAppUpdateFailed:
        return InAppUpdateOutcome.failed;
    }
  }
}
