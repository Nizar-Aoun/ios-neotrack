import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/services/device_location_permission.dart';

/// Settings button uses the app primary color. Close icon dismisses the dialog.
Future<bool?> showLocationRequiredDialog(
  BuildContext context, {
  required bool serviceDisabled,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.translate(
                    serviceDisabled
                        ? 'locationServiceTitle'
                        : 'locationPermissionTitle',
                  ),
                  style: GoogleFonts.barlow(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: l10n.translate('cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        content: Text(
          l10n.translate(
            serviceDisabled
                ? 'locationServiceDisabled'
                : 'locationPermissionDenied',
          ),
          style: GoogleFonts.barlow(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                DeviceLocationPermission.openSettings(
                  serviceDisabled: serviceDisabled,
                );
              },
              child: Text(
                l10n.translate('openSettings'),
                style: GoogleFonts.barlow(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
