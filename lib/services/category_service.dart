import 'dart:convert';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import 'package:taxi_driver_app/models/category.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

class CategoryService {
  final String baseUrl;
  final ApiClient _api;

  CategoryService({
    required this.baseUrl,
    ApiClient? apiClient,
  }) : _api = apiClient ?? Get.find<ApiClient>();

  Future<List<Category>> getCategories() async {
    try {
      // Get token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();
      if (token == null) {
        throw Exception('No token available');
      }

      final uri = Uri.parse('$baseUrl/categories');

      final response = await _api.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

      

        return data.map((json) => Category.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception(
            'Failed to load categories: Server returned ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

}
