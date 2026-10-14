import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/features/auth/controller/auth_controller_getx.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/features/auth/presentation/widgets/auth_card.dart';

class ForgotPasswordPhoneScreen extends StatefulWidget {
  const ForgotPasswordPhoneScreen({super.key});

  @override
  State<ForgotPasswordPhoneScreen> createState() =>
      _ForgotPasswordPhoneScreenState();
}

class _ForgotPasswordPhoneScreenState extends State<ForgotPasswordPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AuthControllerGetX>()) {
      Get.put(AuthControllerGetX(), permanent: false);
    }
  }

  Future<void> _requestOtp() async {
    final authController = Get.find<AuthControllerGetX>();

    if (_formKey.currentState!.validate()) {
      try {
        final phone = _phoneController.text;
        final email = await authController.checkPasswordResetIdentifier(phone);

        final deliveryMethod =
            email != null ? await _showDeliveryChoiceDialog(email) : 'phone';

        if (deliveryMethod == null) {
          return;
        }

        if (deliveryMethod == 'email') {
          await authController.requestPasswordResetOtp(email: email);
        } else {
          await authController.requestPasswordResetOtp(phone: phone);
        }

        // Navigate to OTP screen
        Get.toNamed(
          Routes.forgotPasswordOtp,
          arguments: {
            'phone': phone,
            'email': deliveryMethod == 'email' ? email : null,
            'deliveryMethod': deliveryMethod,
          },
        );
      } catch (e) {
        // Error already shown in controller
      }
    }
  }

  Future<String?> _showDeliveryChoiceDialog(String email) async {
    return Get.dialog<String>(
      AlertDialog(
        title: Text(
          AppLocalizations.of(context).translate('forgotPassword') ??
              'Forgot Password',
        ),
        content: Text(
          'We found $email for this account. Choose how you want to receive the OTP.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: 'phone'),
            child: Text(
              AppLocalizations.of(context).translate('sendOTP') ?? 'SMS OTP',
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'email'),
            child: Text(
              AppLocalizations.of(context).translate('email') ?? 'Email',
            ),
          ),
        ],
      ),
    );
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).translate('forgotPassword') ??
              'Forgot Password',
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
                        Icons.phone_android,
                        size: isTinyScreen ? 28 : 34,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: safeHeight * 0.025),
                  // Title
                  Text(
                    AppLocalizations.of(context)
                            .translate('enterPhoneNumber') ??
                        'Enter Phone Number',
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
                            .translate('forgotPasswordDescription') ??
                        'We will send you an OTP to verify your phone number',
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
                    child: _buildResponsiveTextField(
                      controller: _phoneController,
                      label:
                          AppLocalizations.of(context).translate('phoneNumber'),
                      hint:
                          AppLocalizations.of(context).translate('enterPhone'),
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)
                              .translate('pleaseEnterPhone');
                        }
                        if (value.length != 8) {
                          return AppLocalizations.of(context)
                              .translate('phoneNumberMustBe8Digits');
                        }
                        return null;
                      },
                      isTinyScreen: isTinyScreen,
                      isSmallScreen: isSmallScreen,
                    ),
                  ),
                  SizedBox(height: safeHeight * 0.04),
                  // Submit Button
                  Obx(
                    () => SizedBox(
                      height: isTinyScreen ? 42 : 50,
                      child: ElevatedButton(
                        onPressed:
                            authController.isLoading ? null : _requestOtp,
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
                                        .translate('sendOTP') ??
                                    'Send OTP',
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

  Widget _buildResponsiveTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required bool isSmallScreen,
    required bool isTinyScreen,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
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
    _phoneController.dispose();
    super.dispose();
  }
}
