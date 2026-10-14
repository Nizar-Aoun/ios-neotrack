import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

class NotificationHelper {
  final AuthService _authService;

  NotificationHelper(this._authService);

  Future<void> sendSpeedAlertNotification({
    required double speed,
    required double limit,
    required String location,
  }) async {
    await _sendNotification(
      title: 'Speed Alert',
      body:
          'You are driving at ${speed.toStringAsFixed(1)} km/h in a ${limit.toStringAsFixed(1)} km/h zone near $location',
      type: 'speed_alert',
      data: {
        'speed': speed,
        'limit': limit,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Send a system notification
  Future<void> sendSystemNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await _sendNotification(
      title: title,
      body: body,
      type: 'system_notification',
      data: data,
    );
  }

  /// Send a maintenance reminder
  Future<void> sendMaintenanceReminder({
    required String maintenanceType,
    required String dueDate,
  }) async {
    await _sendNotification(
      title: 'Maintenance Reminder',
      body: 'Your $maintenanceType is due on $dueDate',
      type: 'maintenance',
      data: {
        'maintenance_type': maintenanceType,
        'due_date': dueDate,
      },
    );
  }

  /// Internal method to send notification
  Future<void> _sendNotification({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('No user ID');
      }

      final response = await http
          .post(
            Uri.parse('${Env.apiUrl}/notifications/send'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'user_id': userId,
              'title': title,
              'body': body,
              'type': type,
              'data': data ?? {},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Notification sent successfully
      } else {
        // Failed to send notification
      }
    } catch (e) {
      // Error sending notification
    }
  }
}
