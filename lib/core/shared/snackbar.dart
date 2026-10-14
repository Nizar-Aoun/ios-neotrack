import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

/// Custom SnackBar utility class for displaying elegant notifications
/// Uses GetX for global snackbar management
class CustomSnackBar {
  // Private constructor to prevent instantiation
  CustomSnackBar._();
  static int _webBannerToken = 0;

  static const EdgeInsets _defaultMargin = EdgeInsets.all(16);
  static const double _defaultBorderRadius = 12;

  static List<BoxShadow> _defaultShadows() {
    return [
      BoxShadow(
        color: AppColors.shadowColor,
        spreadRadius: 2,
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static void _show({
    required String title,
    required String message,
    required Color backgroundColor,
    required Color textColor,
    Widget? icon,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
    bool isDismissible = true,
    bool showCloseButton = true,
    VoidCallback? onTap,
    bool shouldIconPulse = true,
    bool showProgressIndicator = false,
  }) {
    if (kIsWeb) {
      final context = Get.context;
      final messenger =
          context != null ? ScaffoldMessenger.maybeOf(context) : null;

      if (messenger != null) {
        messenger.hideCurrentSnackBar();
        messenger.hideCurrentMaterialBanner();

        if (position == SnackPosition.TOP) {
          final int bannerToken = ++_webBannerToken;

          messenger.showMaterialBanner(
            MaterialBanner(
              backgroundColor: backgroundColor,
              leading: icon,
              content: InkWell(
                onTap: onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(color: textColor),
                    ),
                  ],
                ),
              ),
              actions: [
                if (showCloseButton)
                  IconButton(
                    onPressed: () => messenger.hideCurrentMaterialBanner(),
                    icon: Icon(
                      Icons.close,
                      color: textColor,
                      size: 20,
                    ),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          );

          if (isDismissible && duration != const Duration(days: 1)) {
            Future.delayed(duration, () {
              if (_webBannerToken == bannerToken) {
                messenger.hideCurrentMaterialBanner();
              }
            });
          }

          return;
        }

        messenger.showSnackBar(
          SnackBar(
            duration: duration,
            dismissDirection: isDismissible
                ? DismissDirection.horizontal
                : DismissDirection.none,
            behavior: SnackBarBehavior.floating,
            margin: _defaultMargin,
            backgroundColor: backgroundColor,
            showCloseIcon: showCloseButton,
            closeIconColor: textColor,
            content: InkWell(
              onTap: onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    icon,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return;
      }
    }

    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor: backgroundColor,
      colorText: textColor,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      duration: duration,
      isDismissible: isDismissible,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeInCirc,
      margin: _defaultMargin,
      borderRadius: _defaultBorderRadius,
      boxShadows: _defaultShadows(),
      showProgressIndicator: showProgressIndicator,
      mainButton: showCloseButton
          ? TextButton(
              onPressed: () => Get.closeCurrentSnackbar(),
              child: Icon(
                Icons.close,
                color: textColor,
                size: 20,
              ),
            )
          : null,
      onTap: onTap != null ? (_) => onTap() : null,
    );
  }

  /// Show a success snackbar with a green theme
  static void success({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
    bool isDismissible = true,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      backgroundColor: AppColors.successColor,
      textColor: AppColors.white,
      icon: const Icon(
        Icons.check_circle_outline,
        color: AppColors.white,
        size: 28,
      ),
      duration: duration,
      isDismissible: isDismissible,
    );
  }

  /// Show an error snackbar with a red theme
  static void error({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackPosition position = SnackPosition.TOP,
    bool isDismissible = true,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      backgroundColor: AppColors.errorColor,
      textColor: AppColors.white,
      icon: const Icon(
        Icons.error_outline,
        color: AppColors.white,
        size: 28,
      ),
      duration: duration,
      isDismissible: isDismissible,
    );
  }

  /// Show a warning snackbar with an orange theme
  static void warning({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
    bool isDismissible = true,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      backgroundColor: AppColors.warningColor,
      textColor: AppColors.textPrimary,
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.textPrimary,
        size: 28,
      ),
      duration: duration,
      isDismissible: isDismissible,
    );
  }

  /// Show an info snackbar with a blue theme
  static void info({
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
    bool isDismissible = true,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      backgroundColor: AppColors.infoColor,
      textColor: AppColors.textOnBrand,
      icon: const Icon(
        Icons.info_outline,
        color: AppColors.textOnBrand,
        size: 28,
      ),
      duration: duration,
      isDismissible: isDismissible,
    );
  }

  /// Show a custom snackbar with full customization
  static void custom({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 3),
    SnackPosition position = SnackPosition.TOP,
    bool isDismissible = true,
    bool showCloseButton = true,
    Widget? customIcon,
    VoidCallback? onTap,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      backgroundColor: backgroundColor ?? AppColors.baseColor,
      textColor: textColor ?? AppColors.textOnBase,
      icon: customIcon ??
          (icon != null
              ? Icon(
                  icon,
                  color: iconColor ?? AppColors.textOnBase,
                  size: 28,
                )
              : null),
      duration: duration,
      isDismissible: isDismissible,
      showCloseButton: showCloseButton,
      onTap: onTap,
    );
  }

  /// Show a loading snackbar (stays until manually dismissed)
  static void loading({
    String title = 'Loading',
    String message = 'Please wait...',
    SnackPosition position = SnackPosition.TOP,
  }) {
    _show(
      title: title,
      message: message,
      position: position,
      backgroundColor: AppColors.baseColor,
      textColor: AppColors.textOnBase,
      icon: const SizedBox(
        width: 28,
        height: 28,
        child: LoadingGif(
          width: 28,
          height: 28,
        ),
      ),
      shouldIconPulse: false,
      duration: const Duration(days: 1),
      isDismissible: false,
      showProgressIndicator: false,
      showCloseButton: false,
    );
  }

  /// Close the current snackbar
  static void close() {
    if (kIsWeb) {
      final context = Get.context;
      if (context != null) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.hideCurrentSnackBar();
        messenger?.hideCurrentMaterialBanner();
      }
    }

    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
  }

  /// Close all snackbars
  static void closeAll() {
    if (kIsWeb) {
      final context = Get.context;
      if (context != null) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.clearSnackBars();
        messenger?.hideCurrentMaterialBanner();
      }
    }

    Get.closeAllSnackbars();
  }
}
