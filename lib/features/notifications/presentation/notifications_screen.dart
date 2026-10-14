import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/features/notifications/provider/notification_controller.dart';
import 'package:taxi_driver_app/features/notifications/presentation/widgets/notification_app_bar.dart';
import 'package:taxi_driver_app/features/notifications/presentation/widgets/notification_loading_state.dart';
import 'package:taxi_driver_app/features/notifications/presentation/widgets/notification_error_state.dart';
import 'package:taxi_driver_app/features/notifications/presentation/widgets/notification_empty_state.dart';
import 'package:taxi_driver_app/features/notifications/presentation/widgets/notification_list.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<NotificationController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchNotifications(refresh: true);
      controller.fetchUnseenCount();
    });
  }

  @override
  void dispose() {
    // Mark all visible notifications as seen when leaving the screen
    controller.markVisibleNotificationsAsSeen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: NotificationAppBar(controller: controller),
      body: Obx(() => _buildBody()),
    );
  }

  /// Build the appropriate body widget based on state
  Widget _buildBody() {
    // Show loading indicator on initial load
    if (controller.isLoading.value && controller.notifications.isEmpty) {
      return const NotificationLoadingState();
    }

    // Show error state if there's an error and no cached data
    if (controller.error.value != null && controller.notifications.isEmpty) {
      return NotificationErrorState(
        errorMessage: controller.error.value!,
        onRetry: () => controller.fetchNotifications(refresh: true),
      );
    }

    // Show empty state if no notifications exist
    if (controller.notifications.isEmpty) {
      return const NotificationEmptyState();
    }

    // Show notifications list
    return NotificationList(controller: controller);
  }
}
