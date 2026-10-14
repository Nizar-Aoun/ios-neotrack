import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

/// Full-screen gate shown when the backend reports that the user's
/// subscription is not active / not paid.
///
/// It stays open until the user dismisses it and offers a one-tap way to
/// contact support (phone call), mirroring the help screen behaviour.
///
/// All copy is fully localized (FR / AR); the raw backend message is never
/// displayed to the user.
class SubscriptionRequiredScreen extends StatelessWidget {
  /// Support phone number (same as the help screen).
  static const String supportPhone = '71610911';

  const SubscriptionRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 680;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.surfaceColor, AppColors.white],
                stops: [0.0, 0.55],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Close button row
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: IconButton(
                      tooltip: l10n.translate('close'),
                      icon: const Icon(Icons.close,
                          color: AppColors.textSecondary),
                      onPressed: () => Get.back<void>(),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 24 : 32,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: isSmallScreen ? 8 : 24),
                        _PremiumBadge(isSmallScreen: isSmallScreen),
                        SizedBox(height: isSmallScreen ? 24 : 36),
                        Text(
                          l10n.translate('subscriptionRequiredTitle'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 22 : 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.translate('subscriptionRequiredMessage'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20 : 28),
                        _SupportHintCard(l10n: l10n),
                      ],
                    ),
                  ),
                ),
                _buildBottomActions(context, l10n, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    AppLocalizations l10n,
    bool isSmallScreen,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 24 : 32,
        8,
        isSmallScreen ? 24 : 32,
        isSmallScreen ? 16 : 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _makePhoneCall,
              icon: const Icon(Icons.phone, size: 22),
              label: Text(
                l10n.translate('subscriptionContactSupport'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonBg,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.support_agent,
                  size: 18, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Text(
                supportPhone,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall() async {
    final l10n = Get.context != null ? AppLocalizations.of(Get.context!) : null;
    try {
      await launchUrl(Uri.parse('tel:$supportPhone'),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(Uri.parse('tel://$supportPhone'),
            mode: LaunchMode.externalApplication);
      } catch (_) {
        await Clipboard.setData(const ClipboardData(text: supportPhone));
        if (Get.context != null && Get.context!.mounted) {
          CustomSnackBar.info(
            title: l10n?.translate('phoneNumberCopied') ?? '',
            message: supportPhone,
          );
        }
      }
    }
  }
}

/// Animated premium/lock badge.
class _PremiumBadge extends StatelessWidget {
  final bool isSmallScreen;
  const _PremiumBadge({required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final outer = isSmallScreen ? 120.0 : 150.0;
    final inner = isSmallScreen ? 88.0 : 110.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.6, end: 1.0),
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: outer,
        height: outer,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.brandBlue.withOpacity(0.08),
        ),
        child: Center(
          child: Container(
            width: inner,
            height: inner,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandBlue, AppColors.brandBlueDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandBlue.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: isSmallScreen ? 44 : 56,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Small informational card explaining the next step.
class _SupportHintCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _SupportHintCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGrey2),
        boxShadow: AppColors.lightCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.successColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.headset_mic_rounded,
                color: AppColors.successColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.translate('subscriptionRequiredHint'),
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
