import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/profile/presentation/profile_screen.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/core/controllers/language_controller.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/features/notifications/provider/notification_controller.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';
import 'package:taxi_driver_app/features/home/presentation/widgets/profile_avatar.dart';
import 'package:taxi_driver_app/features/profile/application/profile_controller.dart';

class AppHeader extends StatelessWidget {
  final bool isSmallScreen;
  final int currentTabIndex;
  final Function(int) onTabChanged;

  const AppHeader({
    super.key,
    this.isSmallScreen = false,
    required this.currentTabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();
    final userController = Get.find<UserController>();
    final notificationController = Get.find<NotificationController>();
    final home = Get.find<HomeController>();
    final profileController = Get.find<ProfileController>();
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12.0 : 16.0,
          vertical: isSmallScreen ? 12.0 : 16.0,
        ),
        child: Obx(() {
          final isArabic =
              languageController.currentLocale.value.languageCode == 'ar';
          final unseenCount = notificationController.unseenCount.value;

          return Directionality(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile Avatar
                _buildProfileAvatar(
                  context,
                  imageUrl: userController.user.value?.fullProfilePhotoUrl ??
                      profileController.state.value.user?.fullProfilePhotoUrl,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ProfileScreenShell()),
                    );
                  },
                ),

                // Center Content
                if (currentTabIndex == 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 6 : 8,
                      vertical: isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTabButton(
                          context,
                          icon: Icons.location_on,
                          label: l10n.translate('liveTracking'),
                          isSelected: home.tabIndex.value == 0,
                          onTap: () => onTabChanged(0),
                          isSmallScreen: isSmallScreen,
                          compact: true,
                        ),
                        Container(
                          height: 20,
                          width: 1,
                          color: AppColors.brandBlue.withOpacity(0.08),
                        ),
                        _buildTabButton(
                          context,
                          icon: Icons.history,
                          label: l10n.translate('history'),
                          isSelected: home.tabIndex.value == 1,
                          onTap: () => onTabChanged(1),
                          isSmallScreen: isSmallScreen,
                          compact: true,
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Center(
                      child: _buildTitle(
                        currentTabIndex == 1
                            ? l10n.translate('wallet')
                            : currentTabIndex == 2
                                ? l10n.translate('Accueil')
                                : l10n.translate('help'),
                        currentTabIndex == 1
                            ? Icons.account_balance_wallet_rounded
                            : currentTabIndex == 2
                                ? Icons.home_rounded
                                : Icons.help_rounded,
                      ),
                    ),
                  ),

                // Notification Button
                _AnimatedNotificationButton(
                  isSmallScreen: isSmallScreen,
                  unseenCount: unseenCount,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfileAvatar(
    BuildContext context, {
    required String? imageUrl,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.brandBlue,
              AppColors.secondaryColor,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandBlue.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: ProfileAvatar(
            key: const ValueKey('header_profile_avatar'),
            imageUrl: imageUrl,
            onTap: onTap,
            radius: isSmallScreen ? 18 : 22,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.brandBlue,
            size: isSmallScreen ? 18 : 22,
          ),
        ),
        SizedBox(width: isSmallScreen ? 8 : 12),
        Text(
          title,
          style: AppTextStyles.appBarTitle.copyWith(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isSmallScreen,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal:
                compact ? (isSmallScreen ? 8 : 10) : (isSmallScreen ? 12 : 16),
            vertical:
                compact ? (isSmallScreen ? 6 : 8) : (isSmallScreen ? 8 : 10),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.brandBlue.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color:
                    isSelected ? AppColors.brandBlue : AppColors.textSecondary,
                size: compact
                    ? (isSmallScreen ? 14 : 16)
                    : (isSmallScreen ? 16 : 18),
              ),
              SizedBox(
                  width: compact
                      ? (isSmallScreen ? 4 : 6)
                      : (isSmallScreen ? 6 : 8)),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.brandBlue
                      : AppColors.textSecondary,
                  fontSize: compact
                      ? (isSmallScreen ? 10 : 11)
                      : (isSmallScreen ? 11 : 13),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Soft ring + badge pulse while there are unseen notifications.
class _AnimatedNotificationButton extends StatefulWidget {
  final bool isSmallScreen;
  final int unseenCount;

  const _AnimatedNotificationButton({
    required this.isSmallScreen,
    required this.unseenCount,
  });

  @override
  State<_AnimatedNotificationButton> createState() =>
      _AnimatedNotificationButtonState();
}

class _AnimatedNotificationButtonState
    extends State<_AnimatedNotificationButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bellSwing;
  late final Animation<double> _bellScale;
  late final Animation<double> _badgeScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Gentle bell swing in the first half of the cycle
    _bellSwing = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.18, end: -0.16), weight: 1.2),
      TweenSequenceItem(tween: Tween(begin: -0.16, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.0), weight: 1.2),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 3.5),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bellScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1.5),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 4.5),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _badgeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 1.4),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 4.6),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedNotificationButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.unseenCount != widget.unseenCount) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.unseenCount > 0) {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnseen = widget.unseenCount > 0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () => Get.toNamed('/notifications'),
              child: Transform.rotate(
                angle: hasUnseen ? _bellSwing.value : 0,
                alignment: Alignment.topCenter,
                child: Transform.scale(
                  scale: hasUnseen ? _bellScale.value : 1,
                  child: child,
                ),
              ),
            ),
            if (hasUnseen)
              Positioned(
                right: -2,
                top: -2,
                child: Transform.scale(
                  scale: _badgeScale.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.errorColor.withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      widget.unseenCount > 99
                          ? '99+'
                          : widget.unseenCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: Container(
        padding: EdgeInsets.all(widget.isSmallScreen ? 10 : 12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceColor,
          border: Border.all(
            color: AppColors.borderColor,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.notifications_rounded,
          size: widget.isSmallScreen ? 22 : 26,
          color: AppColors.brandBlue,
        ),
      ),
    );
  }
}
