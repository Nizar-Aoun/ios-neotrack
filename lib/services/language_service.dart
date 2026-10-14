import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/user_service.dart';

class LanguageService extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  Locale _currentLocale = const Locale('fr', 'FR');
  UserService? _userService;

  LanguageService() {
    _loadSavedLanguage();
    _initializeUserService();
  }

  Future<void> _initializeUserService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      _userService = UserService(authService);
    } catch (e) {
      // Error initializing UserService
    }
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
      notifyListeners();
    }
  }

  Locale get currentLocale => _currentLocale;

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
    notifyListeners();

    // Update language preference on the server
    await _updateLanguageOnServer(languageCode);
  }

  Future<void> _updateLanguageOnServer(String languageCode) async {
    try {
      final userService = _userService;
      if (userService != null) {
        await userService.updatePreferences({
          'lang': languageCode,
        });
      }
    } catch (e) {
      // Don't throw the error to avoid breaking the UI
      // The language change is still applied locally
    }
  }
}
