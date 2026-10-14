import 'dart:async';
import 'dart:math';
import 'package:latlong2/latlong.dart';

class GPSPoint {
  final LatLng position;
  final double speed; // km/h
  final DateTime timestamp;
  final double? bearing;
  final double? accuracy; // GPS accuracy in meters
  final double? rotationAngle; // Car rotation angle in degrees

  GPSPoint({
    required this.position,
    required this.speed,
    required this.timestamp,
    this.bearing,
    this.accuracy,
    this.rotationAngle,
  });

  GPSPoint copyWith({
    LatLng? position,
    double? speed,
    DateTime? timestamp,
    double? bearing,
    double? accuracy,
    double? rotationAngle,
  }) {
    return GPSPoint(
      position: position ?? this.position,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      bearing: bearing ?? this.bearing,
      accuracy: accuracy ?? this.accuracy,
      rotationAngle: rotationAngle ?? this.rotationAngle,
    );
  }
}

class SimpleGPSService {
  Timer? _interpolationTimer;
  GPSPoint? _currentPoint;
  GPSPoint? _targetPoint;
  DateTime? _interpolationStartTime;
  DateTime? _interpolationEndTime;
  double _interpolationProgress = 0.0;
  Function(GPSPoint)? _onPositionUpdate;
  bool _isInterpolating = false;

  /// Process GPS points without any filtering - use all locations received
  List<GPSPoint> processGPSPoints(List<GPSPoint> points) {
    // Simply return all points as-is, no filtering
    return points;
  }

  /// Start smooth interpolation between two GPS points
  void startInterpolation(
    GPSPoint from,
    GPSPoint to,
    Function(GPSPoint) onPositionUpdate,
  ) {
    _onPositionUpdate = onPositionUpdate;
    _currentPoint = from;
    _targetPoint = to;

    // Calculate interpolation duration based on actual time difference
    final timeDiff = to.timestamp.difference(from.timestamp).inMilliseconds;
    final durationMs = timeDiff > 0 ? timeDiff : 30000; // Default to 30 seconds

    _interpolationStartTime = DateTime.now();
    _interpolationEndTime = _interpolationStartTime!.add(Duration(milliseconds: durationMs));
    _interpolationProgress = 0.0;
    _isInterpolating = true;

    // Start interpolation timer
    _interpolationTimer?.cancel();
    _interpolationTimer = Timer.periodic(const Duration(milliseconds: 50), _updateInterpolation);
  }

  /// Update interpolation progress
  void _updateInterpolation(Timer timer) {
    if (!_isInterpolating || _currentPoint == null || _targetPoint == null) {
      timer.cancel();
      return;
    }

    final now = DateTime.now();
    if (now.isAfter(_interpolationEndTime!)) {
      // Interpolation complete
      _completeInterpolation();
      timer.cancel();
      return;
    }

    // Calculate progress
    final totalDuration = _interpolationEndTime!.difference(_interpolationStartTime!).inMilliseconds;
    final elapsed = now.difference(_interpolationStartTime!).inMilliseconds;
    _interpolationProgress = (elapsed / totalDuration).clamp(0.0, 1.0);

    // Apply easing curve for smooth movement
    final easedProgress = _applyEasingCurve(_interpolationProgress);

    // Interpolate position
    final interpolatedLat = _currentPoint!.position.latitude + 
        (_targetPoint!.position.latitude - _currentPoint!.position.latitude) * easedProgress;
    final interpolatedLng = _currentPoint!.position.longitude + 
        (_targetPoint!.position.longitude - _currentPoint!.position.longitude) * easedProgress;

    // Interpolate speed
    final interpolatedSpeed = _currentPoint!.speed + 
        (_targetPoint!.speed - _currentPoint!.speed) * easedProgress;

    // Interpolate bearing
    final interpolatedBearing = _interpolateBearing(
      _currentPoint!.bearing ?? 0.0,
      _targetPoint!.bearing ?? 0.0,
      easedProgress,
    );

    // Interpolate rotation angle
    final interpolatedRotationAngle = _interpolateBearing(
      _currentPoint!.rotationAngle ?? 0.0,
      _targetPoint!.rotationAngle ?? 0.0,
      easedProgress,
    );

    // Create interpolated point
    final interpolatedPoint = GPSPoint(
      position: LatLng(interpolatedLat, interpolatedLng),
      speed: interpolatedSpeed,
      timestamp: now,
      bearing: interpolatedBearing,
      accuracy: _currentPoint!.accuracy,
      rotationAngle: interpolatedRotationAngle,
    );

    // Notify listener
    _onPositionUpdate?.call(interpolatedPoint);
  }

  /// Complete interpolation
  void _completeInterpolation() {
    if (_targetPoint != null) {
      _onPositionUpdate?.call(_targetPoint!);
    }
    _isInterpolating = false;
    _currentPoint = null;
    _targetPoint = null;
    _interpolationStartTime = null;
    _interpolationEndTime = null;
    _interpolationProgress = 0.0;
  }

  /// Apply easing curve for smooth movement
  double _applyEasingCurve(double t) {
    // Use easeInOutCubic for smooth acceleration and deceleration
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }

  /// Interpolate bearing considering circular nature
  double _interpolateBearing(double from, double to, double progress) {
    // Handle bearing wrap-around
    double diff = to - from;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    
    return (from + diff * progress) % 360;
  }

  /// Calculate bearing between two points
  double calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final y = sin(endLng - startLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(endLng - startLng);
    final bearing = atan2(y, x);

    // Convert to degrees and adjust for car marker orientation
    // Add 90 degrees to align with typical car marker orientation
    return ((bearing * 180 / pi) + 90) % 360;
  }

  /// Calculate distance between two points
  double calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;
    
    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Stop interpolation
  void stop() {
    _interpolationTimer?.cancel();
    _isInterpolating = false;
    _currentPoint = null;
    _targetPoint = null;
    _interpolationStartTime = null;
    _interpolationEndTime = null;
    _interpolationProgress = 0.0;
  }

  /// Check if currently interpolating
  bool get isInterpolating => _isInterpolating;

  /// Reset the service state
  void reset() {
    stop();
  }
} 