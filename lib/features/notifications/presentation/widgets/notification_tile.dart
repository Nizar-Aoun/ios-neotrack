import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/models/notification.dart';
import 'package:taxi_driver_app/features/notifications/presentation/widgets/speed_alert_map_dialog.dart';

/// Notification Tile Widget - Displays a single notification
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String currentLanguage;
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.currentLanguage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.seen;
    final isSpeedAlert = notification.type == 'speed_alert';

    return GestureDetector(
      onTap: () {
        // If it's a speed alert with coordinates, show map dialog
        if (isSpeedAlert &&
            notification.coordinates != null &&
            notification.coordinates!.length == 2) {
          showDialog(
            context: context,
            builder: (context) => SpeedAlertMapDialog(
              coordinates: notification.coordinates!,
              title: notification.getTitle(currentLanguage),
              content: notification.getContent(currentLanguage),
              timestamp: notification.createdAt,
              speed: notification.speed,
              limit: notification.limit,
            ),
          );
        }
        // Call the original onTap callback if provided
        onTap?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isUnread
                ? AppColors.brandBlue.withOpacity(0.25)
                : AppColors.borderColor,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: _NotificationIcon(
            type: notification.type,
            isUnread: isUnread,
          ),
          title: Text(
            notification.getTitle(currentLanguage),
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: _NotificationContent(
            notification: notification,
            currentLanguage: currentLanguage,
            isUnread: isUnread,
          ),
          isThreeLine: true,
          trailing: isUnread ? const _UnreadIndicator() : null,
        ),
      ),
    );
  }
}

/// Notification Content Widget
class _NotificationContent extends StatelessWidget {
  final NotificationModel notification;
  final String currentLanguage;
  final bool isUnread;

  const _NotificationContent({
    required this.notification,
    required this.currentLanguage,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          notification.getContent(currentLanguage),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          notification.getTimeAgo(AppLocalizations.of(context)),
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Unread Indicator Dot
class _UnreadIndicator extends StatelessWidget {
  const _UnreadIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.brandBlue,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

/// Notification Icon Widget
class _NotificationIcon extends StatelessWidget {
  final String? type;
  final bool isUnread;

  const _NotificationIcon({
    required this.type,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.brandBlue.withOpacity(0.14)
            : AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getNotificationIcon(),
        color: isUnread ? AppColors.brandBlue : AppColors.textSecondary,
        size: 24,
      ),
    );
  }

  IconData _getNotificationIcon() {
    switch (type) {
      case 'speed_alert':
        return Icons.speed;
      case 'ride_completed':
        return Icons.check_circle;
      case 'new_message':
        return Icons.message;
      case 'system_update':
        return Icons.system_update;
      case 'payment':
        return Icons.payment;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.notifications;
    }
  }
}
