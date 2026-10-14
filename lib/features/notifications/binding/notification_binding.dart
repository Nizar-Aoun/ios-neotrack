import 'package:get/get.dart';
import 'package:taxi_driver_app/features/notifications/provider/notification_controller.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/notification_service.dart';

/// Notification Binding - Dependency injection for notifications feature
class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    // Get existing services
    final authService = Get.find<AuthService>();
    final notificationService = Get.find<NotificationService>();

    // Register the NotificationController
    Get.lazyPut<NotificationController>(() {
      final controller = NotificationController();
      controller.init(notificationService, authService);
      // onInit will handle loading notifications
      return controller;
    });
  }
}
