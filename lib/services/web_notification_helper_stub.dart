/// Show a notification on web platform - stub implementation for non-web platforms
Future<void> showNotificationImpl({
  required String title,
  required String body,
  String? icon,
  String? badge,
  String? tag,
  Map<String, dynamic>? data,
}) async {
}

/// Check if notifications are supported and permission status - stub implementation
String? getPermissionStatusImpl() {
  return 'not-web';
}

/// Request notification permission - stub implementation
Future<String> requestPermissionImpl() async {
  return 'not-web';
}
