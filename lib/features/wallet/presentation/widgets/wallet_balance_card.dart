import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/features/wallet/domain/filter_types.dart';

/// Ultra-compact balance card widget with minimal spacing
class WalletBalanceCard extends StatelessWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final VoidCallback onDetailsPressed;
  final VoidCallback onFilterPressed;

  const WalletBalanceCard({
    super.key,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    required this.onDetailsPressed,
    required this.onFilterPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<WalletController>();

    return Obx(() {
      final summary = controller.summary;
      final filteredRideCount =
          controller.filteredTransactions.where((t) => !t.isExpense).length;
      final filteredExpenseCount =
          controller.filteredTransactions.where((t) => t.isExpense).length;
      final filteredTransactionCount = controller.filteredTransactions.length;

      return Container(
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
              AppColors.brandBlue,
              AppColors.brandBlueDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(isVerySmallScreen
              ? 12
              : isSmallScreen
                  ? 14
                  : 16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlue.withOpacity(0.22),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Main Balance Display - More Compact
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildBalanceInfo(
                    l10n,
                    summary,
                    filteredTransactionCount,
                    controller.selectedDateFilter.value,
                    controller.startDate.value,
                    controller.endDate.value,
                  ),
                ),
                SizedBox(
                    width: isVerySmallScreen
                        ? 2
                        : isSmallScreen
                            ? 4
                            : 8),
                // Compact Action Buttons Column (LTR keeps calendar icon visible in Arabic RTL)
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCompactActionButton(
                        l10n.translate('details'),
                        Icons.info_outline,
                        onDetailsPressed,
                      ),
                      SizedBox(
                          width: isVerySmallScreen
                              ? 4
                              : isSmallScreen
                                  ? 5
                                  : 6),
                      _buildCompactActionButton(
                        _getFilterButtonText(l10n, controller),
                        controller.selectedFilter.value == TransactionFilter.all
                            ? Icons.calendar_today
                            : Icons.filter_list,
                        onFilterPressed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
                height: isVerySmallScreen
                    ? 6
                    : isSmallScreen
                        ? 8
                        : 10),
            // Revenue and Expenses Summary - Ultra Compact
            Row(
              children: [
                Expanded(
                  child: _buildCompactSummaryItem(
                    l10n,
                    l10n.translate('revenue'),
                    summary.totalRevenue,
                    AppColors.successColor,
                    Icons.arrow_upward,
                    count: filteredRideCount,
                  ),
                ),
                SizedBox(
                    width: isVerySmallScreen
                        ? 6
                        : isSmallScreen
                            ? 8
                            : 10),
                Expanded(
                  child: _buildCompactSummaryItem(
                    l10n,
                    l10n.translate('expenses'),
                    summary.totalExpenses,
                    AppColors.errorColor,
                    Icons.arrow_downward,
                    count: filteredExpenseCount,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBalanceInfo(
    AppLocalizations l10n,
    dynamic summary,
    int filteredTransactionCount,
    DateFilterType selectedDateFilter,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.translate('totalBalance'),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white.withOpacity(0.85),
            fontSize: isVerySmallScreen
                ? 9
                : isSmallScreen
                    ? 10
                    : 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            height: 1.2,
          ),
        ),
        SizedBox(
            height: isVerySmallScreen
                ? 2
                : isSmallScreen
                    ? 3
                    : 4),
        Text(
          '${summary.netBalance.toStringAsFixed(3)} ${l10n.translate('currencySymbol')}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontSize: isVerySmallScreen
                ? 16
                : isSmallScreen
                    ? 18
                    : 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.1,
          ),
        ),
        // Show transaction count for personalized filter - very compact
        if (selectedDateFilter == DateFilterType.personalized &&
            startDate != null &&
            endDate != null) ...[
          SizedBox(height: isVerySmallScreen ? 1 : 2),
          Text(
            '$filteredTransactionCount items',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.6),
              fontSize: isVerySmallScreen
                  ? 7
                  : isSmallScreen
                      ? 8
                      : 9,
              fontStyle: FontStyle.italic,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isVerySmallScreen
            ? 6
            : isSmallScreen
                ? 7
                : 8),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(isVerySmallScreen
              ? 6
              : isSmallScreen
                  ? 7
                  : 8),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isVerySmallScreen
                  ? 6
                  : isSmallScreen
                      ? 7
                      : 8,
              vertical: isVerySmallScreen
                  ? 6
                  : isSmallScreen
                      ? 8
                      : 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: isVerySmallScreen
                      ? 13
                      : isSmallScreen
                          ? 14
                          : 15,
                ),
                if (label.isNotEmpty) ...[
                  SizedBox(
                      width: isVerySmallScreen
                          ? 3
                          : isSmallScreen
                              ? 4
                              : 5),
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: isVerySmallScreen
                            ? 9
                            : isSmallScreen
                                ? 10
                                : 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSummaryItem(
    AppLocalizations l10n,
    String label,
    double amount,
    Color color,
    IconData icon, {
    int? count,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen
            ? 6
            : isSmallScreen
                ? 8
                : 10,
        vertical: isVerySmallScreen
            ? 6
            : isSmallScreen
                ? 7
                : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(isVerySmallScreen
            ? 8
            : isSmallScreen
                ? 9
                : 10),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label with icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white.withOpacity(0.9),
                size: isVerySmallScreen
                    ? 10
                    : isSmallScreen
                        ? 11
                        : 12,
              ),
              SizedBox(
                  width: isVerySmallScreen
                      ? 3
                      : isSmallScreen
                          ? 4
                          : 5),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isVerySmallScreen
                        ? 8
                        : isSmallScreen
                            ? 9
                            : 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
              height: isVerySmallScreen
                  ? 2
                  : isSmallScreen
                      ? 3
                      : 4),
          // Amount
          Text(
            '${amount.toStringAsFixed(3)} ${l10n.translate('currencySymbol')}',
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isVerySmallScreen
                  ? 11
                  : isSmallScreen
                      ? 12
                      : 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.3,
              height: 1.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          // Count
          if (count != null) ...[
            SizedBox(height: isVerySmallScreen ? 1 : 2),
            Text(
              '$count ${l10n.translate('items')}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isVerySmallScreen
                    ? 7
                    : isSmallScreen
                        ? 8
                        : 9,
                color: Colors.white.withOpacity(0.65),
                letterSpacing: 0.2,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFilterButtonText(
      AppLocalizations l10n, WalletController controller) {
    switch (controller.selectedFilter.value) {
      case TransactionFilter.all:
        return l10n.translate('all');
      case TransactionFilter.revenue:
        return l10n.translate('revenue');
      case TransactionFilter.expenses:
        return l10n.translate('expenses');
    }
  }
}
