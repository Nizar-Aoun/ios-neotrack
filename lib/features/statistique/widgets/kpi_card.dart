import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

/// Widget pour afficher une carte KPI
class KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? color;
  final bool isTimeFormat;

  const KpiCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.color,
    this.isTimeFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.6).toDouble();
    final compact = textScale > 1.15;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (color ?? AppColors.brandBlue).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: icon + optional trend/badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 7 : 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (color ?? AppColors.brandBlue).withOpacity(0.15),
                      (color ?? AppColors.brandBlue).withOpacity(0.07),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: compact ? 16 : 18,
                  color: color ?? AppColors.brandBlue,
                ),
              ),
              // Accent dot for visual interest
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: (color ?? AppColors.brandBlue).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 6 : 10),

          // Label
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: compact ? 12 : 13,
              letterSpacing: 0.2,
              height: 1.2,
            ),
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: compact ? 2 : 4),

          // Value + unit row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: _buildValueWidget(compact),
              ),
              if (!isTimeFormat) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: compact ? 9 : 10,
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: compact ? 0 : 2),
        ],
      ),
    );
  }

  Widget _buildValueWidget(bool compact) {
    if (isTimeFormat) {
      // Parse time format like "6h 30min"
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: value,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: compact ? 15 : 16,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Handle decimal values with smaller decimal part
    final parts = value.split('.');
    if (parts.length == 2) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: parts[0],
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: compact ? 15 : 16,
              ),
            ),
            TextSpan(
              text: '.${parts[1]}',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      value,
      style: AppTextStyles.headlineSmall.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: compact ? 15 : 16,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
