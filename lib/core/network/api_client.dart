import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:taxi_driver_app/core/auth/session_manager.dart';

/// Authenticated HTTP helper with single-flight refresh and one retry on 401.
class ApiClient {
  ApiClient({required SessionManager sessionManager, http.Client? client})
      : _sessionManager = sessionManager,
        _client = client ?? http.Client();

  final SessionManager _sessionManager;
  final http.Client _client;

  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
  }) {
    return _send(
      (authHeaders) => _client.get(url, headers: authHeaders),
      headers: headers,
    );
  }

  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(
      (authHeaders) => _client.post(
        url,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      ),
      headers: headers,
    );
  }

  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(
      (authHeaders) => _client.put(
        url,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      ),
      headers: headers,
    );
  }

  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(
      (authHeaders) => _client.patch(
        url,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      ),
      headers: headers,
    );
  }

  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(
      (authHeaders) => _client.delete(
        url,
        headers: authHeaders,
        body: body,
        encoding: encoding,
      ),
      headers: headers,
    );
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request, {
    Map<String, String>? headers,
  }) async {
    final firstHeaders = await _buildHeaders(headers);
    final firstResponse = await request(firstHeaders);

    if (firstResponse.statusCode != 401) {
      return firstResponse;
    }

    final refreshed = await _sessionManager.refreshSession();
    if (!refreshed) {
      return firstResponse;
    }

    final retryHeaders = await _buildHeaders(headers);
    return request(retryHeaders);
  }

  Future<Map<String, String>> _buildHeaders(Map<String, String>? headers) async {
    final merged = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    final token = await _sessionManager.getAccessToken();
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }

    return merged;
  }
}
