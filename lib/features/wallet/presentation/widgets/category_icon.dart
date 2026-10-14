import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/models/category.dart';
import 'package:taxi_driver_app/utils/image_cache_helper.dart';

/// Expense category icon, decoded at a fraction of the asset's real size.
/// See [ImageCacheHelper.categoryIconProvider].
class CategoryIcon extends StatelessWidget {
  final Category category;
  final double size;
  final Color? fallbackColor;

  const CategoryIcon({
    super.key,
    required this.category,
    required this.size,
    this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    return Image(
      image: ImageCacheHelper.categoryIconProvider(category.iconAssetPath),
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.category,
        size: size,
        color: fallbackColor ?? AppColors.textSecondary,
      ),
    );
  }
}
