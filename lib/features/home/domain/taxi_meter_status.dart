import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

/// API `taxiMeterStatus`: 0 = libre, 1 = occupé, 2 = pause.
abstract final class TaxiMeterStatus {
  static const int libre = 0;
  static const int occupe = 1;
  static const int pause = 2;

  static int fromLocation(Map<String, dynamic> location) {
    final raw = location['taxiMeterStatus'] ?? location['taxi_meter_status'];
    if (raw != null) {
      final n = (raw as num).toInt();
      if (n >= libre && n <= pause) return n;
      return libre;
    }
    final legacy = location['taximeter'];
    if (legacy == true || legacy == 1) return occupe;
    return libre;
  }

  static String localizationKey(int status) {
    switch (status) {
      case occupe:
        return 'occupied';
      case pause:
        return 'taxiMeterPause';
      default:
        return 'free';
    }
  }

  static Color color(int status) {
    switch (status) {
      case occupe:
        return AppColors.successColor;
      case pause:
        return AppColors.textSecondary;
      default:
        return AppColors.errorColor;
    }
  }

  static const String occupiedImagePath = 'assets/images/tms_yellow.png';
}
