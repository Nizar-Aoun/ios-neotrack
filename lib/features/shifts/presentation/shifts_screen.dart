import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/shared/shimmer_loading.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/features/shifts/application/shift_controller.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';
import 'package:taxi_driver_app/features/shifts/presentation/widgets/shift_card.dart';
import 'package:taxi_driver_app/features/shifts/presentation/widgets/shift_form_dialog.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

/// Screen to manage driver shifts for the currently selected car.
class ShiftsScreen extends GetView<ShiftController> {
  final String carId;

  const ShiftsScreen({super.key, required this.carId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Load shifts on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.currentCarId.value != carId) {
        controller.loadShiftsForCar(carId);
      }
    });

    final isSmall = MediaQuery.of(context).size.width < 360;

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _titleCase(l10n.translate('shifts')),
          style: GoogleFonts.barlow(
            fontWeight: FontWeight.bold,
            fontSize: isSmall ? 16 : 18,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderColor),
        ),
      ),
      body: Obx(() {
        final state = controller.state.value;

        if (state.isLoading) {
          return _ShiftsSkeleton(isSmall: isSmall);
        }

        if (state.hasError && state.shifts.isEmpty) {
          return _ErrorState(
            message: state.errorMessage!,
            retryLabel: l10n.translate('retry'),
            onRetry: () => controller.loadShiftsForCar(carId),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, isSmall ? 12 : 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CapacityCard(
                      used: state.shifts.length,
                      total: ShiftState.maxShifts,
                      title: l10n.translate('yourShifts'),
                      info: l10n.translate('shiftsInfo'),
                      isSmall: isSmall,
                    ),
                    SizedBox(height: isSmall ? 10 : 12),
                    if (state.canAddMore)
                      SizedBox(
                        width: double.infinity,
                        height: isSmall ? 44 : 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context, l10n),
                          icon: Icon(Icons.add_rounded,
                              color: Colors.white, size: isSmall ? 18 : 20),
                          label: Text(
                            l10n.translate('addShift'),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: isSmall ? 13 : 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    SizedBox(height: isSmall ? 10 : 12),
                  ],
                ),
              ),
            ),
            if (state.shifts.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyState(
                  title: l10n.translate('noShifts'),
                  isSmall: isSmall,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, index) {
                      final shift = state.shifts[index];
                      return ShiftCard(
                        shift: shift,
                        index: index,
                        onEdit: () => _showEditDialog(context, l10n, shift),
                        onDelete: () =>
                            _showDeleteConfirmation(context, l10n, shift),
                      );
                    },
                    childCount: state.shifts.length,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  String _titleCase(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;
    return trimmed[0].toUpperCase() + trimmed.substring(1);
  }

  void _showAddDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<bool>(
      context: context,
      builder: (_) => ShiftFormDialog(
        onSave: ({
          required driverName,
          required phoneNumber,
          required startTime,
          required endTime,
        }) =>
            controller.addShift(
          carId: carId,
          driverName: driverName,
          phoneNumber: phoneNumber,
          startTime: startTime,
          endTime: endTime,
        ),
      ),
    ).then((ok) {
      if (ok == true) {
        CustomSnackBar.success(
          title: l10n.translate('success'),
          message: l10n.translate('shiftAdded'),
        );
      }
    });
  }

  void _showEditDialog(BuildContext context, AppLocalizations l10n, shift) {
    showDialog<bool>(
      context: context,
      builder: (_) => ShiftFormDialog(
        existing: shift,
        onSave: ({
          required driverName,
          required phoneNumber,
          required startTime,
          required endTime,
        }) =>
            controller.updateShift(
          shift: shift,
          driverName: driverName,
          phoneNumber: phoneNumber,
          startTime: startTime,
          endTime: endTime,
        ),
      ),
    ).then((ok) {
      if (ok == true) {
        CustomSnackBar.success(
          title: l10n.translate('success'),
          message: l10n.translate('shiftUpdated'),
        );
      }
    });
  }

  void _showDeleteConfirmation(
      BuildContext context, AppLocalizations l10n, ShiftModel shift) {
    showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isSmall = MediaQuery.of(ctx).size.width < 360;
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(isSmall ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(Icons.delete_outline_rounded,
                          color: AppColors.errorColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.translate('deleteShift'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: isSmall ? 15 : 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.translate('confirmDeleteShift'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isSmall ? 13 : 14,
                    height: 1.4,
                  ),
                ),
                if (shift.driverName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${shift.driverName}  ·  ${shift.timeLabel}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.translate('cancel'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.errorColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          l10n.translate('delete'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((confirmed) async {
      if (confirmed == true && shift.id != null) {
        final ok = await controller.deleteShift(shift.id!);
        if (ok) {
          CustomSnackBar.success(
            title: l10n.translate('success'),
            message: l10n.translate('shiftDeleted'),
          );
        }
      }
    });
  }
}

/// Header card showing how many of the allowed shifts are configured.
class _CapacityCard extends StatelessWidget {
  final int used;
  final int total;
  final String title;
  final String info;
  final bool isSmall;

  const _CapacityCard({
    required this.used,
    required this.total,
    required this.title,
    required this.info,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = used >= total;

    return Container(
      padding: EdgeInsets.all(isSmall ? 12 : 14),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: AppColors.lightCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isSmall ? 34 : 38,
                height: isSmall ? 34 : 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.groups_2_rounded,
                    size: isSmall ? 18 : 20, color: AppColors.primaryColor),
              ),
              SizedBox(width: isSmall ? 10 : 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 14 : 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFull
                      ? AppColors.warningColor.withOpacity(0.2)
                      : AppColors.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$used / $total',
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isSmall ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isSmall ? 10 : 12),
          Row(
            children: List.generate(total, (index) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsetsDirectional.only(
                      end: index == total - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: index < used
                        ? shiftAccentColor(index)
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: isSmall ? 8 : 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  info,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: isSmall ? 10.5 : 11.5,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final bool isSmall;

  const _EmptyState({required this.title, required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, isSmall ? 28 : 40, 24, 0),
      child: Column(
        children: [
          Container(
            width: isSmall ? 72 : 84,
            height: isSmall ? 72 : 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.schedule_rounded,
              size: isSmall ? 32 : 38,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: isSmall ? 14 : 15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder shown while shifts load.
class _ShiftsSkeleton extends StatelessWidget {
  final bool isSmall;

  const _ShiftsSkeleton({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, isSmall ? 12 : 16, 16, 16),
        children: [
          // Capacity card
          Container(
            padding: EdgeInsets.all(isSmall ? 12 : 14),
            decoration: BoxDecoration(
              color: AppColors.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
              boxShadow: AppColors.lightCardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerBox(
                      width: isSmall ? 34 : 38,
                      height: isSmall ? 34 : 38,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    SizedBox(width: isSmall ? 10 : 12),
                    const ShimmerBox(width: 92, height: 13),
                    const Spacer(),
                    ShimmerBox(
                      width: 40,
                      height: 18,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
                SizedBox(height: isSmall ? 10 : 12),
                ShimmerBox(height: 4, borderRadius: BorderRadius.circular(2)),
                SizedBox(height: isSmall ? 10 : 12),
                const ShimmerBox(height: 10),
                const SizedBox(height: 5),
                const ShimmerBox(width: 160, height: 10),
              ],
            ),
          ),
          SizedBox(height: isSmall ? 10 : 12),
          ShimmerBox(
            height: isSmall ? 44 : 48,
            borderRadius: BorderRadius.circular(12),
          ),
          SizedBox(height: isSmall ? 10 : 12),
          ...List.generate(3, (_) => _ShiftCardSkeleton(isSmall: isSmall)),
        ],
      ),
    );
  }
}

class _ShiftCardSkeleton extends StatelessWidget {
  final bool isSmall;

  const _ShiftCardSkeleton({required this.isSmall});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: AppColors.lightCardShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadiusDirectional.only(
                  topStart: Radius.circular(14),
                  bottomStart: Radius.circular(14),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(isSmall ? 10 : 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShimmerBox(
                          width: isSmall ? 34 : 38,
                          height: isSmall ? 34 : 38,
                          shape: BoxShape.circle,
                        ),
                        SizedBox(width: isSmall ? 8 : 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBox(width: 110, height: 12),
                              SizedBox(height: 6),
                              ShimmerBox(width: 80, height: 9),
                            ],
                          ),
                        ),
                        ShimmerBox(
                          width: isSmall ? 28 : 30,
                          height: isSmall ? 28 : 30,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        const SizedBox(width: 5),
                        ShimmerBox(
                          width: isSmall ? 28 : 30,
                          height: isSmall ? 28 : 30,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmall ? 6 : 8),
                    Row(
                      children: [
                        ShimmerBox(
                          width: 86,
                          height: 18,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        const SizedBox(width: 6),
                        ShimmerBox(
                          width: 44,
                          height: 18,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.error_outline_rounded,
                    size: 30, color: AppColors.errorColor),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 18, color: Colors.white),
                  label: Text(
                    retryLabel,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
