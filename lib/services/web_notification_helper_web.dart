import 'dart:html' as html;

/// Show a notification on web platform
Future<void> showNotificationImpl({
  required String title,
  required String body,
  String? icon,
  String? badge,
  String? tag,
  Map<String, dynamic>? data,
}) async {
  try {
    // Check if Notification API is supported
    if (!html.Notification.supported) {
      return;
    }

    final permission = html.Notification.permission;
    if (permission == 'granted') {
      final notification = html.Notification(
        title,
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
        tag: tag ?? 'notification',
      );

      // Handle click
      notification.onClick.listen((event) {
        notification.close();
      });
    } else if (permission == 'default') {
      final result = await html.Notification.requestPermission();
      if (result == 'granted') {
        await showNotificationImpl(
          title: title,
          body: body,
          icon: icon,
          badge: badge,
          tag: tag,
          data: data,
        );
      }
    } else {
    }
  } catch (e) {
  }
}

/// Check if notifications are supported and permission status
String? getPermissionStatusImpl() {
  if (!html.Notification.supported) return 'not-supported';
  return html.Notification.permission;
}

/// Request notification permission
Future<String> requestPermissionImpl() async {
  if (!html.Notification.supported) return 'not-supported';

  try {
    final result = await html.Notification.requestPermission();
    return result;
  } catch (e) {
    return 'error';
  }
}
