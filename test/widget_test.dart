import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/app_theme.dart';

void main() {
  test('semantic palette separates primary UI from brand accent', () {
    expect(AppColors.primaryColor, AppColors.baseColor);
    expect(AppColors.baseColor, const Color(0xFF0E141C));
    expect(AppColors.brandBlue, const Color(0xFF008DD2));
    expect(AppColors.primaryColor, isNot(AppColors.brandBlue));
  });

  test('light theme applies the intended action and accent hierarchy', () {
    final theme = AppTheme.lightTheme;
    final focusedBorder =
        theme.inputDecorationTheme.focusedBorder as OutlineInputBorder;

    expect(theme.colorScheme.primary, AppColors.baseColor);
    expect(theme.scaffoldBackgroundColor, AppColors.backgroundColor);
    expect(
      theme.elevatedButtonTheme.style?.backgroundColor
          ?.resolve(<WidgetState>{}),
      AppColors.baseColor,
    );
    expect(
      theme.textButtonTheme.style?.foregroundColor?.resolve(<WidgetState>{}),
      AppColors.brandBlue,
    );
    expect(focusedBorder.borderSide.color, AppColors.brandBlue);
    expect(theme.progressIndicatorTheme.color, AppColors.brandBlue);
  });
}
