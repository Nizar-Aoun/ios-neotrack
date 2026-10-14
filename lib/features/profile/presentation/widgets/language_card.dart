import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/core/controllers/language_controller.dart';

/// Stateless widget for language selection card
class LanguageCard extends StatelessWidget {
  final bool isSmallScreen;

  const LanguageCard({
    super.key,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageController = Get.find<LanguageController>();

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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('language'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Obx(() {
                final isFrench =
                    languageController.currentLocale.value.languageCode == 'fr';
                return Row(
                  children: [
                    Expanded(
                      child: _LanguageButton(
                        label: 'Français',
                        flag: '🇫🇷',
                        isSelected: isFrench,
                        onTap: () => languageController.setLanguage('fr'),
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LanguageButton(
                        label: 'العربية',
                        flag: '🇹🇳',
                        isSelected: !isFrench,
                        onTap: () => languageController.setLanguage('ar'),
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal widget for language button
class _LanguageButton extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSmallScreen;

  const _LanguageButton({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
    this.isSmallScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : 16,
          horizontal: isSmallScreen ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              flag,
              style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      isSelected ? AppColors.textOnBase : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: isSmallScreen ? 13 : 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
