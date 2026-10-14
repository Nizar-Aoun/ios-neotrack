import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/features/wallet/domain/filter_types.dart';
import 'package:taxi_driver_app/core/shared/custom_elevated_button.dart';

/// Transaction filter dialog matching OLD UI design
class TransactionFilterDialog extends StatelessWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;

  const TransactionFilterDialog({
    super.key,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = Get.find<WalletController>();

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isVerySmallScreen
            ? 16
            : isSmallScreen
                ? 20
                : 24),
      ),
      backgroundColor: Colors.white,
      title: Row(
        children: [
          const Icon(Icons.filter_list, color: AppColors.brandBlue),
          const SizedBox(width: 8),
          Text(
            l10n.translate('filterTransactions'),
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterOption(
            controller,
            TransactionFilter.all,
            l10n.translate('all'),
            Icons.list,
          ),
          const SizedBox(height: 12),
          _buildFilterOption(
            controller,
            TransactionFilter.revenue,
            l10n.translate('revenue'),
            Icons.trending_up,
          ),
          const SizedBox(height: 12),
          _buildFilterOption(
            controller,
            TransactionFilter.expenses,
            l10n.translate('expenses'),
            Icons.trending_down,
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomElevatedButtonPresets.primary(
              onPressed: () => Navigator.of(context).pop(),
              text: l10n.translate('close'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterOption(
    WalletController controller,
    TransactionFilter filter,
    String label,
    IconData icon,
  ) {
    return Obx(() {
      final isSelected = controller.selectedFilter.value == filter;

      return InkWell(
        onTap: () {
          controller.setTransactionFilter(filter);
          Get.back();
        },
        borderRadius: BorderRadius.circular(isVerySmallScreen
            ? 8
            : isSmallScreen
                ? 10
                : 12),
        child: Container(
          padding: EdgeInsets.all(isVerySmallScreen
              ? 10
              : isSmallScreen
                  ? 12
                  : 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isVerySmallScreen
                ? 8
                : isSmallScreen
                    ? 10
                    : 12),
            border: Border.all(
              color: isSelected ? AppColors.brandBlue : AppColors.borderColor,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? AppColors.brandBlue : AppColors.textSecondary,
                size: isVerySmallScreen
                    ? 20
                    : isSmallScreen
                        ? 22
                        : 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppColors.brandBlue
                        : AppColors.textPrimary,
                    fontSize: isVerySmallScreen
                        ? 13
                        : isSmallScreen
                            ? 14
                            : 15,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.brandBlue,
                  size: 24,
                ),
            ],
          ),
        ),
      );
    });
  }
}
