import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/models/notification.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

class NotificationService {
  final AuthService _authService;
  final ApiClient _api;

  NotificationService(this._authService, {ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${Env.apiUrl}/notifications').replace(
        queryParameters: {
          'user_id': userId,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _api.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Notification request timed out');
        },
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> &&
            responseData.containsKey('notifications') &&
            responseData['notifications'] is List) {
          final List<dynamic> notificationsJson = responseData['notifications'];
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else if (responseData is List) {
          // Handle case where response is directly a list
          return responseData
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to fetch notifications';

        switch (response.statusCode) {
          case 401:
            throw Exception('Unauthorized');
          case 403:
            throw Exception('Access denied');
          case 404:
            throw Exception('Notifications not found');
          case 500:
            throw Exception('Server error. Please try again later');
          default:
            throw Exception(errorMessage);
        }
      }
    } on TimeoutException {
      throw Exception(
          'Connection timed out. Please check your internet connection');
    } on SocketException {
      throw Exception('No internet connection');
    } on FormatException {
      throw Exception('Invalid response from server');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationAsSeen(String notificationId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${Env.apiUrl}/notifications/$notificationId/seen');

      final response = await _api.patch(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Mark as seen request timed out');
        },
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to mark notification as seen';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      // Mark as seen timeout - continuing
    } catch (e) {
      // Don't rethrow for this operation as it's not critical
    }
  }

  Future<void> markAllNotificationsAsSeen(String userId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final uri = Uri.parse('${Env.apiUrl}/notifications/mark-all-seen')
          .replace(queryParameters: {'user_id': userId});

      final response = await _api.patch(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Mark all as seen request timed out');
        },
      );

      if (response.statusCode != 200) {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Failed to mark all notifications as seen';
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      // Mark all as seen timeout - continuing
    } catch (e) {
      // Don't rethrow for this operation as it's not critical
    }
  }

  Future<int> getUnseenCount(String userId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }
      final uri = Uri.parse('${Env.apiUrl}/notifications/unread-count')
          .replace(queryParameters: {'user_id': userId});
      final response = await _api.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () =>
            throw TimeoutException('Unseen count request timed out'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('unreadCount')) {
          return data['unreadCount'] as int;
        } else if (data is int) {
          return data;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch unseen count');
      }
    } catch (e) {
      return 0;
    }
  }
}
