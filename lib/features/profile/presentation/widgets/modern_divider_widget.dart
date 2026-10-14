import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

class ModernDividerWidget extends StatelessWidget {
  const ModernDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: const Divider(
        color: AppColors.borderColor,
        thickness: 1.2,
        height: 1.2,
      ),
    );
  }
}
