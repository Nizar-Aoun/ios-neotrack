import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/features/auth/provider/auth_controller_optimized.dart';
import 'package:taxi_driver_app/core/errors/error_messages.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';
import 'package:taxi_driver_app/features/auth/presentation/widgets/auth_card.dart';

import '../../../l10n/app_localizations.dart';

// Using theme colors

class CreatePasswordScreen extends ConsumerStatefulWidget {
  final String? currentPassword;

  const CreatePasswordScreen({
    super.key,
    this.currentPassword,
  });

  @override
  ConsumerState<CreatePasswordScreen> createState() =>
      _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends ConsumerState<CreatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    final hasMinLength = password.length >= 8;
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasMinLength && hasLetter && hasNumber;
  }

  Future<void> _submitPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final currentPassword = widget.currentPassword ?? '';
        final newPassword = _passwordController.text;

        // Update password using auth controller
        final success =
            await ref.read(authControllerProvider.notifier).updatePassword(
                  currentPassword: currentPassword,
                  newPassword: newPassword,
                );

        if (success && mounted) {
          CustomSnackBar.success(
            title: AppLocalizations.of(context).translate('Success'),
            message: AppLocalizations.of(context).translate('passwordUpdated'),
            duration: const Duration(seconds: 2),
          );

          // Navigate to home screen
          Get.offAllNamed(Routes.home);
        } else if (mounted) {
          CustomSnackBar.error(
            title: AppLocalizations.of(context).translate('Error'),
            message:
                AppLocalizations.of(context).translate('failedToResetPassword'),
          );
        }
      } catch (e) {
        if (mounted) {
          CustomSnackBar.error(
            title: AppLocalizations.of(context).translate('Error'),
            message: friendlyErrorMessage(
              context,
              e,
              fallbackKey: 'failedToResetPassword',
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        Get.offAllNamed(Routes.login);
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.error(
          title: AppLocalizations.of(context).translate('Error'),
          message: friendlyErrorMessage(
            context,
            e,
            fallbackKey: 'logoutFailed',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final safeHeight = size.height - padding.top - padding.bottom;
    final isSmallScreen = safeHeight < 650;

    // Watch auth state for automatic navigation
    ref.listen<AsyncValue<AuthStateModel>>(
      authControllerProvider,
      (previous, next) {
        next.whenData((authState) {
          if (authState.isAuthenticated && !authState.needsPasswordUpdate) {
            // Password has been updated, navigate to home
            Get.offAllNamed(Routes.home);
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surfaceColor,
      appBar: AppBar(
        title: Text(
          'Create New Password',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _handleLogout,
            icon:
                const Icon(Icons.logout, color: AppColors.errorColor, size: 18),
            label: Text(
              'Logout',
              style: GoogleFonts.poppins(
                color: AppColors.errorColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 24.0),
            child: AuthCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: isSmallScreen ? 56 : 68,
                        height: isSmallScreen ? 56 : 68,
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: isSmallScreen ? 28 : 34,
                          color: AppColors.brandBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    Text(
                      'Create a Strong Password',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 8 : 12),
                    Text(
                      'Your password must be at least 8 characters long and contain both letters and numbers.',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 12 : 14,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildResponsiveTextField(
                      controller: _passwordController,
                      label: 'New Password',
                      hint: 'Enter your new password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textTertiary,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        if (!_validatePassword(value)) {
                          return 'Password must be 8+ chars with letters & numbers';
                        }
                        return null;
                      },
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 12 : 16),
                    _buildResponsiveTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Re-enter your new password',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textTertiary,
                          size: isSmallScreen ? 18 : 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                      isSmallScreen: isSmallScreen,
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    SizedBox(
                      height: isSmallScreen ? 48 : 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBg,
                          disabledBackgroundColor: AppColors.surfaceMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: LoadingGif(
                                  width: 20,
                                  height: 20,
                                ),
                              )
                            : Text(
                                'Update Password',
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
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
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    required bool isSmallScreen,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      enabled: !_isLoading,
      style: TextStyle(
        fontSize: isSmallScreen ? 13 : 14,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: isSmallScreen ? 12 : 13,
        ),
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: isSmallScreen ? 12 : 13,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppColors.textTertiary,
          size: isSmallScreen ? 20 : 22,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: isSmallScreen ? 14 : 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        errorStyle: TextStyle(
          fontSize: isSmallScreen ? 11 : 12,
        ),
      ),
    );
  }
}
