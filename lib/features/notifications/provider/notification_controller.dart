import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/models/notification.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

class NotificationController extends GetxController {
  // Reactive state
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxInt currentPage = 1.obs;
  final RxnString error = RxnString();
  final RxInt unseenCount = 0.obs;

  // Services
  late final NotificationService _notificationService;
  late final AuthService _authService;

  // State flags
  bool _isInitialized = false;
  bool _isRefreshingCount = false;
  int _retryCount = 0;
  static const int _maxAutoRetries = 3;
  StreamSubscription<RemoteMessage>? _fcmSubscription;
  final Set<String> _visibleNotifications = {};

  // Constants
  static const int _itemsPerPage = 10;
  static const Duration _autoRefreshInterval = Duration(seconds: 15);
  static const Duration _initDelay = Duration(milliseconds: 500);
  static const Duration _retryDelay = Duration(seconds: 2);

  // Computed property
  int get unreadCount =>
      notifications.where((notification) => !notification.seen).length;

  /// Initialize the controller with required services
  void init(NotificationService notificationService, AuthService authService) {
    _notificationService = notificationService;
    _authService = authService;
    _isInitialized = true;

    _initializeData();
  }

  @override
  void onInit() {
    super.onInit();
  }

  void _initializeData() {
    if (_isInitialized) {
      Future.delayed(_initDelay, () async {
        await _fetchWithAutoRetry();
        fetchUnseenCount();
        _startAutoRefresh();
        _listenToFirebaseMessages();
      });
    }
  }

  Future<void> _fetchWithAutoRetry() async {
    await fetchNotifications(refresh: true);

    if (error.value != null &&
        error.value!.contains('not authenticated') &&
        _retryCount < _maxAutoRetries) {
      _retryCount++;

      // Wait before retrying (exponential backoff)
      await Future.delayed(_retryDelay * _retryCount);

      // Retry if controller is still active
      if (!isClosed) {
        await _fetchWithAutoRetry();
      }
    } else if (error.value == null) {
      // Success - reset retry count
      _retryCount = 0;
    }
  }

  /// Auto-refresh unseen count periodically
  void _startAutoRefresh() {
    Future.delayed(_autoRefreshInterval, () {
      if (!isClosed) {
        fetchUnseenCount();
        _startAutoRefresh();
      }
    });
  }

  /// Listen to Firebase messages and refresh notifications
  void _listenToFirebaseMessages() {
    _fcmSubscription =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
      }
      // Refresh the notification list when a new notification arrives
      fetchNotifications(refresh: true);
    });
  }

  /// Fetch unseen notification count
  Future<void> fetchUnseenCount() async {
    // Prevent multiple simultaneous refresh calls
    if (_isRefreshingCount) return;

    try {
      _isRefreshingCount = true;
      final userId = await _authService.getUserId();

      if (userId == null) {
        unseenCount.value = 0;
        return;
      }

      final count = await _notificationService.getUnseenCount(userId);
      unseenCount.value = count;

      if (kDebugMode) {}
    } catch (e) {
      if (kDebugMode) {}
    } finally {
      _isRefreshingCount = false;
    }
  }

  /// Fetch notifications with pagination support
  Future<void> fetchNotifications({bool refresh = false}) async {
    // Reset pagination on refresh
    if (refresh) {
      currentPage.value = 1;
      notifications.clear();
      hasMoreData.value = true;
      // Reset retry count on manual refresh
      _retryCount = 0;
    }

    // Prevent duplicate loading
    if (isLoading.value || !hasMoreData.value) return;

    try {
      isLoading.value = true;
      error.value = null;

      final userId = await _authService.getUserId();
      if (userId == null) {
        // Set error so the error state with retry button is shown
        error.value = 'User not authenticated';

        return;
      }

      final newNotifications = await _notificationService.getNotifications(
        userId: userId,
        page: currentPage.value,
        limit: _itemsPerPage,
      );

      if (kDebugMode) {
      }

      // Update state based on results
      if (newNotifications.isEmpty) {
        hasMoreData.value = false;
      } else {
        notifications.addAll(newNotifications);
        currentPage.value++;
      }

      // Update unseen count after loading
      unawaited(fetchUnseenCount());
    } catch (e) {
      error.value = e.toString();
      if (kDebugMode) {
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark a single notification as seen
  Future<void> markAsSeen(String notificationId) async {
    try {
      // Optimistically update UI
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index == -1) return;

      final notification = notifications[index];
      if (notification.seen) return; // Already seen

      // Update locally first for instant feedback
      notifications[index] = _createSeenNotification(notification);
      notifications.refresh();

      // Update on server
      await _notificationService.markNotificationAsSeen(notificationId);

      // Update count
      unawaited(fetchUnseenCount());

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      // Could revert the optimistic update here if needed
    }
  }

  /// Mark all notifications as seen
  Future<void> markAllAsSeen() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      // Optimistically update UI
      notifications.value =
          notifications.map((n) => _createSeenNotification(n)).toList();
      unseenCount.value = 0;

      // Update on server
      await _notificationService.markAllNotificationsAsSeen(userId);

      if (kDebugMode) {
      }
    } catch (e) {
      if (kDebugMode) {
      }
      // Could revert the optimistic update here if needed
    }
  }

  /// Helper method to create a seen version of a notification
  NotificationModel _createSeenNotification(NotificationModel notification) {
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
  }

  /// Track notification as visible (but don't mark as seen yet)
  void onNotificationVisible(String notificationId) {
    _visibleNotifications.add(notificationId);
  }

  /// Remove notification from visible set when it's no longer visible
  void onNotificationHidden(String notificationId) {
    _visibleNotifications.remove(notificationId);
  }

  /// Mark all visible notifications as seen (call when leaving screen)
  Future<void> markVisibleNotificationsAsSeen() async {
    if (_visibleNotifications.isEmpty) return;

    final notificationsToMark = _visibleNotifications.toList();

    for (final notificationId in notificationsToMark) {
      final notification =
          notifications.firstWhereOrNull((n) => n.id == notificationId);
      if (notification != null && !notification.seen) {
        await markAsSeen(notificationId);
      }
    }

    _visibleNotifications.clear();
  }

  @override
  void onClose() {
    _fcmSubscription?.cancel();
    _visibleNotifications.clear();
    if (kDebugMode) {}
    super.onClose();
  }

  /// Fire and forget helper for non-blocking operations
  void unawaited(Future<void> future) {
    future.catchError((error) {
      if (kDebugMode) {}
    });
  }
}
