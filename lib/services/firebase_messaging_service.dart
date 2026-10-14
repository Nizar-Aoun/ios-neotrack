import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/features/notifications/presentation/notifications_screen.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/web_notification_helper.dart';

class FirebaseMessagingService {
  final AuthService _authService;
  final ApiClient _api;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _deviceTypeKey = 'device_type';

  // VAPID key for web push notifications
  static const String _webVapidKey =
      'BOlkAa1zLhg0Iqe7R3HxYzDyU-3PMJJ0kJx-RvUZA0tGb9ZShcUu4gJRvLAnYCDEf94pb7lnHOF49npe7aSvo2I';

  // Global navigator key reference
  static GlobalKey<NavigatorState>? _navigatorKey;

  FirebaseMessagingService(this._authService, {ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  // Set the navigator key
  static void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  Future<void> initialize() async {
    try {
      // Web-specific initialization
      if (kIsWeb) {
        await _initializeWebNotifications();
        return;
      }

      // Request notification permissions for Android
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }

        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Request permission for iOS
      if (Platform.isIOS) {
        NotificationSettings settings =
            await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          carPlay: false,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          // User granted permission
        } else if (settings.authorizationStatus ==
            AuthorizationStatus.provisional) {
          // User granted provisional permission
        } else {
          // User declined or has not accepted permission
        }
      }

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Get FCM token
      String? token = await ensureCurrentFcmToken();
      if (token != null) {
        await _registerFcmToken(token);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await _saveFcmToken(newToken);
        await _registerFcmToken(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Handle initial message if app was terminated
      RemoteMessage? initialMessage =
          await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      // Firebase messaging initialization error
    }
  }

  /// Initialize Firebase Cloud Messaging for web
  Future<void> _initializeWebNotifications() async {
    try {
      // Request notification permission for web
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token with VAPID key for web
        String? token = await _firebaseMessaging.getToken(
          vapidKey: _webVapidKey,
        );
        if (token != null) {
          await _saveFcmToken(token);
          await _registerFcmToken(token);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) async {
          await _saveFcmToken(newToken);
          await _registerFcmToken(newToken);
        });

        // Handle foreground messages on web
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleWebForegroundMessage(message);
        });

        // Handle when notification is clicked
        FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

        // Handle initial message if app was opened from notification
        RemoteMessage? initialMessage =
            await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleMessageOpenedApp(initialMessage);
        }
      } else {
      }
    } catch (e) {
    }
  }

  /// Handle foreground messages on web using browser Notification API
  void _handleWebForegroundMessage(RemoteMessage message) {
    try {
      // Show notification using browser Notification API
      if (message.notification != null) {
        WebNotificationHelper.showNotification(
          title: message.notification!.title ?? 'NeoTrack',
          body: message.notification!.body ?? 'You have a new notification',
          icon: '/icons/Icon-192.png',
          tag: message.data['type'] ?? 'notification',
          data: message.data,
        );
      }
    } catch (e) {
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final hasNotificationPayload = message.notification != null;
    final hasDataPayload = message.data.isNotEmpty;
    if (hasNotificationPayload || hasDataPayload) {
      await _showLocalNotification(message);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      final notificationId = message.hashCode;

      final title = message.notification?.title ??
          message.data['title']?.toString() ??
          message.data['notification_title']?.toString() ??
          'Notification';

      final body = message.notification?.body ??
          message.data['body']?.toString() ??
          message.data['notification_body']?.toString() ??
          'You have a new notification';

      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: json.encode(message.data),
      );
    } catch (e) {
      // Error showing local notification
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle navigation based on message data
    _navigateToNotificationScreen();
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to notification screen regardless of notification type
    _navigateToNotificationScreen();
  }

  void _navigateToNotificationScreen() {
    try {
      final navigatorKey = _navigatorKey;
      final currentState = navigatorKey?.currentState;
      if (navigatorKey != null && currentState != null) {
        currentState.push(
          MaterialPageRoute(
            builder: (context) => const NotificationsScreen(),
          ),
        );
      } else {
        // Navigator key or current state is null, cannot navigate
      }
    } catch (e) {
      // Error navigating to notification screen
    }
  }

  Future<void> _saveFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);

    // Determine device type
    String deviceType;
    if (kIsWeb) {
      deviceType = 'web';
    } else if (Platform.isIOS) {
      deviceType = 'ios';
    } else {
      deviceType = 'android';
    }

    await prefs.setString(_deviceTypeKey, deviceType);
  }

  Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  Future<String?> ensureCurrentFcmToken() async {
    final cachedToken = await getFcmToken();
    if (cachedToken != null && cachedToken.isNotEmpty) {
      return cachedToken;
    }

    final token = kIsWeb
        ? await _firebaseMessaging.getToken(vapidKey: _webVapidKey)
        : await _firebaseMessaging.getToken();

    if (token != null && token.isNotEmpty) {
      await _saveFcmToken(token);
    }

    return token;
  }

  Future<void> syncFcmTokenWithBackend() async {
    final token = await ensureCurrentFcmToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _registerFcmToken(token);
  }

  Future<void> _registerFcmToken(String token) async {
    try {
      final authToken = await _authService.getToken();
      if (authToken == null) {
        return;
      }

      final userId = await _authService.getUserId();
      if (userId == null) {
        return;
      }

      // Determine device type
      String deviceType;
      if (kIsWeb) {
        deviceType = 'web';
      } else if (Platform.isIOS) {
        deviceType = 'ios';
      } else {
        deviceType = 'android';
      }

      final response = await _api
          .post(
            Uri.parse('${Env.apiUrl}/users/fcm-token'),
            body: json.encode({
              'token': token,
              'device': deviceType,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // FCM token registered successfully
      } else {
        // Failed to register FCM token
      }
    } catch (e) {
      // Error registering FCM token
    }
  }

  Future<void> unregisterFcmToken() async {
    try {
      final token = await getFcmToken();
      if (token == null) {
        return;
      }

      final authToken = await _authService.getToken();
      if (authToken == null) {
        return;
      }

      final response = await _api
          .delete(
            Uri.parse('${Env.apiUrl}/users/fcm-token'),
            body: json.encode({
              'token': token,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Clear local token
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_fcmTokenKey);
        await prefs.remove(_deviceTypeKey);
      } else {
        // Failed to unregister FCM token
      }
    } catch (e) {
      // Error unregistering FCM token
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
    } catch (e) {
      // Error subscribing to topic
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
    } catch (e) {
      // Error unsubscribing from topic
    }
  }

  // Test method to manually trigger a local notification
  Future<void> showTestNotification() async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        enableVibration: true,
        playSound: true,
      );

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotifications.show(
        999,
        'Test Notification',
        'This is a test notification from the app',
        platformChannelSpecifics,
        payload: json.encode({'type': 'test', 'manual': true}),
      );
    } catch (e) {
      // Error showing test notification
    }
  }

  // Test method to navigate to notification screen
  void testNavigation() {
    _navigateToNotificationScreen();
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final localNotifications = FlutterLocalNotificationsPlugin();

  const androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInitSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidInitSettings,
    iOS: iosInitSettings,
  );

  await localNotifications.initialize(initSettings);

  if (!kIsWeb && Platform.isAndroid) {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  final title = message.notification?.title ??
      message.data['title']?.toString() ??
      message.data['notification_title']?.toString();
  final body = message.notification?.body ??
      message.data['body']?.toString() ??
      message.data['notification_body']?.toString();

  if (title == null && body == null) {
    return;
  }

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(android: androidDetails);

  await localNotifications.show(
    message.hashCode,
    title ?? 'Notification',
    body ?? 'You have a new notification',
    notificationDetails,
    payload: json.encode(message.data),
  );
}
