import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/features/auth/controller/auth_controller_getx.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/features/auth/presentation/widgets/auth_card.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  const ForgotPasswordResetScreen({super.key});

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late String _resetToken;
  late String _phone;
  String? _email;
  late String _deliveryMethod;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AuthControllerGetX>()) {
      Get.put(AuthControllerGetX(), permanent: false);
    }

    // Get reset token from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    _resetToken = args?['resetToken'] ?? '';
    _phone = args?['phone'] ?? '';
    _email = args?['email'] as String?;
    _deliveryMethod =
        args?['deliveryMethod'] ?? (_email != null ? 'email' : 'phone');
  }

  bool _validatePassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasMinLength && hasLetter && hasNumber;
  }

  bool get _usesEmail =>
      _deliveryMethod == 'email' && _email != null && _email!.isNotEmpty;

  Future<void> _resetPassword() async {
    final authController = Get.find<AuthControllerGetX>();

    if (_formKey.currentState!.validate()) {
      try {
        await authController.resetPasswordWithToken(
          phone: _usesEmail ? null : _phone,
          email: _usesEmail ? _email : null,
          resetToken: _resetToken,
          newPassword: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
        );

        // Navigate back to login screen
        Get.offAllNamed(Routes.login);
      } catch (e) {
        // Error already shown in controller
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthControllerGetX>();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final safeHeight = size.height - padding.top - padding.bottom;
    final isSmallScreen = safeHeight < 650;
    final isTinyScreen = safeHeight < 450;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.primaryColor,
            size: isTinyScreen ? 20 : 24,
          ),
          onPressed: () => Get.offAllNamed(Routes.login),
        ),
        title: Text(
          AppLocalizations.of(context).translate('resetPassword') ??
              'Reset Password',
          style: GoogleFonts.poppins(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: isTinyScreen ? 16 : 18,
          ),
        ),
      ),
      body: SafeArea(
        top: true,
        bottom: true,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(bottom: viewInsetsBottom),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTinyScreen ? 16 : 24,
              vertical: isTinyScreen ? 12 : 20,
            ),
            child: AuthCard(
              padding: EdgeInsets.all(isTinyScreen ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Center(
                    child: Container(
                      width: isTinyScreen ? 56 : 68,
                      height: isTinyScreen ? 56 : 68,
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock_reset,
                        size: isTinyScreen ? 28 : 34,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: safeHeight * 0.025),
                  // Title
                  Text(
                    AppLocalizations.of(context)
                            .translate('createNewPassword') ??
                        'Create New Password',
                    style: GoogleFonts.poppins(
                      fontSize: isTinyScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: safeHeight * 0.015),
                  // Description
                  Text(
                    AppLocalizations.of(context)
                            .translate('passwordRequirements') ??
                        'Your password must be at least 8 characters long and contain both letters and numbers.',
                    style: GoogleFonts.poppins(
                      fontSize: isTinyScreen ? 12 : 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: safeHeight * 0.05),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildResponsiveTextField(
                          controller: _passwordController,
                          label: AppLocalizations.of(context)
                                  .translate('newPassword') ??
                              'New Password',
                          hint: AppLocalizations.of(context)
                                  .translate('enterNewPassword') ??
                              'Enter your new password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textSecondary,
                              size: isTinyScreen ? 16 : 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                      .translate('pleaseEnterPassword') ??
                                  'Please enter a password';
                            }
                            if (!_validatePassword(value)) {
                              return AppLocalizations.of(context)
                                      .translate('passwordMustMeet') ??
                                  'Password must be at least 8 characters with letters and numbers';
                            }
                            return null;
                          },
                          isTinyScreen: isTinyScreen,
                          isSmallScreen: isSmallScreen,
                        ),
                        SizedBox(height: safeHeight * 0.02),
                        _buildResponsiveTextField(
                          controller: _confirmPasswordController,
                          label: AppLocalizations.of(context)
                                  .translate('confirmPassword') ??
                              'Confirm Password',
                          hint: AppLocalizations.of(context)
                                  .translate('reenterPassword') ??
                              'Re-enter your password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.textSecondary,
                              size: isTinyScreen ? 16 : 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)
                                      .translate('pleaseConfirmPassword') ??
                                  'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return AppLocalizations.of(context)
                                      .translate('passwordsDoNotMatch') ??
                                  'Passwords do not match';
                            }
                            return null;
                          },
                          isTinyScreen: isTinyScreen,
                          isSmallScreen: isSmallScreen,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: safeHeight * 0.04),
                  // Password Requirements
                  Container(
                    padding: EdgeInsets.all(isTinyScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius:
                          BorderRadius.circular(isTinyScreen ? 8 : 12),
                      border: Border.all(
                        color: AppColors.borderColor,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)
                                  .translate('passwordMustContain') ??
                              'Password must contain:',
                          style: GoogleFonts.poppins(
                            fontSize: isTinyScreen ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildRequirement(
                          AppLocalizations.of(context)
                                  .translate('passwordRuleMinLength') ??
                              '• At least 8 characters',
                          _passwordController.text.length >= 8,
                          isTinyScreen: isTinyScreen,
                        ),
                        _buildRequirement(
                          AppLocalizations.of(context)
                                  .translate('passwordRuleLetters') ??
                              '• Contains letters (a-z, A-Z)',
                          _passwordController.text
                              .contains(RegExp(r'[a-zA-Z]')),
                          isTinyScreen: isTinyScreen,
                        ),
                        _buildRequirement(
                          AppLocalizations.of(context)
                                  .translate('passwordRuleNumbers') ??
                              '• Contains numbers (0-9)',
                          _passwordController.text.contains(RegExp(r'[0-9]')),
                          isTinyScreen: isTinyScreen,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: safeHeight * 0.04),
                  // Reset Button
                  Obx(
                    () => SizedBox(
                      height: isTinyScreen ? 42 : 50,
                      child: ElevatedButton(
                        onPressed:
                            authController.isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBg,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              isTinyScreen ? 8 : 12,
                            ),
                          ),
                          elevation: 2,
                          disabledBackgroundColor:
                              AppColors.buttonBg.withOpacity(0.6),
                        ),
                        child: authController.isLoading
                            ? SizedBox(
                                height: isTinyScreen ? 16 : 20,
                                width: isTinyScreen ? 16 : 20,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                AppLocalizations.of(context)
                                        .translate('resetPassword') ??
                                    'Reset Password',
                                style: GoogleFonts.poppins(
                                  fontSize: isTinyScreen ? 13 : 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: isTinyScreen ? 4 : 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isMet,
      {required bool isTinyScreen}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: isTinyScreen ? 14 : 16,
            color: isMet ? AppColors.successColor : AppColors.textTertiary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: isTinyScreen ? 10 : 12,
                color: isMet ? AppColors.successColor : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    required bool isSmallScreen,
    required bool isTinyScreen,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      onChanged: (value) {
        // Trigger rebuild to update requirement indicators
        setState(() {});
      },
      style: TextStyle(
        fontSize: isTinyScreen
            ? 11
            : isSmallScreen
                ? 13
                : 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: isTinyScreen ? 10 : 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontSize: isTinyScreen ? 10 : 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.textSecondary,
          size: isTinyScreen ? 16 : 20,
        ),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        errorStyle: TextStyle(
          fontSize: isTinyScreen ? 9 : 10,
          fontWeight: FontWeight.w400,
          color: AppColors.errorColor,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTinyScreen ? 12 : 16,
          vertical: isTinyScreen ? 12 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
          borderSide: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
          borderSide: BorderSide(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
          borderSide: BorderSide(
            color: AppColors.brandBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
          borderSide: BorderSide(
            color: AppColors.errorColor.withOpacity(0.6),
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
          borderSide: BorderSide(
            color: AppColors.errorColor,
            width: 1.5,
          ),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
      validator: validator,
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
