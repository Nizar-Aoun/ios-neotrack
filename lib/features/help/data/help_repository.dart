import 'dart:convert';
import 'package:get/get.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/features/help/domain/help_video_model.dart';

/// Help Repository - Handles API calls for help videos
class HelpRepository {
  final AuthService _authService;
  final ApiClient _api;

  HelpRepository(this._authService, {ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  /// Get list of help videos
  Future<List<HelpVideoModel>> getHelpVideos({
    String? language,
    String? category,
    int? limit,
    int? page,
  }) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (language != null) queryParams['language'] = language;
      if (category != null) queryParams['category'] = category;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (page != null) queryParams['page'] = page.toString();

      final uri = Uri.parse('${Env.apiUrl}/help-videos')
          .replace(queryParameters: queryParams);
      final response = await _api.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> videosJson;

        // Handle different response formats
        if (data is List) {
          videosJson = data;
        } else if (data['data'] is List) {
          videosJson = data['data'];
        } else if (data['videos'] is List) {
          videosJson = data['videos'];
        } else {
          videosJson = [];
        }

        return videosJson.map((json) => HelpVideoModel.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to load help videos: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single help video by ID
  Future<HelpVideoModel> getHelpVideo(String videoId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _api
          .get(Uri.parse('${Env.apiUrl}/help-videos/$videoId'))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HelpVideoModel.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Video not found');
      } else {
        throw Exception('Failed to load video: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Increment view count for a video
  Future<void> incrementViewCount(String videoId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        return; // Don't throw, just skip
      }

      await _api
          .post(Uri.parse('${Env.apiUrl}/help-videos/$videoId/view'))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      // Don't throw - this is a non-critical operation
    }
  }
}
