import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'text_styles.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        brightness: Brightness.light,
        primary: AppColors.primaryColor,
        onPrimary: AppColors.textOnBase,
        primaryContainer: AppColors.surfaceMuted,
        onPrimaryContainer: AppColors.baseColor,
        secondary: AppColors.secondaryColor,
        onSecondary: AppColors.textOnSecondary,
        secondaryContainer: AppColors.surfaceMuted,
        onSecondaryContainer: AppColors.baseColor,
        tertiary: AppColors.brandBlue,
        onTertiary: AppColors.textOnBrand,
        tertiaryContainer: AppColors.surfaceColor,
        onTertiaryContainer: AppColors.baseColor,
        error: AppColors.errorColor,
        onError: AppColors.white,
        errorContainer: Color(0xFFFFEBEE),
        onErrorContainer: Color(0xFFB71C1C),
        surface: AppColors.cardColor,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceColor,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.textSecondary,
        outlineVariant: AppColors.borderColor,
        shadow: AppColors.shadowColor,
        scrim: Color(0x80000000),
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundColor,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardColor,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:
            AppTextStyles.appBarTitle.copyWith(color: AppColors.textPrimary),
        toolbarTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
        actionsIconTheme:
            const IconThemeData(color: AppColors.textPrimary, size: 24),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.cardColor,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTextStyles.tabText,
        unselectedLabelStyle: AppTextStyles.tabText,
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.cardColor,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.cardBorderRadius,
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBg,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          shadowColor: AppColors.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppColors.buttonBorderRadius,
          ),
          textStyle: AppTextStyles.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.baseColor,
          side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: AppColors.buttonBorderRadius,
          ),
          textStyle: AppTextStyles.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          minimumSize: const Size(120, 48),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          textStyle: AppTextStyles.buttonText,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: AppColors.buttonBorderRadius,
          ),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: AppColors.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppColors.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppColors.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppColors.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppColors.inputBorderRadius,
          borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
        ),
        labelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
        errorStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.errorColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardColor,
        elevation: 8,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle:
            AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.cardColor,
        elevation: 8,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.bottomSheetBorderRadius,
        ),
      ),

      // Snack bar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.buttonBorderRadius,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),

      // Tab bar theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primaryColor,
        unselectedLabelColor: AppColors.textTertiary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.brandBlue, width: 2),
          insets: EdgeInsets.symmetric(horizontal: 16),
        ),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceColor,
        selectedColor: AppColors.primaryColor,
        labelStyle:
            AppTextStyles.labelSmall.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle:
            AppTextStyles.labelSmall.copyWith(color: AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        pressElevation: 2,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerColor,
        thickness: 1,
        space: 1,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandBlue,
        linearTrackColor: AppColors.surfaceMuted,
        circularTrackColor: AppColors.surfaceMuted,
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandBlue;
          }
          return AppColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandBlue.withOpacity(0.35);
          }
          return AppColors.textTertiary.withOpacity(0.25);
        }),
      ),

      // Checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryColor;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandBlue;
          }
          return AppColors.textTertiary;
        }),
      ),

      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.brandBlue,
        inactiveTrackColor: AppColors.surfaceMuted,
        thumbColor: AppColors.brandBlue,
        overlayColor: AppColors.brandBlue.withOpacity(0.2),
        valueIndicatorColor: AppColors.baseColor,
        valueIndicatorTextStyle:
            AppTextStyles.labelSmall.copyWith(color: AppColors.textOnPrimary),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.brandBlue,
        onPrimary: AppColors.textOnBrand,
        primaryContainer: Color(0xFF1A365D),
        onPrimaryContainer: Color(0xFFE3F2FD),
        secondary: AppColors.secondaryColor,
        onSecondary: AppColors.baseColor,
        secondaryContainer: Color(0xFF004D40),
        onSecondaryContainer: Color(0xFFE0F7FA),
        tertiary: AppColors.tertiaryColor,
        onTertiary: AppColors.baseColor,
        tertiaryContainer: AppColors.brandBlueDeep,
        onTertiaryContainer: AppColors.white,
        error: AppColors.errorColor,
        onError: AppColors.textOnPrimary,
        errorContainer: Color(0xFF8C1D18),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: AppColors.darkSurfaceColor,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkBackgroundColor,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkDividerColor,
        outlineVariant: Color(0xFF555555),
        shadow: AppColors.shadowColor,
        scrim: Color(0x80000000),
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.darkBackgroundColor,

      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurfaceColor,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTextStyles.appBarTitle
            .copyWith(color: AppColors.darkTextPrimary),
        toolbarTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextPrimary),
        iconTheme:
            const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
        actionsIconTheme:
            const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // Text theme for dark mode
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge
            .copyWith(color: AppColors.darkTextPrimary),
        displayMedium: AppTextStyles.displayMedium
            .copyWith(color: AppColors.darkTextPrimary),
        displaySmall: AppTextStyles.displaySmall
            .copyWith(color: AppColors.darkTextPrimary),
        headlineLarge: AppTextStyles.headlineLarge
            .copyWith(color: AppColors.darkTextPrimary),
        headlineMedium: AppTextStyles.headlineMedium
            .copyWith(color: AppColors.darkTextPrimary),
        headlineSmall: AppTextStyles.headlineSmall
            .copyWith(color: AppColors.darkTextPrimary),
        titleLarge:
            AppTextStyles.titleLarge.copyWith(color: AppColors.darkTextPrimary),
        titleMedium: AppTextStyles.titleMedium
            .copyWith(color: AppColors.darkTextPrimary),
        titleSmall:
            AppTextStyles.titleSmall.copyWith(color: AppColors.darkTextPrimary),
        bodyLarge:
            AppTextStyles.bodyLarge.copyWith(color: AppColors.darkTextPrimary),
        bodyMedium: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextSecondary),
        bodySmall: AppTextStyles.bodySmall
            .copyWith(color: AppColors.darkTextSecondary),
        labelLarge: AppTextStyles.labelLarge
            .copyWith(color: AppColors.darkTextSecondary),
        labelMedium: AppTextStyles.labelMedium
            .copyWith(color: AppColors.darkTextSecondary),
        labelSmall: AppTextStyles.labelSmall
            .copyWith(color: AppColors.darkTextTertiary),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: AppColors.darkCardColor,
        elevation: 2,
        shadowColor: AppColors.shadowColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppColors.cardBorderRadius,
        ),
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}

/// Backward compatibility - ColorManager alias
typedef ColorManager = AppTheme;
