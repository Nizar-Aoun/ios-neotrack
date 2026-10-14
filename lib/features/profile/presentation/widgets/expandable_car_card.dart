import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/profile_widgets.dart';
import 'package:taxi_driver_app/models/user.dart';

/// Expandable car card that combines vehicle info with alert preferences.
/// When showExpandable is true (multiple cars), preferences are shown in an expandable section.
/// When showExpandable is false (single car), preferences are shown directly below the car info.
class ExpandableCarCard extends StatefulWidget {
  final Map<String, dynamic> car;
  final UserPreferences? preferences;
  final bool showExpandable;
  final bool initiallyExpanded;
  final bool isSmallScreen;
  final String Function(String) translate;

  // Callbacks for preference dialogs
  final VoidCallback onSpeedTap;
  final VoidCallback onFreeStatusTap;
  final VoidCallback onStopTap;
  final VoidCallback onGeoTap;
  final ValueChanged<bool> onOpenDoorChanged;
  final ValueChanged<bool>? onSpeedChanged;
  final ValueChanged<bool>? onFreeStatusChanged;
  final ValueChanged<bool>? onStopChanged;
  final ValueChanged<bool>? onGeoChanged;

  const ExpandableCarCard({
    super.key,
    required this.car,
    required this.preferences,
    required this.showExpandable,
    this.initiallyExpanded = false,
    required this.translate,
    required this.onSpeedTap,
    required this.onFreeStatusTap,
    required this.onStopTap,
    required this.onGeoTap,
    required this.onOpenDoorChanged,
    this.onSpeedChanged,
    this.onFreeStatusChanged,
    this.onStopChanged,
    this.onGeoChanged,
    this.isSmallScreen = false,
  });

  @override
  State<ExpandableCarCard> createState() => _ExpandableCarCardState();
}

class _ExpandableCarCardState extends State<ExpandableCarCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.showExpandable && widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isOnline =
        widget.car['isOnline'] == true || widget.car['isOnline'] == 'true';

    if (!widget.showExpandable) {
      // Single car mode: Show car info and preferences directly without expansion
      return Column(
        children: [
          _buildCarInfoCard(isOnline),
          const SizedBox(height: 16),
          AlertPreferencesSection(
            preferences: widget.preferences,
            onSpeedTap: widget.onSpeedTap,
            onFreeStatusTap: widget.onFreeStatusTap,
            onStopTap: widget.onStopTap,
            onGeoTap: widget.onGeoTap,
            onOpenDoorChanged: widget.onOpenDoorChanged,
            onSpeedChanged: widget.onSpeedChanged,
            onFreeStatusChanged: widget.onFreeStatusChanged,
            onStopChanged: widget.onStopChanged,
            onGeoChanged: widget.onGeoChanged,
            carType: widget.car['car_type']?.toString(),
          ),
        ],
      );
    }

    // Multiple cars mode: Show expandable card
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car info header with expansion control
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(_isExpanded ? 0 : 16),
                  bottomRight: Radius.circular(_isExpanded ? 0 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    color: AppColors.brandBlue,
                    size: widget.isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(width: widget.isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Text(
                      widget.car['brand'] ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: widget.isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isSmallScreen ? 8 : 12,
                      vertical: widget.isSmallScreen ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.driverOnline
                          : AppColors.driverOffline,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOnline
                          ? widget.translate('online')
                          : widget.translate('offline'),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: widget.isSmallScreen ? 10 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: widget.isSmallScreen ? 8 : 12),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                    size: widget.isSmallScreen ? 24 : 28,
                  ),
                ],
              ),
            ),
          ),
          // Car details
          Padding(
            padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                _buildInfoRow(
                  widget.translate('model'),
                  widget.car['model'] ?? '-',
                  context,
                ),
                SizedBox(height: widget.isSmallScreen ? 6 : 8),
                _buildInfoRow(
                  widget.translate('licensePlate'),
                  widget.car['plate_number'] ?? '-',
                  context,
                ),
                SizedBox(height: widget.isSmallScreen ? 6 : 8),
                _buildInfoRow(
                  widget.translate('year'),
                  widget.car['year']?.toString() ?? '-',
                  context,
                ),
              ],
            ),
          ),
          // Expandable preferences section
          if (_isExpanded) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                widget.isSmallScreen ? 12 : 16,
                0,
                widget.isSmallScreen ? 12 : 16,
                widget.isSmallScreen ? 12 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: AppColors.borderColor,
                    thickness: 1,
                  ),
                  SizedBox(height: widget.isSmallScreen ? 12 : 16),
                  Text(
                    widget.translate('alertPreferences'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: widget.isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: widget.isSmallScreen ? 12 : 16),
                  // Use the existing AlertPreferencesSection but without the outer container
                  _buildInlinePreferences(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCarInfoCard(bool isOnline) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: AppColors.brandBlue,
                  size: widget.isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: widget.isSmallScreen ? 8 : 12),
                Expanded(
                  child: Text(
                    widget.car['brand'] ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: widget.isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.isSmallScreen ? 8 : 12,
                    vertical: widget.isSmallScreen ? 4 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.driverOnline
                        : AppColors.driverOffline,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOnline
                        ? widget.translate('online')
                        : widget.translate('offline'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: widget.isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: EdgeInsets.all(widget.isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                _buildInfoRow(
                  widget.translate('model'),
                  widget.car['model'] ?? '-',
                  context,
                ),
                SizedBox(height: widget.isSmallScreen ? 6 : 8),
                _buildInfoRow(
                  widget.translate('licensePlate'),
                  widget.car['plate_number'] ?? '-',
                  context,
                ),
                SizedBox(height: widget.isSmallScreen ? 6 : 8),
                _buildInfoRow(
                  widget.translate('year'),
                  widget.car['year']?.toString() ?? '-',
                  context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: widget.isSmallScreen ? 13 : 15,
              color: AppColors.textSecondary,
            ),
            textAlign: isArabic ? TextAlign.right : TextAlign.left,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: widget.isSmallScreen ? 13 : 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: isArabic ? TextAlign.left : TextAlign.right,
            textDirection: TextDirection.ltr,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Build preferences inline without the outer white container
  /// (since we're already inside the expandable card)
  Widget _buildInlinePreferences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSwitchTile(
          title: widget.translate('speedAlert'),
          subtitle: widget.preferences?.speedAlert != null
              ? '${widget.preferences!.speedAlert} km/h'
              : widget.translate('notSet'),
          value: widget.preferences?.speedAlert != null,
          onChanged: widget.onSpeedChanged ??
              (enabled) {
                if (enabled) {
                  widget.onSpeedTap();
                }
              },
          onTap:
              widget.preferences?.speedAlert != null ? widget.onSpeedTap : null,
          icon: Icons.speed,
        ),
        if (widget.car['car_type']?.toString() == null ||
            widget.car['car_type']?.toString() == 'taxi') ...[
          const Divider(color: AppColors.borderColor, height: 1),
          _buildSwitchTile(
            title: widget.translate('freeStatusAlert'),
            subtitle: _freeStatusText(widget.preferences?.freeStatusAlert),
            value: widget.preferences?.freeStatusAlert != null &&
                ((widget.preferences?.freeStatusAlert?.distance != null) ||
                    (widget.preferences?.freeStatusAlert?.duration != null)),
            onChanged: widget.onFreeStatusChanged ??
                (enabled) {
                  if (enabled) {
                    widget.onFreeStatusTap();
                  }
                },
            onTap: (widget.preferences?.freeStatusAlert != null)
                ? widget.onFreeStatusTap
                : null,
            icon: Icons.access_time,
          ),
        ],
        const Divider(color: AppColors.borderColor, height: 1),
        _buildSwitchTile(
          title: widget.translate('stopAlert'),
          subtitle: widget.preferences?.stopAlert != null
              ? '${widget.preferences!.stopAlert} min'
              : widget.translate('notSet'),
          value: widget.preferences?.stopAlert != null,
          onChanged: widget.onStopChanged ??
              (enabled) {
                if (enabled) {
                  widget.onStopTap();
                }
              },
          onTap:
              widget.preferences?.stopAlert != null ? widget.onStopTap : null,
          icon: Icons.stop,
        ),
        const Divider(color: AppColors.borderColor, height: 1),
        _buildSwitchTile(
          title: widget.translate('geoForcingAlert'),
          subtitle: widget.translate('geoForcingDescription'),
          value: widget.preferences?.isGeoForcingEnabled ?? false,
          onChanged: widget.onGeoChanged ?? (_) {},
          onTap: null,
          icon: Icons.location_on,
        ),
        const Divider(color: AppColors.borderColor, height: 1),
        _buildSwitchTile(
          title: widget.translate('doorOpenAlarm'),
          subtitle: widget.translate('doorOpenAlarmDescription'),
          value: widget.preferences?.openDoor == true,
          onChanged: widget.onOpenDoorChanged,
          onTap: null,
          icon: Icons.door_front_door,
        ),
      ],
    );
  }

  String _freeStatusText(FreeStatusAlert? alert) {
    if (alert == null) return widget.translate('notSet');
    final parts = <String>[];
    if (alert.distance != null) parts.add('${alert.distance} km');
    if (alert.duration != null) parts.add('${alert.duration} min');
    return parts.isEmpty ? widget.translate('notSet') : parts.join(', ');
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required VoidCallback? onTap,
    IconData? icon,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: value && onTap != null ? onTap : () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: widget.isSmallScreen ? 2 : 4),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  color: AppColors.brandBlue,
                  size: widget.isSmallScreen ? 18 : 21),
              SizedBox(width: widget.isSmallScreen ? 12 : 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: widget.isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: widget.isSmallScreen ? 2 : 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: widget.isSmallScreen ? 12 : 14,
                      color: AppColors.textTertiary,
                      fontWeight: value ? FontWeight.w500 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            SizedBox(width: widget.isSmallScreen ? 4 : 8),
            Transform.scale(
              scale: widget.isSmallScreen ? 0.7 : 0.8,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.brandBlue,
                inactiveTrackColor: AppColors.surfaceMuted,
                inactiveThumbColor: AppColors.surfaceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
