import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class ModernTimePicker {
  static Future<TimeOfDay?> show(
    BuildContext context,
    DateTime initialDateTime,
    AppLocalizations? l10n,
  ) async {
    int selectedHour = initialDateTime.hour;
    int selectedMinute = initialDateTime.minute;

    return await showDialog<TimeOfDay>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Theme(
              data: Theme.of(context).copyWith(
                dialogBackgroundColor: AppColors.cardColor,
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      surface: AppColors.cardColor,
                      primary: AppColors.brandBlue,
                      onPrimary: AppColors.textOnBrand,
                      onSurface: AppColors.textPrimary,
                    ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.brandBlue,
                  ),
                ),
              ),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.2),
                ),
                child: AlertDialog(
                  backgroundColor: AppColors.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: EdgeInsets.zero,
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.7,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                              child: Text(
                                l10n?.translate('selectTime') ?? 'Select Time',
                                style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16),
                                textAlign: TextAlign.left,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: AppColors.borderColor,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: SizedBox(
                                height: 240,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      // Hours picker
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              l10n?.translate('hour') ?? 'Hour',
                                              style: AppTextStyles.titleMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: ListWheelScrollView
                                                  .useDelegate(
                                                itemExtent: 40,
                                                diameterRatio: 1.5,
                                                physics:
                                                    const FixedExtentScrollPhysics(),
                                                controller:
                                                    FixedExtentScrollController(
                                                  initialItem: selectedHour,
                                                ),
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    selectedHour = index;
                                                  });
                                                },
                                                childDelegate:
                                                    ListWheelChildBuilderDelegate(
                                                  builder: (context, index) {
                                                    return Center(
                                                      child: Text(
                                                        index
                                                            .toString()
                                                            .padLeft(2, '0'),
                                                        style: AppTextStyles
                                                            .titleLarge
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: index ==
                                                                  selectedHour
                                                              ? AppColors
                                                                  .brandBlue
                                                              : AppColors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  childCount: 24,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Separator
                                      Container(
                                        width: 1,
                                        height: 120,
                                        color: AppColors.dividerColor
                                            .withOpacity(0.3),
                                      ),
                                      // Minutes picker
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Text(
                                              l10n?.translate('minute') ??
                                                  'Minute',
                                              style: AppTextStyles.titleMedium
                                                  .copyWith(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: ListWheelScrollView
                                                  .useDelegate(
                                                itemExtent: 40,
                                                diameterRatio: 1.5,
                                                physics:
                                                    const FixedExtentScrollPhysics(),
                                                controller:
                                                    FixedExtentScrollController(
                                                  initialItem: selectedMinute,
                                                ),
                                                onSelectedItemChanged: (index) {
                                                  setDialogState(() {
                                                    selectedMinute = index;
                                                  });
                                                },
                                                childDelegate:
                                                    ListWheelChildBuilderDelegate(
                                                  builder: (context, index) {
                                                    return Center(
                                                      child: Text(
                                                        index
                                                            .toString()
                                                            .padLeft(2, '0'),
                                                        style: AppTextStyles
                                                            .titleLarge
                                                            .copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: index ==
                                                                  selectedMinute
                                                              ? AppColors
                                                                  .brandBlue
                                                              : AppColors
                                                                  .textSecondary,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  childCount: 60,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text(
                                      l10n?.translate('cancel') ?? 'Cancel',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(
                                        TimeOfDay(
                                          hour: selectedHour,
                                          minute: selectedMinute,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonBg,
                                      foregroundColor: AppColors.textOnBase,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      l10n?.translate('ok') ?? 'OK',
                                      style: AppTextStyles.labelLarge.copyWith(
                                        color: AppColors.textOnBase,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
