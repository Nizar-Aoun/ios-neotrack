import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/core/theme/text_styles.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/features/profile/presentation/widgets/profile_dialogs.dart';
import 'package:taxi_driver_app/core/shared/custom_filed.dart';

/// Stateful dialog for speed alert configuration
class SpeedAlertDialog extends StatefulWidget {
  final double? initialValue;
  final Function(double) onSave;

  const SpeedAlertDialog({
    super.key,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<SpeedAlertDialog> createState() => _SpeedAlertDialogState();
}

class _SpeedAlertDialogState extends State<SpeedAlertDialog> {
  late final TextEditingController controller;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: Colors.white,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: isSmallScreen ? 280 : 320,
        ),
        padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('speedAlert'),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                l10n.translate('enterSpeedLimit'),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              CustomTextField(
                controller: controller,
                labelText: l10n.translate('speedLimit'),
                hintText: '0.0',
                suffixText: l10n.translate('km/h'),
                isNumber: true,
                allowDecimals: true,
                allowNegative: false,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.translate('requiredField');
                  }
                  final speed = double.tryParse(value);
                  if (speed == null) {
                    return l10n.translate('invalidNumber');
                  }
                  if (speed <= 0) {
                    return l10n.translate('mustBeGreaterThanZero');
                  }
                  if (speed > 200) {
                    return l10n.translate('maxSpeedExceeded');
                  }
                  return null;
                },
                borderRadius: 12,
                filled: true,
                fillColor: AppColors.surfaceColor,
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  DialogCancelButton(
                    onPressed: () => Navigator.pop(context),
                    label: l10n.translate('cancel'),
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  DialogSaveButton(
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        final speed = double.parse(controller.text);
                        widget.onSave(speed);
                        Navigator.pop(context);
                      }
                    },
                    label: l10n.translate('save'),
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
