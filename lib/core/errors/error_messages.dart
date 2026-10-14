import 'package:flutter/material.dart';
import 'package:taxi_driver_app/core/errors/app_failure.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';

/// Converts any thrown error into a short, localized sentence for the user.
///
/// Raw exception text (stack traces, HTTP bodies, platform messages) never
/// reaches the UI; [fallbackKey] is used when the error has no known category.
String friendlyErrorMessage(
  BuildContext context,
  Object error, {
  String fallbackKey = 'errorUnexpected',
}) {
  final l10n = AppLocalizations.of(context);

  if (error is AppFailure) {
    switch (error.kind) {
      case AppFailureKind.network:
        return l10n.translate('errorNetwork');
      case AppFailureKind.unauthorized:
        return l10n.translate('errorSessionExpired');
      case AppFailureKind.fileTooLarge:
        return l10n.translate('errorPhotoTooLarge');
      case AppFailureKind.unsupportedFileType:
        return l10n.translate('errorPhotoUnsupported');
      case AppFailureKind.server:
      case AppFailureKind.unknown:
        return l10n.translate(fallbackKey);
    }
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('timeout') ||
      text.contains('network') ||
      text.contains('connection') ||
      text.contains('failed host lookup')) {
    return l10n.translate('errorNetwork');
  }
  if (text.contains('401') || text.contains('invalid token')) {
    return l10n.translate('errorSessionExpired');
  }

  return l10n.translate(fallbackKey);
}
