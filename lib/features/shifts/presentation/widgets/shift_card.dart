import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

Color shiftAccentColor(int index) {
  const colors = [
    AppColors.primaryColor,
    AppColors.brandBlue,
    AppColors.brandBlueDeep,
    AppColors.secondaryColor,
  ];
  return colors[index % colors.length];
}

/// Card widget representing a single shift.
class ShiftCard extends StatelessWidget {
  final ShiftModel shift;
  final bool isSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSelect;
  final int index;

  const ShiftCard({
    super.key,
    required this.shift,
    this.isSelected = false,
    required this.onEdit,
    required this.onDelete,
    this.onSelect,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSmall = MediaQuery.of(context).size.width < 360;
    final radius = BorderRadius.circular(14);
    final accent = shiftAccentColor(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: radius,
        border: Border.all(
          color: isSelected ? accent : AppColors.borderColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: AppColors.lightCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onSelect,
          borderRadius: radius,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(14),
                      bottomStart: Radius.circular(14),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isSmall ? 10 : 12,
                      isSmall ? 10 : 12,
                      isSmall ? 8 : 10,
                      isSmall ? 10 : 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildAvatar(isSmall, accent),
                            SizedBox(width: isSmall ? 8 : 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          shift.driverName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              AppTextStyles.bodyMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: isSmall ? 13 : 14,
                                            color: AppColors.textPrimary,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                      if (shift.isDefault) ...[
                                        const SizedBox(width: 4),
                                        Icon(Icons.star_rounded,
                                            size: 13, color: accent),
                                      ],
                                    ],
                                  ),
                                  if (shift.phoneNumber.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_rounded,
                                            size: 11,
                                            color: AppColors.textTertiary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            shift.phoneNumber,
                                            textDirection: TextDirection.ltr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.bodyMedium
                                                .copyWith(
                                              fontSize: isSmall ? 10.5 : 11,
                                              color: AppColors.textSecondary,
                                              height: 1.1,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            _ActionButton(
                              icon: Icons.edit_outlined,
                              tooltip: l10n.translate('edit'),
                              color: AppColors.primaryColor,
                              onTap: onEdit,
                              isSmall: isSmall,
                            ),
                            SizedBox(width: isSmall ? 4 : 5),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: l10n.translate('deleteShift'),
                              color: AppColors.errorColor,
                              onTap: onDelete,
                              isSmall: isSmall,
                            ),
                          ],
                        ),
                        SizedBox(height: isSmall ? 6 : 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Pill(
                              icon: Icons.access_time_rounded,
                              label: shift.timeLabel,
                              accent: accent,
                              isSmall: isSmall,
                              forceLtr: true,
                            ),
                            _Pill(
                              icon: Icons.timelapse_rounded,
                              label: _durationLabel(),
                              accent: accent,
                              isSmall: isSmall,
                            ),
                            if (shift.isOvernight)
                              _Pill(
                                icon: Icons.nights_stay_rounded,
                                label: l10n.translate('overnight'),
                                accent: AppColors.warningColor,
                                filled: true,
                                isSmall: isSmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isSmall, Color accent) {
    final size = isSmall ? 34.0 : 38.0;
    final trimmed = shift.driverName.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.10),
        border: Border.all(color: accent.withOpacity(0.16)),
      ),
      child: Text(
        initial,
        style: AppTextStyles.bodyMedium.copyWith(
          fontSize: isSmall ? 14 : 15,
          fontWeight: FontWeight.w700,
          color: accent,
          height: 1.1,
        ),
      ),
    );
  }

  String _durationLabel() {
    final hours = shift.durationMinutes ~/ 60;
    final minutes = shift.durationMinutes % 60;
    if (minutes == 0) return '${hours}h';
    return '${hours}h${minutes.toString().padLeft(2, '0')}';
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool filled;
  final bool forceLtr;
  final bool isSmall;

  const _Pill({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isSmall,
    this.filled = false,
    this.forceLtr = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 7,
        vertical: isSmall ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: filled ? accent.withOpacity(0.18) : accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isSmall ? 11 : 12, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            textDirection: forceLtr ? TextDirection.ltr : null,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isSmall ? 10 : 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 28.0 : 30.0;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: isSmall ? 15 : 16),
        ),
      ),
    );
  }
}

/// A compact chip/tag used to display the shift's driver name on a ride row.
class ShiftTag extends StatelessWidget {
  final ShiftModel? shift;

  const ShiftTag({super.key, this.shift});

  @override
  Widget build(BuildContext context) {
    if (shift == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline, size: 11, color: AppColors.primaryColor),
          const SizedBox(width: 3),
          Text(
            shift!.driverName,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 11,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
