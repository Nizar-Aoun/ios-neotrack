import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import '../../l10n/app_localizations.dart';

class CustomElevatedButton extends StatefulWidget {
  // Core properties
  final VoidCallback? onPressed;
  final Widget child;
  final String? text;
  final String? textKey; // Localization key
  final IconData? icon;
  final IconData? trailingIcon;

  // Styling
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledBackgroundColor;
  final Color? disabledForegroundColor;
  final double? elevation;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final BorderSide? borderSide;

  // Loading state
  final bool isLoading;
  final String? loadingText;
  final Widget? loadingWidget;

  // Animation and interaction
  final Duration animationDuration;
  final bool enableHapticFeedback;
  final bool enableSplash;
  final bool enableElevationAnimation;

  // Accessibility
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  const CustomElevatedButton({
    super.key,
    this.onPressed,
    this.child = const SizedBox.shrink(),
    this.text,
    this.textKey,
    this.icon,
    this.trailingIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledBackgroundColor,
    this.disabledForegroundColor,
    this.elevation,
    this.borderRadius = 12.0,
    this.padding,
    this.width,
    this.height,
    this.borderSide,
    this.isLoading = false,
    this.loadingText,
    this.loadingWidget,
    this.animationDuration = const Duration(milliseconds: 200),
    this.enableHapticFeedback = true,
    this.enableSplash = true,
    this.enableElevationAnimation = true,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  }) : assert(
          child != const SizedBox.shrink() ||
              text != null ||
              textKey != null ||
              icon != null,
          'Either child, text, textKey, or icon must be provided',
        );

  @override
  State<CustomElevatedButton> createState() => _CustomElevatedButtonState();
}

class _CustomElevatedButtonState extends State<CustomElevatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) * 0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? _getDisplayText(BuildContext context) {
    if (widget.text != null) {
      return widget.text;
    }
    if (widget.textKey != null) {
      try {
        return AppLocalizations.of(context).translate(widget.textKey!);
      } catch (e) {
        // Fallback to the key if localization fails
        return widget.textKey;
      }
    }
    return null;
  }

  Widget _buildContent(BuildContext context) {
    if (widget.isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: widget.loadingWidget ??
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.textOnBase),
                ),
          ),
          if (widget.loadingText != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.loadingText!,
                style: AppTextStyles.buttonText.copyWith(
                  color: widget.foregroundColor ?? AppColors.textOnBase,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      );
    }

    final children = <Widget>[];

    if (widget.icon != null) {
      children.add(Icon(widget.icon, size: 20));
      if (widget.text != null || widget.trailingIcon != null) {
        children.add(const SizedBox(width: 8));
      }
    }

    if (_getDisplayText(context) != null) {
      children.add(Flexible(
        child: Text(
          _getDisplayText(context)!,
          style: AppTextStyles.buttonText.copyWith(
            color: widget.foregroundColor ?? AppColors.textOnBase,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    if (widget.trailingIcon != null) {
      if (widget.text != null || widget.icon != null) {
        children.add(const SizedBox(width: 8));
      }
      children.add(Icon(widget.trailingIcon, size: 20));
    }

    if (children.isEmpty) {
      return widget.child;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    final backgroundColor = isEnabled
        ? widget.backgroundColor ?? AppColors.buttonBg
        : widget.disabledBackgroundColor ?? AppColors.surfaceColor;

    final foregroundColor = isEnabled
        ? widget.foregroundColor ?? AppColors.textOnBase
        : widget.disabledForegroundColor ?? AppColors.textSecondary;

    return Semantics(
      label: widget.semanticLabel ?? _getDisplayText(context) ?? widget.textKey,
      button: true,
      enabled: isEnabled,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale:
                widget.enableElevationAnimation ? _scaleAnimation.value : 1.0,
            child: ElevatedButton(
              onPressed: widget.isLoading ? null : widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                elevation: widget.enableElevationAnimation
                    ? _elevationAnimation.value
                    : widget.elevation ?? 2.0,
                shadowColor: Colors.black.withOpacity(0.2),
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: widget.width != null || widget.height != null
                    ? Size(widget.width ?? 0, widget.height ?? 48)
                    : const Size(0, 48),
                maximumSize: widget.width != null || widget.height != null
                    ? Size(widget.width ?? double.infinity, widget.height ?? 48)
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  side: widget.borderSide ?? BorderSide.none,
                ),
                animationDuration: widget.animationDuration,
                enableFeedback: widget.enableHapticFeedback,
                splashFactory: widget.enableSplash
                    ? InkRipple.splashFactory
                    : NoSplash.splashFactory,
              ).copyWith(
                elevation: MaterialStateProperty.resolveWith<double>(
                  (states) {
                    if (states.contains(MaterialState.pressed)) {
                      return (widget.elevation ?? 2.0) * 0.5;
                    }
                    if (states.contains(MaterialState.disabled)) {
                      return 0;
                    }
                    return widget.enableElevationAnimation
                        ? _elevationAnimation.value
                        : widget.elevation ?? 2.0;
                  },
                ),
              ),
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              child: _buildContent(context),
            ),
          );
        },
      ),
    );
  }
}

/// Preset configurations for common button styles
class CustomElevatedButtonPresets {
  /// Primary action button (filled)
  static CustomElevatedButton primary({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    IconData? trailingIcon,
    bool isLoading = false,
    String? loadingText,
    double? width,
    bool enableElevationAnimation = true,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      backgroundColor: AppColors.buttonBg,
      elevation: 4.0,
      enableElevationAnimation: enableElevationAnimation,
    );
  }

  /// Brand-specific action button (blue accent).
  static CustomElevatedButton brand({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    IconData? trailingIcon,
    bool isLoading = false,
    String? loadingText,
    double? width,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      backgroundColor: AppColors.brandBlue,
      foregroundColor: AppColors.textOnBrand,
      elevation: 2,
    );
  }

  /// Secondary action button (outlined style)
  static CustomElevatedButton secondary({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    IconData? trailingIcon,
    bool isLoading = false,
    String? loadingText,
    double? width,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      backgroundColor: AppColors.cardColor,
      foregroundColor: AppColors.buttonBg,
      borderSide: const BorderSide(color: AppColors.buttonBg, width: 1.5),
      elevation: 0,
      enableElevationAnimation: false,
    );
  }

  /// Success button (green)
  static CustomElevatedButton success({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    IconData? trailingIcon,
    bool isLoading = false,
    String? loadingText,
    double? width,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      backgroundColor: AppColors.successColor,
      elevation: 4.0,
    );
  }

  /// Danger button (red)
  static CustomElevatedButton danger({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    IconData? trailingIcon,
    bool isLoading = false,
    String? loadingText,
    double? width,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      backgroundColor: AppColors.errorColor,
      elevation: 4.0,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  /// Warning button (orange)
  static CustomElevatedButton warning({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    IconData? trailingIcon,
    bool isLoading = false,
    String? loadingText,
    double? width,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      trailingIcon: trailingIcon,
      isLoading: isLoading,
      loadingText: loadingText,
      width: width,
      backgroundColor: AppColors.warningColor,
      foregroundColor: AppColors.textPrimary,
      elevation: 4.0,
    );
  }

  /// Icon-only button
  static CustomElevatedButton icon({
    Key? key,
    required VoidCallback onPressed,
    required IconData icon,
    bool isLoading = false,
    String? loadingText,
    Color? backgroundColor,
    double size = 48.0,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      loadingText: loadingText,
      backgroundColor: backgroundColor ?? AppColors.surfaceColor,
      foregroundColor: AppColors.textPrimary,
      width: size,
      height: size,
      padding: EdgeInsets.zero,
      borderRadius: size / 2, // Make it circular
      elevation: 2.0,
    );
  }

  /// Small button variant
  static CustomElevatedButton small({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    bool isLoading = false,
    String? loadingText,
    Color? backgroundColor,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      isLoading: isLoading,
      loadingText: loadingText,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 8.0,
      elevation: 2.0,
    );
  }

  /// Large button variant
  static CustomElevatedButton large({
    Key? key,
    required VoidCallback onPressed,
    required String text,
    IconData? icon,
    bool isLoading = false,
    String? loadingText,
    Color? backgroundColor,
  }) {
    return CustomElevatedButton(
      key: key,
      onPressed: onPressed,
      text: text,
      icon: icon,
      isLoading: isLoading,
      loadingText: loadingText,
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      borderRadius: 16.0,
      elevation: 6.0,
    );
  }
}
