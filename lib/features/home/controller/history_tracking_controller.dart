import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:taxi_driver_app/core/error/failure.dart';
import 'package:taxi_driver_app/core/theme/app_colors.dart';
import 'package:taxi_driver_app/services/car_service.dart';
import 'package:taxi_driver_app/services/routing_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class HistoryTrackingController extends GetxController
    with GetTickerProviderStateMixin {
  // Services
  late final CarService _carService;
  final RoutingService _routingService = RoutingService();

  // Map controller
  MapController? mapController;

  // Observable state variables
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final Rx<DateTime> selectedStartDate = DateTime.now()
      .subtract(const Duration(hours: 1))
      .obs; // Start date/time selected by user
  final RxDouble playbackPosition = 0.0.obs;
  final Rx<Map<String, dynamic>?> selectedVehicle =
      Rx<Map<String, dynamic>?>(null);
  final RxString dateError = ''.obs;
  final RxString error = ''.obs;
  final RxList<Map<String, dynamic>> locationHistory =
      <Map<String, dynamic>>[].obs;
  final Rx<LatLng?> currentPosition = Rx<LatLng?>(null);
  final RxDouble currentBearing = 0.0.obs;
  final Rx<double?> rotationAngle = Rx<double?>(null);
  final RxBool isInitialPositionSet = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxDouble currentZoom = 16.0.obs;
  final RxBool isDoorOpen = false.obs;
  final RxBool isPlaying = false.obs;
  final RxDouble playbackSpeed = 1.0.obs;
  final RxBool showRideCompletedCue = false.obs;
  final RxInt rideCompletedCueVersion = 0.obs;
  final Rxn<double> completedRideFare = Rxn<double>();
  final RxBool shouldFollowCar = true.obs;
  final RxBool isUserInteracting = false.obs;
  final RxString currentAddress = ''.obs;
  final RxBool isLoadingAddress = false.obs;
  final RxBool showAddressBubble = false.obs;

  // Playback panel state and route metrics used by the history UI
  final RxBool isPanelExpanded = true.obs;
  final RxDouble totalDistanceKm = 0.0.obs;
  final RxList<TaximeterRun> taximeterRuns = <TaximeterRun>[].obs;

  // Zoom limits
  static const double minZoom = 12.0;
  static const double maxZoom = 19.0;
  static const double defaultZoom = 16.0;

  // Animation controllers
  AnimationController? _centerAnimationController;
  Timer?
      _centerAnimationTimer; // Track centering animation to prevent conflicts

  // Private state
  Timer? _playbackTimer;
  Timer? _userInteractionTimer;
  Timer? _addressUpdateTimer;
  Timer? _periodicAddressUpdateTimer;
  Timer? _rideCompletedCueTimer;
  int? _lastPlaybackLocationIndex;
  static const Duration _userInteractionTimeout = Duration(seconds: 3);
  static const Duration _addressUpdateDebounce = Duration(milliseconds: 500);
  static const Duration _periodicAddressUpdate = Duration(seconds: 2);

  // Map following optimization variables
  LatLng? _lastMapCenter;
  int _mapMoveFrameCounter = 0;
  static const int _mapMoveEveryNFrames = 4; // For non-playback mode
  static const double _minMoveDistance = 0.00008; // ~8 meters
  double _previousZoom = 16.0; // Track previous zoom level

  // Computed properties
  DateTime get startDate => selectedStartDate.value;

  DateTime get endDate {
    // End date is automatically 1 hour after start date
    return selectedStartDate.value.add(const Duration(hours: 1));
  }

  bool get areDatesValid {
    if (startDate.isBefore(minAllowedDate)) return false;
    if (endDate.isAfter(DateTime.now())) return false;
    return true;
  }

  DateTime get minAllowedDate {
    return DateTime.now().subtract(const Duration(days: 15));
  }

  /// Timestamp of the first recorded point of the loaded history.
  DateTime? get historyStartTime => _timestampAt(0);

  /// Timestamp of the last recorded point of the loaded history.
  DateTime? get historyEndTime => _timestampAt(locationHistory.length - 1);

  /// Real duration covered by the loaded history (not the playback duration).
  Duration get totalHistoryDuration {
    final start = historyStartTime;
    final end = historyEndTime;
    if (start == null || end == null) return Duration.zero;
    final duration = end.difference(start);
    return duration.isNegative ? Duration.zero : duration;
  }

  /// Time elapsed between the first point and the current playback position.
  Duration get elapsedHistoryDuration {
    final start = historyStartTime;
    if (start == null) return Duration.zero;
    final elapsed = getPlaybackTime().difference(start);
    if (elapsed.isNegative) return Duration.zero;
    final total = totalHistoryDuration;
    return elapsed > total ? total : elapsed;
  }

  DateTime? _timestampAt(int index) {
    if (index < 0 || index >= locationHistory.length) return null;
    final raw = locationHistory[index]['timestamp'] as String?;
    return raw == null ? null : DateTime.tryParse(raw);
  }

  @override
  void onInit() {
    super.onInit();

    mapController = MapController();
    _initializeServices();

    // Initialize animation controllers
    _centerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Ensure initial date is within allowed range
    if (selectedStartDate.value.isBefore(minAllowedDate)) {
      selectedStartDate.value =
          DateTime.now().subtract(const Duration(hours: 1));
    }

    WakelockPlus.enable();
  }

  @override
  void onClose() {
    _playbackTimer?.cancel();
    _userInteractionTimer?.cancel();
    _addressUpdateTimer?.cancel();
    _periodicAddressUpdateTimer?.cancel();
    _rideCompletedCueTimer?.cancel();
    _centerAnimationTimer?.cancel();
    _centerAnimationController?.dispose();
    _routingService.clearCache();
    WakelockPlus.disable();
    super.onClose();
  }

  Future<void> _initializeServices() async {
    _carService = Get.find<CarService>();
  }

  void restoreState(Map<String, dynamic> preservedState) {
    selectedStartDate.value = preservedState['startDate'] ??
        DateTime.now().subtract(const Duration(hours: 1));
    selectedVehicle.value = preservedState['selectedVehicle'];
    locationHistory.value = preservedState['locationHistory'];
    routePoints.value = preservedState['routePoints'];
    playbackPosition.value = preservedState['playbackPosition'];
    isPlaying.value = preservedState['isPlaying'];
    playbackSpeed.value = preservedState['playbackSpeed'];
    isInitialPositionSet.value = true;

    if (routePoints.isNotEmpty) {
      currentPosition.value = routePoints.first;
      if (routePoints.length > 1) {
        currentBearing.value =
            _calculateBearing(routePoints.first, routePoints.last);
      }
    }

    _computeRouteMetrics();
  }

  void validateDates() {
    if (!areDatesValid) {
      dateError.value = 'Invalid date selection';
    } else {
      dateError.value = '';
    }
  }

  Future<void> fetchLocationHistory() async {
    if (selectedVehicle.value == null) {
      error.value = 'Please select a vehicle';
      return;
    }

    if (!areDatesValid) {
      error.value = 'Invalid date range';
      return;
    }

    isLoading.value = true;
    error.value = '';

    // Reset state when loading new data
    isInitialPositionSet.value = false;
    isUserInteracting.value = false;
    shouldFollowCar.value = true;
    _userInteractionTimer?.cancel();

    try {
      // Use car_id instead of id (matching old implementation)
      final carId =
          selectedVehicle.value!['car_id'] ?? selectedVehicle.value!['id'];

      // Format dates in local time (matching old implementation)
      final startDateStr =
          startDate.toIso8601String().replaceAll('Z', '+01:00');
      final endDateStr = endDate.toIso8601String().replaceAll('Z', '+01:00');

      final response = await _carService.getCarLocationHistory(
        carId,
        {
          'startDate': startDateStr,
          'endDate': endDateStr,
        },
      );

      if (response['locations'] != null && response['locations'].isNotEmpty) {
        final rawLocations =
            List<Map<String, dynamic>>.from(response['locations']);

        // Sort by timestamp ascending (oldest first)
        rawLocations.sort((a, b) => DateTime.parse(a['timestamp'])
            .compareTo(DateTime.parse(b['timestamp'])));

        // Filter out stationary/noise points
        final filteredLocations = _filterStationaryPoints(rawLocations);

        locationHistory.value = filteredLocations;
        _lastPlaybackLocationIndex = null;

        // Extract route points from filtered locations
        final points = filteredLocations
            .map((loc) {
              final coordinates = loc['coordinates'];
              if (coordinates != null &&
                  coordinates is List &&
                  coordinates.length >= 2) {
                // GeoJSON format: [longitude, latitude]
                final lng = (coordinates[0] as num?)?.toDouble();
                final lat = (coordinates[1] as num?)?.toDouble();
                if (lat != null && lng != null) {
                  return LatLng(lat, lng);
                }
              }
              return null;
            })
            .where((point) => point != null)
            .cast<LatLng>()
            .toList();

        if (points.isNotEmpty) {
          // Set initial position immediately
          currentPosition.value = points.first;
          playbackPosition.value = 0.0;

          // Use rotation angle from first location (like live tracking)
          if (filteredLocations.isNotEmpty) {
            rotationAngle.value =
                (filteredLocations.first['rotation_angle'] as num?)
                        ?.toDouble() ??
                    0.0;
          }

          // Move map to first position immediately
          if (mapController != null) {
            mapController!.move(points.first, currentZoom.value);
          }

          // Snap points to road for better visualization
          await _snapPointsToRoadProgressive(points);
          _setupInitialRoute();
        } else {
          error.value = 'No valid location data found';
          isLoading.value = false;
        }
      } else {
        error.value = 'No location data found for this period';
        isLoading.value = false;
      }
    } catch (e) {
      error.value = e is SubscriptionRequiredFailure
          ? e.message
          : 'Failed to load history. Please try again.';
      isLoading.value = false;
    }
  }

  /// Filter out stationary points and noise
  List<Map<String, dynamic>> _filterStationaryPoints(
      List<Map<String, dynamic>> locations) {
    if (locations.isEmpty) return locations;

    final filtered = <Map<String, dynamic>>[];
    const double minSpeed = 2.0; // km/h - more lenient for smooth movement
    const double minDistance =
        3.0; // meters - keep more points for smooth route
    const int maxStationaryCount = 2; // keep only 2 stationary points

    LatLng? lastPosition;
    int stationaryCount = 0;

    for (final location in locations) {
      final coordinates = location['coordinates'];
      if (coordinates == null ||
          coordinates is! List ||
          coordinates.length < 2) {
        continue;
      }

      final lng = (coordinates[0] as num?)?.toDouble();
      final lat = (coordinates[1] as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      final currentPosition = LatLng(lat, lng);
      final speed = (location['speed_kmh'] as num?)?.toDouble() ?? 0.0;

      // Always keep first point
      if (lastPosition == null) {
        filtered.add(location);
        lastPosition = currentPosition;
        stationaryCount = speed < minSpeed ? 1 : 0;
        continue;
      }

      final distance = _calculateDistance(lastPosition, currentPosition);

      // Keep taximeter edges even when the taxi is stationary so playback can
      // detect the exact course completion point.
      final taximeterChanged =
          filtered.last['taximeter'] != location['taximeter'];
      if (taximeterChanged) {
        filtered.add(location);
        lastPosition = currentPosition;
        stationaryCount = 0;
        continue;
      }

      // Check if point is stationary
      final isStationary = speed < minSpeed && distance < minDistance;

      if (isStationary) {
        stationaryCount++;
        // Keep fewer stationary points
        if (stationaryCount <= maxStationaryCount) {
          filtered.add(location);
        }
      } else {
        // Moving point - keep more points for smoother route
        if (distance >= minDistance || speed >= minSpeed) {
          filtered.add(location);
          lastPosition = currentPosition;
          stationaryCount = 0;
        }
      }
    }

    // Always keep last point to show final position
    if (locations.isNotEmpty &&
        (filtered.isEmpty || filtered.last != locations.last)) {
      filtered.add(locations.last);
    }

    return filtered;
  }

  Future<void> _snapPointsToRoadProgressive(List<LatLng> allPoints) async {
    if (allPoints.isEmpty) return;

    try {
      // Don't snap to road - use raw GPS points for clearer route
      // Road snapping can cause distortions and unclear paths
      routePoints.value = allPoints;
      isLoadingMore.value = false;
    } catch (e) {
      await _showRawPoints(allPoints);
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
    _computeRouteMetrics();
    _showRouteOnMap();
  }

  /// Pre-computes the values shown by the playback panel so they are not
  /// recalculated on every frame while the route plays back.
  void _computeRouteMetrics() {
    double meters = 0;
    for (int i = 1; i < routePoints.length; i++) {
      meters += _calculateDistance(routePoints[i - 1], routePoints[i]);
    }
    totalDistanceKm.value = meters / 1000;

    final runs = <TaximeterRun>[];
    final count = locationHistory.length;
    if (count > 1) {
      bool runStatus = locationHistory.first['taximeter'] as bool? ?? false;
      int runStart = 0;

      for (int i = 1; i < count; i++) {
        final status = locationHistory[i]['taximeter'] as bool? ?? false;
        if (status != runStatus) {
          runs.add(TaximeterRun(
            start: runStart / (count - 1),
            end: i / (count - 1),
            occupied: runStatus,
          ));
          runStart = i;
          runStatus = status;
        }
      }

      runs.add(TaximeterRun(
        start: runStart / (count - 1),
        end: 1.0,
        occupied: runStatus,
      ));
    }
    taximeterRuns.value = runs;
  }

  /// Moves the playback cursor by a real-world duration.
  void seekBy(Duration offset) {
    final total = totalHistoryDuration.inMilliseconds;
    if (total <= 0) return;
    final delta = offset.inMilliseconds / total;
    updatePosition((playbackPosition.value + delta).clamp(0.0, 1.0));
  }

  /// Sends the playback cursor back to the first recorded point.
  void restartPlayback() => updatePosition(0.0);

  void _showRouteOnMap() {
    if (routePoints.isEmpty || mapController == null) return;

    final bounds = LatLngBounds.fromPoints(routePoints);
    mapController!.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(50),
    ));
  }

  Future<void> _showRawPoints(List<LatLng> points) async {
    routePoints.value = points;
    _setupInitialRoute();
  }

  void updatePosition(double value) {
    if (routePoints.isEmpty) return;

    final normalizedValue = value.clamp(0.0, 1.0);
    playbackPosition.value = normalizedValue;
    _checkHistoricalRideCompletion(normalizedValue);

    // Use floating point for smooth interpolation between points
    final exactPosition = normalizedValue * (routePoints.length - 1);
    final index = exactPosition.floor();
    final fraction = exactPosition - index;

    final clampedIndex = index.clamp(0, routePoints.length - 1);

    // Smooth interpolation between current and next point
    if (fraction > 0 && clampedIndex < routePoints.length - 1) {
      final currentPoint = routePoints[clampedIndex];
      final nextPoint = routePoints[clampedIndex + 1];

      // Interpolate position
      final interpolatedLat = currentPoint.latitude +
          (nextPoint.latitude - currentPoint.latitude) * fraction;
      final interpolatedLng = currentPoint.longitude +
          (nextPoint.longitude - currentPoint.longitude) * fraction;

      currentPosition.value = LatLng(interpolatedLat, interpolatedLng);

      // Calculate rotation from movement direction (like Bolt)
      // This ensures car always points in the direction it's moving
      final bearing = _calculateBearing(currentPoint, nextPoint);
      rotationAngle.value = bearing;
      currentBearing.value = bearing;
    } else {
      // Snap to exact point
      currentPosition.value = _getPositionAtIndex(clampedIndex);

      // Calculate rotation from next movement direction
      if (clampedIndex < routePoints.length - 1) {
        final nextPoint = routePoints[clampedIndex + 1];
        final bearing = _calculateBearing(routePoints[clampedIndex], nextPoint);
        rotationAngle.value = bearing;
        currentBearing.value = bearing;
      }
    }

    // Update door status from nearest point
    if (clampedIndex < locationHistory.length) {
      isDoorOpen.value =
          locationHistory[clampedIndex]['door_status'] as bool? ?? false;
    }

    // Auto-update address if bubble is visible (during playback or scrubbing)
    if (showAddressBubble.value && currentPosition.value != null) {
      _debouncedAddressUpdate(currentPosition.value!);
    }

    // Smooth, immediate map following during playback (like Bolt)
    if (shouldFollowCar.value && !isUserInteracting.value) {
      _smoothFollowCar();
    }
  }

  void _checkHistoricalRideCompletion(double progress) {
    if (locationHistory.isEmpty) return;
    final currentIndex = (progress * (locationHistory.length - 1))
        .round()
        .clamp(0, locationHistory.length - 1)
        .toInt();
    final previousIndex = _lastPlaybackLocationIndex;

    if (previousIndex != null && currentIndex > previousIndex) {
      for (var index = previousIndex + 1; index <= currentIndex; index++) {
        if (_isTaximeterActive(locationHistory[index - 1]) &&
            !_isTaximeterActive(locationHistory[index])) {
          final endFare = _taximeterFare(locationHistory[index]);
          final priorFare = _taximeterFare(locationHistory[index - 1]);
          _showRideCompletedCue(
            endFare != null && endFare > 0 ? endFare : priorFare,
          );
        }
      }
    }

    _lastPlaybackLocationIndex = currentIndex;
  }

  bool _isTaximeterActive(Map<String, dynamic> location) {
    final value = location['taximeter'];
    return value == true || value == 1 || value == 'true' || value == '1';
  }

  double? _taximeterFare(Map<String, dynamic> location) {
    final value = location['p_taxi'];
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  void _showRideCompletedCue(double? fare) {
    completedRideFare.value = fare;
    rideCompletedCueVersion.value++;
    showRideCompletedCue.value = true;
    _rideCompletedCueTimer?.cancel();
    _rideCompletedCueTimer = Timer(const Duration(milliseconds: 2600), () {
      showRideCompletedCue.value = false;
    });
    unawaited(SystemSound.play(SystemSoundType.alert).catchError((_) {}));
  }

  // Smooth map following in real-time during playback
  // Moves map on every frame for synchronized car movement
  void _smoothFollowCar() {
    if (currentPosition.value == null || mapController == null) return;

    // During playback, follow car in real-time on every frame (like live tracking)
    if (isPlaying.value) {
      // Real-time synchronization: move map immediately with car
      final targetZoom = currentZoom.value < 14.0
          ? defaultZoom
          : currentZoom.value.clamp(minZoom, maxZoom);
      mapController?.moveAndRotate(
        currentPosition.value!,
        targetZoom,
        0.0,
      );
    } else {
      // When not playing, use throttled movement to save resources
      _mapMoveFrameCounter++;
      if (_mapMoveFrameCounter < _mapMoveEveryNFrames) {
        return; // Skip this frame
      }
      _mapMoveFrameCounter = 0;

      // Only move map if car moved significantly
      if (_lastMapCenter != null) {
        final distance =
            _calculateDistance(_lastMapCenter!, currentPosition.value!);
        if (distance < _minMoveDistance) {
          return; // Car hasn't moved enough
        }
      }

      // Move map to car position with zoom limits
      _lastMapCenter = currentPosition.value;
      final safeZoom = currentZoom.value.clamp(minZoom, maxZoom);
      mapController?.move(currentPosition.value!, safeZoom);
    }
  }

  LatLng _getPositionAtIndex(int index) {
    if (index < 0 || index >= routePoints.length) {
      return routePoints.first;
    }
    return routePoints[index];
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

    // If playback finished, reset to beginning for replay
    if (playbackPosition.value >= 1.0) {
      playbackPosition.value = 0.0;
      updatePosition(0.0);
    }

    // Reset map following state for smooth tile loading
    _lastMapCenter = null;
    _mapMoveFrameCounter = 0;

    isPlaying.value = true;

    // Start periodic address updates if bubble is visible
    if (showAddressBubble.value) {
      _startPeriodicAddressUpdate();
    }

    const updateInterval = 16; // ~60 FPS (1000ms / 60 = 16.67ms)

    _playbackTimer?.cancel();
    _playbackTimer =
        Timer.periodic(const Duration(milliseconds: updateInterval), (timer) {
      if (playbackPosition.value >= 1.0) {
        stopPlayback();
        // Reset to start for easy replay
        playbackPosition.value = 0.0;
        updatePosition(0.0);
        return;
      }

      final increment = (0.0001 * playbackSpeed.value);
      updatePosition((playbackPosition.value + increment).clamp(0.0, 1.0));
    });
  }

  void stopPlayback() {
    isPlaying.value = false;
    _playbackTimer?.cancel();
    _periodicAddressUpdateTimer?.cancel();
    // Reset map following state
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

  void setSelectedVehicle(Map<String, dynamic>? vehicle) {
    selectedVehicle.value = vehicle;
  }

  void resetState() {
    routePoints.clear();
    locationHistory.clear();
    taximeterRuns.clear();
    totalDistanceKm.value = 0.0;
    currentPosition.value = null;
    playbackPosition.value = 0.0;
    isInitialPositionSet.value = false;
    isLoading.value = false;
    isLoadingMore.value = false;
    error.value = '';
    dateError.value = '';
    stopPlayback();
  }

  /// Clear route data only (preserve vehicle selection and date)
  void clearRouteData() {
    routePoints.clear();
    locationHistory.clear();
    taximeterRuns.clear();
    totalDistanceKm.value = 0.0;
    currentPosition.value = null;
    playbackPosition.value = 0.0;
    isInitialPositionSet.value = false;
    isLoading.value = false;
    isLoadingMore.value = false;
    error.value = '';
    stopPlayback();
  }

  // Map interaction
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
    // Enforce zoom limits
    final clampedZoom = newZoom.clamp(minZoom, maxZoom);

    // Check if zoom actually changed (not just a position update)
    if ((clampedZoom - _previousZoom).abs() > 0.01) {
      // User is zooming in or out - disable auto-focus
      isUserInteracting.value = true;
      shouldFollowCar.value = false;
      currentZoom.value = clampedZoom;

      _userInteractionTimer?.cancel();
      _userInteractionTimer = Timer(_userInteractionTimeout, () {
        isUserInteracting.value = false;
      });
    }
    _previousZoom = clampedZoom;
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

      // Ensure optimal zoom level for car tracking (within limits)
      final targetZoom = currentZoom.value < 15.0
          ? defaultZoom
          : currentZoom.value.clamp(minZoom, maxZoom);
      currentZoom.value = targetZoom;

      // Always use smooth animation when centering
      _animateToCenter(currentPosition.value!, targetZoom);
    }
  }

  void _animateToCenter(LatLng targetPosition, double targetZoom) {
    if (mapController == null) return;

    // Cancel any existing centering animation to prevent conflicts
    _centerAnimationTimer?.cancel();
    _centerAnimationController?.stop();

    // Use smoother animation with separate tweens for better control
    final camera = mapController!.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: targetPosition.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: targetPosition.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: targetZoom,
    );

    _centerAnimationController!.reset();

    final animation = CurvedAnimation(
      parent: _centerAnimationController!,
      curve: Curves.easeInOutCubic, // Smooth curve for natural movement
    );

    // Track that centering animation is in progress
    bool animationInProgress = true;

    animation.addListener(() {
      if (mapController != null && animationInProgress) {
        mapController!.move(
          LatLng(
            latTween.evaluate(animation),
            lngTween.evaluate(animation),
          ),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        animationInProgress = false;
      }
    });

    _centerAnimationController!.forward();
  }

  // Helper methods
  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final dLon = (end.longitude - start.longitude) * pi / 180;

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x) * 180 / pi;

    return (bearing + 360) % 360;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000;
    final dLat = (point2.latitude - point1.latitude) * pi / 180;
    final dLon = (point2.longitude - point1.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1.latitude * pi / 180) *
            cos(point2.latitude * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Get colored segments for route visualization
  List<Polyline> getColoredSegments() {
    if (routePoints.length < 2 || locationHistory.isEmpty) {
      return [];
    }

    List<Polyline> segments = [];
    List<LatLng> currentSegment = [routePoints.first];
    bool? currentTaximeterStatus;

    for (int i = 0; i < min(routePoints.length, locationHistory.length); i++) {
      final location = locationHistory[i];
      final taximeterStatus = location['taximeter'] as bool? ?? false;

      currentTaximeterStatus ??= taximeterStatus;

      if (taximeterStatus != currentTaximeterStatus &&
          currentSegment.length > 1) {
        segments.add(Polyline(
          points: List.from(currentSegment),
          color: currentTaximeterStatus
              ? AppColors.successColor
              : AppColors.errorColor,
          strokeWidth: 4.0, // Much thicker line for better visibility
          borderStrokeWidth: 3.0, // Thicker border for clarity
          borderColor: AppColors.white.withOpacity(0.7),
        ));
        currentSegment = [currentSegment.last];
        currentTaximeterStatus = taximeterStatus;
      }

      if (i < routePoints.length) {
        currentSegment.add(routePoints[i]);
      }
    }

    if (currentSegment.length > 1) {
      segments.add(Polyline(
        points: currentSegment,
        color: currentTaximeterStatus == true
            ? AppColors.successColor
            : AppColors.errorColor,
        strokeWidth: 4.0, // Much thicker line for better visibility
        borderStrokeWidth: 3.0, // Thicker border for clarity
        borderColor: AppColors.white.withOpacity(0.7),
      ));
    }

    return segments;
  }

  // Get door open markers with start/end points
  List<Marker> getDoorOpenMarkers() {
    // No separate door markers - the main car marker changes when door is open
    return [];
  }

  // Get start and end point markers - elegant design without heavy backgrounds
  List<Marker> getStartEndMarkers() {
    List<Marker> markers = [];

    if (routePoints.isEmpty || locationHistory.isEmpty) return markers;

    // Start point marker (departure) - elegant minimal design
    if (routePoints.isNotEmpty) {
      markers.add(
        Marker(
          point: routePoints.first,
          width: 48,
          height: 48,
          alignment: Alignment
              .bottomCenter, // Bottom-center so the pin points to exact location
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.successColor,
                  AppColors.successColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.successColor.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.successColor,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // End point marker (arrival) - elegant minimal design with fare badge
    if (routePoints.length > 1 && locationHistory.isNotEmpty) {
      // Use routePoints.last to ensure marker is exactly at the end of the route line
      final endPoint = routePoints.last;

      markers.add(
        Marker(
          point: endPoint,
          width: 48,
          height: 48,
          alignment: Alignment
              .bottomCenter, // Bottom-center so the pin points to exact location
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.errorColor,
                  AppColors.errorColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.errorColor.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white,
                ),
                child: Icon(
                  Icons.location_on,
                  color: AppColors.errorColor,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // Get playback time
  DateTime getPlaybackTime() {
    if (locationHistory.isEmpty) return DateTime.now();

    final index =
        (playbackPosition.value * (locationHistory.length - 1)).round();
    final clampedIndex = index.clamp(0, locationHistory.length - 1);
    final location = locationHistory[clampedIndex];

    return DateTime.parse(
        location['timestamp'] as String? ?? DateTime.now().toIso8601String());
  }

  // Get current speed at playback position
  double getCurrentSpeed() {
    if (locationHistory.isEmpty) return 0.0;

    final index =
        (playbackPosition.value * (locationHistory.length - 1)).round();
    final clampedIndex = index.clamp(0, locationHistory.length - 1);
    final location = locationHistory[clampedIndex];

    // Match backend field: speed_kmh
    return (location['speed_kmh'] as num?)?.toDouble() ?? 0.0;
  }

  // Compact badge for inline display
  // Get current taximeter status
  bool getCurrentTaximeter() {
    if (locationHistory.isEmpty) return false;

    final index =
        (playbackPosition.value * (locationHistory.length - 1)).round();
    final clampedIndex = index.clamp(0, locationHistory.length - 1);
    final location = locationHistory[clampedIndex];

    return location['taximeter'] as bool? ?? false;
  }

  // Get current fare
  double getCurrentFare() {
    if (locationHistory.isEmpty) return 0.0;

    final index =
        (playbackPosition.value * (locationHistory.length - 1)).round();
    final clampedIndex = index.clamp(0, locationHistory.length - 1);
    final location = locationHistory[clampedIndex];

    return (location['p_taxi'] as num?)?.toDouble() ?? 0.0;
  }

  // Get current door status
  bool getCurrentDoorStatus() {
    if (locationHistory.isEmpty) return false;

    final index =
        (playbackPosition.value * (locationHistory.length - 1)).round();
    final clampedIndex = index.clamp(0, locationHistory.length - 1);
    final location = locationHistory[clampedIndex];

    // Match backend field: door_status
    return location['door_status'] as bool? ?? false;
  }

  double getCarRotationAngle() {
    // Always prefer rotation_angle from backend (like live tracking)
    if (rotationAngle.value != null) {
      return rotationAngle.value! * pi / 180;
    }
    // Fallback to calculated bearing
    return currentBearing.value * pi / 180;
  }

  /// Fetch address from coordinates using Nominatim reverse geocoding
  Future<void> fetchAddressFromCoordinates(LatLng position) async {
    if (isLoadingAddress.value) return;

    try {
      isLoadingAddress.value = true;
      showAddressBubble.value = true;
      currentAddress.value = 'Loading...';

      // Get current app language
      final locale = Get.locale?.languageCode ?? 'en';

      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1');

      final response = await Future.any([
        Future.delayed(const Duration(seconds: 5),
            () => throw TimeoutException('Request timeout')),
        http.get(url, headers: {
          'User-Agent': 'NeoTrackMobileApp/1.0',
          'Accept-Language': locale,
        }),
      ]);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Extract address components
        final address = jsonData['address'] as Map<String, dynamic>?;
        if (address != null) {
          // Priority: suburb > neighbourhood > city_district > quarter > hamlet > town > city
          final zone = address['suburb'] ??
              address['neighbourhood'] ??
              address['city_district'] ??
              address['quarter'] ??
              address['hamlet'] ??
              address['town'] ??
              address['city'] ??
              '';

          final road = address['road'] ?? '';
          final city = address['city'] ??
              address['town'] ??
              address['village'] ??
              address['municipality'] ??
              '';

          // Build address: road + zone, prioritizing meaningful information
          String displayAddress = '';

          // If we have a road name, include it
          if (road.isNotEmpty) {
            displayAddress = road;
          }

          // If we have a zone, add it (with comma if road exists)
          if (zone.isNotEmpty) {
            if (displayAddress.isNotEmpty) {
              displayAddress = '$displayAddress, $zone';
            } else {
              displayAddress = zone;
            }
          }

          // Add city if different from zone
          if (city.isNotEmpty && city != zone && city != road) {
            displayAddress =
                displayAddress.isEmpty ? city : '$displayAddress, $city';
          }

          currentAddress.value = displayAddress.isEmpty
              ? jsonData['display_name'] ?? 'Address not available'
              : displayAddress;
        } else {
          currentAddress.value =
              jsonData['display_name'] ?? 'Address not available';
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

  /// Debounced address update during playback
  void _debouncedAddressUpdate(LatLng position) {
    _addressUpdateTimer?.cancel();
    _addressUpdateTimer = Timer(_addressUpdateDebounce, () {
      if (showAddressBubble.value) {
        fetchAddressFromCoordinates(position);
      }
    });
  }

  String getCarMarkerPath(Map<String, dynamic>? vehicle) {
    if (vehicle == null) return 'assets/images/car_marker.png';

    final carType = vehicle['car_type']?.toString().toLowerCase() ?? '';
    switch (carType) {
      case 'taxi':
        return 'assets/images/car_marker.png';
      case 'louage':
        return 'assets/images/louage_marker.png';
      default:
        return 'assets/images/car_marker.png';
    }
  }

  List<LatLng> getPlayedPoints() {
    if (routePoints.isEmpty) return [];
    final index = (playbackPosition.value * (routePoints.length - 1)).round();
    return routePoints.sublist(0, index + 1);
  }

  Color getLineColor() {
    return getCurrentTaximeter() ? AppColors.successColor : AppColors.brandBlue;
  }
}

/// A stretch of the route where the taximeter kept the same state, expressed
/// as fractions of the playback timeline.
class TaximeterRun {
  final double start;
  final double end;
  final bool occupied;

  const TaximeterRun({
    required this.start,
    required this.end,
    required this.occupied,
  });
}

// Custom tween class for LatLng animation
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
