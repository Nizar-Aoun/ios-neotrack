import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/controllers/language_controller.dart';
import 'package:taxi_driver_app/features/notifications/provider/notification_controller.dart';
import 'package:taxi_driver_app/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:taxi_driver_app/core/shared/loading_gif.dart';

/// Notification List Widget - Displays the list of notifications with pagination
class NotificationList extends StatefulWidget {
  final NotificationController controller;

  const NotificationList({
    super.key,
    required this.controller,
  });

  @override
  State<NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<NotificationList> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _notificationKeys = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Check visibility after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibleNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _checkVisibleNotifications();
  }

  void _checkVisibleNotifications() {
    if (!mounted) return;

    final scrollViewContext = _scrollController.position.context.storageContext;
    final scrollViewBox = scrollViewContext.findRenderObject() as RenderBox?;
    if (scrollViewBox == null || !scrollViewBox.hasSize) return;

    final viewportHeight = scrollViewBox.size.height;

    for (final notification in widget.controller.notifications) {
      final key = _notificationKeys[notification.id];
      if (key?.currentContext == null) continue;

      final notificationBox =
          key!.currentContext!.findRenderObject() as RenderBox?;
      if (notificationBox == null || !notificationBox.hasSize) continue;

      final position =
          notificationBox.localToGlobal(Offset.zero, ancestor: scrollViewBox);
      final notificationHeight = notificationBox.size.height;

      // Check if at least 50% of the notification is visible
      final visibleTop = position.dy.clamp(0.0, viewportHeight);
      final visibleBottom =
          (position.dy + notificationHeight).clamp(0.0, viewportHeight);
      final visibleHeight = visibleBottom - visibleTop;
      final visibilityRatio = visibleHeight / notificationHeight;

      if (visibilityRatio >= 0.5) {
        widget.controller.onNotificationVisible(notification.id);
      } else {
        widget.controller.onNotificationHidden(notification.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageController = Get.find<LanguageController>();

    return Obx(() {
      final currentLanguage =
          languageController.currentLocale.value.languageCode;
      final itemCount = widget.controller.notifications.length +
          (widget.controller.hasMoreData.value ? 1 : 0);

      // Update keys for current notifications
      for (final notification in widget.controller.notifications) {
        if (!_notificationKeys.containsKey(notification.id)) {
          _notificationKeys[notification.id] = GlobalKey();
        }
      }

      return RefreshIndicator(
        onRefresh: () => widget.controller.fetchNotifications(refresh: true),
        color: AppColors.brandBlue,
        child: ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: itemCount,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            // Loading indicator for pagination
            if (index == widget.controller.notifications.length) {
              // Trigger load more only if not already loading
              if (!widget.controller.isLoading.value) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.controller.fetchNotifications();
                });
              }
              return const _PaginationLoader();
            }

            final notification = widget.controller.notifications[index];

            return NotificationTile(
              key: _notificationKeys[notification.id],
              notification: notification,
              currentLanguage: currentLanguage,
              onTap: () {
                // Mark as seen if not already seen
                if (!notification.seen) {
                  widget.controller.markAsSeen(notification.id);
                }
              },
            );
          },
        ),
      );
    });
  }
}

/// Pagination Loader Widget
class _PaginationLoader extends StatelessWidget {
  const _PaginationLoader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: LoadingGif(
          width: 60,
          height: 60,
        ),
      ),
    );
  }
}
