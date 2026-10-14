import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:feather_icons/feather_icons.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/services/permission_service.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';

class HomeBottomNavigationBar extends StatelessWidget {
  final bool isSmallScreen;
  const HomeBottomNavigationBar({super.key, required this.isSmallScreen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final home = Get.find<HomeController>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark ? Colors.black : Colors.white,
        border: Border(
          top: BorderSide(
            color: theme.brightness == Brightness.dark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
        left: 8,
        right: 8,
      ),
      child: Obx(() {
        final selectedIndex = home.selectedIndex.value;
        final isTaxiUser = home.hasTaxiCar;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (isTaxiUser)
              _buildNavItem(
                context,
                icon: FeatherIcons.home,
                label: l10n.translate('Accueil'),
                selected: selectedIndex ==
                    (PermissionService.hasWalletPermission(context) ? 2 : 1),
                index: PermissionService.hasWalletPermission(context) ? 2 : 1,
              ),
            _buildNavItem(
              context,
              icon: FeatherIcons.map,
              label: l10n.translate('map'),
              selected: selectedIndex == 0,
              index: 0,
            ),
            if (PermissionService.hasWalletPermission(context))
              _buildNavItem(
                context,
                icon: FeatherIcons.creditCard,
                label: l10n.translate('wallet'),
                selected: selectedIndex == 1,
                index: 1,
              ),
            _buildNavItem(
              context,
              icon: FeatherIcons.helpCircle,
              label: l10n.translate('help'),
              selected: selectedIndex ==
                  (PermissionService.hasWalletPermission(context) ? 3 : 2),
              index: PermissionService.hasWalletPermission(context) ? 3 : 2,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool selected,
    required int index,
  }) {
    final home = Get.find<HomeController>();
    final theme = Theme.of(context);
    final unselectedColor = theme.brightness == Brightness.dark
        ? Colors.white.withOpacity(0.5)
        : Colors.black.withOpacity(0.5);

    return Expanded(
      flex: selected ? 2 : 1,
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: InkWell(
          onTap: () => home.selectTab(index),
          splashColor: AppColors.primaryColor.withOpacity(0.1),
          highlightColor: AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: selected ? 0.85 + (value * 0.15) : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 12 : 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primaryColor.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: selected && value > 0
                        ? [
                            BoxShadow(
                              color: AppColors.primaryColor
                                  .withOpacity((0.2 * value).clamp(0.0, 1.0)),
                              blurRadius: (8 * value).clamp(0.1, 8.0),
                              offset: Offset(0, (2 * value).clamp(0.0, 2.0)),
                            )
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Icon(
                        icon,
                        size: selected ? 26 : 24,
                        color:
                            selected ? AppColors.primaryColor : unselectedColor,
                      ),
                      // Label appears next to icon when selected
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Opacity(
                            opacity: value.clamp(0.0, 1.0),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                                letterSpacing: 0.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
