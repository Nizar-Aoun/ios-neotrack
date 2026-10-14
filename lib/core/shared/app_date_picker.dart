import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/utils/date_formatter.dart';

/// Shows a date picker with Tunisian Arabic month names and Latin digits when
/// the app language is Arabic; otherwise uses the Material date picker.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerEntryMode initialEntryMode = DatePickerEntryMode.calendar,
  TransitionBuilder? builder,
}) {
  final locale = Localizations.localeOf(context);
  if (locale.languageCode == 'ar') {
    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        Widget child = _TunisianDatePickerDialog(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (builder != null) {
          child = builder(dialogContext, child);
        }
        return child;
      },
    );
  }

  return showDatePicker(
    context: context,
    locale: locale,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    initialEntryMode: initialEntryMode,
    builder: builder,
  );
}

/// Shared theme wrapper for date picker dialogs.
Widget appDatePickerThemeBuilder(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      dialogBackgroundColor: AppColors.cardColor,
      colorScheme: ColorScheme.light(
        primary: AppColors.brandBlue,
        onPrimary: AppColors.textOnBrand,
        surface: AppColors.cardColor,
        onSurface: AppColors.textPrimary,
      ),
    ),
    child: child!,
  );
}

class _TunisianDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _TunisianDatePickerDialog({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_TunisianDatePickerDialog> createState() =>
      _TunisianDatePickerDialogState();
}

class _TunisianDatePickerDialogState extends State<_TunisianDatePickerDialog> {
  static const _weekdayLabels = [
    'اثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
    'أحد',
  ];
  late DateTime _selectedDate;
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = _clampDate(widget.initialDate);
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  DateTime _clampDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final min = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final max = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    if (day.isBefore(min)) return min;
    if (day.isAfter(max)) return max;
    return day;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isSelectable(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final min = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final max = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    return !day.isBefore(min) && !day.isAfter(max);
  }

  bool get _canGoToPreviousMonth {
    final prev = DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    final min = DateTime(widget.firstDate.year, widget.firstDate.month);
    return !prev.isBefore(min);
  }

  bool get _canGoToNextMonth {
    final next = DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    final max = DateTime(widget.lastDate.year, widget.lastDate.month);
    return !next.isAfter(max);
  }

  void _goToPreviousMonth() {
    if (!_canGoToPreviousMonth) return;
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    if (!_canGoToNextMonth) return;
    setState(() {
      _displayedMonth =
          DateTime(_displayedMonth.year, _displayedMonth.month + 1);
    });
  }

  int _daysInMonth(DateTime month) =>
      DateTime(month.year, month.month + 1, 0).day;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monthName = DateFormatter.arabicMonths[_displayedMonth.month] ?? '';
    final yearText = _displayedMonth.year.toString();
    final daysInMonth = _daysInMonth(_displayedMonth);
    final firstWeekday =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;
    final leadingEmptyCells = firstWeekday - 1;
    final today = DateTime.now();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: AppColors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed:
                        _canGoToPreviousMonth ? _goToPreviousMonth : null,
                    icon: const Icon(Icons.chevron_right),
                    color: AppColors.brandBlue,
                  ),
                  Expanded(
                    child: Text(
                      '$monthName $yearText',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _canGoToNextMonth ? _goToNextMonth : null,
                    icon: const Icon(Icons.chevron_left),
                    color: AppColors.brandBlue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: _weekdayLabels
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w100,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: leadingEmptyCells + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingEmptyCells) {
                    return const SizedBox.shrink();
                  }

                  final day = index - leadingEmptyCells + 1;
                  final date = DateTime(
                    _displayedMonth.year,
                    _displayedMonth.month,
                    day,
                  );
                  final selectable = _isSelectable(date);
                  final selected = _isSameDay(date, _selectedDate);
                  final isToday = _isSameDay(date, today);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: selectable
                          ? () => setState(() => _selectedDate = date)
                          : null,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brandBlue
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !selected
                              ? Border.all(
                                  color: AppColors.brandBlue.withOpacity(0.5),
                                )
                              : null,
                        ),
                        child: Text(
                          day.toString(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: !selectable
                                ? AppColors.textTertiary.withOpacity(0.4)
                                : selected
                                    ? AppColors.textOnBrand
                                    : AppColors.textPrimary,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.translate('cancel'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selectedDate),
            child: Text(
              l10n.translate('ok'),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
