import 'dart:convert';
import 'package:get/get.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

class HelpService {
  final AuthService _authService;
  final ApiClient _api;

  HelpService(this._authService, {ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  Future<List<dynamic>> getHelpVideos({
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

      final uri = Uri.parse('${Env.apiUrl}/help-videos').replace(queryParameters: queryParams);

      final response = await _api.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Return the array directly, whether it's wrapped or not
        if (data is List) {
          return data;
        } else if (data['data'] is List) {
          return data['data'];
        } else if (data['videos'] is List) {
          return data['videos'];
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to load help videos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> getHelpVideo(String videoId) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await _api.get(
        Uri.parse('${Env.apiUrl}/help-videos/$videoId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Video not found');
      } else {
        throw Exception('Failed to load video: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Helper method to format duration from seconds to MM:SS format
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper method to extract YouTube video ID from URL
  String? extractYouTubeVideoId(String url) {
    // Handle YouTube Shorts URLs
    if (url.contains('/shorts/')) {
      final shortsRegex = RegExp(r'youtube\.com\/shorts\/([^"&?\/\s]{11})');
      final match = shortsRegex.firstMatch(url);
      return match?.group(1);
    }
    
    // Handle regular YouTube URLs
    final regex = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regex.firstMatch(url);
    return match?.group(1);
  }
}
