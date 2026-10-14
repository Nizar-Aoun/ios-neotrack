import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/auth/token_store.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/features/auth/controller/auth_controller_getx.dart';
import 'package:taxi_driver_app/router.dart';

/// Coordinates token refresh with single-flight locking and session expiry.
class SessionManager {
  SessionManager({
    required TokenStore tokenStore,
    http.Client? client,
    void Function()? onSessionExpired,
  })  : _tokenStore = tokenStore,
        _client = client ?? http.Client(),
        _onSessionExpired = onSessionExpired;

  final TokenStore _tokenStore;
  final http.Client _client;
  void Function()? _onSessionExpired;

  Completer<bool>? _refreshCompleter;

  TokenStore get tokenStore => _tokenStore;

  void setOnSessionExpired(void Function()? callback) {
    _onSessionExpired = callback;
  }

  Future<String?> getAccessToken() => _tokenStore.getAccessToken();

  Future<void> saveLoginSession({
    required String accessToken,
    String? refreshToken,
    required int expiresInSeconds,
    required String userId,
  }) {
    return _tokenStore.saveTokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresInSeconds: expiresInSeconds,
      userId: userId,
    );
  }

  /// Single-flight refresh. Returns true if a usable access token is available.
  Future<bool> refreshSession() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refreshToken = await _tokenStore.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _expireSession();
        completer.complete(false);
        return false;
      }

      final response = await _client
          .post(
            Uri.parse(Env.refreshEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final accessToken = (data['access_token'] ?? data['token']) as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        final expiresIn = data['expires_in'];

        if (accessToken == null ||
            accessToken.isEmpty ||
            newRefreshToken == null ||
            newRefreshToken.isEmpty) {
          await _expireSession();
          completer.complete(false);
          return false;
        }

        final expiresInSeconds =
            expiresIn is int ? expiresIn : int.tryParse('$expiresIn') ?? 900;

        await _tokenStore.saveTokenPair(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
          expiresInSeconds: expiresInSeconds,
        );

        completer.complete(true);
        return true;
      }

      if (response.statusCode == 429) {
        // Rate limited — do not clear session; caller should back off.
        completer.complete(false);
        return false;
      }

      // 401 and other refresh failures clear the session.
      await _expireSession();
      completer.complete(false);
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Session refresh failed');
      }
      await _expireSession();
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> logoutRemote() async {
    final refreshToken = await _tokenStore.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return;

    try {
      await _client
          .post(
            Uri.parse(Env.logoutEndpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({'refresh_token': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Local logout must proceed even if remote logout fails.
    }
  }

  Future<void> clearSession({bool navigateToLogin = false}) async {
    await _tokenStore.clear();
    if (navigateToLogin) {
      _notifySessionExpired();
    }
  }

  Future<void> _expireSession() async {
    await _tokenStore.clear();
    _notifySessionExpired();
  }

  void _notifySessionExpired() {
    final callback = _onSessionExpired;
    if (callback != null) {
      callback();
      return;
    }
    _defaultNavigateToLogin();
  }

  void _defaultNavigateToLogin() {
    try {
      if (Get.isRegistered<AuthControllerGetX>()) {
        Get.find<AuthControllerGetX>().forceUnauthenticated();
      }
    } catch (_) {}

    try {
      if (Get.isRegistered<UserController>()) {
        Get.find<UserController>().clearUser();
      }
    } catch (_) {}

    try {
      if (Get.currentRoute != Routes.login) {
        Get.offAllNamed(Routes.login);
      }
    } catch (_) {
      // Navigator may not be ready during early startup.
    }
  }
}
