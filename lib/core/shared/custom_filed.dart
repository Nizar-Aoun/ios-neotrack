import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final String? initialValue;

  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final bool readOnly;
  final bool enabled;

  final TextDirection? textDirection;
  final TextAlign textAlign;

  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;

  final Widget? prefixIcon;
  final IconData? prefixIconData;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final Color? fillColor;
  final Color? focusedBorderColor;
  final Color? enabledBorderColor;
  final Color? errorBorderColor;
  final Color? cursorColor;
  final double borderRadius;
  final bool filled;
  final bool showCounter;
  final EdgeInsetsGeometry? contentPadding;

  // Password field
  final bool isPassword;
  final bool showPasswordToggle;

  // Number field
  final bool isNumber;
  final bool allowDecimals;
  final bool allowNegative;

  // Email field
  final bool isEmail;

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.readOnly = false,
    this.enabled = true,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.validator,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.prefixIcon,
    this.prefixIconData,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.fillColor,
    this.focusedBorderColor,
    this.enabledBorderColor,
    this.errorBorderColor,
    this.cursorColor,
    this.borderRadius = 8.0,
    this.filled = true,
    this.showCounter = false,
    this.contentPadding,
    this.isPassword = false,
    this.showPasswordToggle = true,
    this.isNumber = false,
    this.allowDecimals = false,
    this.allowNegative = false,
    this.isEmail = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;
  late FocusNode _focusNode;
  String? _currentError;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && widget.validator != null) {
      setState(() {
        _currentError = widget.validator!(widget.controller?.text);
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  List<TextInputFormatter> _buildInputFormatters() {
    List<TextInputFormatter> formatters = [];

    // Add custom formatters first
    if (widget.inputFormatters != null) {
      formatters.addAll(widget.inputFormatters!);
    }

    // Number formatters
    if (widget.isNumber) {
      if (widget.allowDecimals) {
        if (widget.allowNegative) {
          formatters.add(
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
          );
        } else {
          formatters.add(
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          );
        }
      } else {
        if (widget.allowNegative) {
          formatters.add(
            FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
          );
        } else {
          formatters.add(FilteringTextInputFormatter.digitsOnly);
        }
      }
    }

    // Email formatters (remove spaces)
    if (widget.isEmail) {
      formatters.add(
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      );
    }

    // Max length formatter
    if (widget.maxLength != null && !widget.showCounter) {
      formatters.add(LengthLimitingTextInputFormatter(widget.maxLength));
    }

    return formatters;
  }

  TextInputType _getKeyboardType() {
    if (widget.isNumber) {
      return widget.allowDecimals
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.number;
    }
    if (widget.isEmail) {
      return TextInputType.emailAddress;
    }
    if (widget.isPassword) {
      return TextInputType.visiblePassword;
    }
    // For multiline fields with newline action, use multiline keyboard type
    if (widget.maxLines != null &&
        widget.maxLines! > 1 &&
        widget.textInputAction == TextInputAction.newline) {
      return TextInputType.multiline;
    }
    return widget.keyboardType;
  }

  String? _getValidationError(String? value) {
    // Use custom validator if provided
    if (widget.validator != null) {
      return widget.validator!(value);
    }

    // Email validation
    if (widget.isEmail && value != null && value.isNotEmpty) {
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    // Number validation
    if (widget.isNumber && value != null && value.isNotEmpty) {
      final number = double.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      if (!widget.allowNegative && number < 0) {
        return 'Negative numbers are not allowed';
      }
    }

    return null;
  }

  Widget? _buildSuffixIcon() {
    // Password visibility toggle
    if (widget.isPassword && widget.showPasswordToggle) {
      return IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
          size: 22,
        ),
        onPressed: _togglePasswordVisibility,
        tooltip: _obscureText ? 'Show password' : 'Hide password',
      );
    }

    // Custom suffix icon
    if (widget.suffixIcon != null) {
      return widget.suffixIcon;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text Field (styled to match provided design)
        Builder(builder: (context) {
          final width = MediaQuery.of(context).size.width;
          // Reasonable breakpoints (assumption): tiny < 360, small < 420
          final isTinyScreen = width < 360;
          final isSmallScreen = width >= 360 && width < 420;

          // build a responsive prefix icon if IconData is provided
          Widget? builtPrefix;
          if (widget.prefixIcon != null) {
            builtPrefix = widget.prefixIcon;
          } else if (widget.prefixIconData != null) {
            builtPrefix = Icon(
              widget.prefixIconData,
              color: AppColors.textSecondary,
              size: isTinyScreen
                  ? 14
                  : isSmallScreen
                      ? 16
                      : 24,
            );
          } else {
            builtPrefix = null;
          }

          return TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            focusNode: _focusNode,
            keyboardType: _getKeyboardType(),
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            minLines: widget.minLines,
            maxLength: widget.showCounter ? widget.maxLength : null,
            obscureText: _obscureText,
            autocorrect: widget.autocorrect,
            enableSuggestions: widget.enableSuggestions,
            readOnly: widget.readOnly,
            enabled: widget.enabled,
            textDirection: widget.textDirection,
            textAlign: widget.textAlign,
            inputFormatters: _buildInputFormatters(),
            cursorColor: widget.cursorColor ?? AppColors.brandBlue,
            style: TextStyle(
              fontSize: isTinyScreen
                  ? 14
                  : isSmallScreen
                      ? 16
                      : 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: widget.enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            onChanged: (value) {
              if (widget.onChanged != null) widget.onChanged!(value);
              if (_currentError != null) {
                setState(() => _currentError = null);
              }
            },
            onFieldSubmitted: widget.onSubmitted,
            onTap: widget.onTap,
            validator: widget.validator ?? _getValidationError,
            decoration: InputDecoration(
              labelText: widget.labelText ?? widget.labelText,
              hintText: widget.hintText,
              errorText: widget.errorText,
              labelStyle: TextStyle(
                fontSize: isTinyScreen
                    ? 13
                    : isSmallScreen
                        ? 15
                        : 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              floatingLabelStyle: TextStyle(
                fontSize: isTinyScreen
                    ? 15
                    : isSmallScreen
                        ? 17
                        : 20,
                fontWeight: FontWeight.w700,
                color: AppColors.brandBlue,
              ),
              hintStyle: TextStyle(
                fontSize: isTinyScreen
                    ? 13
                    : isSmallScreen
                        ? 15
                        : 18,
                fontWeight: FontWeight.w400,
                color: AppColors.textTertiary,
              ),
              prefixIcon: builtPrefix,
              suffixIcon: _buildSuffixIcon() ?? widget.suffixIcon,
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              errorStyle: TextStyle(
                fontSize: isTinyScreen
                    ? 11
                    : isSmallScreen
                        ? 13
                        : 16,
                fontWeight: FontWeight.w400,
                color: AppColors.errorColor,
              ),
              contentPadding: widget.contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: isTinyScreen
                        ? 8
                        : isSmallScreen
                            ? 10
                            : 16,
                    vertical: isTinyScreen
                        ? 8
                        : isSmallScreen
                            ? 10
                            : 16,
                  ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTinyScreen
                    ? 8
                    : isSmallScreen
                        ? 10
                        : 16),
                borderSide: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTinyScreen
                    ? 8
                    : isSmallScreen
                        ? 10
                        : 16),
                borderSide: BorderSide(
                  color: AppColors.borderColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTinyScreen
                    ? 8
                    : isSmallScreen
                        ? 10
                        : 16),
                borderSide: BorderSide(
                  color: AppColors.brandBlue,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTinyScreen
                    ? 8
                    : isSmallScreen
                        ? 10
                        : 16),
                borderSide: BorderSide(
                  color: AppColors.errorColor.withOpacity(0.6),
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(isTinyScreen
                    ? 8
                    : isSmallScreen
                        ? 10
                        : 16),
                borderSide: BorderSide(
                  color: AppColors.errorColor,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColors.cardColor,
            ),
          );
        }),
      ],
    );
  }
}

/// Preset configurations for common use cases
class CustomTextFieldPresets {
  /// Email field with validation
  static CustomTextField email({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      labelText: labelText ?? 'Email',
      hintText: hintText ?? 'example@email.com',
      errorText: errorText,
      isEmail: true,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.email_outlined),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }

  /// Password field with visibility toggle
  static CustomTextField password({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      labelText: labelText ?? 'Password',
      hintText: hintText ?? '••••••••',
      errorText: errorText,
      isPassword: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      prefixIcon: const Icon(Icons.lock_outline),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }

  /// Phone number field
  static CustomTextField phone({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      labelText: labelText ?? 'Phone Number',
      hintText: hintText ?? '+1 234 567 8900',
      errorText: errorText,
      isNumber: true,
      allowNegative: false,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.phone_outlined),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }

  /// Number field (integer)
  static CustomTextField number({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    bool allowNegative = false,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? '0',
      errorText: errorText,
      isNumber: true,
      allowDecimals: false,
      allowNegative: allowNegative,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }

  /// Decimal number field
  static CustomTextField decimal({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    bool allowNegative = false,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      labelText: labelText,
      hintText: hintText ?? '0.00',
      errorText: errorText,
      isNumber: true,
      allowDecimals: true,
      allowNegative: allowNegative,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
    );
  }

  /// Search field
  static CustomTextField search({
    Key? key,
    TextEditingController? controller,
    String? hintText,
    void Function(String)? onChanged,
    void Function(String)? onSubmitted,
    VoidCallback? onClear,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      hintText: hintText ?? 'Search...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }

  /// Multi-line text area
  static CustomTextField textArea({
    Key? key,
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    String? errorText,
    int maxLines = 5,
    int? maxLength,
    bool showCounter = false,
    void Function(String)? onChanged,
    bool enabled = true,
  }) {
    return CustomTextField(
      key: key,
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      errorText: errorText,
      maxLines: maxLines,
      minLines: 3,
      maxLength: maxLength,
      showCounter: showCounter,
      textInputAction: TextInputAction.newline,
      onChanged: onChanged,
      enabled: enabled,
    );
  }
}
