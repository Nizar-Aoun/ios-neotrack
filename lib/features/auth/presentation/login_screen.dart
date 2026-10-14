import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/features/auth/controller/auth_controller_getx.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/core/controllers/language_controller.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/features/auth/presentation/widgets/auth_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedPrivacyPolicy = false;

  @override
  void initState() {
    super.initState();
    // Ensure AuthControllerGetX is available
    // This is a safety check in case we navigate here without going through the route
    if (!Get.isRegistered<AuthControllerGetX>()) {
      Get.put(AuthControllerGetX(), permanent: false);
    }
  }

  Future<void> _login() async {
    final authController = Get.find<AuthControllerGetX>();

    // Clear previous error message
    authController.clearError();

    if (_formKey.currentState!.validate()) {
      if (!_acceptedPrivacyPolicy) {
        CustomSnackBar.error(
          title: AppLocalizations.of(context).translate('error'),
          message: AppLocalizations.of(context).translate('mustAcceptPrivacy'),
        );
        return;
      }
      await authController.login(
        phone: _phoneController.text,
        password: _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthControllerGetX>();
    final languageController = Get.find<LanguageController>();
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final safeHeight = size.height - padding.top - padding.bottom;
    final isSmallScreen = safeHeight < 650;
    final isTinyScreen = safeHeight < 450;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        // If keyboard is open, close it and don't pop the route
        if (FocusManager.instance.primaryFocus?.hasFocus ?? false) {
          FocusManager.instance.primaryFocus?.unfocus();
          return false;
        }
        // Prevent going back when not authenticated
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.surfaceColor,
        body: SafeArea(
          top: true,
          bottom: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: isTinyScreen ? 2 : 4,
                      right: isTinyScreen ? 6 : 10,
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: _buildLanguageSelector(languageController,
                          constraints, isSmallScreen, isTinyScreen),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTinyScreen
                            ? 6
                            : isSmallScreen
                                ? 8
                                : 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: isTinyScreen ? 2 : 4),
                          AuthCard(
                            padding: EdgeInsets.all(
                              isTinyScreen
                                  ? 14
                                  : isSmallScreen
                                      ? 18
                                      : 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: SizedBox(
                                    width: constraints.maxWidth *
                                        (isTinyScreen
                                            ? 0.32
                                            : isSmallScreen
                                                ? 0.38
                                                : 0.45),
                                    height: (constraints.maxWidth *
                                            (isTinyScreen
                                                ? 0.32
                                                : isSmallScreen
                                                    ? 0.38
                                                    : 0.45)) *
                                        0.5,
                                    child: Image.asset(
                                      'assets/images/neos_track_hor.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: isTinyScreen ? 8 : 14,
                                ),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('welcome'),
                                  style: GoogleFonts.barlow(
                                    fontSize: isTinyScreen ? 18 : 20,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)
                                      .translate('continue'),
                                  style: GoogleFonts.barlow(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                SizedBox(height: availableHeight * 0.025),
                                _buildLoginForm(
                                  context,
                                  authController,
                                  availableHeight,
                                  isSmallScreen,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            bottom: padding.bottom + 8,
            top: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'POWERED BY',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'Arial',
                      color: AppColors.textSecondary,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 6),
              Image.asset(
                'assets/images/neos_logo.png',
                width: 70,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(LanguageController languageController,
      BoxConstraints constraints, bool isSmallScreen, bool isTinyScreen) {
    return Obx(() {
      final currentLang = languageController.currentLocale.value.languageCode;
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(isTinyScreen
              ? 10
              : isSmallScreen
                  ? 12
                  : 20),
          border: Border.all(color: AppColors.borderColor),
          boxShadow: AppColors.lightCardShadow,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageButton(
                context: context,
                label: '🇫🇷',
                isSelected: currentLang == 'fr',
                onTap: () => languageController.setLanguage('fr'),
                isSmallScreen: isSmallScreen,
                isTinyScreen: isTinyScreen,
              ),
              _buildLanguageButton(
                context: context,
                label: '🇹🇳',
                isSelected: currentLang == 'ar',
                onTap: () => languageController.setLanguage('ar'),
                isSmallScreen: isSmallScreen,
                isTinyScreen: isTinyScreen,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildLanguageButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSmallScreen,
    required bool isTinyScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isTinyScreen
            ? 10
            : isSmallScreen
                ? 12
                : 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTinyScreen
                ? 8
                : isSmallScreen
                    ? 10
                    : 16,
            vertical: isTinyScreen
                ? 6
                : isSmallScreen
                    ? 8
                    : 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(isTinyScreen
                ? 10
                : isSmallScreen
                    ? 12
                    : 20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTinyScreen
                  ? 14
                  : isSmallScreen
                      ? 16
                      : 20,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(
      BuildContext context,
      AuthControllerGetX authController,
      double availableHeight,
      bool isSmallScreen) {
    final isTinyScreen = MediaQuery.of(context).size.height < 450;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildResponsiveTextField(
            controller: _phoneController,
            label: AppLocalizations.of(context).translate('phoneNumber'),
            hint: AppLocalizations.of(context).translate('enterPhone'),
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context).translate('enterPhone');
              }
              if (value.length != 8) {
                return AppLocalizations.of(context).translate('invalidPhone');
              }
              return null;
            },
            availableHeight: availableHeight,
            isSmallScreen: isSmallScreen,
            isTinyScreen: isTinyScreen,
          ),
          SizedBox(height: availableHeight * 0.018),
          _buildResponsiveTextField(
            controller: _passwordController,
            label: AppLocalizations.of(context).translate('password'),
            hint: AppLocalizations.of(context).translate('enterPassword'),
            prefixIcon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
                size: availableHeight * 0.03,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppLocalizations.of(context).translate('enterPassword');
              }
              if (value.length < 8) {
                return AppLocalizations.of(context)
                    .translate('invalidPassword');
              }
              return null;
            },
            availableHeight: availableHeight,
            isSmallScreen: isSmallScreen,
            isTinyScreen: isTinyScreen,
          ),
          SizedBox(height: availableHeight * 0.01),
          // Forgot Password Link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Get.toNamed(Routes.forgotPasswordPhone);
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isTinyScreen ? 8 : 12,
                  vertical: isTinyScreen ? 4 : 8,
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('forgotPassword') ??
                    'Forgot Password?',
                style: GoogleFonts.poppins(
                  fontSize: isTinyScreen ? 11 : 13,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: availableHeight * 0.005),
          _buildPrivacyPolicyCheckbox(
              context, availableHeight, isSmallScreen, isTinyScreen),
          SizedBox(height: availableHeight * 0.02),
          Obx(() => SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: authController.isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonBg,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  child: authController.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnBase),
                          ),
                        )
                      : Center(
                          child: Text(
                            AppLocalizations.of(context).translate('login'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              )),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    required double availableHeight,
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
                ? 12
                : 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: isTinyScreen
              ? 10
              : isSmallScreen
                  ? 11
                  : 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        hintStyle: TextStyle(
          fontSize: isTinyScreen
              ? 10
              : isSmallScreen
                  ? 11
                  : 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: AppColors.textSecondary,
          size: isTinyScreen
              ? 14
              : isSmallScreen
                  ? 16
                  : 24,
        ),
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        errorStyle: TextStyle(
          fontSize: isTinyScreen
              ? 8
              : isSmallScreen
                  ? 9
                  : 12,
          fontWeight: FontWeight.w400,
          color: AppColors.errorColor,
        ),
        contentPadding: EdgeInsets.symmetric(
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
        fillColor: AppColors.surfaceColor,
      ),
      validator: validator,
    );
  }

  Widget _buildPrivacyPolicyCheckbox(BuildContext context,
      double availableHeight, bool isSmallScreen, bool isTinyScreen) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Transform.scale(
          scale: isTinyScreen
              ? 0.8
              : isSmallScreen
                  ? 0.9
                  : 1.0,
          child: Checkbox(
            value: _acceptedPrivacyPolicy,
            onChanged: (value) {
              setState(() {
                _acceptedPrivacyPolicy = value ?? false;
              });
            },
            activeColor: AppColors.brandBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _acceptedPrivacyPolicy = !_acceptedPrivacyPolicy;
              });
            },
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${AppLocalizations.of(context).translate('iAccept')} ',
                    style: GoogleFonts.barlow(
                      fontSize: isTinyScreen
                          ? 10
                          : isSmallScreen
                              ? 11
                              : 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Get.toNamed('/privacy-policy');
                    },
                    child: Text(
                      AppLocalizations.of(context).translate('privacyPolicy'),
                      style: GoogleFonts.barlow(
                        fontSize: isTinyScreen
                            ? 10
                            : isSmallScreen
                                ? 11
                                : 13,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.brandBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
