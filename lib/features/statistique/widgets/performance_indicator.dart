import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';

/// Widget pour afficher l'indicateur de performance circulaire
class PerformanceIndicator extends StatelessWidget {
  final double value;
  final String badge;

  const PerformanceIndicator({
    super.key,
    required this.value,
    required this.badge,
  });

  Color _getBadgeColor() {
    // Color by 25% ranges
    if (value >= 76) return AppColors.successColor; // 76-100% = Green
    if (value >= 51) return AppColors.warningColor; // 51-75% = Yellow
    if (value >= 26) return AppColors.tertiaryColor; // 26-50% = Highlight
    return AppColors.errorColor; // 0-25% = Red
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: value / 100,
            strokeWidth: 6,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(_getBadgeColor()),
          ),
        ),
        Text(
          '${value.toStringAsFixed(0)}%',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
