import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:taxi_driver_app/features/subscription/presentation/subscription_required_screen.dart';
import 'failure.dart';

/// Detects the "subscription not paid" response produced by the backend access
/// middleware and notifies the user.
///
/// The middleware guards car-related endpoints (start/stop/restart/status,
/// preferences, location, ...) and returns the following body when the account
/// has no active (paid) subscription:
///
/// ```json
/// { "error": "don't have access because not payé abonnement", "status": false }
/// ```
///
/// The HTTP status code can vary (401/402/403/...), so detection is based on
/// the response body shape rather than the status code.
class SubscriptionErrorHandler {
  SubscriptionErrorHandler._();

  /// Keyword present in the backend error message for the subscription case.
  static const String _abonnementKeyword = 'abonnement';

  /// Guards against pushing the gate screen multiple times when several
  /// guarded requests fail at once.
  static bool _isScreenOpen = false;

  /// Returns a [SubscriptionRequiredFailure] when [response] is the backend
  /// "subscription not paid" response, otherwise `null`.
  static SubscriptionRequiredFailure? checkResponse(http.Response response) {
    // A 2xx response is always a success and never a subscription error.
    if (response.statusCode >= 200 && response.statusCode < 300) return null;
    if (response.body.isEmpty) return null;

    try {
      final decoded = json.decode(response.body);
      if (decoded is! Map) return null;

      final status = decoded['status'];
      final error = decoded['error'];

      final isBlocked = status == false &&
          error is String &&
          error.toLowerCase().contains(_abonnementKeyword);

      if (!isBlocked) return null;

      if (kDebugMode) {
      }

      return SubscriptionRequiredFailure(message: error as String);
    } catch (_) {
      // Body was not JSON / not the expected shape: not a subscription error.
      return null;
    }
  }

  /// Opens the full-screen subscription gate (only one instance at a time).
  static void showGate() {
    if (_isScreenOpen) return;
    _isScreenOpen = true;
    Get.to<void>(
      () => const SubscriptionRequiredScreen(),
      fullscreenDialog: true,
      transition: Transition.downToUp,
    )?.whenComplete(() => _isScreenOpen = false);
  }

  /// Convenience guard used by services: if [response] is a subscription error,
  /// open the gate screen and throw a [SubscriptionRequiredFailure].
  static void enforce(http.Response response) {
    final failure = checkResponse(response);
    if (failure != null) {
      showGate();
      throw failure;
    }
  }
}
