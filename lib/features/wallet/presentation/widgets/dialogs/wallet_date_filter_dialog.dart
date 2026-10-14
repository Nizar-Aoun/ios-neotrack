import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/core/shared/timepicker.dart';
import 'package:taxi_driver_app/core/shared/app_date_picker.dart';
import '../../../domain/filter_types.dart';

class WalletDateFilterDialog extends StatefulWidget {
  final bool isVerySmallScreen;
  final bool isSmallScreen;
  final DateFilterType initialFilter;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateFilterType, DateTime?, DateTime?) onApply;

  const WalletDateFilterDialog({
    super.key,
    required this.isVerySmallScreen,
    required this.isSmallScreen,
    required this.initialFilter,
    this.initialStartDate,
    this.initialEndDate,
    required this.onApply,
  });

  @override
  State<WalletDateFilterDialog> createState() => _WalletDateFilterDialogState();
}

class _WalletDateFilterDialogState extends State<WalletDateFilterDialog> {
  late DateFilterType _tempFilter;
  DateTime? _tempStartDate;
  DateTime? _tempEndDate;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.initialFilter;
    _tempStartDate = widget.initialStartDate;
    _tempEndDate = widget.initialEndDate;
  }

  Future<void> _selectDateTime(bool isStart) async {
    final l10n = AppLocalizations.of(context)!;
    final initialDate = isStart
        ? (_tempStartDate ?? DateTime.now())
        : (_tempEndDate ?? DateTime.now());

    // First select date
    final pickedDate = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStart
          ? DateTime(DateTime.now().year - 2)
          : (_tempStartDate ?? DateTime(DateTime.now().year - 2)),
      lastDate: DateTime.now(),
      builder: appDatePickerThemeBuilder,
    );

    if (pickedDate != null && mounted) {
      // Then show time picker
      final pickedTime = await ModernTimePicker.show(
        context,
        pickedDate,
        l10n,
      );

      if (pickedTime != null && mounted) {
        setState(() {
          final dateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStart) {
            _tempStartDate = dateTime;
          } else {
            _tempEndDate = dateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: widget.isVerySmallScreen
            ? 8
            : widget.isSmallScreen
                ? 12
                : 16,
        vertical: widget.isVerySmallScreen
            ? 20
            : widget.isSmallScreen
                ? 24
                : 32,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.isVerySmallScreen
            ? 16
            : widget.isSmallScreen
                ? 20
                : 24),
      ),
      backgroundColor: Colors.white,
      elevation: 8,
      title: Container(
        padding: EdgeInsets.all(widget.isVerySmallScreen
            ? 8
            : widget.isSmallScreen
                ? 12
                : 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(widget.isVerySmallScreen
                ? 16
                : widget.isSmallScreen
                    ? 20
                    : 24),
            topRight: Radius.circular(widget.isVerySmallScreen
                ? 16
                : widget.isSmallScreen
                    ? 20
                    : 24),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt,
              color: AppColors.brandBlue,
              size: widget.isVerySmallScreen
                  ? 18
                  : widget.isSmallScreen
                      ? 20
                      : 22,
            ),
            SizedBox(
                width: widget.isVerySmallScreen
                    ? 8
                    : widget.isSmallScreen
                        ? 10
                        : 12),
            Text(
              l10n.translate('dateFilter'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: widget.isVerySmallScreen
                    ? 14
                    : widget.isSmallScreen
                        ? 16
                        : 18,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date filter options
            _buildFilterOption(
              DateFilterType.lastDay,
              l10n.translate('lastDay'),
              Icons.today,
            ),
            SizedBox(
                height: widget.isVerySmallScreen
                    ? 8
                    : widget.isSmallScreen
                        ? 10
                        : 12),
            _buildFilterOption(
              DateFilterType.lastWeek,
              l10n.translate('lastWeek'),
              Icons.view_week,
            ),
            SizedBox(
                height: widget.isVerySmallScreen
                    ? 8
                    : widget.isSmallScreen
                        ? 10
                        : 12),
            _buildFilterOption(
              DateFilterType.lastMonth,
              l10n.translate('lastMonth'),
              Icons.calendar_view_month,
            ),
            SizedBox(
                height: widget.isVerySmallScreen
                    ? 8
                    : widget.isSmallScreen
                        ? 10
                        : 12),
            _buildFilterOption(
              DateFilterType.personalized,
              l10n.translate('personalized'),
              Icons.date_range,
            ),

            // Show custom date range if personalized is selected
            if (_tempFilter == DateFilterType.personalized) ...[
              SizedBox(
                  height: widget.isVerySmallScreen
                      ? 12
                      : widget.isSmallScreen
                          ? 16
                          : 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _selectDateTime(true),
                      child: _buildDateTimeBox(
                        l10n.translate('start'),
                        _tempStartDate,
                      ),
                    ),
                  ),
                  SizedBox(
                      width: widget.isVerySmallScreen
                          ? 8
                          : widget.isSmallScreen
                              ? 10
                              : 12),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _selectDateTime(false),
                      child: _buildDateTimeBox(
                        l10n.translate('end'),
                        _tempEndDate,
                      ),
                    ),
                  ),
                ],
              ),
              // Add display for the selected date range
              if (_tempStartDate != null && _tempEndDate != null) ...[
                SizedBox(
                    height: widget.isVerySmallScreen
                        ? 16
                        : widget.isSmallScreen
                            ? 20
                            : 24),
                Container(
                  padding: EdgeInsets.all(widget.isVerySmallScreen
                      ? 8
                      : widget.isSmallScreen
                          ? 10
                          : 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(widget.isVerySmallScreen
                        ? 8
                        : widget.isSmallScreen
                            ? 10
                            : 12),
                    border: Border.all(
                      color: AppColors.secondaryColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${l10n.translate('selectedRange')}: ${_tempStartDate?.day.toString().padLeft(2, '0')}/${_tempStartDate?.month.toString().padLeft(2, '0')}/${_tempStartDate?.year} ${_tempStartDate?.hour.toString().padLeft(2, '0')}:${_tempStartDate?.minute.toString().padLeft(2, '0')} - ${_tempEndDate?.day.toString().padLeft(2, '0')}/${_tempEndDate?.month.toString().padLeft(2, '0')}/${_tempEndDate?.year} ${_tempEndDate?.hour.toString().padLeft(2, '0')}:${_tempEndDate?.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: widget.isVerySmallScreen
                          ? 12
                          : widget.isSmallScreen
                              ? 13
                              : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceAround,
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
          onPressed: () {
            widget.onApply(_tempFilter, _tempStartDate, _tempEndDate);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            l10n.translate('apply'),
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterOption(
    DateFilterType filterType,
    String label,
    IconData icon,
  ) {
    final isSelected = _tempFilter == filterType;

    return InkWell(
      onTap: () {
        setState(() {
          _tempFilter = filterType;
        });
      },
      borderRadius: BorderRadius.circular(widget.isVerySmallScreen
          ? 8
          : widget.isSmallScreen
              ? 10
              : 12),
      child: Container(
        padding: EdgeInsets.all(widget.isVerySmallScreen
            ? 10
            : widget.isSmallScreen
                ? 12
                : 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandBlue.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(widget.isVerySmallScreen
              ? 8
              : widget.isSmallScreen
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
              color: isSelected ? AppColors.brandBlue : AppColors.textSecondary,
              size: widget.isVerySmallScreen
                  ? 18
                  : widget.isSmallScreen
                      ? 20
                      : 22,
            ),
            SizedBox(
                width: widget.isVerySmallScreen
                    ? 8
                    : widget.isSmallScreen
                        ? 10
                        : 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      isSelected ? AppColors.brandBlue : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: widget.isVerySmallScreen
                      ? 12
                      : widget.isSmallScreen
                          ? 14
                          : 16,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.brandBlue,
                size: widget.isVerySmallScreen
                    ? 18
                    : widget.isSmallScreen
                        ? 20
                        : 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeBox(String label, DateTime? dateTime) {
    return Container(
      padding: EdgeInsets.all(widget.isVerySmallScreen
          ? 12
          : widget.isSmallScreen
              ? 14
              : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(widget.isVerySmallScreen
            ? 10
            : widget.isSmallScreen
                ? 12
                : 14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.borderColor,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.event,
                color: AppColors.brandBlue,
                size: widget.isVerySmallScreen
                    ? 14
                    : widget.isSmallScreen
                        ? 16
                        : 18,
              ),
              SizedBox(
                  width: widget.isVerySmallScreen
                      ? 6
                      : widget.isSmallScreen
                          ? 8
                          : 10),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: widget.isVerySmallScreen
                        ? 11
                        : widget.isSmallScreen
                            ? 12
                            : 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
              height: widget.isVerySmallScreen
                  ? 8
                  : widget.isSmallScreen
                      ? 10
                      : 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.textSecondary,
                size: widget.isVerySmallScreen
                    ? 12
                    : widget.isSmallScreen
                        ? 14
                        : 16,
              ),
              SizedBox(
                  width: widget.isVerySmallScreen
                      ? 4
                      : widget.isSmallScreen
                          ? 6
                          : 8),
              Flexible(
                child: Text(
                  dateTime != null
                      ? "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}"
                      : '--/--/----',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: widget.isVerySmallScreen
                        ? 13
                        : widget.isSmallScreen
                            ? 14
                            : 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
              height: widget.isVerySmallScreen
                  ? 4
                  : widget.isSmallScreen
                      ? 6
                      : 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.textSecondary,
                size: widget.isVerySmallScreen
                    ? 12
                    : widget.isSmallScreen
                        ? 14
                        : 16,
              ),
              SizedBox(
                  width: widget.isVerySmallScreen
                      ? 4
                      : widget.isSmallScreen
                          ? 6
                          : 8),
              Flexible(
                child: Text(
                  dateTime != null
                      ? "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}"
                      : '--:--',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontSize: widget.isVerySmallScreen
                        ? 13
                        : widget.isSmallScreen
                            ? 14
                            : 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
