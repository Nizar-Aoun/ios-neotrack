import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/controller/home_controller.dart';

class CarSelectionDialog extends StatelessWidget {
  final bool isSmallScreen;
  final Map<String, dynamic>? selectedCar;
  final Function(Map<String, dynamic>) onCarSelected;

  const CarSelectionDialog({
    super.key,
    required this.isSmallScreen,
    required this.selectedCar,
    required this.onCarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final homeController = Get.find<HomeController>();

    final taxiCars = homeController.cars
        .where((c) => (c['car_type']?.toString().toLowerCase() ?? '') == 'taxi')
        .toList();

    if (taxiCars.isEmpty) {
      return AlertDialog(
        title: Text(l10n.translate('selectACar')),
        content: Text(l10n.translate('noTransactionsFound')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.translate('close')),
          ),
        ],
      );
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
      ),
      backgroundColor: Colors.white,
      title: Container(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isSmallScreen ? 16 : 20),
            topRight: Radius.circular(isSmallScreen ? 16 : 20),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.directions_car,
              color: AppColors.brandBlue,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            Expanded(
              child: Text(
                l10n.translate('selectACar'),
                style: AppTextStyles.titleMedium.copyWith(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: taxiCars.map((car) {
            final carKey = car['car_id'] ?? car['id'];
            final selectedKey = selectedCar?['car_id'] ?? selectedCar?['id'];
            final isSelected = carKey != null && carKey == selectedKey;
            return InkWell(
              onTap: () {
                onCarSelected(car);
                Navigator.of(context).pop();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.brandBlue.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(isSmallScreen ? 8 : 12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.brandBlue
                        : AppColors.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        color: AppColors.brandBlue,
                        size: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car['plate_number'] ?? '',
                            textDirection: TextDirection.ltr,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (car['model'] != null)
                            Text(
                              car['model'],
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.brandBlue,
                        size: isSmallScreen ? 20 : 24,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.translate('close'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
