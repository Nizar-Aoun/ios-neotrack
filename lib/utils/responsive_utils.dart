import 'package:flutter/material.dart';

/// Responsive utilities to centralize common size checks and paddings.
class ResponsiveUtils {
  const ResponsiveUtils._();

  /// Consider devices narrower than 360dp as small screens.
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Standard horizontal padding that adapts to screen size.
  static EdgeInsets horizontalPad(BuildContext context) {
    final small = isSmallScreen(context);
    return EdgeInsets.symmetric(horizontal: small ? 12 : 16);
  }

  /// Standard all-side padding that adapts to screen size.
  static EdgeInsets allPad(BuildContext context) {
    final small = isSmallScreen(context);
    return EdgeInsets.all(small ? 12 : 16);
  }

  /// Vertical spacing based on size tier.
  static double vSpaceSmall(BuildContext context) =>
      isSmallScreen(context) ? 8 : 12;
  static double vSpaceMedium(BuildContext context) =>
      isSmallScreen(context) ? 12 : 16;
  static double vSpaceLarge(BuildContext context) =>
      isSmallScreen(context) ? 16 : 24;

  /// Font sizes.
  static double titleFont(BuildContext context) =>
      isSmallScreen(context) ? 16 : 18;
  static double subtitleFont(BuildContext context) =>
      isSmallScreen(context) ? 12 : 14;
  static double bodyFont(BuildContext context) =>
      isSmallScreen(context) ? 14 : 16;

  /// Icon size that scales.
  static double iconMedium(BuildContext context) =>
      isSmallScreen(context) ? 20 : 24;
}
