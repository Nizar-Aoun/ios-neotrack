import 'dart:convert';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:taxi_driver_app/core/auth/session_manager.dart';
import 'package:taxi_driver_app/core/errors/app_failure.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/models/user.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'auth_service.dart';

class UserService {
  final AuthService _authService;
  final ApiClient _api;

  UserService(this._authService, {ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  Future<User> getCurrentUser(String token, String userId) async {
    try {
      final response = await _api.get(
        Uri.parse('${Env.userEndpoint}/$userId'),
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (!responseData.containsKey('user')) {
          throw Exception('Invalid response: user data not found');
        }
        final Map<String, dynamic> userData = responseData['user'];
        return User.fromJson(userData);
      } else {
        throw Exception('Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? fname,
    String? lname,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No token available');
    }

    final payload = <String, dynamic>{
      if (fname != null && fname.trim().isNotEmpty) 'fname': fname.trim(),
      if (lname != null && lname.trim().isNotEmpty) 'lname': lname.trim(),
    };

    if (payload.isEmpty) {
      throw Exception('At least one of fname or lname is required');
    }

    try {
      final response = await _api.patch(
        Uri.parse(Env.updateProfileEndpoint),
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        throw Exception('Invalid token');
      }

      throw Exception(
          'Failed to update profile: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  Future<Map<String, dynamic>> requestProfileChangeOtp({
    String? phone,
    String? email,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No token available');
    }

    final payload = <String, dynamic>{
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    };

    if (payload.length != 1) {
      throw Exception('Exactly one of phone or email is required');
    }

    try {
      final response = await _api.post(
        Uri.parse(Env.requestProfileChangeOtpEndpoint),
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        throw Exception('Invalid token');
      }

      throw Exception(
          'Failed to request profile change OTP: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Error requesting profile change OTP: $e');
    }
  }

  Future<Map<String, dynamic>> verifyProfileChangeOtp({
    String? phone,
    String? email,
    required String otp,
  }) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No token available');
    }

    final payload = <String, dynamic>{
      if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      'otp': otp.trim(),
    };

    if (!payload.containsKey('phone') && !payload.containsKey('email')) {
      throw Exception('Phone or email is required');
    }

    try {
      final response = await _api.post(
        Uri.parse(Env.verifyProfileChangeOtpEndpoint),
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.statusCode == 401) {
        throw Exception('Invalid token');
      }

      throw Exception(
          'Failed to verify profile change OTP: ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Error verifying profile change OTP: $e');
    }
  }

  /// Uploads the profile photo from raw bytes so the same code path works on
  /// mobile and web (`MultipartFile.fromPath` requires `dart:io`).
  Future<Map<String, dynamic>> updateProfilePhoto(
    Uint8List bytes,
    String filename,
  ) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AppFailure(AppFailureKind.unauthorized,
          debugMessage: 'No token available');
    }

    final uploadUrl = '${Env.apiUrl}/users/profile/photo';
    final safeName = _safePhotoFilename(filename);
    final mimeType = _getMimeType(safeName.split('.').last.toLowerCase());

    Future<http.Response> sendWithToken(String authToken) async {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(uploadUrl),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $authToken',
      });

      request.files.add(
        http.MultipartFile.fromBytes(
          'profile_photo',
          bytes,
          filename: safeName,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final streamedResponse = await request.send();
      return http.Response.fromStream(streamedResponse);
    }

    http.Response response;
    try {
      response = await sendWithToken(token);

      if (response.statusCode == 401) {
        final refreshed = await Get.find<SessionManager>().refreshSession();
        if (refreshed) {
          final newToken = await _authService.getToken();
          if (newToken != null) {
            response = await sendWithToken(newToken);
          }
        }
      }
    } catch (e) {
      throw AppFailure(AppFailureKind.network, debugMessage: '$e');
    }

    switch (response.statusCode) {
      case 200:
        return json.decode(response.body) as Map<String, dynamic>;
      case 401:
        throw const AppFailure(AppFailureKind.unauthorized);
      case 413:
        throw const AppFailure(AppFailureKind.fileTooLarge);
      case 415:
        throw const AppFailure(AppFailureKind.unsupportedFileType);
      default:
        throw AppFailure(
          AppFailureKind.server,
          debugMessage:
              'Profile photo upload failed: ${response.statusCode} - ${response.body}',
        );
    }
  }

  /// Web pickers often return names without a usable extension; fall back to a
  /// jpg name so the backend receives a valid image filename.
  String _safePhotoFilename(String filename) {
    final name = filename.trim().split(RegExp(r'[\\/]')).last;
    if (name.isEmpty) return 'profile_photo.jpg';

    final extension =
        name.contains('.') ? name.split('.').last.toLowerCase() : '';
    const allowed = {'jpg', 'jpeg', 'png', 'gif'};
    if (!allowed.contains(extension)) {
      final base = name.contains('.')
          ? name.substring(0, name.lastIndexOf('.'))
          : name;
      return '${base.isEmpty ? 'profile_photo' : base}.jpg';
    }
    return name;
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
      default:
        return 'image/jpeg';
    }
  }

  Future<Map<String, dynamic>> updatePreferences(
      Map<String, dynamic> preferences) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No token available');
    }

    try {
      final response = await _api.patch(
        Uri.parse('${Env.apiUrl}/users/preferences'),
        body: json.encode(preferences),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid token');
      } else {
        throw Exception('Failed to update preferences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating preferences: $e');
    }
  }

  Future<Map<String, dynamic>> removeProfilePhoto() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw const AppFailure(AppFailureKind.unauthorized,
          debugMessage: 'No token available');
    }

    http.Response response;
    try {
      response = await _api.delete(
        Uri.parse('${Env.apiUrl}/users/profile/photo'),
      );
    } catch (e) {
      throw AppFailure(AppFailureKind.network, debugMessage: '$e');
    }

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    if (response.statusCode == 401) {
      throw const AppFailure(AppFailureKind.unauthorized);
    }
    throw AppFailure(
      AppFailureKind.server,
      debugMessage: 'Profile photo removal failed: ${response.statusCode}',
    );
  }

  Future<Map<String, dynamic>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Trim the passwords to check for whitespace issues
      final trimmedOldPassword = oldPassword.trim();
      final trimmedNewPassword = newPassword.trim();

      final requestBody = {
        'currentPassword': trimmedOldPassword,
        'newPassword': trimmedNewPassword,
      };

      final response = await _api.patch(
        Uri.parse('${Env.apiUrl}/users/password'),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid token');
      } else if (response.statusCode == 400) {
        final body = jsonDecode(response.body);
        if (body['error'] != null) {
          // Add more context to the error message
          final error = body['error'];
          if (error == 'Password must be at least 8 characters long') {
            throw Exception(
                'Password validation failed: Length is ${trimmedNewPassword.length} characters');
          }
          throw Exception(error);
        }
        throw Exception('Invalid request');
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      rethrow;
    }
  }
}
