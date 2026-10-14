import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/services/connectivity_service.dart';

class ConnectivityUtils {
  /// Check if the device has internet connectivity
  static Future<bool> isConnected(BuildContext context) async {
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);
    return await connectivityService.checkConnectivity();
  }

  /// Show a snackbar when there's no internet connection
  static void showOfflineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Image.asset(
              'assets/images/icons8-wi-fi-off-94.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text('No internet connection'),
          ],
        ),
        backgroundColor: AppColors.errorColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Execute a function only if connected, otherwise show offline message
  static Future<T?> executeIfConnected<T>(
    BuildContext context,
    Future<T> Function() function, {
    bool showOfflineMessage = true,
  }) async {
    if (await isConnected(context)) {
      try {
        return await function();
      } catch (e) {
        if (showOfflineMessage) {
          showOfflineSnackBar(context);
        }
        rethrow;
      }
    } else {
      if (showOfflineMessage) {
        showOfflineSnackBar(context);
      }
      return null;
    }
  }

  /// Get the current connectivity status
  static bool getConnectionStatus(BuildContext context) {
    final connectivityService =
        Provider.of<ConnectivityService>(context, listen: false);
    return connectivityService.isConnected;
  }
}
