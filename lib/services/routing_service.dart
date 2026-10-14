import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'dart:async'; // Added for Completer

class RoutingService {
  static const String _baseUrl = 'https://osrm.neos.tn';
  static const String _fallbackBaseUrl = 'https://router.project-osrm.org';
  static const double _closeDistanceThreshold = 10.0; // 10 meters in meters
  static const double _stationaryThreshold =
      5.0; // 5 meters for stationary detection
  static const double _gpsNoiseThreshold =
      20.0; // 20 meters for GPS noise detection
  static const int _maxConcurrentRequests = 3; // Limit concurrent API calls

  // Cache for route segments to avoid repeated API calls
  final Map<String, OsrmRouteResult> _routeCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Driving route between two points (A → B along roads).
  /// Prefer this over [snapToRoad] for simple origin/destination queries.
  Future<List<LatLng>> getDrivingRoute(
    LatLng start,
    LatLng end, {
    double? startBearing,
    double startBearingRange = 60.0,
  }) async {
    final result = await getRoute(
      start,
      end,
      profile: 'driving',
      startBearing: startBearing,
      startBearingRange: startBearingRange,
    );
    return result.points;
  }

  /// Road route with distance, duration, and the first named step.
  /// [profile] is OSRM `foot` or `driving`.
  Future<OsrmRouteResult> getRoute(
    LatLng start,
    LatLng end, {
    String profile = 'foot',
    double? startBearing,
    double startBearingRange = 60.0,
  }) async {
    return _fetchOsrmRoute(
      start,
      end,
      profile: profile,
      startBearing: startBearing,
      startBearingRange: startBearingRange,
    );
  }

  /// Calculate distance between two GPS coordinates in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLonRad = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Detect and handle GPS noise (sudden jumps)
  List<LatLng> _removeGpsNoise(List<LatLng> points) {
    if (points.length < 3) return points;

    List<LatLng> cleanedPoints = [points.first];

    for (int i = 1; i < points.length - 1; i++) {
      final prevPoint = points[i - 1];
      final currentPoint = points[i];
      final nextPoint = points[i + 1];

      final distanceToPrev = _calculateDistance(prevPoint, currentPoint);
      final distanceToNext = _calculateDistance(currentPoint, nextPoint);
      final distancePrevToNext = _calculateDistance(prevPoint, nextPoint);

      // Check if current point is a GPS noise (sudden jump)
      if (distanceToPrev > _gpsNoiseThreshold &&
          distanceToNext > _gpsNoiseThreshold &&
          distancePrevToNext < _gpsNoiseThreshold) {
        // This point is likely GPS noise, skip it
        continue;
      }

      cleanedPoints.add(currentPoint);
    }

    // Always include the last point
    if (cleanedPoints.isNotEmpty && cleanedPoints.last != points.last) {
      cleanedPoints.add(points.last);
    }

    return cleanedPoints;
  }

  /// Smart filtering that handles stationary periods and close coordinates
  List<LatLng> _smartFilterCoordinates(List<LatLng> points) {
    if (points.length <= 1) return points;

    List<LatLng> filteredPoints = [points.first];
    LatLng lastKeptPoint = points.first;
    bool isStationary = false;
    int stationaryCount = 0;

    for (int i = 1; i < points.length; i++) {
      final distance = _calculateDistance(lastKeptPoint, points[i]);

      if (distance < _stationaryThreshold) {
        // Car is stationary or moving very slowly
        stationaryCount++;
        if (!isStationary) {
          isStationary = true;
          // Keep the first stationary point to mark the stop
          filteredPoints.add(points[i]);
          lastKeptPoint = points[i];
        }
        // Skip subsequent stationary points unless we've been stationary for too long
        else if (stationaryCount % 5 == 0) {
          // Keep every 5th stationary point
          filteredPoints.add(points[i]);
          lastKeptPoint = points[i];
        }
      } else if (distance >= _closeDistanceThreshold) {
        // Car is moving significantly
        isStationary = false;
        stationaryCount = 0;
        filteredPoints.add(points[i]);
        lastKeptPoint = points[i];
      }
      // If distance is between thresholds, skip this point (minimal movement)
    }

    return filteredPoints;
  }

  /// Enhanced route snapping with improved performance and caching
  Future<List<LatLng>> snapToRoad(List<LatLng> points) async {
    if (points.isEmpty) return [];
    if (points.length == 1) return points;

    // First, remove GPS noise
    final cleanedPoints = _removeGpsNoise(points);

    // Then apply smart filtering
    final filteredPoints = _smartFilterCoordinates(cleanedPoints);

    if (filteredPoints.length <= 1) return filteredPoints;

    List<LatLng> routePoints = [];

    // Process points in optimized batches
    final batchSize = _calculateOptimalBatchSize(filteredPoints.length);
    final batches = _createBatches(filteredPoints, batchSize);

    // Use semaphore to limit concurrent requests
    final semaphore = _RequestSemaphore(_maxConcurrentRequests);

    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];

      // Process batch with controlled concurrency
      final batchResults = await Future.wait(batch
          .map((segment) =>
              semaphore.run(() => _getRouteSegment(segment.start, segment.end)))
          .toList());

      // Combine batch results
      for (int i = 0; i < batchResults.length; i++) {
        final segmentPoints = batchResults[i];
        if (segmentPoints.isNotEmpty) {
          if (batchIndex == 0 && i == 0) {
            // First segment, add all points
            routePoints.addAll(segmentPoints);
          } else {
            // Skip first point to avoid duplicates
            routePoints.addAll(segmentPoints.skip(1));
          }
        }
      }

      // Adaptive delay between batches based on server response
      if (batchIndex < batches.length - 1) {
        await Future.delayed(Duration(
            milliseconds: _calculateAdaptiveDelay(batchIndex, batches.length)));
      }
    }

    return routePoints.isEmpty ? filteredPoints : routePoints;
  }

  /// Calculate optimal batch size based on total points
  int _calculateOptimalBatchSize(int totalPoints) {
    if (totalPoints <= 10) return 3;
    if (totalPoints <= 50) return 5;
    if (totalPoints <= 100) return 8;
    return 10;
  }

  /// Calculate adaptive delay between batches
  int _calculateAdaptiveDelay(int batchIndex, int totalBatches) {
    // Start with shorter delays, increase as we progress
    final baseDelay = 30;
    final progressFactor = batchIndex / totalBatches;
    return (baseDelay + (progressFactor * 20)).round();
  }

  /// Create batches of route segments for parallel processing
  List<List<_RouteSegment>> _createBatches(List<LatLng> points, int batchSize) {
    List<List<_RouteSegment>> batches = [];
    List<_RouteSegment> currentBatch = [];

    for (int i = 0; i < points.length - 1; i++) {
      currentBatch.add(_RouteSegment(points[i], points[i + 1]));

      // If we've reached batch size, add this batch and start a new one
      if (currentBatch.length >= batchSize) {
        batches.add(List.from(currentBatch));
        currentBatch.clear();
      }
    }

    // Add remaining segments to the last batch
    if (currentBatch.isNotEmpty) {
      batches.add(currentBatch);
    }

    return batches;
  }

  /// Get route segment between two points with caching
  Future<List<LatLng>> _getRouteSegment(
    LatLng start,
    LatLng end, {
    double? startBearing,
    double startBearingRange = 60.0,
  }) async {
    final result = await _fetchOsrmRoute(
      start,
      end,
      profile: 'driving',
      startBearing: startBearing,
      startBearingRange: startBearingRange,
    );
    return result.points;
  }

  Future<OsrmRouteResult> _fetchOsrmRoute(
    LatLng start,
    LatLng end, {
    required String profile,
    double? startBearing,
    double startBearingRange = 60.0,
  }) async {
    final safeProfile = profile == 'driving' ? 'driving' : 'foot';
    final bearingKey = startBearing == null
        ? ''
        : '|b=${startBearing.round()}r=${startBearingRange.round()}';
    final cacheKey =
        '$safeProfile|${start.latitude},${start.longitude}-${end.latitude},${end.longitude}$bearingKey';

    if (_routeCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        final cachedRoute = _routeCache[cacheKey];
        if (cachedRoute != null) {
          return cachedRoute;
        }
      }
    }

    final distance = _calculateDistance(start, end);
    if (distance < 50) {
      final result = OsrmRouteResult(
        points: [start, end],
        distanceMeters: distance,
        durationSeconds: max(30, distance / 1.2),
      );
      _routeCache[cacheKey] = result;
      _cacheTimestamps[cacheKey] = DateTime.now();
      return result;
    }

    final bearingsQuery = startBearing == null
        ? ''
        : '&bearings=${startBearing.round()},${startBearingRange.round()};';

    for (final baseUrl in [_baseUrl, _fallbackBaseUrl]) {
      try {
        final url =
            '$baseUrl/route/v1/$safeProfile/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&steps=true$bearingsQuery';

        final response = await http.get(
          Uri.parse(url),
          headers: {'Accept': 'application/json'},
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final route = data['routes'][0] as Map<String, dynamic>;
            final geometry = route['geometry'];
            final coordinates = (geometry['coordinates'] as List).map((coord) {
              final list = (coord as List).map((e) => e.toDouble()).toList();
              return list;
            }).toList();

            final points =
                coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
            if (points.length <= 2 && distance >= 50) {
              continue;
            }

            final parsed = OsrmRouteResult(
              points: points,
              distanceMeters:
                  (route['distance'] as num?)?.toDouble() ?? distance,
              durationSeconds:
                  (route['duration'] as num?)?.toDouble() ?? (distance / 1.2),
              firstStepName: _firstNamedStep(route),
              firstManeuver: _firstManeuver(route),
            );
            _routeCache[cacheKey] = parsed;
            _cacheTimestamps[cacheKey] = DateTime.now();
            return parsed;
          }
        }
      } catch (_) {
        // Try next base URL
      }
    }

    return OsrmRouteResult(
      points: [start, end],
      distanceMeters: distance,
      durationSeconds: distance / 1.2,
    );
  }

  String? _firstNamedStep(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List || legs.isEmpty) return null;
    final steps = (legs.first as Map)['steps'];
    if (steps is! List) return null;
    for (final step in steps) {
      if (step is! Map) continue;
      final type = (step['maneuver'] is Map)
          ? step['maneuver']['type']?.toString()
          : null;
      if (type == 'depart' || type == 'arrive') continue;
      final name = step['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  String? _firstManeuver(Map<String, dynamic> route) {
    final legs = route['legs'];
    if (legs is! List || legs.isEmpty) return null;
    final steps = (legs.first as Map)['steps'];
    if (steps is! List) return null;
    for (final step in steps) {
      if (step is! Map) continue;
      final maneuver = step['maneuver'];
      if (maneuver is! Map) continue;
      final type = maneuver['type']?.toString();
      if (type == null || type == 'depart' || type == 'arrive') continue;
      final modifier = maneuver['modifier']?.toString();
      if (modifier != null && modifier.isNotEmpty) {
        return '$type $modifier';
      }
      return type;
    }
    return null;
  }

  /// Alternative method for very large datasets - simplified routing
  Future<List<LatLng>> snapToRoadSimplified(List<LatLng> points) async {
    if (points.isEmpty) return [];
    if (points.length == 1) return points;

    // Remove GPS noise first
    final cleanedPoints = _removeGpsNoise(points);

    // Apply smart filtering
    final filteredPoints = _smartFilterCoordinates(cleanedPoints);

    if (filteredPoints.length <= 1) return filteredPoints;

    // For very large datasets, use a simplified approach
    if (filteredPoints.length > 100) {
      return _simplifiedRouting(filteredPoints);
    }

    // For medium datasets, use optimized routing with smaller batches
    if (filteredPoints.length > 20) {
      return _optimizedRouting(filteredPoints);
    }

    // For smaller datasets, use the full routing
    return snapToRoad(filteredPoints);
  }

  /// Optimized routing for medium datasets
  Future<List<LatLng>> _optimizedRouting(List<LatLng> points) async {
    if (points.isEmpty) return [];
    if (points.length == 1) return points;

    List<LatLng> routePoints = [];

    // Process points in smaller batches for better performance
    final batchSize = 5; // Process up to 5 segments at once
    final batches = _createBatches(points, batchSize);

    // Use semaphore to limit concurrent requests
    final semaphore = _RequestSemaphore(_maxConcurrentRequests);

    for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];

      // Process batch with controlled concurrency
      final batchResults = await Future.wait(batch
          .map((segment) =>
              semaphore.run(() => _getRouteSegment(segment.start, segment.end)))
          .toList());

      // Combine batch results
      for (int i = 0; i < batchResults.length; i++) {
        final segmentPoints = batchResults[i];
        if (segmentPoints.isNotEmpty) {
          if (batchIndex == 0 && i == 0) {
            // First segment, add all points
            routePoints.addAll(segmentPoints);
          } else {
            // Skip first point to avoid duplicates
            routePoints.addAll(segmentPoints.skip(1));
          }
        }
      }

      // Add small delay between batches to avoid overwhelming the server
      if (batchIndex < batches.length - 1) {
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }

    return routePoints.isEmpty ? points : routePoints;
  }

  /// Simplified routing for large datasets - only route between significant points
  List<LatLng> _simplifiedRouting(List<LatLng> points) {
    List<LatLng> simplifiedPoints = [];

    // For very large datasets, use Douglas-Peucker algorithm or simple decimation
    if (points.length > 200) {
      // Keep every nth point to reduce complexity significantly
      final step = (points.length / 30).ceil(); // Keep max 30 points

      for (int i = 0; i < points.length; i += step) {
        simplifiedPoints.add(points[i]);
      }

      // Always include the last point
      if (simplifiedPoints.isNotEmpty && simplifiedPoints.last != points.last) {
        simplifiedPoints.add(points.last);
      }
    } else {
      // For moderately large datasets, use more points for better accuracy
      final step = (points.length / 15).ceil(); // Keep max 15 points

      for (int i = 0; i < points.length; i += step) {
        simplifiedPoints.add(points[i]);
      }

      // Always include the last point
      if (simplifiedPoints.isNotEmpty && simplifiedPoints.last != points.last) {
        simplifiedPoints.add(points.last);
      }
    }

    return simplifiedPoints;
  }

  /// Clear cache to free memory
  void clearCache() {
    _routeCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _routeCache.length,
      'cacheKeys': _routeCache.keys.toList(),
    };
  }
}

/// Road route returned by OSRM (geometry plus ETA metadata).
class OsrmRouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final String? firstStepName;
  final String? firstManeuver;

  const OsrmRouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.firstStepName,
    this.firstManeuver,
  });
}

/// Helper class for route segments
class _RouteSegment {
  final LatLng start;
  final LatLng end;

  _RouteSegment(this.start, this.end);
}

/// Semaphore to limit concurrent HTTP requests
class _RequestSemaphore {
  final int _maxConcurrent;
  int _current = 0;
  final List<Completer<void>> _waiting = [];

  _RequestSemaphore(this._maxConcurrent);

  Future<T> run<T>(Future<T> Function() operation) async {
    await _acquire();
    try {
      return await operation();
    } finally {
      _release();
    }
  }

  Future<void> _acquire() async {
    if (_current < _maxConcurrent) {
      _current++;
      return;
    }

    final completer = Completer<void>();
    _waiting.add(completer);
    await completer.future;
  }

  void _release() {
    _current--;
    if (_waiting.isNotEmpty) {
      final completer = _waiting.removeAt(0);
      completer.complete();
      _current++;
    }
  }
}
