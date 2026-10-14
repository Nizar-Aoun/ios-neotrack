import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/l10n/app_localizations.dart';
import 'package:taxi_driver_app/models/ride.dart';
import 'package:taxi_driver_app/services/ride_service.dart';
import 'package:taxi_driver_app/services/routing_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class RideDetailsController extends GetxController
    with GetTickerProviderStateMixin {
  // Services
  late final RideService _rideService;
  final RoutingService _routingService = RoutingService();

  // Map controller
  MapController? mapController;

  // Input data
  final Ride ride;
  final String baseUrl;

  RideDetailsController({
    required this.ride,
    required this.baseUrl,
  });

  // Observable state variables
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxDouble playbackPosition = 0.0.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> locationHistory =
      <Map<String, dynamic>>[].obs;
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final RxDouble currentBearing = 0.0.obs;
  final RxBool isInitialPositionSet = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxDouble currentZoom = 16.0.obs;
  final RxBool isPlaying = false.obs;
  final RxDouble playbackSpeed = 1.0.obs;
  final RxDouble currentSpeed = 0.0.obs;
  final RxBool shouldFollowCar = true.obs;
  final RxBool isUserInteracting = false.obs;
  final RxString currentAddress = ''.obs;
  final RxBool isLoadingAddress = false.obs;
  final RxBool showAddressBubble = false.obs;
  final RxBool dateRangeAlert = false.obs;
  final Rxn<double> maxSpeed = Rxn<double>();
  final RxBool isPanelExpanded = true.obs;

  AnimationController? _centerAnimationController;

  // Private state
  Timer? _playbackTimer;
  Timer? _userInteractionTimer;
  Timer? _periodicAddressUpdateTimer;
  int _currentFareSegmentIndex = 0;
  double _currentFareSegmentFraction = 0.0;
  static const Duration _userInteractionTimeout = Duration(seconds: 3);
  static const Duration _periodicAddressUpdate = Duration(seconds: 2);
  LatLng? _lastMapCenter;
  int _mapMoveFrameCounter = 0;
  static const int _mapMoveEveryNFrames = 4;
  static const double _minMoveDistance = 0.00008;
  double _previousZoom = 16.0;

  @override
  void onInit() {
    super.onInit();
    mapController = MapController();
    _initializeServices();

    // Initialize animation controller
    _centerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Keep the screen awake while replaying the ride, like history tracking
    WakelockPlus.enable();
  }

  @override
  void onClose() {
    _periodicAddressUpdateTimer?.cancel();
    _playbackTimer?.cancel();
    _userInteractionTimer?.cancel();
    _centerAnimationController?.dispose();
    _routingService.clearCache();
    WakelockPlus.disable();
    super.onClose();
  }

  /// Where the map opens before the snapped route is ready, so the tiles are
  /// already around the ride instead of the null island while loading.
  LatLng get initialMapCenter {
    final current = currentPosition.value;
    if (current != null) return current;

    for (final location in ride.locations) {
      final coordinates = location.coordinates;
      if (coordinates.length >= 2) {
        return LatLng(coordinates[1], coordinates[0]);
      }
    }

    return const LatLng(36.8065, 10.1815); // Tunis
  }

  /// Real duration of the ride, used by the playback timeline labels.
  Duration get totalRideDuration {
    final start = ride.startDate;
    final end = ride.endDate;
    if (start == null || end == null) return Duration.zero;
    final duration = end.difference(start);
    return duration.isNegative ? Duration.zero : duration;
  }

  /// Ride time elapsed at the current playback position.
  Duration get elapsedRideDuration => Duration(
        milliseconds:
            (totalRideDuration.inMilliseconds * playbackPosition.value).round(),
      );

  /// Moves the playback cursor by a real-world duration.
  void seekBy(Duration offset) {
    final total = totalRideDuration.inMilliseconds;
    if (total <= 0) return;
    final delta = offset.inMilliseconds / total;
    updatePosition((playbackPosition.value + delta).clamp(0.0, 1.0));
  }

  /// Sends the playback cursor back to the departure point.
  void restartPlayback() => updatePosition(0.0);

  /// Retries loading the ride after a failure.
  Future<void> reload() => _loadRideDetails();

  void _initializeServices() {
    final carId = ride.car.id;
    _rideService = RideService(
      baseUrl: baseUrl,
      carId: carId,
    );
    _loadRideDetails();
  }

  Future<void> _loadRideDetails() async {
    isLoading.value = true;
    isInitialPositionSet.value = false;
    error.value = '';

    try {
      final response = await _rideService.getRideDetails(ride.id);
      dateRangeAlert.value = _extractDateRangeAlert(response);
      maxSpeed.value = _extractMaxSpeed(response);
      await _applyLocationHistory(_extractLocations(response));
    } catch (e) {
      if (ride.locations.isNotEmpty && await _applyFallbackRideData()) {
        return;
      }

      error.value = 'Failed to load ride details: $e';
      isLoading.value = false;
    }
  }

  Future<bool> _applyFallbackRideData() async {
    final fallbackLocations = ride.locations
        .map(
          (location) => {
            'timestamp': location.timestamp.toIso8601String(),
            'coordinates': location.coordinates,
          },
        )
        .toList();

    if (fallbackLocations.isEmpty) {
      return false;
    }

    dateRangeAlert.value = ride.dateRangeAlert;
    maxSpeed.value = ride.maxSpeed;
    await _applyLocationHistory(fallbackLocations);
    return true;
  }

  List<Map<String, dynamic>> _extractLocations(Map<String, dynamic> response) {
    final dynamic rawLocations = response['locations'] ??
        (response['ride'] is Map ? response['ride']['locations'] : null);

    if (rawLocations is List) {
      return List<Map<String, dynamic>>.from(rawLocations);
    }

    return <Map<String, dynamic>>[];
  }

  /// Safely parse a coordinates array into doubles.
  ///
  /// The backend can return whole-number coordinates as `int` (e.g. `[10, 36]`),
  /// which makes `List<double>.from(...)` throw "type 'int' is not a subtype of
  /// type 'double'". Converting each element via `num.toDouble()` avoids that.
  List<double> _parseCoordinates(dynamic raw) {
    if (raw is! List) return const <double>[];

    return raw
        .map((value) {
          if (value is num) return value.toDouble();
          if (value is String) return double.tryParse(value);
          return null;
        })
        .whereType<double>()
        .toList();
  }

  Future<void> _applyLocationHistory(
      List<Map<String, dynamic>> locations) async {
    if (locations.isEmpty) {
      error.value = 'No tracking data available for this ride';
      isLoading.value = false;
      return;
    }

    // Sort locations by timestamp in ascending order
    locations.sort((a, b) => DateTime.parse(a['timestamp'])
        .compareTo(DateTime.parse(b['timestamp'])));

    // Extract GPS points from coordinates array [longitude, latitude]
    final validLocations = <Map<String, dynamic>>[];
    final points = <LatLng>[];
    for (final location in locations) {
      final coordinates = _parseCoordinates(location['coordinates']);
      if (coordinates.length < 2) continue;
      validLocations.add(location);
      points.add(LatLng(coordinates[1], coordinates[0]));
    }

    if (points.isEmpty) {
      error.value = 'No valid GPS data';
      isLoading.value = false;
      return;
    }

    locationHistory.value = validLocations;
    final endpointSpeeds = List<int>.generate(validLocations.length, (i) => i)
        .map(_endpointSpeedKmh)
        .map((speed) => speed?.toStringAsFixed(1) ?? 'unavailable')
        .toList();
    debugPrint(
      '[Ride details] Endpoint location speeds (km/h): $endpointSpeeds',
    );

    currentPosition.value = points.first;

    if (points.length > 1) {
      currentBearing.value = _calculateBearing(points[0], points[1]);
    }

    // The ride endpoint's ordered GPS trace is the source of truth. Routing
    // each sparse pair through OSRM can invent shortcuts on a different road.
    routePoints.value = points;
    _setupInitialRoute();
  }

  bool _extractDateRangeAlert(Map<String, dynamic> response) {
    dynamic value;

    if (response.containsKey('date_range_alert')) {
      value = response['date_range_alert'];
    } else if (response.containsKey('ride') && response['ride'] is Map) {
      value = response['ride']['date_range_alert'];
    }

    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return ride.dateRangeAlert;
  }

  double? _extractMaxSpeed(Map<String, dynamic> response) {
    dynamic value = response['maxSpeed'] ?? response['max_speed'];

    if (value == null && response['ride'] is Map) {
      final rideMap = response['ride'] as Map;
      value = rideMap['maxSpeed'] ?? rideMap['max_speed'];
    }

    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);

    return ride.maxSpeed;
  }

  Future<void> _snapPointsToRoadProgressive(List<LatLng> allPoints) async {
    if (allPoints.isEmpty) return;

    try {
      final initialPortionSize = _calculateInitialPortionSize(allPoints.length);
      final initialPoints = allPoints.take(initialPortionSize).toList();

      await _showInitialRoute(initialPoints);

      if (allPoints.length > initialPortionSize) {
        _loadRemainingPoints(allPoints, initialPortionSize);
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      error.value = 'Error processing route: $e';
      _showRawPoints(allPoints);
    }
  }

  int _calculateInitialPortionSize(int totalPoints) {
    if (totalPoints <= 20) return totalPoints;
    if (totalPoints <= 50) return 20;
    if (totalPoints <= 100) return 30;
    return 40;
  }

  Future<void> _showInitialRoute(List<LatLng> initialPoints) async {
    try {
      final snappedPoints = await _routingService.snapToRoad(initialPoints);
      routePoints.value =
          snappedPoints.isNotEmpty ? snappedPoints : initialPoints;
      _setupInitialRoute();
    } catch (e) {
      routePoints.value = initialPoints;
      _setupInitialRoute();
    }
  }

  void _setupInitialRoute() {
    if (routePoints.isEmpty) return;

    currentPosition.value = routePoints.first;
    isInitialPositionSet.value = true;

    if (routePoints.length > 1) {
      currentBearing.value =
          _calculateBearing(routePoints.first, routePoints[1]);
    }

    isLoading.value = false;

    // Delay map operations to ensure FlutterMap is rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      _showRouteOnMap();
    });
  }

  void _showRouteOnMap() {
    if (routePoints.isEmpty || mapController == null) return;

    try {
      final bounds = LatLngBounds.fromPoints(routePoints);
      mapController!.fitCamera(CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ));

      Future.delayed(const Duration(milliseconds: 300), () {
        if (currentPosition.value != null && mapController != null) {
          try {
            mapController!.move(currentPosition.value!, 19.0);
          } catch (e) {
            // Error moving map
          }
        }
      });
    } catch (e) {
      // Error showing route on map
    }
  }

  void _loadRemainingPoints(
      List<LatLng> allPoints, int initialPortionSize) async {
    isLoadingMore.value = true;

    try {
      final remainingPoints = allPoints.skip(initialPortionSize).toList();
      final snappedRemaining =
          await _routingService.snapToRoad(remainingPoints);

      routePoints.value = [...routePoints, ...snappedRemaining];
    } catch (e) {
      // Error loading remaining points
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _showRawPoints(List<LatLng> points) {
    routePoints.value = points;
    _setupInitialRoute();
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final y = sin(endLng - startLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(endLng - startLng);
    final bearing = atan2(y, x);

    return (bearing * 180 / pi) % 360;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;

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

  void updatePosition(double value) {
    if (routePoints.isEmpty) return;

    final clampedValue = value.clamp(0.0, 1.0);
    playbackPosition.value = clampedValue;

    // Locate the GPS segment by endpoint timestamps so unevenly sampled
    // locations retain their real timing and the taxi speed varies naturally.
    final firstTime = _locationTimestamp(0);
    final lastTime = _locationTimestamp(routePoints.length - 1);
    var clampedIndex = 0;
    var fraction = 0.0;
    if (firstTime != null && lastTime != null && lastTime.isAfter(firstTime)) {
      final targetTime = firstTime.add(Duration(
        microseconds:
            (lastTime.difference(firstTime).inMicroseconds * clampedValue)
                .round(),
      ));
      clampedIndex = routePoints.length - 1;
      for (var i = 0; i < routePoints.length - 1; i++) {
        final start = _locationTimestamp(i);
        final end = _locationTimestamp(i + 1);
        if (start == null || end == null || !end.isAfter(start)) continue;
        if (!targetTime.isAfter(end)) {
          clampedIndex = i;
          fraction = targetTime.difference(start).inMicroseconds /
              end.difference(start).inMicroseconds;
          break;
        }
      }
    } else {
      final exactPosition = clampedValue * (routePoints.length - 1);
      clampedIndex =
          exactPosition.floor().clamp(0, routePoints.length - 1).toInt();
      fraction = exactPosition - clampedIndex;
    }

    _currentFareSegmentIndex = clampedIndex;
    _currentFareSegmentFraction = fraction.clamp(0.0, 1.0);

    if (clampedIndex < routePoints.length - 1) {
      final current = routePoints[clampedIndex];
      final next = routePoints[clampedIndex + 1];

      final lat =
          current.latitude + (next.latitude - current.latitude) * fraction;
      final lng =
          current.longitude + (next.longitude - current.longitude) * fraction;

      currentPosition.value = LatLng(lat, lng);
      currentBearing.value = _calculateBearing(current, next);

      final distance = _calculateDistance(current, next);
      currentSpeed.value = _endpointSpeedKmh(clampedIndex) ??
          _speedFromEndpointInterval(distance, clampedIndex);
    } else {
      currentPosition.value = routePoints[clampedIndex];
      if (clampedIndex > 0) {
        currentBearing.value = _calculateBearing(
          routePoints[clampedIndex - 1],
          routePoints[clampedIndex],
        );

        final distance = _calculateDistance(
          routePoints[clampedIndex - 1],
          routePoints[clampedIndex],
        );
        currentSpeed.value = _endpointSpeedKmh(clampedIndex) ??
            _speedFromEndpointInterval(distance, clampedIndex - 1);
      } else {
        currentSpeed.value = 0.0;
      }
    }

    if (shouldFollowCar.value && !isUserInteracting.value) {
      _smoothFollowCar();
    }
  }

  DateTime? _locationTimestamp(int index) {
    if (index < 0 || index >= locationHistory.length) return null;
    return DateTime.tryParse(
      locationHistory[index]['timestamp']?.toString() ?? '',
    );
  }

  double? _endpointSpeedKmh(int index) {
    if (index < 0 || index >= locationHistory.length) return null;
    final location = locationHistory[index];
    final value = location['speedKmh'] ??
        location['speed_kmh'] ??
        location['speed'];
    final speed = value is num ? value.toDouble() : double.tryParse('$value');
    if (speed == null || !speed.isFinite || speed < 0) return null;

    // The endpoint's ride detail speed is presented in km/h in this screen.
    return speed;
  }

  double _speedFromEndpointInterval(double distance, int index) {
    final start = _locationTimestamp(index);
    final end = _locationTimestamp(index + 1);
    if (start == null || end == null) return 0;
    final seconds = end.difference(start).inMicroseconds / 1000000;
    return seconds > 0 ? distance / seconds * 3.6 : 0;
  }

  // Smooth map following in real-time during playback
  void _smoothFollowCar() {
    if (currentPosition.value == null || mapController == null) return;

    // During playback, follow car in real-time on every frame
    if (isPlaying.value) {
      // Real-time synchronization: move map immediately with car
      final targetZoom = currentZoom.value < 14.0 ? 16.0 : currentZoom.value;
      mapController?.moveAndRotate(
        currentPosition.value!,
        targetZoom,
        0.0,
      );
    } else {
      // When not playing, use throttled movement
      _mapMoveFrameCounter++;
      if (_mapMoveFrameCounter < _mapMoveEveryNFrames) return;
      _mapMoveFrameCounter = 0;

      if (_lastMapCenter != null) {
        final distance =
            _calculateDistance(_lastMapCenter!, currentPosition.value!);
        if (distance < _minMoveDistance) return;
      }

      _lastMapCenter = currentPosition.value;
      mapController?.move(currentPosition.value!, currentZoom.value);
    }
  }

  void togglePlayback() {
    if (isPlaying.value) {
      stopPlayback();
    } else {
      startPlayback();
    }
  }

  void startPlayback() {
    if (routePoints.isEmpty) return;

    if (playbackPosition.value >= 1.0) {
      playbackPosition.value = 0.0;
    }

    _lastMapCenter = null;
    _mapMoveFrameCounter = 0;

    isPlaying.value = true;

    const updateInterval = 16; // 60 FPS smooth animation

    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(
      const Duration(milliseconds: updateInterval),
      (timer) {
        if (playbackPosition.value >= 1.0) {
          stopPlayback();
          return;
        }

        // Keep replay deliberately slow; speed choices scale this duration.
        final totalDuration = 120.0 / playbackSpeed.value; // seconds
        final increment = (updateInterval / 1000) / totalDuration;

        updatePosition((playbackPosition.value + increment).clamp(0.0, 1.0));
      },
    );
  }

  void stopPlayback() {
    isPlaying.value = false;
    _playbackTimer?.cancel();
    _lastMapCenter = null;
    _mapMoveFrameCounter = 0;
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    if (isPlaying.value) {
      stopPlayback();
      startPlayback();
    }
  }

  void onMapInteraction() {
    isUserInteracting.value = true;
    shouldFollowCar.value = false;

    _userInteractionTimer?.cancel();
    _userInteractionTimer = Timer(_userInteractionTimeout, () {
      isUserInteracting.value = false;
    });
  }

  // Handle zoom changes - disable auto-focus when user zooms
  void onZoomChange(double newZoom) {
    // Check if zoom actually changed (not just a position update)
    if ((newZoom - _previousZoom).abs() > 0.01) {
      // User is zooming in or out - disable auto-focus
      isUserInteracting.value = true;
      shouldFollowCar.value = false;
      currentZoom.value = newZoom;

      _userInteractionTimer?.cancel();
      _userInteractionTimer = Timer(_userInteractionTimeout, () {
        isUserInteracting.value = false;
      });
    }
    _previousZoom = newZoom;
  }

  void centerOnCar() {
    if (currentPosition.value == null || mapController == null) return;

    // Toggle follow mode on/off when button is clicked
    if (shouldFollowCar.value) {
      // Currently following, disable it
      shouldFollowCar.value = false;
      isUserInteracting.value = false;
    } else {
      // Currently not following, enable it
      shouldFollowCar.value = true;
      isUserInteracting.value = false;

      // Ensure optimal zoom level for car tracking
      final targetZoom = currentZoom.value < 15.0 ? 16.0 : currentZoom.value;
      currentZoom.value = targetZoom;

      // Always use smooth animation when centering
      _animateToCenter(currentPosition.value!, targetZoom);
    }
  }

  void _animateToCenter(LatLng targetPosition, double targetZoom) {
    if (mapController == null) return;

    final currentCenter = mapController!.camera.center;
    final currentZoom = mapController!.camera.zoom;

    final latTween = Tween<double>(
      begin: currentCenter.latitude,
      end: targetPosition.latitude,
    );
    final lngTween = Tween<double>(
      begin: currentCenter.longitude,
      end: targetPosition.longitude,
    );
    final zoomTween = Tween<double>(
      begin: currentZoom,
      end: targetZoom,
    );

    _centerAnimationController!.reset();

    final animation = CurvedAnimation(
      parent: _centerAnimationController!,
      curve: Curves.easeInOutCubic, // Smooth curve for natural movement
    );

    animation.addListener(() {
      if (mapController != null) {
        mapController!.move(
          LatLng(
            latTween.evaluate(animation),
            lngTween.evaluate(animation),
          ),
          zoomTween.evaluate(animation),
        );
      }
    });

    _centerAnimationController!.forward();
  }

  // Get colored segments for route visualization
  List<Polyline> getColoredSegments() {
    if (routePoints.isEmpty) return [];

    final playedIndex =
        (playbackPosition.value * (routePoints.length - 1)).round();

    return [
      // Played portion (primary color)
      if (playedIndex > 0)
        Polyline(
          points: routePoints.sublist(0, playedIndex + 1),
          strokeWidth: 5.0,
          color: AppColors.brandBlue,
        ),
      // Remaining portion (light gray)
      if (playedIndex < routePoints.length - 1)
        Polyline(
          points: routePoints.sublist(playedIndex),
          strokeWidth: 5.0,
          color: AppColors.surfaceMuted,
        ),
    ];
  }

  // Get playback time
  DateTime getPlaybackTime() {
    if (locationHistory.isEmpty ||
        ride.startDate == null ||
        ride.endDate == null) {
      return DateTime.now();
    }

    final start = ride.startDate!;
    final end = ride.endDate!;
    final duration = end.difference(start);
    final elapsed = Duration(
        milliseconds:
            (duration.inMilliseconds * playbackPosition.value).round());

    return start.add(elapsed);
  }

  // Get current speed at playback position
  double getCurrentSpeed() {
    return currentSpeed.value;
  }

  // Get current duration
  String getCurrentDuration(AppLocalizations l10n) {
    if (routePoints.isEmpty || ride.startDate == null || ride.endDate == null) {
      return '0 ${l10n.translate('minutes')}';
    }

    final start = ride.startDate!;
    final end = ride.endDate!;
    final totalDuration = end.difference(start);
    final currentDuration = Duration(
        milliseconds:
            (totalDuration.inMilliseconds * playbackPosition.value).round());

    if (currentDuration.inHours > 0) {
      return '${currentDuration.inHours}h ${currentDuration.inMinutes.remainder(60)}m';
    } else {
      return '${currentDuration.inMinutes} ${l10n.translate('minutes')}';
    }
  }

  // Get current distance traveled
  double getCurrentDistance() {
    if (routePoints.isEmpty) return 0.0;

    final currentIndex =
        (playbackPosition.value * (routePoints.length - 1)).round();
    double totalDistance = 0.0;

    for (int i = 0; i < currentIndex && i < routePoints.length - 1; i++) {
      totalDistance += _calculateDistance(routePoints[i], routePoints[i + 1]);
    }

    // Convert meters to kilometers
    return totalDistance / 1000;
  }

  // Get current taximeter status
  bool getCurrentTaximeter() {
    if (locationHistory.isEmpty) return false;

    final index =
        (playbackPosition.value * (locationHistory.length - 1)).round();
    final clampedIndex = index.clamp(0, locationHistory.length - 1);

    final location = locationHistory[clampedIndex];
    return location['taximeter'] == true || location['taximeter'] == 1;
  }

  // Get current fare
  double getCurrentFare() {
    if (locationHistory.isEmpty) return 0.0;

    final index = _currentFareSegmentIndex.clamp(0, locationHistory.length - 1);
    final currentFare = _parseTaximeterFare(locationHistory[index]);
    if (index >= locationHistory.length - 1) return currentFare ?? 0.0;

    final nextFare = _parseTaximeterFare(locationHistory[index + 1]);
    if (currentFare == null) return nextFare ?? 0.0;
    if (nextFare == null) return currentFare;

    return currentFare +
        (nextFare - currentFare) * _currentFareSegmentFraction;
  }

  double? _parseTaximeterFare(Map<String, dynamic> location) {
    final value = location['p_taxi'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  double getCarRotationAngle() {
    return currentBearing.value;
  }

  String getCarMarkerPath() {
    final carType = ride.car.carType;
    switch (carType) {
      case 'louage':
        return 'assets/images/louage_marker.png';
      case 'taxi':
        return 'assets/images/car_marker.png';
      default:
        return 'assets/images/car_marker.png';
    }
  }

  List<LatLng> getPlayedPoints() {
    final playedIndex =
        (playbackPosition.value * (routePoints.length - 1)).round();
    return routePoints.sublist(0, playedIndex + 1);
  }

  Color getLineColor() {
    return AppColors.brandBlue;
  }

  /// Fetch address from coordinates using Nominatim reverse geocoding
  Future<void> fetchAddressFromCoordinates(LatLng position) async {
    if (isLoadingAddress.value) return;

    isLoadingAddress.value = true;
    showAddressBubble.value = true;

    try {
      // Get current app language
      final locale = Get.locale?.languageCode ?? 'en';

      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');

      final response = await Future.any([
        http.get(url, headers: {
          'User-Agent': 'TaxiDriverApp/1.0',
          'Accept': 'application/json',
          'Accept-Language': locale,
        }),
        Future.delayed(const Duration(seconds: 8),
            () => throw TimeoutException('Request timeout')),
      ]);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data != null && data['display_name'] != null) {
          String address = data['display_name'];

          if (data['address'] != null) {
            final addressParts = <String>[];

            if (data['address']['road'] != null) {
              addressParts.add(data['address']['road']);
            }

            if (data['address']['suburb'] != null) {
              addressParts.add(data['address']['suburb']);
            } else if (data['address']['neighbourhood'] != null) {
              addressParts.add(data['address']['neighbourhood']);
            }

            if (data['address']['city'] != null) {
              addressParts.add(data['address']['city']);
            } else if (data['address']['town'] != null) {
              addressParts.add(data['address']['town']);
            } else if (data['address']['village'] != null) {
              addressParts.add(data['address']['village']);
            }

            if (addressParts.isNotEmpty) {
              address = addressParts.join(', ');
            }
          }

          currentAddress.value = address;
        } else {
          currentAddress.value = 'Unknown location';
        }
      } else {
        currentAddress.value = 'Address not available';
      }
    } catch (e) {
      currentAddress.value = 'Address not available';
    } finally {
      isLoadingAddress.value = false;
    }
  }

  /// Toggle address bubble visibility
  void toggleAddressBubble() {
    if (showAddressBubble.value) {
      showAddressBubble.value = false;
      _periodicAddressUpdateTimer?.cancel();
    } else if (currentPosition.value != null) {
      fetchAddressFromCoordinates(currentPosition.value!);
      // Start periodic updates if playing
      if (isPlaying.value) {
        _startPeriodicAddressUpdate();
      }
    }
  }

  /// Hide address bubble
  void hideAddressBubble() {
    showAddressBubble.value = false;
    _periodicAddressUpdateTimer?.cancel();
  }

  /// Start periodic address updates during playback
  void _startPeriodicAddressUpdate() {
    _periodicAddressUpdateTimer?.cancel();
    _periodicAddressUpdateTimer =
        Timer.periodic(_periodicAddressUpdate, (timer) {
      if (showAddressBubble.value &&
          currentPosition.value != null &&
          !isLoadingAddress.value) {
        fetchAddressFromCoordinates(currentPosition.value!);
      }
    });
  }
}

class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end})
      : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    return LatLng(
      begin!.latitude + (end!.latitude - begin!.latitude) * t,
      begin!.longitude + (end!.longitude - begin!.longitude) * t,
    );
  }
}
