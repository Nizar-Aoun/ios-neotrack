import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/error/subscription_error_handler.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'auth_service.dart';

class CarService {
  final AuthService _authService;
  final ApiClient _api;

  CarService(this._authService, {ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  Future<void> _ensureAuthenticated() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No token available');
    }
  }

  Future<Map<String, dynamic>> getUserCars() async {
    await _ensureAuthenticated();

    final response = await _api.get(Uri.parse(Env.getUserCarsEndpoint));

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      throw Exception('No cars available');
    } else {
      throw Exception('Failed to load cars: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCarLocation(String carId) async {
    await _ensureAuthenticated();

    final response =
        await _api.get(Uri.parse('${Env.getCarLocationEndpoint}/$carId'));

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else {
      throw Exception('Failed to load car location: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCarLocationHistory(
      String carId, Map<String, String> dates) async {
    await _ensureAuthenticated();

    final uri = Uri.parse('${Env.getCarLocationEndpoint}/$carId').replace(
      queryParameters: {
        'startDate': dates['startDate'] ?? '',
        'endDate': dates['endDate'] ?? '',
      },
    );

    final response = await _api.get(uri);

    _debugPrintHistoryResponse(response.statusCode, response.body);

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData.containsKey('locations') &&
          responseData['locations'] is List) {
        return responseData;
      } else if (responseData.containsKey('location') &&
          responseData['location'] is Map) {
        return {
          'car_id': responseData['car_id'],
          'locations': [responseData['location']],
          'location': responseData['location'],
        };
      } else {
        return {
          'car_id': carId,
          'locations': [],
          'error': 'Unexpected response format'
        };
      }
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      final responseData = json.decode(response.body);
      return {
        'error': responseData['error'] ?? 'No location data found',
        'car_id': carId,
        'locations': [],
        'location': responseData['location'] ?? {'speed_kmh': 0}
      };
    } else {
      throw Exception(
          'Failed to load location history: ${response.statusCode}');
    }
  }

  void _debugPrintHistoryResponse(int statusCode, String body) {
    const chunkSize = 700;
    final chunkCount = (body.length / chunkSize).ceil();
    debugPrint('[API][get-car-location-history] status=$statusCode');

    for (var start = 0, part = 1; start < body.length;
        start += chunkSize, part++) {
      final end = (start + chunkSize).clamp(0, body.length).toInt();
      debugPrint(
        '[API][get-car-location-history][part $part/$chunkCount] '
        '${body.substring(start, end)}',
      );
    }
  }

  Future<Map<String, dynamic>> remoteStop(String carId) async {
    await _ensureAuthenticated();

    final response =
        await _api.post(Uri.parse('${Env.remoteStopEndpoint}/$carId'));
    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      throw Exception('Car not found');
    } else if (response.statusCode == 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Bad request');
    } else {
      throw Exception('Failed to stop car remotely: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> remoteStart(String carId) async {
    await _ensureAuthenticated();

    final response =
        await _api.post(Uri.parse('${Env.remoteStartEndpoint}/$carId'));

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      throw Exception('Car not found');
    } else if (response.statusCode == 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Bad request');
    } else {
      throw Exception('Failed to start car remotely: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> remoteRestart(String carId) async {
    await _ensureAuthenticated();

    final response =
        await _api.post(Uri.parse('${Env.remoteRestartEndpoint}/$carId'));

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      throw Exception('Car not found');
    } else if (response.statusCode == 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Bad request');
    } else {
      throw Exception('Failed to restart device: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCarStatus(String carId) async {
    await _ensureAuthenticated();

    final response =
        await _api.get(Uri.parse('${Env.carStatusEndpoint}/$carId'));

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      throw Exception('Car not found');
    } else {
      throw Exception('Failed to load car status: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCarPreferencesById(String carId) async {
    await _ensureAuthenticated();

    final response =
        await _api.get(Uri.parse('${Env.carsEndpoint}/$carId/preferences'));

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      throw Exception('Car not found');
    } else {
      throw Exception('Failed to load car preferences: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCarPreferences() async {
    await _ensureAuthenticated();

    final response = await _api.get(Uri.parse(Env.carPreferencesEndpoint));

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else {
      throw Exception('Failed to load car preferences: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateCarPreferences(
      String carId, Map<String, dynamic> preferences) async {
    await _ensureAuthenticated();

    final response = await _api.patch(
      Uri.parse('${Env.carsEndpoint}/$carId/preferences'),
      body: json.encode(preferences),
    );

    SubscriptionErrorHandler.enforce(response);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid token');
    } else if (response.statusCode == 404) {
      throw Exception('Car not found');
    } else if (response.statusCode == 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Bad request');
    } else {
      throw Exception(
          'Failed to update car preferences: ${response.statusCode}');
    }
  }
}
