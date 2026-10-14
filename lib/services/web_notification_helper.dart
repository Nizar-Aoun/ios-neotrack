import 'web_notification_helper_stub.dart'
    if (dart.library.html) 'web_notification_helper_web.dart';

/// Helper class to show web notifications using the browser Notification API
class WebNotificationHelper {
  /// Show a notification on web platform
  static Future<void> showNotification({
    required String title,
    required String body,
    String? icon,
    String? badge,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    await showNotificationImpl(
      title: title,
      body: body,
      icon: icon,
      badge: badge,
      tag: tag,
      data: data,
    );
  }

  static String? getPermissionStatus() {
    return getPermissionStatusImpl();
  }

  static Future<String> requestPermission() async {
    return await requestPermissionImpl();
  }
}
