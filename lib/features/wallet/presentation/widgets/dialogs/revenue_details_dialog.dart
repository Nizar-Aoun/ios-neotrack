import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/core/shared/custom_elevated_button.dart';

/// Revenue details dialog matching OLD UI design with Owner/Driver split
class RevenueDetailsDialog extends StatelessWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;

  const RevenueDetailsDialog({
    super.key,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<WalletController>();

    return Obx(() {
      final breakdown = controller.summary.revenueBreakdown ?? {};
      final totalRevenue = breakdown['totalRevenue'] ?? 0.0;
      final ownerShare = breakdown['ownerShare'] ?? 0.0;
      final driverShare = breakdown['driverShare'] ?? 0.0;

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isVerySmallScreen
              ? 16
              : isSmallScreen
                  ? 20
                  : 24),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.all(isVerySmallScreen
              ? 12
              : isSmallScreen
                  ? 16
                  : 20),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isVerySmallScreen
                  ? 16
                  : isSmallScreen
                      ? 20
                      : 24),
              topRight: Radius.circular(isVerySmallScreen
                  ? 16
                  : isSmallScreen
                      ? 20
                      : 24),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.brandBlue,
                size: isVerySmallScreen
                    ? 20
                    : isSmallScreen
                        ? 22
                        : 24,
              ),
              SizedBox(
                  width: isVerySmallScreen
                      ? 8
                      : isSmallScreen
                          ? 10
                          : 12),
              Expanded(
                child: Text(
                  l10n.translate('revenueDetails'),
                  style: GoogleFonts.barlow(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: isVerySmallScreen
                        ? 16
                        : isSmallScreen
                            ? 18
                            : 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isVerySmallScreen
                    ? 12
                    : isSmallScreen
                        ? 14
                        : 16,
                isVerySmallScreen
                    ? 10
                    : isSmallScreen
                        ? 12
                        : 14,
                isVerySmallScreen
                    ? 12
                    : isSmallScreen
                        ? 14
                        : 16,
                isVerySmallScreen
                    ? 6
                    : isSmallScreen
                        ? 8
                        : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Revenue
                  _buildRevenueRow(
                    l10n.translate('totalRevenue'),
                    totalRevenue,
                    l10n,
                    Icons.trending_up,
                    AppColors.successColor,
                    isBold: true,
                  ),
                  SizedBox(
                      height: isVerySmallScreen
                          ? 6
                          : isSmallScreen
                              ? 8
                              : 10),

                  // Owner Share
                  _buildRevenueRow(
                    l10n.translate('ownerShare'),
                    ownerShare,
                    l10n,
                    Icons.person,
                    AppColors.brandBlue,
                  ),
                  SizedBox(
                      height: isVerySmallScreen
                          ? 6
                          : isSmallScreen
                              ? 8
                              : 10),

                  // Driver Share
                  _buildRevenueRow(
                    l10n.translate('driverShare'),
                    driverShare,
                    l10n,
                    Icons.drive_eta,
                    AppColors.secondaryColor,
                  ),
                  SizedBox(
                      height: isVerySmallScreen
                          ? 8
                          : isSmallScreen
                              ? 10
                              : 12),

                  // Split Rules Info
                  Container(
                    padding: EdgeInsets.all(isVerySmallScreen
                        ? 8
                        : isSmallScreen
                            ? 9
                            : 10),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(isVerySmallScreen
                          ? 8
                          : isSmallScreen
                              ? 10
                              : 12),
                      border: Border.all(
                        color: AppColors.brandBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.brandBlue,
                              size: isVerySmallScreen
                                  ? 14
                                  : isSmallScreen
                                      ? 16
                                      : 18,
                            ),
                            SizedBox(
                                width: isVerySmallScreen
                                    ? 5
                                    : isSmallScreen
                                        ? 6
                                        : 8),
                            Text(
                              l10n.translate('splitRules'),
                              style: GoogleFonts.barlow(
                                color: AppColors.brandBlue,
                                fontSize: isVerySmallScreen
                                    ? 11
                                    : isSmallScreen
                                        ? 12
                                        : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                            height: isVerySmallScreen
                                ? 4
                                : isSmallScreen
                                    ? 5
                                    : 6),
                        Text(
                          '05:00 - 20:59: ${l10n.translate('owner')} 70%, ${l10n.translate('driver')} 30%',
                          style: GoogleFonts.barlow(
                            color: AppColors.textPrimary,
                            fontSize: isVerySmallScreen
                                ? 9
                                : isSmallScreen
                                    ? 10
                                    : 11,
                          ),
                        ),
                        SizedBox(
                            height: isVerySmallScreen
                                ? 2
                                : isSmallScreen
                                    ? 3
                                    : 4),
                        Text(
                          '21:00 - 04:59: ${l10n.translate('owner')} 47%, ${l10n.translate('driver')} 53%',
                          style: GoogleFonts.barlow(
                            color: AppColors.textPrimary,
                            fontSize: isVerySmallScreen
                                ? 9
                                : isSmallScreen
                                    ? 10
                                    : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: CustomElevatedButtonPresets.primary(
              onPressed: () => Navigator.of(context).pop(),
              text: l10n.translate('close'),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildRevenueRow(
    String label,
    double amount,
    AppLocalizations l10n,
    IconData icon,
    Color color, {
    bool isBold = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isVerySmallScreen
          ? 7
          : isSmallScreen
              ? 8
              : 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(isVerySmallScreen
            ? 8
            : isSmallScreen
                ? 10
                : 12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmallScreen
                ? 5
                : isSmallScreen
                    ? 6
                    : 7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(isVerySmallScreen
                  ? 6
                  : isSmallScreen
                      ? 7
                      : 8),
            ),
            child: Icon(
              icon,
              color: color,
              size: isVerySmallScreen
                  ? 16
                  : isSmallScreen
                      ? 18
                      : 20,
            ),
          ),
          SizedBox(
              width: isVerySmallScreen
                  ? 8
                  : isSmallScreen
                      ? 9
                      : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.barlow(
                    color: AppColors.textPrimary,
                    fontSize: isVerySmallScreen
                        ? 10
                        : isSmallScreen
                            ? 11
                            : 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(
                    height: isVerySmallScreen
                        ? 1
                        : isSmallScreen
                            ? 2
                            : 3),
                Text(
                  '${amount.toStringAsFixed(3)} ${l10n.translate('currencySymbol')}',
                  style: GoogleFonts.barlow(
                    color: color,
                    fontSize: isVerySmallScreen
                        ? 13
                        : isSmallScreen
                            ? 14
                            : 16,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
