import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';

/// Stateless widget for displaying user information card
class UserInfoCard extends StatelessWidget {
  final Map<String, String> items;
  final bool isSmallScreen;

  const UserInfoCard({
    super.key,
    required this.items,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    // Detect if current language is Arabic
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
        children: items.entries
            .map((entry) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: isSmallScreen ? 13 : 15,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: isSmallScreen ? 13 : 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          // In Arabic (RTL), align left; in LTR languages, align right
                          textAlign:
                              isArabic ? TextAlign.left : TextAlign.right,
                          textDirection: TextDirection.ltr,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
