import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/errors/error_messages.dart';
import 'package:taxi_driver_app/core/shared/custom_filed.dart';
import 'package:taxi_driver_app/core/shared/snackbar.dart';
import 'package:taxi_driver_app/core/shared/timepicker.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

/// Dialog to add or edit a shift.
class ShiftFormDialog extends StatefulWidget {
  final ShiftModel? existing;
  final Future<String?> Function({
    required String driverName,
    required String phoneNumber,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) onSave;

  const ShiftFormDialog({
    super.key,
    this.existing,
    required this.onSave,
  });

  @override
  State<ShiftFormDialog> createState() => _ShiftFormDialogState();
}

class _ShiftFormDialogState extends State<ShiftFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.driverName ?? '');
    _phoneCtrl =
        TextEditingController(text: widget.existing?.phoneNumber ?? '');
    _startTime =
        widget.existing?.startTime ?? const TimeOfDay(hour: 3, minute: 0);
    _endTime = widget.existing?.endTime ?? const TimeOfDay(hour: 2, minute: 59);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart, AppLocalizations l10n) async {
    final current = isStart ? _startTime : _endTime;
    final picked = await ModernTimePicker.show(
      context,
      DateTime(2000, 1, 1, current.hour, current.minute),
      l10n,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool _isOvernightPreview() {
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    return e < s;
  }

  String _previewDuration() {
    final start = _startTime.hour * 60 + _startTime.minute;
    final end = _endTime.hour * 60 + _endTime.minute;
    final minutes = end < start ? (24 * 60 - start) + end : end - start;
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) return '${hours}h';
    return '${hours}h${mins.toString().padLeft(2, '0')}';
  }

  Future<void> _submit(AppLocalizations l10n) async {
    setState(() => _error = null);

    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = l10n.translate('requiredField'));
      return;
    }

    setState(() => _saving = true);
    try {
      final errorMsg = await widget.onSave(
        driverName: _nameCtrl.text.trim(),
        phoneNumber: _phoneCtrl.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
      );
      if (!mounted) return;
      if (errorMsg == null) {
        Navigator.of(context).pop(true);
      } else {
        _showErrorSnackBar(l10n, errorMsg);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(
          l10n,
          friendlyErrorMessage(context, e, fallbackKey: 'shiftSaveError'),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isOverlapError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('overlap') ||
        lower.contains('time slot') ||
        lower.contains('existing shift');
  }

  void _showErrorSnackBar(AppLocalizations l10n, String message) {
    final isOverlap = _isOverlapError(message);
    final localizedMessage =
        isOverlap ? l10n.translate('shiftOverlapError') : message;
    CustomSnackBar.error(
      title: l10n.translate('shiftSaveError'),
      message: localizedMessage,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.existing != null;
    final isSmall = MediaQuery.of(context).size.width < 360;
    final radius = BorderRadius.circular(16);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 24,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: radius),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isSmall ? 320 : 360),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: Radius.circular(16),
                    bottomStart: Radius.circular(16),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isSmall ? 14 : 18),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: isSmall ? 36 : 40,
                              height: isSmall ? 36 : 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isEdit
                                    ? Icons.edit_outlined
                                    : Icons.add_rounded,
                                color: AppColors.primaryColor,
                                size: isSmall ? 18 : 20,
                              ),
                            ),
                            SizedBox(width: isSmall ? 10 : 12),
                            Expanded(
                              child: Text(
                                isEdit
                                    ? l10n.translate('editShift')
                                    : l10n.translate('addShift'),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: isSmall ? 15 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmall ? 14 : 16),
                        CustomTextField(
                          controller: _nameCtrl,
                          labelText: l10n.translate('driverName'),
                          prefixIcon: const Icon(Icons.person_outline),
                          borderRadius: 12,
                          filled: true,
                          fillColor: AppColors.surfaceColor,
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: _phoneCtrl,
                          labelText: l10n.translate('phoneNumber'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          borderRadius: 12,
                          filled: true,
                          fillColor: AppColors.surfaceColor,
                        ),
                        SizedBox(height: isSmall ? 14 : 16),
                        Text(
                          l10n.translate('shiftTime'),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: isSmall ? 12.5 : 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TimePicker(
                                label: l10n.translate('startTime'),
                                time: _startTime,
                                isSmall: isSmall,
                                onTap: () => _pickTime(true, l10n),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _TimePicker(
                                label: l10n.translate('endTime'),
                                time: _endTime,
                                isSmall: isSmall,
                                onTap: () => _pickTime(false, l10n),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _InfoPill(
                              icon: Icons.access_time_rounded,
                              label: '${_fmt(_startTime)} – ${_fmt(_endTime)}',
                              isSmall: isSmall,
                              forceLtr: true,
                            ),
                            _InfoPill(
                              icon: Icons.timelapse_rounded,
                              label: _previewDuration(),
                              isSmall: isSmall,
                            ),
                            if (_isOvernightPreview())
                              _InfoPill(
                                icon: Icons.nights_stay_rounded,
                                label: l10n.translate('overnight'),
                                accent: AppColors.warningColor,
                                filled: true,
                                isSmall: isSmall,
                              ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.errorColor,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                        SizedBox(height: isSmall ? 16 : 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textPrimary,
                                  side: const BorderSide(
                                      color: AppColors.borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(
                                  l10n.translate('cancel'),
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : () => _submit(l10n),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryColor,
                                  disabledBackgroundColor:
                                      AppColors.primaryColor.withOpacity(0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        l10n.translate('save'),
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final bool isSmall;
  final VoidCallback onTap;

  const _TimePicker({
    required this.label,
    required this.time,
    required this.isSmall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 10 : 12,
          vertical: isSmall ? 9 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          border: Border.all(color: AppColors.borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: isSmall ? 10 : 10.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 15, color: AppColors.primaryColor),
                const SizedBox(width: 6),
                Text(
                  formatted,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmall ? 14 : 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool filled;
  final bool forceLtr;
  final bool isSmall;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.isSmall,
    this.accent = AppColors.primaryColor,
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
