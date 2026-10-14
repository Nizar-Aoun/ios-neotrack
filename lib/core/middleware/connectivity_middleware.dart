import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/controllers/connectivity_controller.dart';
import 'package:taxi_driver_app/router.dart';

/// Middleware to handle navigation to offline screen when connection is lost
class ConnectivityMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final connectivityController = Get.find<ConnectivityController>();
    
    // If user is not connected and not already on offline screen, redirect
    if (!connectivityController.isConnected.value && route != Routes.offline) {
      // Allow these routes even when offline
      final allowedOfflineRoutes = [
        Routes.offline,
        Routes.splash,
        Routes.login,
      ];
      
      if (!allowedOfflineRoutes.contains(route)) {
        return const RouteSettings(name: Routes.offline);
      }
    }
    
    return null;
  }
}
