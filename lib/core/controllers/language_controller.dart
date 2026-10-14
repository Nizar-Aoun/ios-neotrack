import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Language Controller - Manages app language state
class LanguageController extends GetxController {
  static const String _languageKey = 'app_language';
  final Rx<Locale> currentLocale = const Locale('fr', 'FR').obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = Get.find<SharedPreferences>();
    final languageCode = prefs.getString(_languageKey);
    if (languageCode != null) {
      currentLocale.value = Locale(languageCode);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    currentLocale.value = Locale(languageCode);
    final prefs = Get.find<SharedPreferences>();
    await prefs.setString(_languageKey, languageCode);

    // Update GetX locale to trigger app rebuild
    Get.updateLocale(Locale(languageCode));

    // Update language preference on the server
    await _updateLanguageOnServer(languageCode);
  }

  Future<void> _updateLanguageOnServer(String languageCode) async {
    try {
      // Language preference can be updated through UserService if needed
      // For now, just log it
    } catch (e) {
    }
  }
}
