import 'package:taxi_driver_app/models/notification.dart';
import 'package:taxi_driver_app/services/notification_service.dart';

/// Notifications Repository - Data layer for notifications
///
/// This repository wraps the NotificationService for the feature-based architecture.
/// It provides a clean interface for the controller to interact with notification data.
class NotificationsRepository {
  final NotificationService _notificationService;

  NotificationsRepository(this._notificationService);

  /// Fetch notifications for a user
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    return await _notificationService.getNotifications(
      userId: userId,
      page: page,
      limit: limit,
    );
  }

  /// Mark a notification as seen
  Future<void> markNotificationAsSeen(String notificationId) async {
    await _notificationService.markNotificationAsSeen(notificationId);
  }

  /// Mark all notifications as seen for a user
  Future<void> markAllNotificationsAsSeen(String userId) async {
    await _notificationService.markAllNotificationsAsSeen(userId);
  }

  /// Get the count of unseen notifications
  Future<int> getUnseenCount(String userId) async {
    return await _notificationService.getUnseenCount(userId);
  }
}
