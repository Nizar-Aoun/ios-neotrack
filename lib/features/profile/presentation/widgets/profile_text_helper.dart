import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/models/user.dart';

/// Helper class for text formatting in profile UI
class ProfileTextHelper {
  static String getFreeStatusAlertText(
    AppLocalizations l10n,
    FreeStatusAlert? alert,
  ) {
    final notSet = l10n.translate('notSet');
    if (alert == null) return notSet;
    final parts = <String>[];
    if (alert.distance != null) parts.add('${alert.distance} km');
    if (alert.duration != null) parts.add('${alert.duration} min');
    return parts.isEmpty ? notSet : parts.join(', ');
  }

  static String getGeoForcingAlertText(
    AppLocalizations l10n,
    GeoForcingAlert? alert,
  ) {
    final notSet = l10n.translate('geoForcingNotSet');
    if (alert == null) return notSet;
    final radiusKm = alert.radius / 1000;
    if (radiusKm >= 1) {
      return '${radiusKm.toStringAsFixed(1)} km radius';
    } else {
      return '${(alert.radius).toStringAsFixed(0)} m radius';
    }
  }

  static double calculateCircleSize(double radius, double zoom) {
    final baseSize = radius / 1000;
    final zoomFactor = (zoom - 10) / 5;
    final scaledSize = baseSize * 50 * (1 + zoomFactor * 0.5);
    return scaledSize.clamp(20.0, 300.0);
  }
}
