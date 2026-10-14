import 'package:taxi_driver_app/models/user.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PermissionService {
  static UserPermissions? _getUserPermissions(BuildContext context) {
    try {
      final userController = Get.find<UserController>();

      final permissions = userController.permissions;
      return permissions;
    } catch (e) {
      return null;
    }
  }

  /// Check if user has GPS permission
  static bool hasGpsPermission(BuildContext context) {
    final permissions = _getUserPermissions(context);
    return permissions?.gps ?? false;
  }

  /// Check if user has wallet permission
  static bool hasWalletPermission(BuildContext context) {
    final permissions = _getUserPermissions(context);
    return permissions?.wallet ?? false;
  }

  /// Check if user has booking permission
  static bool hasBookingPermission(BuildContext context) {
    final permissions = _getUserPermissions(context);
    return permissions?.booking ?? false;
  }

  /// Check if user has camera permission
  static bool hasCameraPermission(BuildContext context) {
    final permissions = _getUserPermissions(context);
    return permissions?.cam ?? false;
  }

  /// Check if user has ads permission
  static bool hasAdsPermission(BuildContext context) {
    final permissions = _getUserPermissions(context);
    return permissions?.ads ?? false;
  }

  /// Get all user permissions
  static UserPermissions? getAllPermissions(BuildContext context) {
    return _getUserPermissions(context);
  }
}
