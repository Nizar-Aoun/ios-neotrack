import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/core/auth/session_manager.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

class ProfileService {
  final SharedPreferences _prefs;
  late final AuthService _authService;

  ProfileService(this._prefs) {
    _authService = AuthService(_prefs);
  }

  Future<String?> getAuthToken() async {
    try {
      return await _authService.getToken();
    } catch (e) {
      return null;
    }
  }

  Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> getAuthHeaders() async {
    var token = await getAuthToken();
    if ((token == null || token.isEmpty) &&
        Get.isRegistered<SessionManager>()) {
      final refreshed = await Get.find<SessionManager>().refreshSession();
      if (refreshed) {
        token = await getAuthToken();
      }
    }
    if (token == null || token.isEmpty) {
      return {};
    }
    return {
      'Authorization': 'Bearer $token',
    };
  }
}
