// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/wallet/provider/wallet_controller.dart';
import 'package:taxi_driver_app/features/wallet/domain/filter_types.dart';
import 'package:taxi_driver_app/features/wallet/presentation/widgets/expense_dialog.dart';
import 'package:taxi_driver_app/models/ride.dart';
import 'package:taxi_driver_app/services/permission_service.dart';
import 'package:taxi_driver_app/features/statistique/widgets/car_selection_dialog.dart';
import 'widgets/wallet_balance_card.dart';
import 'widgets/date_warning_banner.dart';
import 'widgets/filter_status_indicator.dart';
import 'widgets/transaction_item_widget.dart';
import 'widgets/transaction_list_skeleton.dart';
import 'widgets/dialogs/transaction_filter_dialog.dart';
import 'widgets/dialogs/revenue_details_dialog.dart';
import 'widgets/dialogs/wallet_date_filter_dialog.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/features/shifts/application/shift_controller.dart';
import 'package:taxi_driver_app/router.dart';
import 'package:taxi_driver_app/utils/date_formatter.dart';

class WalletScreen extends GetView<WalletController> {
  final List<Map<String, dynamic>> cars;
  final String baseUrl;

  const WalletScreen({
    super.key,
    required this.cars,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isVerySmallScreen = screenWidth < 320;

    // Check wallet permission
    if (!PermissionService.hasWalletPermission(context)) {
      return Scaffold(
        backgroundColor: AppColors.errorColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: AppColors.errorColor.withOpacity(0.7),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.translate('accessDenied'),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.translate('walletAccessDenied'),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Initialize controller with first car if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (cars.isNotEmpty && controller.selectedCar.value == null) {
        controller.setSelectedCar(cars.first);
        // Load shifts for this car
        _loadShiftsIfAvailable(cars.first);
      }
    });

    return Scaffold(
      floatingActionButton: Obx(() {
        final hasCar = controller.selectedCar.value != null;
        final taxiCars = cars
            .where((c) =>
                (c['car_type']?.toString().toLowerCase() ?? '') == 'taxi')
            .toList();
        final hasMultipleCars = taxiCars.length > 1;

        if (!hasCar && !hasMultipleCars) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasCar) ...[
              if (controller.rides.any((ride) => ride.isDeleted == true))
                Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(isSmallScreen ? 24 : 28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.errorColor.withOpacity(0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    heroTag: 'deleted_rides_button',
                    onPressed: () => _showDeletedRidesDialog(
                      context,
                      l10n,
                      isVerySmallScreen,
                      isSmallScreen,
                    ),
                    backgroundColor: AppColors.errorColor,
                    mini: isSmallScreen,
                    elevation: 0,
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white, size: 20),
                  ),
                ),
              if (controller.rides.any((ride) => ride.isDeleted == true))
                SizedBox(
                    height: isVerySmallScreen
                        ? 8
                        : isSmallScreen
                            ? 10
                            : 12),
              // Date Filter Button (Purple)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'date_filter_button',
                  onPressed: () => _showDateFilterDialog(
                      context, isVerySmallScreen, isSmallScreen),
                  backgroundColor: AppColors.secondaryColor,
                  mini: isSmallScreen,
                  elevation: 0,
                  child: const Icon(Icons.calendar_today,
                      color: Colors.white, size: 20),
                ),
              ),
              SizedBox(
                  height: isVerySmallScreen
                      ? 8
                      : isSmallScreen
                          ? 10
                          : 12),
              // Add Expense Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brandBlue.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'add_expense_button',
                  onPressed: () => _showExpenseDialog(context),
                  backgroundColor: AppColors.brandBlue,
                  mini: isSmallScreen,
                  elevation: 0,
                  child: const Icon(Icons.receipt_long,
                      color: Colors.white, size: 22),
                ),
              ),
              SizedBox(
                  height: isVerySmallScreen
                      ? 8
                      : isSmallScreen
                          ? 10
                          : 12),
            ],
            // Car Selection Button
            if (hasMultipleCars)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: FloatingActionButton(
                  heroTag: 'car_selection_button',
                  onPressed: () =>
                      _showCarSelectionDialog(context, isSmallScreen),
                  backgroundColor: AppColors.secondaryColor,
                  mini: isSmallScreen,
                  elevation: 0,
                  child: const Icon(Icons.directions_car,
                      color: Colors.white, size: 22),
                ),
              ),
          ],
        );
      }),
      body: Column(
        children: [
          // Main Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: isVerySmallScreen
                    ? 8.0
                    : isSmallScreen
                        ? 10.0
                        : 16.0,
                right: isVerySmallScreen
                    ? 8.0
                    : isSmallScreen
                        ? 10.0
                        : 16.0,
                top: (MediaQuery.of(context).padding.top +
                        (isVerySmallScreen
                            ? 70
                            : isSmallScreen
                                ? 80
                                : 90))
                    .clamp(100, double.infinity),
                bottom: isVerySmallScreen
                    ? 4.0
                    : isSmallScreen
                        ? 6.0
                        : 12.0,
              ),
              child: Obx(() => _buildContent(
                  context, l10n, isVerySmallScreen, isSmallScreen)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n,
      bool isVerySmallScreen, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Car Selector removed - car is selected via the FAB dialog
        // ignore: dead_code
        if (false) ...[
          // placeholder kept for structure
          _buildCarSelector(l10n, isVerySmallScreen, isSmallScreen),
          SizedBox(
              height: isVerySmallScreen
                  ? 6
                  : isSmallScreen
                      ? 8
                      : 12),
        ],

        if (controller.selectedCar.value != null) ...[
          WalletBalanceCard(
            isVerySmallScreen: isVerySmallScreen,
            isSmallScreen: isSmallScreen,
            onDetailsPressed: () => _showRevenueDetailsDialog(
                l10n, isVerySmallScreen, isSmallScreen),
            onFilterPressed: () {
              if (controller.selectedFilter.value == TransactionFilter.all) {
                _showDateFilterDialog(
                    context, isVerySmallScreen, isSmallScreen);
              } else {
                _showFilterDialog(l10n, isVerySmallScreen, isSmallScreen);
              }
            },
          ),
          SizedBox(
              height: isVerySmallScreen
                  ? 2
                  : isSmallScreen
                      ? 6
                      : 8),

          // Date Validation Warning (for predefined filters)
          if (controller.dateError.value != null &&
              controller.selectedDateFilter.value !=
                  DateFilterType.personalized) ...[
            DateWarningBanner(
              isVerySmallScreen: isVerySmallScreen,
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(
                height: isVerySmallScreen
                    ? 6
                    : isSmallScreen
                        ? 8
                        : 12),
          ],

          // Filter Status Indicator (for all filters except today)
          if (controller.selectedDateFilter.value !=
              DateFilterType.lastDay) ...[
            FilterStatusIndicator(
              isVerySmallScreen: isVerySmallScreen,
              isSmallScreen: isSmallScreen,
              onClearPressed: () {
                controller.setDateFilter(DateFilterType.lastDay);
                controller.loadData();
              },
            ),
            SizedBox(
                height: isVerySmallScreen
                    ? 6
                    : isSmallScreen
                        ? 8
                        : 12),
          ],

          // Shift filter row
          Obx(() {
            try {
              final sc = Get.find<ShiftController>();
              final shifts = sc.state.value.shifts;
              if (shifts.isEmpty) return const SizedBox.shrink();
              return _buildShiftFilterRow(
                  l10n, sc, isVerySmallScreen, isSmallScreen);
            } catch (_) {
              return const SizedBox.shrink();
            }
          }),
          // Transactions List
          Expanded(
            child:
                _buildTransactionsList(l10n, isVerySmallScreen, isSmallScreen),
          ),
        ] else ...[
          Expanded(
            child: _buildNoCarSelectedMessage(l10n),
          ),
        ],
      ],
    );
  }

  // Car Selector Widget
  Widget _buildCarSelector(
      AppLocalizations l10n, bool isVerySmallScreen, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen
            ? 8
            : isSmallScreen
                ? 10
                : 12,
        vertical: isVerySmallScreen
            ? 6
            : isSmallScreen
                ? 8
                : 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceColor,
            AppColors.cardColor,
          ],
        ),
        borderRadius: BorderRadius.circular(isVerySmallScreen
            ? 10
            : isSmallScreen
                ? 12
                : 14),
        border: Border.all(color: AppColors.borderColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.lightShadowColor,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Row(
            children: [
              Container(
                padding: EdgeInsets.all(isVerySmallScreen
                    ? 5
                    : isSmallScreen
                        ? 6
                        : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.brandBlue.withOpacity(0.12),
                      AppColors.brandBlue.withOpacity(0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isVerySmallScreen
                      ? 6
                      : isSmallScreen
                          ? 8
                          : 10),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: AppColors.brandBlue,
                  size: isVerySmallScreen
                      ? 14
                      : isSmallScreen
                          ? 16
                          : 18,
                ),
              ),
              SizedBox(
                  width: isVerySmallScreen
                      ? 6
                      : isSmallScreen
                          ? 8
                          : 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Map<String, dynamic>>(
                    value: controller.selectedCar.value,
                    isExpanded: true,
                    isDense: false,
                    hint: Text(
                      l10n.translate('selectACar'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: isVerySmallScreen
                            ? 12
                            : isSmallScreen
                                ? 13
                                : 14,
                      ),
                    ),
                    items: cars.map((car) {
                      return DropdownMenuItem(
                        value: car,
                        child: Text(
                          '${car['brand'] ?? ''} ${car['model'] ?? ''} (${car['plate_number'] ?? ''})',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: isVerySmallScreen
                                ? 12
                                : isSmallScreen
                                    ? 13
                                    : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.setSelectedCar(value);
                        _loadShiftsIfAvailable(value);
                      }
                    },
                  ),
                ),
              ),
            ],
          )),
    );
  }

  void _showDateFilterDialog(
      BuildContext context, bool isVerySmallScreen, bool isSmallScreen) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => WalletDateFilterDialog(
        isVerySmallScreen: isVerySmallScreen,
        isSmallScreen: isSmallScreen,
        initialFilter: controller.selectedDateFilter.value,
        initialStartDate: controller.startDate.value,
        initialEndDate: controller.endDate.value,
        onApply: (filter, startDate, endDate) {
          controller.setDateFilter(filter);
          if (filter == DateFilterType.personalized &&
              startDate != null &&
              endDate != null) {
            controller.setCustomDateRange(startDate, endDate);
          }
          controller.loadData();
        },
      ),
    );
  }

  void _showExpenseDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const ExpenseDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        // RepaintBoundary lets the fade/scale reuse a cached raster of the
        // dialog instead of repainting the whole form on every frame.
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: RepaintBoundary(child: child),
          ),
        );
      },
    );
  }

  // Transactions List Widget
  Widget _buildTransactionsList(
      AppLocalizations l10n, bool isVerySmallScreen, bool isSmallScreen) {
    return Obx(() {
      if (controller.isLoading.value) {
        return TransactionListSkeleton(
          isVerySmallScreen: isVerySmallScreen,
          isSmallScreen: isSmallScreen,
        );
      }

      final transactions = controller.filteredTransactions;

      if (transactions.isEmpty) {
        return Center(
          child: Text(
            l10n.translate('noTransactionsFound'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontSize: isVerySmallScreen
                  ? 12
                  : isSmallScreen
                      ? 13
                      : 14,
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          await controller.loadData();
        },
        child: ListView.builder(
          padding: EdgeInsets.only(
              bottom: isVerySmallScreen
                  ? 60
                  : isSmallScreen
                      ? 70
                      : 80),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return TransactionItemWidget(
              transaction: transaction,
              isVerySmallScreen: isVerySmallScreen,
              isSmallScreen: isSmallScreen,
              onDeleteExpense: () {
                final expense = transaction.asExpense;
                if (expense != null) {
                  _showDeleteExpenseConfirmation(expense, l10n);
                }
              },
              onDeleteRide: () {
                final ride = transaction.asRide;
                if (ride != null) {
                  _showDeleteRideConfirmation(ride, l10n);
                }
              },
            );
          },
        ),
      );
    });
  }

  void _showDeleteRideConfirmation(dynamic ride, AppLocalizations l10n) async {
    try {
      await controller.deleteRide(ride.id);
      if (Get.context != null) {
        CustomSnackBar.success(
          title: l10n.translate('Success'),
          message: l10n.translate('rideDeletedSuccess'),
        );
      }
    } catch (e) {
      if (Get.context != null) {
        CustomSnackBar.error(
          title: l10n.translate('Error'),
          message: l10n.translate('failedToDeleteRide'),
        );
      }
    }
  }

  void _showDeleteExpenseConfirmation(dynamic expense, AppLocalizations l10n) {
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.warning, color: AppColors.errorColor),
            SizedBox(width: 8),
            Text(
              l10n.translate('confirmDelete'),
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          l10n.translate('confirmDeleteExpense'),
          style: AppTextStyles.bodyMedium.copyWith(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.translate('cancel'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await controller.deleteExpense(expense.id);
                if (Get.context != null) {
                  CustomSnackBar.success(
                    title: l10n.translate('Success'),
                    message: l10n.translate('expenseDeletedSuccess'),
                  );
                }
              } catch (e) {
                if (Get.context != null) {
                  CustomSnackBar.error(
                    title: l10n.translate('Error'),
                    message: l10n.translate('expenseDeleteError'),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              l10n.translate('delete'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoCarSelectedMessage(AppLocalizations l10n) {
    return Center(
      child: Text(
        l10n.translate('selectACar'),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }

  // Dialog methods
  void _showRevenueDetailsDialog(
      AppLocalizations l10n, bool isVerySmallScreen, bool isSmallScreen) {
    showDialog(
      context: Get.context!,
      builder: (context) => RevenueDetailsDialog(
        isVerySmallScreen: isVerySmallScreen,
        isSmallScreen: isSmallScreen,
      ),
    );
  }

  void _showFilterDialog(
      AppLocalizations l10n, bool isVerySmallScreen, bool isSmallScreen) {
    showDialog(
      context: Get.context!,
      builder: (context) => TransactionFilterDialog(
        isVerySmallScreen: isVerySmallScreen,
        isSmallScreen: isSmallScreen,
      ),
    );
  }

  void _showCarSelectionDialog(BuildContext context, bool isSmallScreen) {
    showDialog(
      context: context,
      builder: (dialogContext) => CarSelectionDialog(
        isSmallScreen: isSmallScreen,
        selectedCar: controller.selectedCar.value,
        onCarSelected: (car) {
          controller.setSelectedCar(car);
          _loadShiftsIfAvailable(car);
        },
      ),
    );
  }

  void _showDeletedRidesDialog(
    BuildContext context,
    AppLocalizations l10n,
    bool isVerySmallScreen,
    bool isSmallScreen,
  ) {
    final deletedRides = controller.rides
        .where((ride) => ride.isDeleted == true)
        .toList()
      ..sort((a, b) => (b.startDate ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.startDate ?? DateTime.fromMillisecondsSinceEpoch(0)));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        backgroundColor: Colors.white,
        titlePadding: EdgeInsets.zero,
        contentPadding: EdgeInsets.zero,
        title: Container(
          padding: EdgeInsets.all(isVerySmallScreen
              ? 12
              : isSmallScreen
                  ? 14
                  : 16),
          decoration: BoxDecoration(
            color: AppColors.errorColor.withOpacity(0.08),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.errorColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.translate('deletedRides'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: isVerySmallScreen ? 14 : 16,
                  ),
                ),
              ),
              Text(
                '${deletedRides.length}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: isVerySmallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: deletedRides.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                  child: Text(
                    l10n.translate('noDeletedRidesFound'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.all(isVerySmallScreen
                      ? 12
                      : isSmallScreen
                          ? 14
                          : 16),
                  itemCount: deletedRides.length,
                  separatorBuilder: (_, __) => SizedBox(
                    height: isVerySmallScreen ? 8 : 10,
                  ),
                  itemBuilder: (context, index) {
                    final ride = deletedRides[index];
                    return _DeletedRideCard(
                      ride: ride,
                      isVerySmallScreen: isVerySmallScreen,
                      isSmallScreen: isSmallScreen,
                    );
                  },
                ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          isVerySmallScreen ? 12 : 16,
          0,
          isVerySmallScreen ? 12 : 16,
          isVerySmallScreen ? 12 : 16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.translate('cancel'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shift helpers ─────────────────────────────────────────────────────────────

  void _loadShiftsIfAvailable(Map<String, dynamic> car) {
    try {
      final sc = Get.find<ShiftController>();
      final carId = car['car_id']?.toString() ?? car['id']?.toString() ?? '';
      if (carId.isNotEmpty) {
        sc.loadShiftsForCar(carId);
      }
    } catch (_) {}
  }

  Widget _buildShiftFilterRow(AppLocalizations l10n, ShiftController sc,
      bool isVerySmallScreen, bool isSmallScreen) {
    final shifts = sc.state.value.shifts;
    final selected = sc.selectedShift;
    final carId = controller.selectedCar.value?['car_id']?.toString() ??
        controller.selectedCar.value?['id']?.toString() ??
        '';

    final chipHeight = isVerySmallScreen
        ? 28.0
        : isSmallScreen
            ? 30.0
            : 32.0;

    return Container(
      margin: EdgeInsets.only(bottom: isVerySmallScreen ? 4 : 6),
      padding: EdgeInsets.all(isVerySmallScreen ? 3 : 4),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: AppColors.lightCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: chipHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                children: [
                  // "All" chip
                  _ShiftChip(
                    label: l10n.translate('allShifts'),
                    icon: Icons.groups_2_rounded,
                    badge: '${shifts.length}',
                    selected: selected == null,
                    isVerySmallScreen: isVerySmallScreen,
                    isSmallScreen: isSmallScreen,
                    onTap: () => sc.selectShiftForFilter(null),
                  ),
                  ...shifts.map((s) => _ShiftChip(
                        label: s.driverName,
                        subtitle: s.timeLabel,
                        selected: s.id == selected?.id,
                        isVerySmallScreen: isVerySmallScreen,
                        isSmallScreen: isSmallScreen,
                        onTap: () => sc.selectShiftForFilter(s.id),
                      )),
                ],
              ),
            ),
          ),
          // Manage shifts button
          if (carId.isNotEmpty) ...[
            Container(
              width: 1,
              height: chipHeight * 0.5,
              margin:
                  EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 4 : 6),
              color: AppColors.borderColor,
            ),
            InkWell(
              onTap: () => Get.toNamed(
                Routes.shifts,
                arguments: {'carId': carId},
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: chipHeight,
                padding:
                    EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tune_rounded,
                        size: isVerySmallScreen ? 13 : 14,
                        color: AppColors.primaryColor),
                    if (!isSmallScreen) ...[
                      const SizedBox(width: 4),
                      Text(
                        l10n.translate('manage'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeletedRideCard extends StatelessWidget {
  final Ride ride;
  final bool isVerySmallScreen;
  final bool isSmallScreen;

  const _DeletedRideCard({
    required this.ride,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = ride.startDate != null
        ? DateFormatter.formatDateTime(ride.startDate!, context)
        : AppLocalizations.of(context).translate('unknownDate');

    return Container(
      padding: EdgeInsets.all(isVerySmallScreen
          ? 10
          : isSmallScreen
              ? 12
              : 14),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.errorColor.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_taxi,
                  color: AppColors.errorColor,
                  size: isVerySmallScreen ? 16 : 18,
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ride.car.brand} ${ride.car.model}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: isVerySmallScreen ? 11 : 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isVerySmallScreen ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: _infoPill(
                  icon: Icons.event,
                  label: dateText,
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 6 : 8),
              Expanded(
                child: _infoPill(
                  icon: Icons.payments_outlined,
                  label:
                      '${ride.rideAmount?.toStringAsFixed(3) ?? '0.000'} ${AppLocalizations.of(context).translate('currencySymbol')}',
                  isVerySmallScreen: isVerySmallScreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required bool isVerySmallScreen,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallScreen ? 8 : 10,
        vertical: isVerySmallScreen ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: isVerySmallScreen ? 12 : 14, color: AppColors.textPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontSize: isVerySmallScreen ? 10 : 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final String? badge;
  final bool selected;
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final VoidCallback onTap;

  const _ShiftChip({
    required this.label,
    required this.selected,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    final gap = isVerySmallScreen ? 4.0 : 5.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: EdgeInsetsDirectional.only(end: isVerySmallScreen ? 4 : 5),
        padding: EdgeInsets.symmetric(horizontal: isVerySmallScreen ? 6 : 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryColor : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.borderColor,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.22),
                    offset: const Offset(0, 2),
                    blurRadius: 5,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildLeading(),
            SizedBox(width: gap),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isVerySmallScreen
                      ? 72
                      : isSmallScreen
                          ? 84
                          : 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isVerySmallScreen ? 9.5 : 10.5,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                      height: 1.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: isVerySmallScreen ? 7.5 : 8.5,
                        fontWeight: FontWeight.w500,
                        color: selected
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textSecondary,
                        height: 1.1,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: gap),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 4 : 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isVerySmallScreen ? 8 : 9,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.primaryColor,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    if (icon != null) {
      return Icon(
        icon,
        size: isVerySmallScreen ? 13 : 14,
        color: selected ? Colors.white : AppColors.primaryColor,
      );
    }

    final trimmed = label.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
    final avatarSize = isVerySmallScreen ? 16.0 : 18.0;

    return Container(
      width: avatarSize,
      height: avatarSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? Colors.white.withOpacity(0.2)
            : AppColors.primaryColor.withOpacity(0.08),
      ),
      child: Text(
        initial,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: isVerySmallScreen ? 8.5 : 9.5,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : AppColors.primaryColor,
          height: 1.1,
        ),
      ),
    );
  }
}
