import 'package:flutter/foundation.dart';

class PlatformHelper {
  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;

  static void debugLog(String message) {
    if (kDebugMode) {
    }
  }

  static void webDebugLog(String message) {
    if (kIsWeb && kDebugMode) {
    }
  }
}
