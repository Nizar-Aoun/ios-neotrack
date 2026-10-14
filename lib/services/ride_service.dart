import 'package:taxi_driver_app/utils/date_formatter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/models/ride.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

class RideService {
  final String baseUrl;
  final String carId;
  final ApiClient _api;

  RideService({
    required this.baseUrl,
    required this.carId,
    ApiClient? apiClient,
  }) : _api = apiClient ?? Get.find<ApiClient>();

  Future<List<Ride>> getRides({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};

    if (startDate != null) {
      queryParams['start_date'] =
          DateFormatter.toApiDateTimeParam(startDate);
    }
    if (endDate != null) {
      queryParams['end_date'] = DateFormatter.toApiDateTimeParam(endDate);
    }

    final uri = Uri.parse('$baseUrl/rides/$carId/').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    // Get token
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(prefs);
    final token = await authService.getToken();
    if (token == null) {
      throw Exception('No token available');
    }

    try {
      final response = await _api.get(uri);

      debugPrint('[RideService] getRides GET $uri');
      debugPrint('[RideService] getRides status: ${response.statusCode}');
      debugPrint('[RideService] getRides response: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Ride.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load rides: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load rides: $e');
    }
  }

  Future<Map<String, dynamic>> getRideDetails(String rideId) async {
    try {
      await _ensureAuthenticated();

      final response = await _api.get(
        Uri.parse('$baseUrl/rides/details/$rideId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Invalid token');
      } else {
        throw Exception('Failed to load ride details');
      }
    } catch (e) {
      throw Exception('Error getting ride details: $e');
    }
  }

  Future<void> deleteRide(String rideId) async {
    try {
      await _ensureAuthenticated();

      final response = await _api.patch(
        Uri.parse('$baseUrl/rides/$rideId'),
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid token');
      } else if (response.statusCode == 404) {
        throw Exception('Ride not found');
      } else {
        throw Exception('Failed to delete ride: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting ride: $e');
    }
  }

  Future<void> _ensureAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(prefs);
    final token = await authService.getToken();
    if (token == null) {
      throw Exception('No token available');
    }
  }
}
