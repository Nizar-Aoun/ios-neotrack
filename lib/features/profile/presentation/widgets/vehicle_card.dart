import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';

/// Stateless widget for displaying a vehicle card
class VehicleCard extends StatelessWidget {
  final Map<String, dynamic> car;
  final bool isSmallScreen;
  final String Function(String) translate;

  const VehicleCard({
    super.key,
    required this.car,
    required this.translate,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = car['isOnline'] == true || car['isOnline'] == 'true';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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
                    car['brand'] ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 12,
                    vertical: isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.driverOnline
                        : AppColors.driverOffline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnline ? translate('online') : translate('offline'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                _buildInfoRow(
                  translate('model'),
                  car['model'] ?? '-',
                  context,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _buildInfoRow(
                  translate('licensePlate'),
                  car['plate_number'] ?? '-',
                  context,
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                _buildInfoRow(
                  translate('year'),
                  car['year']?.toString() ?? '-',
                  context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isSmallScreen ? 13 : 15,
              color: AppColors.textSecondary,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isSmallScreen ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: isArabic ? TextAlign.left : TextAlign.right,
            textDirection: TextDirection.ltr,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
