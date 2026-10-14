import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null,
        child: imageUrl == null || imageUrl!.isEmpty
            ? Image.asset(
                'assets/images/icons8-add-user-male-94.png',
                width: radius * 1.2,
                height: radius * 1.2,
                fit: BoxFit.contain,
              )
            : null,
      ),
    );
  }
}
