import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/auth/session_manager.dart';
import 'package:taxi_driver_app/core/auth/token_store.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:taxi_driver_app/services/user_service.dart';
import 'package:taxi_driver_app/services/firebase_messaging_service.dart';

class AuthService {
  final TokenStore _tokenStore;
  final SessionManager _sessionManager;

  AuthService._(this._tokenStore, this._sessionManager);

  factory AuthService(
    SharedPreferences prefs, {
    TokenStore? tokenStore,
    SessionManager? sessionManager,
  }) {
    if (sessionManager != null) {
      return AuthService._(sessionManager.tokenStore, sessionManager);
    }
    if (Get.isRegistered<SessionManager>()) {
      final session = Get.find<SessionManager>();
      return AuthService._(session.tokenStore, session);
    }
    final store = tokenStore ?? TokenStore(prefs: prefs);
    return AuthService._(store, SessionManager(tokenStore: store));
  }

  Future<String?> getToken() => _tokenStore.getAccessToken();

  Future<String?> getUserId() => _tokenStore.getUserId();

  Future<void> clearAuthData() => _sessionManager.clearSession();

  Future<void> login(
      BuildContext context, String phone, String password) async {
    try {
      final Map<String, dynamic> requestBody = {
        'phone': phone,
        'password': password,
      };

      final response = await http
          .post(
        Uri.parse(Env.loginEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Login request timed out');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final accessToken =
            (data['access_token'] ?? data['token']) as String?;
        final refreshToken = data['refresh_token'] as String?;
        final userId = data['id'] as String?;
        final expiresInRaw = data['expires_in'];
        final expiresIn = expiresInRaw is int
            ? expiresInRaw
            : int.tryParse('$expiresInRaw') ?? 2592000;

        if (accessToken == null ||
            userId == null ||
            accessToken.isEmpty ||
            userId.isEmpty) {
          throw Exception('Invalid response: token or id not found');
        }

        await _sessionManager.saveLoginSession(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresInSeconds: expiresIn,
          userId: userId,
        );

        final userService = UserService(this);
        final user = await userService.getCurrentUser(accessToken, userId);

        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false).setUser(user);
        }

        await _registerFcmTokenForUser(accessToken);
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'Échec de Connexion';

        switch (response.statusCode) {
          case 401:
            throw Exception('Invalid credentials');
          case 403:
            throw Exception('Account is disabled');
          case 404:
            throw Exception('Account not found');
          case 429:
            throw Exception('Too many login attempts. Please try again later');
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

  Future<void> logout(BuildContext context) async {
    try {
      await _sessionManager.logoutRemote();
    } on TimeoutException {
      // Logout timeout - proceeding with local logout
    } catch (_) {
      // Logout error
    } finally {
      await _unregisterFcmToken();
      await _sessionManager.clearSession();
      if (context.mounted) {
        Provider.of<UserProvider>(context, listen: false).clearUser();
      }
    }
  }

  Future<void> updatePassword(
      BuildContext context, String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final apiClient =
          Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;
      final body = json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      final response = apiClient != null
          ? await apiClient
              .patch(
                Uri.parse('${Env.apiUrl}/users/password'),
                body: body,
              )
              .timeout(const Duration(seconds: 30))
          : await http
              .patch(
                Uri.parse('${Env.apiUrl}/users/password'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: body,
              )
              .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (context.mounted) {
          Provider.of<UserProvider>(context, listen: false)
              .updatePasswordStatus(true);
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        final String errorMessage =
            errorData['message'] ?? 'Password update failed';

        switch (response.statusCode) {
          case 400:
            throw Exception('Invalid password format');
          case 401:
            throw Exception('Current password is incorrect');
          case 403:
            throw Exception('Not authorized to update password');
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

  Future<void> _registerFcmTokenForUser(String authToken) async {
    try {
      final firebaseService = FirebaseMessagingService(this);
      final fcmToken = await firebaseService.ensureCurrentFcmToken();

      if (fcmToken != null) {
        final apiClient =
            Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;
        final body = json.encode({
          'token': fcmToken,
          'device': kIsWeb
              ? 'web'
              : Platform.isIOS
                  ? 'ios'
                  : 'android',
        });

        if (apiClient != null) {
          await apiClient
              .post(
                Uri.parse('${Env.apiUrl}/users/fcm-token'),
                body: body,
              )
              .timeout(const Duration(seconds: 10));
        } else {
          await http
              .post(
                Uri.parse('${Env.apiUrl}/users/fcm-token'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $authToken',
                },
                body: body,
              )
              .timeout(const Duration(seconds: 10));
        }
      }
    } catch (_) {
      // Error registering FCM token for user
    }
  }

  Future<void> _unregisterFcmToken() async {
    try {
      final firebaseService = FirebaseMessagingService(this);
      final fcmToken = await firebaseService.getFcmToken();

      if (fcmToken != null) {
        final token = await getToken();
        if (token != null) {
          final apiClient =
              Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;
          final body = json.encode({'token': fcmToken});

          if (apiClient != null) {
            await apiClient
                .delete(
                  Uri.parse('${Env.apiUrl}/users/fcm-token'),
                  body: body,
                )
                .timeout(const Duration(seconds: 10));
          } else {
            await http
                .delete(
                  Uri.parse('${Env.apiUrl}/users/fcm-token'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: body,
                )
                .timeout(const Duration(seconds: 10));
          }
        }
      }

      await firebaseService.unregisterFcmToken();
    } catch (_) {
      // Error unregistering FCM token
    }
  }
}
