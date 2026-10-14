import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';

/// Date warning banner widget matching OLD UI design
class DateWarningBanner extends StatelessWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;

  const DateWarningBanner({
    super.key,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<WalletController>();

    return Obx(() {
      final dateError = controller.dateError.value;

      if (dateError == null || dateError.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.only(
          top: isVerySmallScreen
              ? 4
              : isSmallScreen
                  ? 6
                  : 8,
        ),
        padding: EdgeInsets.all(isVerySmallScreen
            ? 8
            : isSmallScreen
                ? 10
                : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warningColor.withOpacity(0.14),
              AppColors.warningColor.withOpacity(0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(isVerySmallScreen
              ? 10
              : isSmallScreen
                  ? 12
                  : 14),
          border: Border.all(
            color: AppColors.warningColor.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.warningColor.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppColors.textPrimary,
              size: isVerySmallScreen
                  ? 16
                  : isSmallScreen
                      ? 18
                      : 20,
            ),
            SizedBox(
                width: isVerySmallScreen
                    ? 6
                    : isSmallScreen
                        ? 8
                        : 10),
            Expanded(
              child: Text(
                dateError,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: isVerySmallScreen
                      ? 10
                      : isSmallScreen
                          ? 11
                          : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
