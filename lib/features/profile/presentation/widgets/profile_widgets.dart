import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/language_card.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/user_info_card.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/vehicle_card.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/modern_divider_widget.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/models/user.dart';

class PersonalInfoSection extends StatelessWidget {
  final Map<String, String> items;
  const PersonalInfoSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return UserInfoCard(items: items, isSmallScreen: isSmall);
  }
}

class ProfileActionsCard extends StatelessWidget {
  final VoidCallback onEditNameTap;
  final VoidCallback onChangeContactTap;

  const ProfileActionsCard({
    super.key,
    required this.onEditNameTap,
    required this.onChangeContactTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;

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
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('profileManagement'),
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isSmall ? 16 : 20),
            _ActionTile(
              icon: Icons.contact_phone_outlined,
              title: l10n.translate('changeContactInfo'),
              onTap: onChangeContactTap,
              isSmall: isSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSmall;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 20,
          vertical: isSmall ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandBlue, size: isSmall ? 20 : 24),
            SizedBox(width: isSmall ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppColors.textSecondary, size: isSmall ? 14 : 16),
          ],
        ),
      ),
    );
  }
}

class VehiclesSection extends StatelessWidget {
  final List<Map<String, dynamic>> cars;
  const VehiclesSection({super.key, required this.cars});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (cars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(l10n.translate('noVehiclesAvailable'),
              style: AppTextStyles.bodyMedium
                  .copyWith(fontSize: 16, color: AppColors.textSecondary)),
        ),
      );
    }
    return Column(
      children: cars
          .map((car) => Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: VehicleCard(
                  car: car,
                  translate: (key) => l10n.translate(key),
                  isSmallScreen: MediaQuery.of(context).size.width < 360,
                ),
              ))
          .toList(),
    );
  }
}

class PasswordSectionCard extends StatelessWidget {
  final VoidCallback onTap;
  const PasswordSectionCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ]),
      child: Padding(
        padding: EdgeInsets.all(isSmall ? 16 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.translate('security'),
              style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          SizedBox(height: isSmall ? 16 : 20),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 16 : 20, vertical: isSmall ? 12 : 16),
              decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor)),
              child: Row(children: [
                Icon(Icons.lock_outline,
                    color: AppColors.brandBlue, size: isSmall ? 20 : 24),
                SizedBox(width: isSmall ? 12 : 16),
                Expanded(
                    child: Text(l10n.translate('updatePassword'),
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary))),
                Icon(Icons.arrow_forward_ios,
                    color: AppColors.textSecondary, size: isSmall ? 16 : 18),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class AlertPreferencesSection extends StatelessWidget {
  final UserPreferences? preferences;
  final VoidCallback onSpeedTap;
  final VoidCallback onFreeStatusTap;
  final VoidCallback onStopTap;
  final VoidCallback onGeoTap;
  final ValueChanged<bool> onOpenDoorChanged;
  final ValueChanged<bool>? onSpeedChanged;
  final ValueChanged<bool>? onFreeStatusChanged;
  final ValueChanged<bool>? onStopChanged;
  final ValueChanged<bool>? onGeoChanged;
  final String? carType;

  const AlertPreferencesSection({
    super.key,
    required this.preferences,
    required this.onSpeedTap,
    required this.onFreeStatusTap,
    required this.onStopTap,
    required this.onGeoTap,
    required this.onOpenDoorChanged,
    this.onSpeedChanged,
    this.onFreeStatusChanged,
    this.onStopChanged,
    this.onGeoChanged,
    this.carType,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2)),
          ]),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 16 : 20, vertical: isSmall ? 16 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.translate('alertPreferences'),
              style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: isSmall ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          SizedBox(height: isSmall ? 16 : 20),
          _SwitchTile(
            title: l10n.translate('speedAlert'),
            subtitle: preferences?.speedAlert != null
                ? '${preferences!.speedAlert} km/h'
                : l10n.translate('notSet'),
            value: preferences?.speedAlert != null,
            onChanged: onSpeedChanged ??
                (enabled) {
                  if (enabled) {
                    onSpeedTap();
                  } else {
                    // Handle disabling the alert - call onSpeedChanged if provided
                  }
                },
            onTap: preferences?.speedAlert != null ? onSpeedTap : null,
            icon: Icons.speed,
          ),
          if (carType == null || carType == 'taxi') ...[
            const ModernDividerWidget(),
            _SwitchTile(
              title: l10n.translate('freeStatusAlert'),
              subtitle: _freeStatusText(l10n, preferences?.freeStatusAlert),
              value: preferences?.freeStatusAlert != null &&
                  ((preferences?.freeStatusAlert?.distance != null) ||
                      (preferences?.freeStatusAlert?.duration != null)),
              onChanged: onFreeStatusChanged ??
                  (enabled) {
                    if (enabled) {
                      onFreeStatusTap();
                    } else {
                      // Handle disabling
                    }
                  },
              onTap: (preferences?.freeStatusAlert != null)
                  ? onFreeStatusTap
                  : null,
              icon: Icons.access_time,
            ),
          ],
          const ModernDividerWidget(),
          _SwitchTile(
            title: l10n.translate('stopAlert'),
            subtitle: preferences?.stopAlert != null
                ? '${preferences!.stopAlert} min'
                : l10n.translate('notSet'),
            value: preferences?.stopAlert != null,
            onChanged: onStopChanged ??
                (enabled) {
                  if (enabled) {
                    onStopTap();
                  } else {
                    // Handle disabling
                  }
                },
            onTap: preferences?.stopAlert != null ? onStopTap : null,
            icon: Icons.stop,
          ),
          const ModernDividerWidget(),
          _SwitchTile(
            title: l10n.translate('geoForcingAlert'),
            subtitle: l10n.translate('geoForcingDescription'),
            value: preferences?.isGeoForcingEnabled ?? false,
            onChanged: onGeoChanged ?? (_) {},
            onTap: null,
            icon: Icons.location_on,
          ),
          const ModernDividerWidget(),
          _SwitchTile(
            title: l10n.translate('doorOpenAlarm'),
            subtitle: l10n.translate('doorOpenAlarmDescription'),
            value: preferences?.openDoor == true,
            onChanged: onOpenDoorChanged,
            onTap: null,
            icon: Icons.door_front_door,
          ),
        ]),
      ),
    );
  }

  String _freeStatusText(AppLocalizations l10n, FreeStatusAlert? alert) {
    if (alert == null) return l10n.translate('notSet');
    final parts = <String>[];
    if (alert.distance != null) parts.add('${alert.distance} km');
    if (alert.duration != null) parts.add('${alert.duration} min');
    return parts.isEmpty ? l10n.translate('notSet') : parts.join(', ');
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTap;
  final IconData? icon;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 360;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: value && onTap != null ? onTap : () => onChanged(!value),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isSmall ? 2 : 4),
        child: Row(children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.brandBlue, size: isSmall ? 18 : 21),
            SizedBox(width: isSmall ? 12 : 14),
          ],
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis),
              SizedBox(height: isSmall ? 2 : 4),
              Text(subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: isSmall ? 12 : 14,
                      color: AppColors.textTertiary,
                      fontWeight: value ? FontWeight.w500 : FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1),
            ]),
          ),
          SizedBox(width: isSmall ? 4 : 8),
          Transform.scale(
            scale: isSmall ? 0.7 : 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.brandBlue,
              inactiveTrackColor: AppColors.surfaceMuted,
              inactiveThumbColor: AppColors.surfaceColor,
            ),
          ),
        ]),
      ),
    );
  }
}

class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageCard(isSmallScreen: MediaQuery.of(context).size.width < 360);
  }
}
