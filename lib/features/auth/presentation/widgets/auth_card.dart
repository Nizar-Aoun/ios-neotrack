import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

/// Shared surface used to visually group content throughout the auth flow.
class AuthCard extends StatelessWidget {
  const AuthCard({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = 520,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: padding ??
              EdgeInsets.all(
                isCompact ? AppColors.spacingM : AppColors.spacingL,
              ),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(isCompact ? 18 : 24),
            border: Border.all(color: AppColors.borderColor),
            boxShadow: const [
              BoxShadow(
                color: AppColors.lightShadowColor,
                offset: Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
