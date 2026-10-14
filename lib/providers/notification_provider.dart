import 'package:flutter/material.dart';
import 'package:taxi_driver_app/models/notification.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/notification_service.dart';
import 'dart:async';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _notificationService;
  final AuthService _authService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  String? _error;
  int _unseenCount = 0;
  Timer? _refreshTimer;

  NotificationProvider(this._notificationService, this._authService) {
    fetchUnseenCount();
    _startAutoRefresh();
  }

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  bool get hasMoreData => _hasMoreData;
  String? get error => _error;
  int get unseenCount => _unseenCount;

  int get unreadCount =>
      _notifications.where((notification) => !notification.seen).length;

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      await fetchUnseenCount();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchUnseenCount() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        _unseenCount = 0;
        notifyListeners();
        return;
      }
      final count = await _notificationService.getUnseenCount(userId);
      _unseenCount = count;
      notifyListeners();
    } catch (e) {
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      if (refresh) {
        _currentPage = 1;
        _notifications.clear();
        _hasMoreData = true;
      }

      final newNotifications = await _notificationService.getNotifications(
        userId: userId,
        page: _currentPage,
        limit: 10,
      );

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      // Check if we have more data
      _hasMoreData = newNotifications.length == 10;
      if (_hasMoreData) {
        _currentPage++;
      }

      // Fetch unseen count after loading notifications
      await fetchUnseenCount();

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreNotifications() async {
    if (_isLoading || !_hasMoreData) return;
    await loadNotifications();
  }

  Future<void> refreshNotifications() async {
    await loadNotifications(refresh: true);
  }

  Future<void> markNotificationAsSeen(String notificationId) async {
    try {
      await _notificationService.markNotificationAsSeen(notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        // Create a new notification with seen = true
        final notification = _notifications[index];
        final updatedNotification = NotificationModel(
          id: notification.id,
          fr: notification.fr,
          ar: notification.ar,
          type: notification.type,
          userId: notification.userId,
          carId: notification.carId,
          seen: true,
          createdAt: notification.createdAt,
          updatedAt: notification.updatedAt,
        );

        _notifications[index] = updatedNotification;
        notifyListeners();
      }
      await fetchUnseenCount();
    } catch (e) {
    }
  }

  Future<void> markAllNotificationsAsSeen() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;
      await _notificationService.markAllNotificationsAsSeen(userId);
      // Update local state
      _notifications = _notifications.map((notification) {
        return NotificationModel(
          id: notification.id,
          fr: notification.fr,
          ar: notification.ar,
          type: notification.type,
          userId: notification.userId,
          carId: notification.carId,
          seen: true,
          createdAt: notification.createdAt,
          updatedAt: notification.updatedAt,
        );
      }).toList();
      notifyListeners();
      await fetchUnseenCount();
    } catch (e) {
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    _currentPage = 1;
    _hasMoreData = true;
    _error = null;
    notifyListeners();
  }
}
