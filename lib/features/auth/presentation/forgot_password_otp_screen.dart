import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/features/auth/controller/auth_controller_getx.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/features/auth/presentation/widgets/auth_card.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key});

  @override
  State<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  late String _phone;
  String? _email;
  late String _deliveryMethod;
  int _resendCountdown = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<AuthControllerGetX>()) {
      Get.put(AuthControllerGetX(), permanent: false);
    }

    // Get phone from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    _phone = args?['phone'] ?? '';
    _email = args?['email'] as String?;
    _deliveryMethod =
        args?['deliveryMethod'] ?? (_email != null ? 'email' : 'phone');

    _startResendTimer();
  }

  String get _recipient =>
      _deliveryMethod == 'email' ? (_email ?? _phone) : _phone;

  bool get _usesEmail =>
      _deliveryMethod == 'email' && _email != null && _email!.isNotEmpty;

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 60;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyOtp() async {
    final authController = Get.find<AuthControllerGetX>();

    if (_formKey.currentState!.validate()) {
      final otp = _otpControllers.map((c) => c.text).join();

      if (otp.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)
                      .translate('pleaseEnterCompleteOTP') ??
                  'Please enter complete OTP',
            ),
          ),
        );
        return;
      }

      try {
        final resetToken = await authController.verifyPasswordResetOtp(
          phone: _usesEmail ? null : _phone,
          email: _usesEmail ? _email : null,
          otp: otp,
        );

        // Navigate to reset password screen
        Get.toNamed(
          Routes.forgotPasswordReset,
          arguments: {
            'resetToken': resetToken,
            'phone': _phone,
            'email': _usesEmail ? _email : null,
            'deliveryMethod': _deliveryMethod,
          },
        );
      } catch (e) {
        // Error already shown in controller
      }
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend) return;

    final authController = Get.find<AuthControllerGetX>();

    try {
      await authController.requestPasswordResetOtp(
        phone: _usesEmail ? null : _phone,
        email: _usesEmail ? _email : null,
      );
      _startResendTimer();
    } catch (e) {
      // Error already shown in controller
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthControllerGetX>();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final safeHeight = size.height - padding.top - padding.bottom;
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
          AppLocalizations.of(context).translate('verifyOTP') ?? 'Verify OTP',
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
                        Icons.verified_user_outlined,
                        size: isTinyScreen ? 28 : 34,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: safeHeight * 0.025),
                  // Title
                  Text(
                    AppLocalizations.of(context)
                            .translate('enterVerificationCode') ??
                        'Enter Verification Code',
                    style: GoogleFonts.poppins(
                      fontSize: isTinyScreen ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: safeHeight * 0.015),
                  // Description
                  Text(
                    AppLocalizations.of(context).translate('otpSentTo') ??
                        'We sent a code to',
                    style: GoogleFonts.poppins(
                      fontSize: isTinyScreen ? 12 : 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: safeHeight * 0.01),
                  Text(
                    _recipient,
                    style: GoogleFonts.poppins(
                      fontSize: isTinyScreen ? 13 : 15,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: safeHeight * 0.05),
                  // OTP Input
                  Form(
                    key: _formKey,
                    child: Row(
                      children: List.generate(
                        6,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: index < 5 ? (isTinyScreen ? 6 : 8) : 0,
                            ),
                            child: _buildOtpField(
                              index,
                              isTinyScreen: isTinyScreen,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: safeHeight * 0.04),
                  // Resend OTP
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)
                                .translate('didntReceiveCode') ??
                            "Didn't receive code?",
                        style: GoogleFonts.poppins(
                          fontSize: isTinyScreen ? 12 : 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      TextButton(
                        onPressed: _canResend ? _resendOtp : null,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTinyScreen ? 8 : 12,
                            vertical: 4,
                          ),
                        ),
                        child: Text(
                          _canResend
                              ? AppLocalizations.of(context)
                                      .translate('resend') ??
                                  'Resend'
                              : '${AppLocalizations.of(context).translate('resendIn') ?? 'Resend in'} ${_resendCountdown}s',
                          style: GoogleFonts.poppins(
                            fontSize: isTinyScreen ? 12 : 14,
                            color: _canResend
                                ? AppColors.brandBlue
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: safeHeight * 0.04),
                  // Verify Button
                  Obx(
                    () => SizedBox(
                      height: isTinyScreen ? 42 : 50,
                      child: ElevatedButton(
                        onPressed: authController.isLoading ? null : _verifyOtp,
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
                                        .translate('verify') ??
                                    'Verify',
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

  Widget _buildOtpField(int index, {required bool isTinyScreen}) {
    return SizedBox(
      height: isTinyScreen ? 50 : 60,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: TextStyle(
          fontSize: isTinyScreen ? 18 : 24,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
            borderSide: BorderSide(
              color: AppColors.borderColor,
              width: 1.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
            borderSide: BorderSide(
              color: AppColors.borderColor,
              width: 1.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isTinyScreen ? 8 : 12),
            borderSide: BorderSide(
              color: AppColors.brandBlue,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: AppColors.surfaceColor,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          } else if (value.isNotEmpty && index == 5) {
            _focusNodes[index].unfocus();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}
