import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/utils/image_cache_helper.dart';

class InfoItem extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final Color iconBg;
  final String label;
  final String value;
  final Color textColor;
  final String? valueFontFamily;
  final double? valueFontSize;
  final bool? colorImage;
  final bool? showLabel;

  const InfoItem({
    super.key,
    this.icon,
    this.imagePath,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.textColor,
    this.valueFontFamily,
    this.valueFontSize,
    this.colorImage,
    this.showLabel,
  }) : assert(icon != null || imagePath != null,
            'Either icon or imagePath must be provided');

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: iconBg.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(AppColors.spacingXS),
          child: imagePath != null
              ? ImageCacheHelper.buildAssetImage(
                  imagePath!,
                  width: AppColors.iconSizeL - 4,
                  height: AppColors.iconSizeL - 4,
                  color: colorImage ?? true ? iconBg : null,
                )
              : Icon(icon, color: iconBg, size: AppColors.iconSizeL - 4),
        ),
        const SizedBox(height: AppColors.spacingXXS),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showLabel ?? true) ...[
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: textColor.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              value,
              style: AppTextStyles.labelMedium.copyWith(
                color: textColor,
                fontSize: valueFontSize ?? 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
