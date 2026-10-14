import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core brand and UI hierarchy
  static const Color baseColor = Color(0xFF0E141C);
  static const Color primaryColor = baseColor;
  static const Color brandBlue = Color(0xFF008DD2);
  static const Color brandBlueDeep = Color(0xFF395EA7);
  static const Color primaryVariant = brandBlueDeep; // Compatibility alias

  // Semantic status colors
  static const Color successColor = Color(0xFF009846);
  static const Color warningColor = Color(0xFFFFED00);
  static const Color errorColor = Color(0xFFE31E24);
  static const Color infoColor = brandBlue;

  static const Color secondaryColor = Color(0xFF7ED6C9);
  static const Color secondaryVariant =
      successColor; // Compatibility alias for environmental green
  static const Color tertiaryColor = Color(0xFFFBCB07);
  static const Color tertiaryVariant =
      warningColor; // Compatibility alias for environmental yellow

  // Neutral surfaces and borders
  static const Color backgroundColor = Color(0xFFFEFEFE);
  static const Color surfaceColor = Color(0xFFF5F5F5);
  static const Color surfaceMuted = Color(0xFFE7EBEB);
  static const Color cardColor = Color(0xFFFFFFFF);
  static const Color borderColor = surfaceMuted;
  static const Color dividerColor = surfaceMuted;
  // Mid-gray hairline, used where a divider needs to stay visible over maps
  static const Color dividerStrong = textSecondary;

  // Compatibility neutrals
  static const Color white = cardColor;
  static const Color black = Color(0xFF000000);
  static const Color greybg = surfaceColor;
  static const Color buttonBg = baseColor;
  static const Color lightGrey2 = Color(0xFFE0E0E0);
  static const Color blackLight = Color(0xFF333333);

  // Text colors
  static const Color textPrimary = baseColor;
  static const Color textSecondary = Color(0xFF626D77);
  static const Color textTertiary = Color(0xFF898989);
  static const Color textOnBase = white;
  static const Color textOnBrand = white;
  static const Color textOnSecondary = baseColor;
  static const Color textOnPrimary = textOnBase; // Compatibility alias
  static const Color textLight = textPrimary; // Compatibility alias

  // Domain semantics
  static const Color rideActive = secondaryColor;
  static const Color rideWaiting = warningColor;
  static const Color rideCancelled = errorColor;
  static const Color rideCompleted = successColor;
  static const Color walletPositive = successColor;
  static const Color walletNegative = errorColor;
  static const Color driverOnline = successColor;
  static const Color driverOffline = textTertiary;

  // Dark theme colors
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);
  static const Color darkCardColor = Color(0xFF2D2D2D);
  static const Color darkDividerColor = Color(0xFF404040);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF808080);

  // Shadow colors
  static const Color shadowColor = Color(0x1A000000);
  static const Color lightShadowColor = Color(0x0D000000);

  /// NEOS app-specific color extensions
  static const Map<String, Color> appColors = {
    'rideActive': rideActive,
    'rideWaiting': rideWaiting,
    'rideCancelled': rideCancelled,
    'rideCompleted': rideCompleted,
    'walletPositive': walletPositive,
    'walletNegative': walletNegative,
    'driverOnline': driverOnline,
    'driverOffline': driverOffline,
    'vehicleEconomy': secondaryColor,
    'vehicleComfort': brandBlue,
    'vehiclePremium': tertiaryColor,
    'vehicleLuxury': brandBlueDeep,
    'businessPortal': brandBlue,
    'supportTicket': brandBlueDeep,
    'notification': warningColor,
    'neosBlue': brandBlue,
    'neosTeal': secondaryColor,
    'neosYellow': tertiaryColor,
    'neosGray': textTertiary,
    'envBlue': brandBlueDeep,
    'envGreen': successColor,
    'envRed': errorColor,
    'envYellow': warningColor,
    'envBlack': black,
    'envGray': textSecondary,
    'envLightGray': surfaceMuted,
    'envWhite': backgroundColor,
  };

  /// Get app-specific color
  static Color getAppColor(String colorName) {
    return appColors[colorName] ?? brandBlue;
  }

  /// Common border radius
  static const BorderRadius cardBorderRadius =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius buttonBorderRadius =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius inputBorderRadius =
      BorderRadius.all(Radius.circular(8));
  static const BorderRadius bottomSheetBorderRadius =
      BorderRadius.vertical(top: Radius.circular(16));

  /// Common shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: shadowColor,
      offset: Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> lightCardShadow = [
    BoxShadow(
      color: lightShadowColor,
      offset: Offset(0, 1),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  /// Common spacings
  static const double spacingXXS = 4.0;
  static const double spacingXS = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  /// Icon sizes
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;
}
