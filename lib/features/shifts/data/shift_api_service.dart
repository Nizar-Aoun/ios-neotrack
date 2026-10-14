import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

/// Exception thrown when the Shifts API returns a non-2xx response.
class ShiftApiException implements Exception {
  final String message;
  final int statusCode;
  const ShiftApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}

/// Low-level HTTP service for the Shifts API.
class ShiftApiService {
  final String _base = Env.apiUrl;
  final ApiClient _api;

  ShiftApiService({ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  Future<void> _ensureAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await AuthService(prefs).getToken();
    if (token == null) throw Exception('Not authenticated');
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<ShiftModel> createShift(ShiftModel shift) async {
    await _ensureAuthenticated();
    final response = await _api.post(
      Uri.parse('$_base/shifts'),
      body: jsonEncode(shift.toJson()),
    );
    _assertOk(response, 'createShift');
    final data = _decodeBody(response.body);
    return ShiftModel.fromJson(data is Map ? data : data['shift'] ?? data);
  }

  // ── Update (full) ────────────────────────────────────────────────────────────

  Future<ShiftModel> updateShift(String id, ShiftModel shift) async {
    await _ensureAuthenticated();
    final response = await _api.put(
      Uri.parse('$_base/shifts/$id'),
      body: jsonEncode(shift.toUpdateJson()),
    );
    _assertOk(response, 'updateShift');
    final data = _decodeBody(response.body);
    return ShiftModel.fromJson(data is Map ? data : data['shift'] ?? data);
  }

  // ── Get by car ───────────────────────────────────────────────────────────────

  Future<List<ShiftModel>> getShiftsByCar(String carId) async {
    await _ensureAuthenticated();
    final response = await _api.get(
      Uri.parse('$_base/shifts/car/$carId'),
    );
    _assertOk(response, 'getShiftsByCar');
    final body = _decodeBody(response.body);
    final list = body is List ? body : (body['shifts'] ?? body['data'] ?? []);
    return (list as List)
        .map((e) => ShiftModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Close / Update status ────────────────────────────────────────────────────

  Future<void> patchShiftStatus(String id) async {
    await _ensureAuthenticated();
    final response = await _api.patch(
      Uri.parse('$_base/shifts/$id'),
    );
    _assertOk(response, 'patchShiftStatus');
  }

  // ── Delete ───────────────────────────────────────────────────────────────────

  Future<void> deleteShift(String id) async {
    await _ensureAuthenticated();
    final response = await _api.patch(
      Uri.parse('$_base/shifts/$id'),
    );
    _assertOk(response, 'deleteShift');
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void _assertOk(http.Response response, String context) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String errorMsg = 'HTTP ${response.statusCode}';
      try {
        final body = jsonDecode(response.body) as Map;
        errorMsg = (body['message'] ?? body['error'] ?? errorMsg).toString();
      } catch (_) {}
      throw ShiftApiException(errorMsg, response.statusCode);
    }
  }

  dynamic _decodeBody(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {};
    }
  }
}
