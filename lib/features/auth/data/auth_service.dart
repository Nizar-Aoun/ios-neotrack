import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';

import '../../../l10n/app_localizations.dart';

/// Remote auth service - handles all API calls for authentication
class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  ApiClient? get _api =>
      Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null;

  /// Login user with phone and password
  Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'phone': phone,
        'password': password,
      };

      print('========== LOGIN DEBUG START ==========');
      print('Login URL: ${Env.loginEndpoint}');
      print('Login request body: $requestBody');

      final response = await _client
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
          throw TimeoutException('Connection timed out');
        },
      );

      print('Login status code: ${response.statusCode}');
      print('Login raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('Login success parsed data: $data');
        print('========== LOGIN DEBUG END ==========');

        final accessToken = data['access_token'] ?? data['token'];
        if (accessToken == null) {
          throw Exception('No access token received from server');
        }

        if (data['id'] == null) {
          throw Exception('No user ID received from server');
        }

        return data;
      } else {
        final errorData = json.decode(response.body);
        print('Login error parsed data: $errorData');
        final errorMessage =
            errorData['error'] ?? errorData['message'] ?? 'Échec de Connexion';
        print('Login error message used in snackbar: $errorMessage');
        print('========== LOGIN DEBUG END ==========');
        throw Exception(errorMessage);
      }
    } on TimeoutException catch (e) {
      print('Login TimeoutException: $e');
      print('========== LOGIN DEBUG END ==========');
      throw Exception(
          'Connection timed out. Please check your internet connection');
    } on SocketException catch (e) {
      print('Login SocketException: $e');
      print('========== LOGIN DEBUG END ==========');
      throw Exception('No internet connection');
    } on http.ClientException catch (e) {
      print('Login ClientException: $e');
      print('========== LOGIN DEBUG END ==========');
      // Handle CORS and network errors (common on web)
      if (kIsWeb) {
        throw Exception(
            'Cannot connect to server. This may be due to CORS restrictions. '
            'Please ensure the backend server has proper CORS configuration for web access, '
            'or use the mobile app for full functionality.');
      }
      throw Exception('Network error: Unable to connect to server');
    } on FormatException catch (e) {
      print('Login FormatException: $e');
      print('========== LOGIN DEBUG END ==========');
      throw Exception('Invalid response from server');
    } catch (e) {
      print('Login unexpected error: $e');
      print('========== LOGIN DEBUG END ==========');
      rethrow;
    }
  }

  /// Logout user by revoking the refresh-token session.
  Future<void> logout({required String refreshToken}) async {
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
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user password
  Future<void> updatePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final body = json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      final api = _api;
      final response = api != null
          ? await api
              .patch(
                Uri.parse('${Env.apiUrl}/users/password'),
                body: body,
              )
              .timeout(const Duration(seconds: 30))
          : await _client
              .patch(
                Uri.parse('${Env.apiUrl}/users/password'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: body,
              )
              .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Password update failed';
        throw Exception(errorMessage);
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

  Map<String, dynamic> _buildForgotPasswordBody({
    String? phone,
    String? email,
    String? otp,
    String? resetToken,
    String? newPassword,
    String? confirmPassword,
  }) {
    final body = <String, dynamic>{};

    if (phone != null && phone.isNotEmpty) {
      body['phone'] = phone;
    }
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    if (otp != null && otp.isNotEmpty) {
      body['otp'] = otp;
    }
    if (resetToken != null && resetToken.isNotEmpty) {
      body['resetToken'] = resetToken;
    }
    if (newPassword != null) {
      body['newPassword'] = newPassword;
    }
    if (confirmPassword != null) {
      body['confirmPassword'] = confirmPassword;
    }

    if (body.isEmpty) {
      throw ArgumentError('Either phone or email must be provided');
    }

    return body;
  }

  /// Check whether a forgotten-password identifier has an email address
  Future<String?> checkPasswordResetIdentifier({
    required String phone,
  }) async {
    try {
      final response = await _client
          .post(
        Uri.parse(Env.forgotPasswordCheckIdentifierEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'phone': phone}),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final email = data['email'] as String?;
        return (email != null && email.isNotEmpty) ? email : null;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to check account details';
        throw Exception(errorMessage);
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

  /// Register FCM token for push notifications
  Future<void> registerFcmToken({
    required String authToken,
    required String fcmToken,
  }) async {
    try {
      final body = json.encode({'fcm_token': fcmToken});
      final api = _api;
      if (api != null) {
        await api
            .post(Uri.parse('${Env.apiUrl}/users/fcm-token'), body: body)
            .timeout(const Duration(seconds: 30));
      } else {
        await _client
            .post(
              Uri.parse('${Env.apiUrl}/users/fcm-token'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 30));
      }
    } catch (e) {
      // Don't throw - FCM token registration failure shouldn't block login
    }
  }

  /// Unregister FCM token
  Future<void> unregisterFcmToken({
    required String authToken,
    required String fcmToken,
  }) async {
    try {
      final body = json.encode({'fcm_token': fcmToken});
      final api = _api;
      if (api != null) {
        await api
            .delete(Uri.parse('${Env.apiUrl}/users/fcm-token'), body: body)
            .timeout(const Duration(seconds: 30));
      } else {
        await _client
            .delete(
              Uri.parse('${Env.apiUrl}/users/fcm-token'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
              body: body,
            )
            .timeout(const Duration(seconds: 30));
      }
    } catch (e) {
      // Don't throw - FCM token unregistration failure shouldn't block logout
    }
  }

  /// Fetch user data by ID and token
  Future<Map<String, dynamic>> getUserData({
    required String token,
    required String userId,
  }) async {
    try {
      final api = _api;
      final response = api != null
          ? await api
              .get(Uri.parse('${Env.apiUrl}/users/$userId'))
              .timeout(const Duration(seconds: 30))
          : await _client
              .get(
                Uri.parse('${Env.apiUrl}/users/$userId'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data.containsKey('user')) {
          return data['user'] as Map<String, dynamic>;
        }
        return data;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage =
            errorData['message'] ?? 'Failed to fetch user data';
        throw Exception(errorMessage);
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

  /// Request OTP for password reset
  Future<void> requestPasswordResetOtp({
    String? phone,
    String? email,
  }) async {
    try {
      final response = await _client
          .post(
        Uri.parse(Env.forgotPasswordRequestOtpEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(
          _buildForgotPasswordBody(phone: phone, email: email),
        ),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode == 200) {
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Failed to send OTP';
        throw Exception(errorMessage);
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

  /// Verify OTP for password reset
  Future<String> verifyPasswordResetOtp({
    String? phone,
    String? email,
    required String otp,
  }) async {
    try {
      final response = await _client
          .post(
        Uri.parse(Env.forgotPasswordVerifyOtpEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(
          _buildForgotPasswordBody(phone: phone, email: email, otp: otp),
        ),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Return reset token from server
        final resetToken = data['resetToken'] as String?;
        if (resetToken == null) {
          throw Exception('No reset token received from server');
        }
        return resetToken;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ??
            AppLocalizations.of(Get.context!).translate('invalidOtp') ??
            'Invalid OTP';
        throw Exception(errorMessage);
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

  /// Reset password using reset token
  Future<void> resetPassword({
    String? phone,
    String? email,
    required String resetToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await _client
          .post(
        Uri.parse(Env.forgotPasswordResetEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(
          _buildForgotPasswordBody(
            phone: phone,
            email: email,
            resetToken: resetToken,
            newPassword: newPassword,
            confirmPassword: confirmPassword,
          ),
        ),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode == 200) {
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ??
            AppLocalizations.of(Get.context!)
                .translate('failedToResetPassword') ??
            'Failed to reset password';
        throw Exception(errorMessage);
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

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}
