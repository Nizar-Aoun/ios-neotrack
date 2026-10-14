import 'package:taxi_driver_app/utils/date_formatter.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/models/expense.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

class ExpenseService {
  final String baseUrl;
  final String carId;
  final ApiClient _api;

  ExpenseService({
    required this.baseUrl,
    required this.carId,
    ApiClient? apiClient,
  }) : _api = apiClient ?? Get.find<ApiClient>();

  Future<List<Expense>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('No token available');
      }

      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = DateFormatter.toApiDateParam(startDate);
      }
      if (endDate != null) {
        queryParams['end_date'] = DateFormatter.toApiDateParam(endDate);
      }

      final uri = Uri.parse('$baseUrl/expenses/car/$carId').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await _api.get(uri);

      debugPrint('[ExpenseService] getExpenses GET $uri');
      debugPrint('[ExpenseService] getExpenses status: ${response.statusCode}');
      debugPrint('[ExpenseService] getExpenses response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> expensesList = data['expenses'] ?? [];

 
        return expensesList.map((json) => Expense.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // If the endpoint doesn't exist yet, return an empty list instead of throwing an error
        return [];
      } else {
        throw Exception(
            'Failed to load expenses: Server returned ${response.statusCode}');
      }
    } catch (e) {
      // If there's any other error, return an empty list instead of throwing
      return [];
    }
  }

  Future<Expense> createExpense({
    required double amount,
    required DateTime date,
    required String categoryId,
    required String title,
    required String description,
  }) async {
    try {
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('No token available');
      }

      final uri = Uri.parse('$baseUrl/expenses');

      final response = await _api.post(
        uri,
        body: json.encode({
          'id_car': carId,
          'amount': amount,
          'date': date.toIso8601String(),
          'id_category': categoryId,
          'title': title,
          'description': description,
        }),
      );

      debugPrint('[ExpenseService] createExpense status: ${response.statusCode}');
      debugPrint('[ExpenseService] createExpense response: ${response.body}');

      if (response.statusCode == 201) {
        return Expense.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception(
            'Expense creation endpoint not available yet. Please try again later.');
      } else {
        throw Exception(
            'Failed to create expense: Server returned ${response.statusCode}');
      }
    } catch (e) {
      rethrow; // Rethrow the error since we want to show it to the user
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    try {
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('No token available');
      }

      final uri = Uri.parse('$baseUrl/expenses/$expenseId');

      final response = await _api.delete(uri);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Both 200 and 204 indicate successful deletion
        return;
      } else if (response.statusCode == 404) {
        throw Exception(
            'Expense deletion endpoint not available yet. Please try again later.');
      } else {
        throw Exception(
            'Failed to delete expense: Server returned ${response.statusCode}');
      }
    } catch (e) {
      rethrow; // Rethrow the error since we want to show it to the user
    }
  }

  Future<Expense> updateExpense(
    String expenseId, {
    required double amount,
    required DateTime date,
    required String categoryId,
    required String title,
    required String description,
  }) async {
    try {
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('No token available');
      }

      final uri = Uri.parse('$baseUrl/expenses/$expenseId');

      final response = await _api.put(
        uri,
        body: json.encode({
          'id_car': carId,
          'amount': amount,
          'date': date.toIso8601String(),
          'id_category': categoryId,
          'title': title,
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception(
            'Expense update endpoint not available yet. Please try again later.');
      } else {
        throw Exception(
            'Failed to update expense: Server returned ${response.statusCode}');
      }
    } catch (e) {
      rethrow; // Rethrow the error since we want to show it to the user
    }
  }
}
