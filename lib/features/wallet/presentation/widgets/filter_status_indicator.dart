import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/features/wallet/domain/filter_types.dart';
import 'package:taxi_driver_app/utils/date_formatter.dart';

/// Compact elegant filter card - space optimized
class FilterStatusIndicator extends StatelessWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final VoidCallback onClearPressed;

  const FilterStatusIndicator({
    super.key,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    required this.onClearPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<WalletController>();

    return Obx(() {
      final selectedDateFilter = controller.selectedDateFilter.value;
      final startDate = controller.startDate.value;
      final endDate = controller.endDate.value;
      final filteredTransactionCount = controller.filteredTransactions.length;

      // Don't show for "Today" filter - it's the default
      if (selectedDateFilter == DateFilterType.lastDay) {
        return const SizedBox.shrink();
      }

      // Get filter label
      String filterLabel;

      switch (selectedDateFilter) {
        case DateFilterType.lastWeek:
          filterLabel = l10n.translate('weeklyStats');
          break;
        case DateFilterType.lastMonth:
          filterLabel = l10n.translate('monthlyStats');
          break;
        case DateFilterType.personalized:
          if (startDate == null || endDate == null) {
            return const SizedBox.shrink();
          }
          filterLabel = l10n.translate('personalizedFilter');
          break;
        default:
          return const SizedBox.shrink();
      }

      return Container(
        margin: EdgeInsets.only(
            top: isVerySmallScreen
                ? 2
                : isSmallScreen
                    ? 4
                    : 6),
        padding: EdgeInsets.symmetric(
          horizontal: isVerySmallScreen
              ? 6
              : isSmallScreen
                  ? 8
                  : 12,
          vertical: isVerySmallScreen
              ? 4
              : isSmallScreen
                  ? 6
                  : 10,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondaryColor.withOpacity(0.18),
              AppColors.secondaryColor.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(isVerySmallScreen ? 10 : 12),
          border: Border.all(
            color: AppColors.secondaryColor.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(isVerySmallScreen ? 5 : 6),
              decoration: BoxDecoration(
                color: AppColors.secondaryColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.filter_alt_rounded,
                color: AppColors.textPrimary,
                size: isVerySmallScreen ? 14 : 16,
              ),
            ),

            SizedBox(width: isVerySmallScreen ? 8 : 10),

            // Filter Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show filter label for weekly/monthly, dates for personalized
                  Text(
                    selectedDateFilter == DateFilterType.personalized &&
                            startDate != null &&
                            endDate != null
                        ? '${DateFormatter.formatDate(startDate, context)} → ${DateFormatter.formatDate(endDate, context)}'
                        : filterLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: isVerySmallScreen
                          ? 11
                          : isSmallScreen
                              ? 12
                              : 13,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '$filteredTransactionCount ${l10n.translate('transactionsFound')}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: isVerySmallScreen
                          ? 9
                          : isSmallScreen
                              ? 10
                              : 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Close Button
            InkWell(
              onTap: onClearPressed,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(isVerySmallScreen ? 4 : 6),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: isVerySmallScreen ? 16 : 18,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
