import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/core/network/api_client.dart';
import '../models/dashboard_stats.dart';
import '../../../services/auth_service.dart';
import '../../../config/env.dart';

/// Service pour récupérer les statistiques du tableau de bord
class DashboardService {
  final ApiClient _api;

  DashboardService({ApiClient? apiClient})
      : _api = apiClient ?? Get.find<ApiClient>();

  /// Récupère les statistiques pour une voiture donnée
  ///
  /// [carId] est l'identifiant MongoDB de la voiture
  /// [startDate] et [endDate] définissent la période (optional)
  /// Si pas de dates fournies, retourne les stats du jour courant (00:00 à 23:59:59.999)
  Future<DashboardStats> getStats({
    required String carId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get authentication token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();

      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Si pas de dates fournies, utiliser aujourd'hui par défaut (00:00 à 23:59:59.999)
      final now = DateTime.now();
      final effectiveStartDate =
          startDate ?? DateTime.utc(now.year, now.month, now.day, 0, 0, 0);
      final effectiveEndDate =
          endDate ?? DateTime.utc(now.year, now.month, now.day, 23, 59, 59, 999);

      // Construction de l'URL avec paramètres de date
      final uri = Uri.parse('${Env.statisticsEndpoint}/$carId/').replace(
        queryParameters: {
          'startDate': effectiveStartDate.toUtc().toIso8601String(),
          'endDate': effectiveEndDate.toUtc().toIso8601String(),
        },
      );

      // Appel API
      final response = await _api.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle both direct object response and array response
        Map<String, dynamic> data;
        if (responseData is List && responseData.isNotEmpty) {
          data = responseData[0] as Map<String, dynamic>;
        } else if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else {
          throw Exception('Invalid API response format');
        }

        // Check if the API call was successful
        if (data['success'] == true) {
          return DashboardStats.fromJson(data);
        } else {
          throw Exception('API returned success=false');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('No data available for this car');
      } else {
        throw Exception('Failed to load stats: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Récupère les statistiques hebdomadaires pour les graphiques
  /// Appelle l'endpoint /7days qui retourne les données de lundi au jour courant
  /// Non affecté par les filtres de date
  Future<WeeklyStats> getWeeklyStats({
    required String carId,
  }) async {
    try {
      // Get authentication token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();

      if (token == null) {
        throw Exception('No authentication token available');
      }

      // Construction de l'URL pour les stats hebdomadaires
      final uri = Uri.parse('${Env.statisticsEndpoint}/$carId/7days');

      // Appel API
      final response = await _api.get(uri).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Handle both direct object response and array response
        Map<String, dynamic> data;
        if (responseData is List && responseData.isNotEmpty) {
          data = responseData[0] as Map<String, dynamic>;
        } else if (responseData is Map<String, dynamic>) {
          data = responseData;
        } else {
          throw Exception('Invalid API response format');
        }

        // Check if the API call was successful
        if (data['success'] == true) {
          return WeeklyStats.fromJson(data);
        } else {
          throw Exception('API returned success=false');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('No weekly data available for this car');
      } else {
        throw Exception('Failed to load weekly stats: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
