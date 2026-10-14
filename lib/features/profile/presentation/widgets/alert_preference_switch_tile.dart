import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';

class AlertPreferenceSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;
  final bool enabled;

  const AlertPreferenceSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled && value && onTap != null
          ? onTap
          : (enabled ? () => onChanged(!value) : null),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 2 : 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 2 : 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: AppColors.textTertiary,
                      fontWeight: value ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: isSmallScreen ? 0.7 : 0.8,
              child: Theme(
                data: Theme.of(context).copyWith(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                ),
                child: Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeColor: AppColors.brandBlue,
                  inactiveTrackColor: AppColors.surfaceMuted,
                  inactiveThumbColor: AppColors.surfaceColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
