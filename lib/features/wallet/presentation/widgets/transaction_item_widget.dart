import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/wallet/domain/transaction_model.dart';
import 'package:taxi_driver_app/features/wallet/presentation/widgets/expense_dialog.dart';
import 'package:taxi_driver_app/utils/image_cache_helper.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/utils/date_formatter.dart';
import 'package:taxi_driver_app/features/shifts/application/shift_controller.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';
import 'package:taxi_driver_app/features/shifts/presentation/widgets/shift_card.dart';

/// Transaction item widget matching OLD UI design
class TransactionItemWidget extends StatelessWidget {
  final TransactionModel transaction;
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final VoidCallback onDeleteExpense;
  final VoidCallback? onDeleteRide;

  const TransactionItemWidget({
    super.key,
    required this.transaction,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    required this.onDeleteExpense,
    this.onDeleteRide,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (transaction.isExpense) {
      return _buildExpenseItem(context, l10n);
    } else {
      return _buildRideItem(context, l10n);
    }
  }

  // Build ride transaction item
  Widget _buildRideItem(BuildContext context, AppLocalizations l10n) {
    final ride = transaction.asRide;
    if (ride == null) return const SizedBox.shrink();

    // Wrap ride item in Dismissible for swipe-to-delete
    return Dismissible(
        key: Key('ride_${ride.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // Show confirmation dialog before deleting
          return await _showDeleteRideConfirmation(context, l10n);
        },
        onDismissed: (direction) {
          // Call the delete callback
          if (onDeleteRide != null) {
            onDeleteRide!();
          }
        },
        background: Container(
          margin: EdgeInsets.only(
            bottom: isVerySmallScreen
                ? 4
                : isSmallScreen
                    ? 6
                    : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.errorColor,
            borderRadius: BorderRadius.circular(isVerySmallScreen
                ? 10
                : isSmallScreen
                    ? 12
                    : 14),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: isVerySmallScreen ? 12 : 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: isVerySmallScreen ? 24 : 28,
              ),
              SizedBox(height: 4),
              Text(
                l10n.translate('delete'),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isVerySmallScreen ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: isVerySmallScreen
                ? 4
                : isSmallScreen
                    ? 6
                    : 8,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isVerySmallScreen
                ? 10
                : isSmallScreen
                    ? 12
                    : 14),
            border: Border.all(
              color: AppColors.borderColor,
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.lightShadowColor,
                blurRadius: 8,
                offset: Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToRideDetails(context, ride.id),
              borderRadius: BorderRadius.circular(isVerySmallScreen
                  ? 10
                  : isSmallScreen
                      ? 12
                      : 14),
              child: Padding(
                padding: EdgeInsets.all(isVerySmallScreen
                    ? 8
                    : isSmallScreen
                        ? 10
                        : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status badge
                    Row(
                      children: [
                        Icon(
                          Icons.local_taxi,
                          color: AppColors.brandBlue,
                          size: isVerySmallScreen
                              ? 16
                              : isSmallScreen
                                  ? 18
                                  : 20,
                        ),
                        SizedBox(
                            width: isVerySmallScreen
                                ? 4
                                : isSmallScreen
                                    ? 6
                                    : 8),
                        Expanded(
                          child: Text(
                            l10n.translate('ride'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: isVerySmallScreen
                                  ? 11
                                  : isSmallScreen
                                      ? 12
                                      : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Exact time verified icon
                        if (!ride.dateRangeAlert)
                          Icon(
                            Icons.verified_outlined,
                            color: AppColors.secondaryColor,
                            size: isVerySmallScreen
                                ? 16
                                : isSmallScreen
                                    ? 18
                                    : 20,
                          ),
                        if (ride.isDeleted == true) ...[
                          SizedBox(
                              width: isVerySmallScreen
                                  ? 4
                                  : isSmallScreen
                                      ? 6
                                      : 8),
                          Container(
                            padding: EdgeInsets.all(isVerySmallScreen
                                ? 2
                                : isSmallScreen
                                    ? 3
                                    : 4),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor.withOpacity(0.12),
                              borderRadius:
                                  BorderRadius.circular(isVerySmallScreen
                                      ? 4
                                      : isSmallScreen
                                          ? 5
                                          : 6),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: AppColors.errorColor,
                              size: isVerySmallScreen
                                  ? 14
                                  : isSmallScreen
                                      ? 16
                                      : 18,
                            ),
                          ),
                        ],
                        // Status badge
                      ],
                    ),
                    SizedBox(
                        height: isVerySmallScreen
                            ? 4
                            : isSmallScreen
                                ? 6
                                : 8),
                    // Amount and badges row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${(ride.rideAmount ?? 0).toStringAsFixed(3)} ${l10n.translate('currencySymbol')}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: isVerySmallScreen
                                  ? 13
                                  : isSmallScreen
                                      ? 15
                                      : 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Duration badge
                        if (ride.startDate != null && ride.endDate != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen
                                  ? 4
                                  : isSmallScreen
                                      ? 6
                                      : 8,
                              vertical: isVerySmallScreen
                                  ? 2
                                  : isSmallScreen
                                      ? 3
                                      : 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(isVerySmallScreen
                                      ? 4
                                      : isSmallScreen
                                          ? 5
                                          : 6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: isVerySmallScreen
                                      ? 10
                                      : isSmallScreen
                                          ? 11
                                          : 12,
                                  color: AppColors.primaryColor,
                                ),
                                SizedBox(
                                    width: isVerySmallScreen
                                        ? 2
                                        : isSmallScreen
                                            ? 3
                                            : 4),
                                Text(
                                  _formatDuration(
                                      ride.startDate!, ride.endDate!, l10n),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: isVerySmallScreen
                                        ? 8
                                        : isSmallScreen
                                            ? 9
                                            : 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              width: isVerySmallScreen
                                  ? 4
                                  : isSmallScreen
                                      ? 6
                                      : 8),
                        ],
                        // Distance badge
                        if (ride.locations.isNotEmpty)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen
                                  ? 4
                                  : isSmallScreen
                                      ? 6
                                      : 8,
                              vertical: isVerySmallScreen
                                  ? 2
                                  : isSmallScreen
                                      ? 3
                                      : 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(isVerySmallScreen
                                      ? 4
                                      : isSmallScreen
                                          ? 5
                                          : 6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.route,
                                  size: isVerySmallScreen
                                      ? 10
                                      : isSmallScreen
                                          ? 11
                                          : 12,
                                  color: AppColors.primaryColor,
                                ),
                                SizedBox(
                                    width: isVerySmallScreen
                                        ? 2
                                        : isSmallScreen
                                            ? 3
                                            : 4),
                                Text(
                                  '${((ride.distance ?? 0) / 100).toStringAsFixed(1)} ${l10n.translate('distanceUnitKm')}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: isVerySmallScreen
                                        ? 8
                                        : isSmallScreen
                                            ? 9
                                            : 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                        height: isVerySmallScreen
                            ? 4
                            : isSmallScreen
                                ? 6
                                : 8),
                    // Date/Time with max speed at bottom-right
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            DateFormatter.formatDateTime(
                                transaction.date, context),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: isVerySmallScreen
                                  ? 8
                                  : isSmallScreen
                                      ? 9
                                      : 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        if (ride.maxSpeed != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen
                                  ? 4
                                  : isSmallScreen
                                      ? 6
                                      : 8,
                              vertical: isVerySmallScreen
                                  ? 2
                                  : isSmallScreen
                                      ? 3
                                      : 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor.withOpacity(0.1),
                              borderRadius:
                                  BorderRadius.circular(isVerySmallScreen
                                      ? 4
                                      : isSmallScreen
                                          ? 5
                                          : 6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.speed,
                                  size: isVerySmallScreen
                                      ? 10
                                      : isSmallScreen
                                          ? 11
                                          : 12,
                                  color: AppColors.primaryColor,
                                ),
                                SizedBox(
                                    width: isVerySmallScreen
                                        ? 2
                                        : isSmallScreen
                                            ? 3
                                            : 4),
                                Text(
                                  '${l10n.translate('maxSpeed')}: ${ride.maxSpeed!.toStringAsFixed(0)} ${l10n.translate('speedUnit')}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: isVerySmallScreen
                                        ? 8
                                        : isSmallScreen
                                            ? 9
                                            : 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (ride.dateRangeAlert) ...[
                      SizedBox(
                          height: isVerySmallScreen
                              ? 4
                              : isSmallScreen
                                  ? 5
                                  : 6),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isVerySmallScreen
                              ? 6
                              : isSmallScreen
                                  ? 8
                                  : 10,
                          vertical: isVerySmallScreen
                              ? 3
                              : isSmallScreen
                                  ? 4
                                  : 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            isVerySmallScreen
                                ? 6
                                : isSmallScreen
                                    ? 7
                                    : 8,
                          ),
                          border: Border.all(
                            color: AppColors.warningColor.withOpacity(0.45),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.errorColor,
                              size: isVerySmallScreen
                                  ? 12
                                  : isSmallScreen
                                      ? 13
                                      : 14,
                            ),
                            SizedBox(
                              width: isVerySmallScreen
                                  ? 3
                                  : isSmallScreen
                                      ? 4
                                      : 5,
                            ),
                            Text(
                              l10n.translate('dateRangeAlertWarning'),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: isVerySmallScreen
                                    ? 8
                                    : isSmallScreen
                                        ? 9
                                        : 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Shift tag
                    Builder(builder: (_) {
                      final shift = _resolveShift(ride);
                      if (shift == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: ShiftTag(shift: shift),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ));
  }

  // Build expense transaction item
  Widget _buildExpenseItem(BuildContext context, AppLocalizations l10n) {
    final expense = transaction.asExpense;
    if (expense == null) return const SizedBox.shrink();

    final controller = Get.find<WalletController>();
    final category = controller.categories.firstWhere(
      (c) => c.id == expense.categoryId,
      orElse: () => controller.categories.first,
    );

    // Get current locale
    final currentLocale = Localizations.localeOf(context).languageCode;

    // Get localized name
    final categoryName = category.getLocalizedName(currentLocale);

    return Container(
      margin: EdgeInsets.only(
        bottom: isVerySmallScreen
            ? 4
            : isSmallScreen
                ? 6
                : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isVerySmallScreen
            ? 10
            : isSmallScreen
                ? 12
                : 14),
        border: Border.all(
          color: AppColors.errorColor.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.errorColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isVerySmallScreen
            ? 8
            : isSmallScreen
                ? 10
                : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with actions
            Row(
              children: [
                // Category icon
                Image(
                  image: ImageCacheHelper.categoryIconProvider(
                      category.iconAssetPath),
                  width: isVerySmallScreen
                      ? 20
                      : isSmallScreen
                          ? 24
                          : 28,
                  height: isVerySmallScreen
                      ? 20
                      : isSmallScreen
                          ? 24
                          : 28,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.receipt,
                      color: AppColors.errorColor,
                      size: isVerySmallScreen
                          ? 20
                          : isSmallScreen
                              ? 24
                              : 28,
                    );
                  },
                ),
                SizedBox(
                    width: isVerySmallScreen
                        ? 6
                        : isSmallScreen
                            ? 8
                            : 10),
                Expanded(
                  child: Text(
                    categoryName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: isVerySmallScreen
                          ? 11
                          : isSmallScreen
                              ? 12
                              : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Edit button
                InkWell(
                  onTap: () => _editExpense(context, expense),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.edit,
                      color: AppColors.brandBlue,
                      size: isVerySmallScreen
                          ? 16
                          : isSmallScreen
                              ? 18
                              : 20,
                    ),
                  ),
                ),
                SizedBox(
                    width: isVerySmallScreen
                        ? 4
                        : isSmallScreen
                            ? 6
                            : 8),
                // Delete button
                InkWell(
                  onTap: onDeleteExpense,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete,
                      color: AppColors.errorColor,
                      size: isVerySmallScreen
                          ? 16
                          : isSmallScreen
                              ? 18
                              : 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
                height: isVerySmallScreen
                    ? 4
                    : isSmallScreen
                        ? 6
                        : 8),
            // Description if available
            if (expense.description.isNotEmpty) ...[
              Text(
                expense.description,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: isVerySmallScreen
                      ? 9
                      : isSmallScreen
                          ? 10
                          : 11,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(
                  height: isVerySmallScreen
                      ? 4
                      : isSmallScreen
                          ? 6
                          : 8),
            ],
            // Amount
            Text(
              '${expense.amount.toStringAsFixed(3)} ${l10n.translate('currencySymbol')}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.errorColor,
                fontSize: isVerySmallScreen
                    ? 13
                    : isSmallScreen
                        ? 15
                        : 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
                height: isVerySmallScreen
                    ? 4
                    : isSmallScreen
                        ? 6
                        : 8),
            // Date/Time
            Text(
              DateFormatter.formatDateTime(transaction.date, context),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: isVerySmallScreen
                    ? 8
                    : isSmallScreen
                        ? 9
                        : 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(DateTime start, DateTime end, AppLocalizations l10n) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours} ${l10n.translate('hours')} ${minutes} ${l10n.translate('minutes')}';
    } else {
      return '${minutes} ${l10n.translate('minutes')}';
    }
  }

  // Navigate to ride details
  void _navigateToRideDetails(BuildContext context, String rideId) {
    final ride = transaction.asRide;

    if (ride == null) return;

    Get.toNamed(
      '/ride-details',
      arguments: {
        'ride': ride,
        'baseUrl': Env.apiUrl,
      },
    );
  } // Edit expense

  void _editExpense(BuildContext context, dynamic expense) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ExpenseDialog(expense: expense);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
        );
      },
    );
  }

  // Show confirmation dialog for ride deletion
  Future<bool?> _showDeleteRideConfirmation(
      BuildContext context, AppLocalizations l10n) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.errorColor),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                l10n.translate('confirmDelete'),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isVerySmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          l10n.translate('confirmDeleteRide'),
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: isVerySmallScreen ? 12 : 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.translate('cancel'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: isVerySmallScreen ? 12 : 14,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmallScreen ? 12 : 16,
                vertical: isVerySmallScreen ? 8 : 12,
              ),
            ),
            child: Text(
              l10n.translate('delete'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isVerySmallScreen ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Safely resolve the ShiftModel for a ride by checking ShiftController.
  ShiftModel? _resolveShift(ride) {
    try {
      final sc = Get.find<ShiftController>();
      return sc.shiftForRide(ride);
    } catch (_) {
      return null;
    }
  }
}
