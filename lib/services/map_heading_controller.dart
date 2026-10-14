import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Tunable heading-up navigation behavior.
///
/// Adjust these when rotation feels too sensitive or too sluggish:
/// - [deadbandDegrees]: ignore GPS jitter below this turn size.
/// - [minSpeedMetersPerSecond]: freeze rotation when GPS course is unreliable.
/// - [smoothing]: lerp factor per ~16 ms frame (higher = snappier).
class MapHeadingConfig {
  const MapHeadingConfig({
    this.deadbandDegrees = 3.5,
    this.minSpeedMetersPerSecond = 1.4,
    this.minMovementFallbackMeters = 4.0,
    this.smoothing = 0.10,
    this.snapDegrees = 0.4,
    this.maxHeadingAccuracyDegrees = 45.0,
  });

  /// Ignore heading changes smaller than this (degrees).
  /// 3.5° lets real turns start immediately; ~2° GPS wobble is still filtered
  /// by the lerp so the map does not step in 10° chunks.
  final double deadbandDegrees;

  /// GPS course is unstable below this speed (~5 km/h).
  final double minSpeedMetersPerSecond;

  /// Minimum travelled distance before deriving bearing from two points.
  final double minMovementFallbackMeters;

  /// Exponential lerp per ~16 ms tick. 0.10 glides a 45–90° turn instead of snapping.
  final double smoothing;

  /// Snap the remaining interpolation error under this.
  final double snapDegrees;

  /// Reject GPS heading when the device reports worse accuracy than this.
  final double maxHeadingAccuracyDegrees;
}

/// Angle helpers for 0–360° compass bearings.
class MapHeadingMath {
  MapHeadingMath._();

  /// Normalize to `[0, 360)`.
  static double normalize(double degrees) {
    var value = degrees % 360.0;
    if (value < 0) value += 360.0;
    return value;
  }

  /// Shortest signed delta from [fromDegrees] to [toDegrees] in `(-180, 180]`.
  ///
  /// 350° → 10° yields +20°, not -340°.
  static double shortestDelta(double fromDegrees, double toDegrees) {
    return normalize(toDegrees - fromDegrees + 180.0) - 180.0;
  }

  /// Forward azimuth from [from] to [to], clockwise from north, `[0, 360)`.
  static double bearingBetween(LatLng from, LatLng to) {
    return normalize(
      Geolocator.bearingBetween(
        from.latitude,
        from.longitude,
        to.latitude,
        to.longitude,
      ),
    );
  }

  static double distanceMeters(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
}

/// Filters GPS course and produces a smoothly interpolated heading-up rotation.
///
/// Does not own a location stream — callers feed existing [Position] updates.
class MapHeadingController {
  MapHeadingController({this.config = const MapHeadingConfig()});

  final MapHeadingConfig config;

  double _targetHeading = 0.0;
  double _displayedHeading = 0.0;
  bool _hasHeading = false;

  bool get hasHeading => _hasHeading;
  double get displayedHeading => _displayedHeading;

  /// flutter_map rotation is clockwise from north. Heading-up needs `-heading`
  /// so the vehicle direction stays at the top of the screen.
  double get mapRotationDegrees => -_displayedHeading;

  void reset() {
    _targetHeading = 0.0;
    _displayedHeading = 0.0;
    _hasHeading = false;
  }

  /// Extract a usable GPS course, or null when the sample is invalid.
  double? extractGpsCourse(Position position) {
    final heading = position.heading;
    if (heading.isNaN || heading.isInfinite || heading < 0) {
      return null;
    }

    final accuracy = position.headingAccuracy;
    if (accuracy > config.maxHeadingAccuracyDegrees) {
      return null;
    }

    // Many Android devices report heading=0 and accuracy=0 when course is unknown.
    if (heading == 0 && accuracy == 0) {
      return null;
    }

    return MapHeadingMath.normalize(heading);
  }

  /// Accept a GPS sample from the existing location stream.
  ///
  /// Low speed freezes the last accepted heading so a stopped vehicle does not
  /// spin. Tiny changes inside [MapHeadingConfig.deadbandDegrees] are ignored.
  void ingestPosition(
    Position position, {
    LatLng? previous,
    required LatLng current,
  }) {
    if (position.speed < config.minSpeedMetersPerSecond) {
      return;
    }

    double? bearing = extractGpsCourse(position);
    if (bearing == null && previous != null) {
      final travelled = MapHeadingMath.distanceMeters(previous, current);
      if (travelled >= config.minMovementFallbackMeters) {
        bearing = MapHeadingMath.bearingBetween(previous, current);
      }
    }
    if (bearing == null) return;

    if (!_hasHeading) {
      _targetHeading = bearing;
      _displayedHeading = bearing;
      _hasHeading = true;
      return;
    }

    final delta = MapHeadingMath.shortestDelta(_targetHeading, bearing);
    if (delta.abs() < config.deadbandDegrees) {
      return;
    }
    _targetHeading = bearing;
  }

  /// Advance interpolation by one frame. Returns true if the displayed heading
  /// changed enough to warrant a camera update.
  bool tick() {
    if (!_hasHeading) return false;

    final delta =
        MapHeadingMath.shortestDelta(_displayedHeading, _targetHeading);
    if (delta.abs() < config.snapDegrees) {
      if (delta.abs() < 0.05) return false;
      _displayedHeading = _targetHeading;
      return true;
    }

    _displayedHeading = MapHeadingMath.normalize(
      _displayedHeading + delta * config.smoothing,
    );
    return true;
  }
}
