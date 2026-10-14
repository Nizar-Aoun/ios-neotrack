import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_driver_app/config/env.dart';
import 'package:taxi_driver_app/core/error/failure.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/car_service.dart';
import 'package:taxi_driver_app/services/map_heading_controller.dart';
import 'package:taxi_driver_app/services/routing_service.dart';
import 'package:taxi_driver_app/features/home/controller/map_controller.dart';
import 'package:taxi_driver_app/features/home/domain/taxi_meter_status.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class LiveTrackingController extends GetxController
    with WidgetsBindingObserver {
  // Services
  late final CarService _carService;
  late final MapController _mapController;
  final RoutingService _routingService = RoutingService();
  IO.Socket? _socket;

  // Flutter Map Controller
  fm.MapController? flutterMapController;
  Timer? _zoomDebounceTimer;
  Timer?
      _centerAnimationTimer; // Track centering animation to prevent conflicts

  // Observable state
  final Rx<LatLng?> carPosition = Rx<LatLng?>(null);
  final Rx<LatLng?> previousPosition = Rx<LatLng?>(null);
  final RxList<LatLng> routePoints = <LatLng>[].obs;
  final RxDouble currentSpeed = 0.0.obs;
  final RxInt taxiMeterStatus = TaxiMeterStatus.libre.obs;
  final Rxn<double> taximeterPrice = Rxn<double>();
  final RxBool showRideCompletedCue = false.obs;
  final RxInt rideCompletedCueVersion = 0.obs;
  final Rxn<double> completedRideFare = Rxn<double>();
  final RxBool isDoorOpen = false.obs;
  final RxDouble currentBearing = 0.0.obs;
  final RxDouble rotationAngle = 0.0.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final RxBool isReconnecting = false.obs;
  final RxInt reconnectionAttempts = 0.obs;
  final RxBool shouldFollowCar = true.obs;
  final RxBool isUserInteracting = false.obs;
  final RxDouble currentZoom = 16.0.obs; // Optimal zoom level for car tracking
  double? lastKnownZoom; // Track zoom for detecting user zoom gestures
  final RxString currentAddress = ''.obs;
  final RxBool isLoadingAddress = false.obs;
  final RxBool showAddressBubble = false.obs;

  // User (phone) GPS position for locate-me
  final Rx<LatLng?> userPosition = Rx<LatLng?>(null);
  final RxBool isLocatingUser = false.obs;
  final RxBool isTrackingUser = false.obs;
  final RxBool shouldFollowUser = false.obs;
  final RxDouble userHeading = 0.0.obs;

  /// Marker position snapped onto the road polyline (falls back to raw GPS).
  final Rx<LatLng?> userMarkerPosition = Rx<LatLng?>(null);

  /// Throttled polyline start so the line stays glued without 60fps rebuilds.
  final Rx<LatLng?> polylineVisualStart = Rx<LatLng?>(null);
  DateTime? _lastPolylineVisualAt;
  final RxList<LatLng> userToCarRoute = <LatLng>[].obs;
  final RxBool isUserToCarRouteLoading = false.obs;
  final RxDouble userToCarDistanceMeters = 0.0.obs;
  final RxDouble userToCarDurationSeconds = 0.0.obs;
  final RxDouble userToCarRemainingMeters = 0.0.obs;
  final RxString nextManeuverStreet = ''.obs;
  final RxString nextManeuverType = ''.obs;
  final RxBool hasArrivedAtTaxi = false.obs;
  final RxDouble userGpsAccuracyMeters = 0.0.obs;
  final RxString userRouteProfile = 'driving'.obs;
  bool _haptic100Fired = false;
  bool _haptic30Fired = false;
  bool _arrivalHapticFired = false;
  static const double _arrivalDistanceMeters = 35.0;
  LatLng? _lastRoutedCarPosition;
  LatLng? _lastRoutedUserPosition;
  Timer? _userToCarRouteDebounceTimer;
  StreamSubscription<Position>? _userPositionSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  /// True while phone compass is producing readings (used for reverse detection).
  bool _usingPhoneCompass = false;

  /// Last compass heading. Does not drive map rotation (GPS course does).
  double? _compassHeading;

  /// GPS heading-up rotation (deadband, speed gate, shortest-path smoothing).
  final MapHeadingController _mapHeading = MapHeadingController();

  /// Continuous ~60fps loop for smooth marker / heading / camera.
  Timer? _userSmoothMoveTimer;
  LatLng? _userAnimTarget;
  double _userHeadingTarget = 0.0;
  int _userRouteSegmentIndex = 0;
  bool _isUpdatingUserToCarRoute = false;

  /// When true, hide the user→taxi polyline until locate is pressed again.
  bool _userRouteDismissed = false;
  bool _isUserOffRoute = false;
  bool _userRouteRefreshQueued = false;
  int _userRouteRequestGeneration = 0;
  int _offRouteSampleCount = 0;
  DateTime? _lastOffRouteRouteRequestAt;

  /// Google-like reverse: still on the line, but moving away from the taxi.
  bool _isUserGoingReverse = false;
  int _reverseSampleCount = 0;
  double _minRemainingRouteMeters = double.infinity;
  DateTime? _lastReverseRouteRequestAt;

  /// When set, OSRM departs from the user in this facing/movement direction.
  double? _preferredRouteStartBearing;
  static const double _userToCarRouteRefreshDistance = 80.0;
  static const double _maxRouteGpsAccuracyMeters = 40.0;
  static const double _minOffRouteDistanceMeters = 30.0;
  static const double _maxOffRouteDistanceMeters = 60.0;
  static const int _offRouteConfirmationSamples = 2;
  static const double _staleRouteRequestDistanceMeters = 40.0;
  static const Duration _offRouteRetryInterval = Duration(seconds: 4);
  static const double _minReverseRemainingIncreaseMeters = 20.0;
  static const double _reverseJitterMeters = 10.0;
  static const int _reverseConfirmationSamples = 3;
  static const double _reverseHeadingDeltaDegrees = 120.0;
  static const Duration _reverseRetryInterval = Duration(seconds: 4);
  static const double _headingUpdateMinSpeedMs = 0.8;

  /// Position lerp factor per frame (~60fps) — lower = more glide between GPS ticks.
  static const double _userPositionLerp = 0.12;

  /// Snap remaining position error under this (meters).
  static const double _userPositionSnapMeters = 0.04;

  /// Rebuild the route polyline at most this often / after this much travel.
  static const Duration _polylineVisualInterval = Duration(milliseconds: 50);
  static const double _polylineVisualMoveMeters = 0.4;

  /// Icon heading lerp when heading-up GPS course is not driving the camera.
  static const double _userHeadingLerp = 0.35;

  // Location queue for smooth animation
  final RxList<LatLng> positionQueue = <LatLng>[].obs;
  final RxList<Map<String, dynamic>> dataQueue = <Map<String, dynamic>>[].obs;
  final RxBool isMoving = false.obs;
  Timer? _movementTimer;

  // Current movement animation
  LatLng? _animationStart;
  LatLng? _animationTarget;
  int _animationStep = 0;
  int _animationTotalSteps = 0;
  double _animationStartSpeed = 0.0;
  double _animationTargetSpeed = 0.0;

  // Expose animation progress for synchronized map following
  final Rx<double> movementProgress = 0.0.obs;
  final Rx<LatLng?> interpolatedPosition = Rx<LatLng?>(null);

  // Predictive movement (keeps car moving when waiting for new data)
  Timer? _predictionTimer;
  LatLng? _lastMovementDirection;
  double _lastMovementSpeed = 0.0;

  // T-1 Continuous Buffer System
  Timer? _continuousBufferTimer;
  final RxBool isUsingContinuousBuffer = false.obs;
  final RxInt bufferPredictionTicks = 0.obs;

  // App lifecycle tracking
  bool _wasActuallyPaused = false;

  // Reconnection settings
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionDelay = Duration(seconds: 2);
  Timer? _reconnectionTimer;
  Timer? _connectionHealthTimer;
  Timer? _queueProcessingTimer;
  Timer? _userInteractionTimer;
  Timer? _addressUpdateTimer;
  Timer? _rideCompletedCueTimer;
  int? _lastSocketTaxiMeterStatus;
  static const Duration _addressUpdateDebounce = Duration(milliseconds: 800);

  // Enhanced stationary detection
  final RxList<LatLng> recentPositions = <LatLng>[].obs;
  static const int _maxRecentPositions = 5;
  final RxBool isCarStationary = false.obs;
  final RxInt stationaryCount = 0.obs;
  static const int _stationaryConfirmationThreshold = 3;

  // Route point management - significant points only
  final RxList<LatLng> significantRoutePoints = <LatLng>[].obs;
  static const double _minRoutePointDistance = 10.0;

  @override
  void onInit() {
    super.onInit();
    flutterMapController = fm.MapController();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    WakelockPlus.enable();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectSocket();
    _reconnectionTimer?.cancel();
    _connectionHealthTimer?.cancel();
    _queueProcessingTimer?.cancel();
    _userInteractionTimer?.cancel();
    _addressUpdateTimer?.cancel();
    _rideCompletedCueTimer?.cancel();
    _movementTimer?.cancel();
    _predictionTimer?.cancel();
    _continuousBufferTimer?.cancel();
    _zoomDebounceTimer?.cancel();
    _centerAnimationTimer?.cancel();
    _userToCarRouteDebounceTimer?.cancel();
    _userSmoothMoveTimer?.cancel();
    _stopUserTracking();
    WakelockPlus.disable();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // App actually went to background (not just control center)
        _wasActuallyPaused = true;
        break;

      case AppLifecycleState.inactive:
        // App is inactive (control center, notification shade, etc.)
        // Don't set _wasActuallyPaused - this is temporary
        break;

      case AppLifecycleState.resumed:
        // Only fetch position if app was actually paused (backgrounded)
        if (_wasActuallyPaused) {
          _handleAppResume();
          _wasActuallyPaused = false;
        }
        break;

      default:
        break;
    }
  }

  void _handleAppResume() async {
    // First, fetch the latest position from API to catch up
    // This ensures we show the current position, not the old one from before backgrounding
    // Loading state is now handled inside _fetchLatestPositionOnResume
    await _fetchLatestPositionOnResume();

    // Then check if we need to reconnect WebSocket
    if (_socket == null || !_socket!.connected) {
      // Don't clear error immediately - let reconnection succeed first
      if (!isReconnecting.value) {
        _handleSocketDisconnect();
      }
    } else {
      // Clear any stale errors
      error.value = null;
    }
  }

  // Fetch latest position when app resumes from background
  Future<void> _fetchLatestPositionOnResume() async {
    final selectedVehicle = _mapController.liveTrackingVehicle.value;
    if (selectedVehicle == null) return;

    // Only fetch if we already have a position (not initial load)
    if (carPosition.value == null) return;

    try {
      final response =
          await _carService.getCarLocation(selectedVehicle['car_id']);
      final location = response['location'];
      final coordinates = List<double>.from(location['coordinates']);
      final latestPosition = LatLng(coordinates[1], coordinates[0]);

      // Calculate how far the car moved while app was in background
      final distance = _calculateDistance(carPosition.value!, latestPosition);

      // Update to latest position
      final locationData = {
        'position': latestPosition,
        'timestamp': DateTime.now(),
        'speed': (location['speed_kmh'] ?? 0).toDouble(),
        'taxiMeterStatus': TaxiMeterStatus.fromLocation(
          Map<String, dynamic>.from(location),
        ),
        'p_taxi': location['p_taxi'],
        'door_status': location['door_status'] ?? false,
        'rotation_angle': (location['rotation_angle'] ?? 0).toDouble(),
      };
      print(
          '[COMPTEUR][api-resume] taxiMeterStatus=${locationData['taxiMeterStatus']} raw=${location['taxiMeterStatus']}');

      // If car moved significantly, update immediately
      if (distance > 5.0) {
        // Add to significant route points if moved enough
        _addSignificantRoutePoint(latestPosition);

        // Update position and data
        previousPosition.value = carPosition.value;
        carPosition.value = latestPosition;
        interpolatedPosition.value =
            latestPosition; // Sync interpolated position
        currentSpeed.value = locationData['speed'] as double;
        taxiMeterStatus.value = locationData['taxiMeterStatus'] as int;
        taximeterPrice.value = _parseTaxiPrice(locationData['p_taxi']);
        isDoorOpen.value = locationData['door_status'] as bool;
        rotationAngle.value = locationData['rotation_angle'] as double;

        // Calculate bearing if we have previous position
        if (previousPosition.value != null) {
          final bearing =
              _calculateBearing(previousPosition.value!, latestPosition);
          currentBearing.value = bearing;
        }

        // Center on car if auto-follow is enabled
        if (shouldFollowCar.value && flutterMapController != null) {
          flutterMapController!.move(latestPosition, currentZoom.value);
        }
      } else {
        // Update speed and status even if position didn't change much
        // Also sync interpolated position to ensure Center button works correctly
        interpolatedPosition.value = latestPosition;
        currentSpeed.value = locationData['speed'] as double;
        taxiMeterStatus.value = locationData['taxiMeterStatus'] as int;
        taximeterPrice.value = _parseTaxiPrice(locationData['p_taxi']);
        isDoorOpen.value = locationData['door_status'] as bool;
        rotationAngle.value = locationData['rotation_angle'] as double;
      }
    } catch (e) {
      // Don't set error - this is a background operation
      // WebSocket reconnection will continue regardless
    }
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      _carService = CarService(authService);
      _mapController = Get.find<MapController>();

      // Wait for map controller to have vehicles
      if (_mapController.onlineVehicles.isEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // If we have a selected vehicle from map controller, start tracking
      if (_mapController.liveTrackingVehicle.value != null) {
        _initializeSocket();
      }
    } catch (e) {
      error.value = e.toString();
    }
  }

  // Initialize WebSocket connection
  Future<void> _initializeSocket() async {
    _disconnectSocket();

    final selectedVehicle = _mapController.liveTrackingVehicle.value;
    if (selectedVehicle == null) return;

    if (!isReconnecting.value) {
      isLoading.value = true;
      error.value = null;
    }

    if (kIsWeb) {}

    try {
      // Fetch last 10 seconds of history for smooth start
      await _fetchLastTenSecondsHistory();

      // Only proceed if we have initial position
      if (carPosition.value == null || error.value != null) {
        return;
      }

      // Get JWT token
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs);
      final token = await authService.getToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Web platform needs polling as fallback due to CORS and browser restrictions
      final transports = kIsWeb ? ['polling', 'websocket'] : ['websocket'];

      _socket = IO.io(Env.websocketUrl, <String, dynamic>{
        'transports': transports,
        'autoConnect': false,
        'timeout': 15000, // Increased timeout for web
        'forceNew': true,
        'reconnection': true,
        'reconnectionAttempts': 5,
        'reconnectionDelay': 1000,
        'reconnectionDelayMax': 5000,
        'maxReconnectionAttempts': 5,
        'extraHeaders': {'authorization': 'Bearer $token'},
        // Web-specific options
        'upgrade': kIsWeb, // Allow transport upgrade on web
        'rememberUpgrade': kIsWeb,
      });

      _socket!.onConnect((_) {
        _reconnectionTimer?.cancel();
        isReconnecting.value = false;
        reconnectionAttempts.value = 0;
        // Don't set isLoading to false here - wait for actual position data
        error.value = null;

        _startConnectionHealthCheck();

        _socket!.emit('subscribe-car-location', selectedVehicle['car_id']);
      });

      _socket!.onConnectError((err) {
        if (!isReconnecting.value) {
          isLoading.value = false;
        }
      });

      _socket!.onDisconnect((_) {
        if (!isReconnecting.value) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!isReconnecting.value) {
              _handleSocketDisconnect();
            }
          });
        }
      });

      _socket!.on('car-location-update', (data) {
        // Disable loading now that we received position data
        if (isLoading.value) {
          isLoading.value = false;
        }

        final location = data['location'];
        final coordinates = List<double>.from(location['coordinates']);
        final newPosition = LatLng(coordinates[1], coordinates[0]);
        final timestamp = DateTime.parse(location['timestamp']);
        final newSpeed = (location['speed_kmh'] ?? 0).toDouble();
        final locMap = Map<String, dynamic>.from(location as Map);
        final newTaxiMeterStatus = TaxiMeterStatus.fromLocation(locMap);
        final newDoorStatus = location['door_status'] ?? false;
        final newRotationAngle = (location['rotation_angle'] ?? 0).toDouble();
        final previousSocketStatus =
            _lastSocketTaxiMeterStatus ?? taxiMeterStatus.value;
        if (previousSocketStatus == TaxiMeterStatus.occupe &&
            newTaxiMeterStatus == TaxiMeterStatus.libre) {
          final finalMeterPrice = _parseTaxiPrice(locMap['p_taxi']);
          _showRideCompletedCue(finalMeterPrice != null && finalMeterPrice > 0
              ? finalMeterPrice
              : taximeterPrice.value);
        }
        _lastSocketTaxiMeterStatus = newTaxiMeterStatus;
        final locationData = {
          'position': newPosition,
          'timestamp': timestamp,
          'speed': newSpeed,
          'taxiMeterStatus': newTaxiMeterStatus,
          'p_taxi': locMap['p_taxi'],
          'door_status': newDoorStatus,
          'rotation_angle': newRotationAngle,
        };

        // Detect if car is stationary using enhanced logic
        final isStationary = _detectStationaryState(newPosition, newSpeed);

        if (carPosition.value == null) {
          // First location received - set directly

          _setInitialPosition(newPosition, locationData);
        } else {
          // Check if this is a meaningful movement
          final distance = _calculateDistance(carPosition.value!, newPosition);

          if (isStationary) {
            // Car is stopped - update state but don't queue movement
            _handleStationaryUpdate(newPosition, locationData);
          } else if (distance < 0.5) {
            // Too small to animate, but not stationary - just update state
            _updateCarData(newPosition, locationData);
          } else {
            // Meaningful movement - add to queue
            positionQueue.add(newPosition);
            dataQueue.add(locationData);

            // Add to route if significant distance from last route point
            _addSignificantRoutePoint(newPosition);

            // Reset stationary counter
            stationaryCount.value = 0;
            isCarStationary.value = false;

            if (!isMoving.value) {
              _startSmoothMovement();
            } else {}
          }
        }
      });

      _socket!.connect();
    } catch (e) {
      isLoading.value = false;
      error.value = e.toString();
    }
  }

  // Enhanced stationary detection with speed + distance analysis
  bool _detectStationaryState(LatLng position, double speed) {
    // Add to recent positions for analysis
    recentPositions.add(position);
    if (recentPositions.length > _maxRecentPositions) {
      recentPositions.removeAt(0);
    }

    // Primary check: speed threshold
    if (speed < 2.0) {
      // Very slow - likely stopped
      stationaryCount.value++;
      if (stationaryCount.value >= _stationaryConfirmationThreshold) {
        return true;
      }
    } else if (speed > 5.0) {
      // Clearly moving
      stationaryCount.value = 0;
      return false;
    }

    // Secondary check: position variance for ambiguous speeds (2-5 km/h)
    if (recentPositions.length >= 3) {
      double totalDistance = 0.0;
      for (int i = 1; i < recentPositions.length; i++) {
        totalDistance +=
            _calculateDistance(recentPositions[i - 1], recentPositions[i]);
      }

      // If average movement is less than 2m, consider stationary
      double avgDistance = totalDistance / (recentPositions.length - 1);
      if (avgDistance < 2.0) {
        stationaryCount.value++;
        return stationaryCount.value >= _stationaryConfirmationThreshold;
      }
    }

    return false;
  }

  // Handle stationary car updates
  void _handleStationaryUpdate(LatLng position, Map<String, dynamic> data) {
    // Stop any ongoing movement and prediction
    _movementTimer?.cancel();
    _predictionTimer?.cancel();
    _continuousBufferTimer?.cancel();
    isMoving.value = false;
    isUsingContinuousBuffer.value = false;

    // Clear movement queues
    positionQueue.clear();
    dataQueue.clear();

    // Update position and data immediately (no animation needed)
    carPosition.value = position;
    previousPosition.value = position;
    interpolatedPosition.value = position; // Sync interpolated position
    currentSpeed.value = data['speed'] as double;
    taxiMeterStatus.value = data['taxiMeterStatus'] as int;
    taximeterPrice.value = _parseTaxiPrice(data['p_taxi']);
    isDoorOpen.value = data['door_status'] as bool;
    rotationAngle.value = data['rotation_angle'] as double;

    isCarStationary.value = true;
  }

  // Set initial position
  void _setInitialPosition(LatLng position, Map<String, dynamic> data) {
    carPosition.value = position;
    previousPosition.value = position;
    interpolatedPosition.value = position; // Initialize interpolated position
    significantRoutePoints.add(position);
    routePoints.add(position);
    currentSpeed.value = data['speed'] as double;
    taxiMeterStatus.value = data['taxiMeterStatus'] as int;
    taximeterPrice.value = _parseTaxiPrice(data['p_taxi']);
    isDoorOpen.value = data['door_status'] as bool;
    rotationAngle.value = data['rotation_angle'] as double;

    _maybeRefreshUserToCarRoute();
    // Loading is now disabled in car-location-update handler
  }

  // Add route point only if significant distance from last point
  void _addSignificantRoutePoint(LatLng newPoint) {
    if (significantRoutePoints.isEmpty) {
      significantRoutePoints.add(newPoint);
      return;
    }

    final lastPoint = significantRoutePoints.last;
    final distance = _calculateDistance(lastPoint, newPoint);

    if (distance >= _minRoutePointDistance) {
      significantRoutePoints.add(newPoint);

      // Keep route history manageable (last 200 significant points)
      if (significantRoutePoints.length > 200) {
        significantRoutePoints.removeAt(0);
      }
    }
  }

  // Fetch last 10 seconds of history for smooth animation start
  // Skip history API and fetch current location directly
  Future<void> _fetchLastTenSecondsHistory() async {
    final selectedVehicle = _mapController.liveTrackingVehicle.value;
    if (selectedVehicle == null) return;

    // Skip the history API call (often returns 404)
    // Go directly to fetching current location
    await _fetchInitialLocation();
  }

  // Fetch initial location as fallback
  Future<void> _fetchInitialLocation() async {
    final selectedVehicle = _mapController.liveTrackingVehicle.value;
    if (selectedVehicle == null) return;

    try {
      final response =
          await _carService.getCarLocation(selectedVehicle['car_id']);
      final location = response['location'];
      final coordinates = List<double>.from(location['coordinates']);
      final initialPosition = LatLng(coordinates[1], coordinates[0]);

      carPosition.value = initialPosition;
      previousPosition.value = initialPosition;
      interpolatedPosition.value =
          initialPosition; // Initialize interpolated position
      significantRoutePoints.add(initialPosition);
      routePoints.add(initialPosition);
      currentSpeed.value = (location['speed_kmh'] ?? 0).toDouble();
      taxiMeterStatus.value = TaxiMeterStatus.fromLocation(
        Map<String, dynamic>.from(location),
      );
      _lastSocketTaxiMeterStatus = taxiMeterStatus.value;
      taximeterPrice.value = _parseTaxiPrice(location['p_taxi']);
      isDoorOpen.value = location['door_status'] ?? false;
      rotationAngle.value = (location['rotation_angle'] ?? 0).toDouble();
      isLoading.value = false;

      // Center the map on the car immediately after finding it
      if (flutterMapController != null) {
        shouldFollowCar.value = true;
        isUserInteracting.value = false;
        flutterMapController!.move(initialPosition, 17.0);
        currentZoom.value = 17.0;
      }
    } catch (e) {
      isLoading.value = false;

      // Only set error if this is NOT during a reconnection attempt
      // If reconnecting, we already have the last known position, so keep it visible
      if (!isReconnecting.value) {
        error.value = e is Failure ? e.message : e.toString();
      }
    }
  }

  // Start smooth car movement through queued positions
  void _startSmoothMovement() {
    if (isMoving.value || positionQueue.isEmpty) return;

    isMoving.value = true;
    _moveToNextPosition();
  }

  // Move car smoothly to the next position in queue
  void _moveToNextPosition() {
    if (kIsWeb) {}

    // If queue is empty, we shouldn't be here - safety check
    if (positionQueue.isEmpty) {
      isMoving.value = false;
      return;
    }

    // Get next position from queue
    final targetPosition = positionQueue.removeAt(0);
    final targetData = dataQueue.removeAt(0);

    final startPosition = carPosition.value!;

    // Calculate distance and duration
    final distance = _calculateDistance(startPosition, targetPosition);
    final speed = (targetData['speed'] as double);

    // Skip extremely small movements
    if (distance < 0.5) {
      _updateCarData(targetPosition, targetData);
      _moveToNextPosition();
      return;
    }

    // Calculate realistic duration based on actual speed
    double durationSeconds;
    if (speed >= 1.0 && speed <= 120.0) {
      // Calculate time based on actual vehicle speed
      final speedMetersPerSecond = speed * 1000 / 3600;
      durationSeconds = distance / speedMetersPerSecond;

      // Clamp duration to reasonable limits
      durationSeconds = durationSeconds.clamp(0.3, 4.0);
    } else {
      // Fallback for stationary or invalid speed
      if (distance < 5.0) {
        durationSeconds = 2.5;
      } else if (distance < 20.0) {
        durationSeconds = 3.5;
      } else {
        durationSeconds = 4.5;
      }
    }

    // Calculate animation parameters - Reduced frame rate for better performance
    final frameRate = 20; // 20 FPS (was 30) - reduces main thread work
    final frameDuration = 1000 ~/ frameRate; // ~50ms
    _animationTotalSteps = (durationSeconds * frameRate).round().clamp(8, 60);
    _animationStep = 0;
    _animationStart = startPosition;
    _animationTarget = targetPosition;
    _animationStartSpeed = currentSpeed.value;
    _animationTargetSpeed = speed;

    // Calculate bearing for rotation
    final bearing = _calculateBearing(startPosition, targetPosition);
    currentBearing.value = bearing;

    // Start animation timer
    _movementTimer?.cancel();
    _predictionTimer
        ?.cancel(); // Stop any old prediction when real movement starts
    _continuousBufferTimer?.cancel(); // Stop buffer when real movement starts
    isUsingContinuousBuffer.value = false;

    _movementTimer =
        Timer.periodic(Duration(milliseconds: frameDuration), (timer) {
      if (_animationStep >= _animationTotalSteps) {
        // Animation complete - ensure we're exactly at target
        timer.cancel();
        _updateCarData(targetPosition, targetData);

        // Save movement direction for prediction
        _lastMovementDirection = LatLng(
          targetPosition.latitude - startPosition.latitude,
          targetPosition.longitude - startPosition.longitude,
        );
        _lastMovementSpeed = targetData['speed'] as double;

        // Check if new data arrived during movement - continue immediately!
        if (positionQueue.isNotEmpty) {
          _moveToNextPosition(); // Continue without stopping
        } else {
          // Queue empty - start T-1 continuous buffer for smooth movement
          if (isCarStationary.value) {
            isMoving.value = false;
          } else if (_lastMovementDirection != null &&
              currentSpeed.value >= 5.0) {
            // Start continuous buffer - keep moving with T-1 prediction
            _startContinuousBufferMovement();
          } else {
            isMoving.value = false;
          }
        }
        return;
      }

      // Calculate interpolated position
      final progress = _animationStep / _animationTotalSteps;
      final lat = _animationStart!.latitude +
          ((_animationTarget!.latitude - _animationStart!.latitude) * progress);
      final lng = _animationStart!.longitude +
          ((_animationTarget!.longitude - _animationStart!.longitude) *
              progress);

      final interpolatedPos = LatLng(lat, lng);

      // Interpolate speed smoothly like a real speedometer
      final interpolatedSpeed = _animationStartSpeed +
          ((_animationTargetSpeed - _animationStartSpeed) * progress);

      // Update position and expose for map synchronization
      previousPosition.value = carPosition.value;
      carPosition.value = interpolatedPos;
      interpolatedPosition.value = interpolatedPos;
      movementProgress.value = progress;

      // Update data with interpolated speed (realistic speedometer effect)
      currentSpeed.value = interpolatedSpeed;
      taxiMeterStatus.value = targetData['taxiMeterStatus'] as int;
      taximeterPrice.value = _parseTaxiPrice(targetData['p_taxi']);
      isDoorOpen.value = targetData['door_status'] as bool;
      rotationAngle.value = bearing;

      // Synchronize map movement with car animation at SAME speed as car
      // Update map with EVERY car position for perfectly smooth tracking
      // BUT skip updates if centering animation is in progress to avoid conflicts
      if (shouldFollowCar.value &&
          !isUserInteracting.value &&
          flutterMapController != null &&
          _centerAnimationTimer == null) {
        final targetZoom = currentZoom.value < 14.0 ? 16.0 : currentZoom.value;
        flutterMapController?.moveAndRotate(
          interpolatedPos,
          targetZoom,
          0.0, // No map rotation - only car marker rotates
        );
      }

      // Debug every 10 steps
      if (_animationStep % 10 == 0) {}

      _animationStep++;
    });
  }

  // Start T-1 Continuous Buffer Movement
  // Keeps the car moving smoothly using predicted positions while waiting for GPS updates
  void _startContinuousBufferMovement() {
    if (_lastMovementDirection == null ||
        _lastMovementSpeed < 5.0 ||
        isCarStationary.value) {
      isMoving.value = false;
      return;
    }

    isMoving.value = true;
    isUsingContinuousBuffer.value = true;
    bufferPredictionTicks.value = 0;

    // Calculate realistic movement increment based on speed
    final speedMetersPerSecond = _lastMovementSpeed * 1000 / 3600;
    final metersPerTick = speedMetersPerSecond * 0.1; // 100ms intervals

    // Approximate: 1 degree latitude ≈ 111,000 meters
    final degreesPerMeter = 1.0 / 111000.0;

    // Normalize direction vector
    final directionLength = sqrt(_lastMovementDirection!.latitude *
            _lastMovementDirection!.latitude +
        _lastMovementDirection!.longitude * _lastMovementDirection!.longitude);
    final normalizedLat = _lastMovementDirection!.latitude / directionLength;
    final normalizedLng = _lastMovementDirection!.longitude / directionLength;

    // Continue moving in the same direction at realistic speed
    _continuousBufferTimer?.cancel();
    _continuousBufferTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) {
      bufferPredictionTicks.value = timer.tick;

      // Check if new real data arrived - switch immediately!
      if (positionQueue.isNotEmpty) {
        timer.cancel();
        isUsingContinuousBuffer.value = false;
        _moveToNextPosition();
        return;
      }

      // Stop after 3 seconds of prediction (30 ticks) and wait for GPS
      if (timer.tick > 30) {
        timer.cancel();
        isMoving.value = false;
        isUsingContinuousBuffer.value = false;
        return;
      }

      // Move car realistically in last known direction
      final currentPos = carPosition.value!;
      final increment = metersPerTick * degreesPerMeter;
      final predictedLat = currentPos.latitude + (normalizedLat * increment);
      final predictedLng = currentPos.longitude + (normalizedLng * increment);

      previousPosition.value = carPosition.value;
      carPosition.value = LatLng(predictedLat, predictedLng);
      interpolatedPosition.value = carPosition.value;

      // Synchronize map movement with prediction at SAME speed
      // Update map with EVERY predicted position for smooth tracking
      // BUT skip updates if centering animation is in progress to avoid conflicts
      if (shouldFollowCar.value &&
          !isUserInteracting.value &&
          flutterMapController != null &&
          _centerAnimationTimer == null) {
        final targetZoom = currentZoom.value < 14.0 ? 16.0 : currentZoom.value;
        flutterMapController?.moveAndRotate(
          carPosition.value!,
          targetZoom,
          0.0, // No map rotation
        );
      }

      // Debug every 10 ticks (1 second)
      if (timer.tick % 10 == 0) {}
    });
  }

  // Update car data at target position
  void _updateCarData(LatLng position, Map<String, dynamic> data) {
    carPosition.value = position;
    previousPosition.value = position;
    interpolatedPosition.value = position; // Sync interpolated position
    currentSpeed.value = data['speed'] as double;
    taxiMeterStatus.value = data['taxiMeterStatus'] as int;
    taximeterPrice.value = _parseTaxiPrice(data['p_taxi']);
    isDoorOpen.value = data['door_status'] as bool;
    rotationAngle.value = data['rotation_angle'] as double;

    // Update legacy route points (kept for compatibility)
    if (routePoints.length > 100) {
      routePoints.value = routePoints.sublist(routePoints.length - 50);
    }
    routePoints.add(position);

    // Auto-update address if bubble is visible
    if (showAddressBubble.value) {
      _debouncedAddressUpdate(position);
    }

    _maybeRefreshUserToCarRoute();
  }

  // Initialize location queue (for history)
  // Calculate distance between two points
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

  // Calculate bearing between two points (0–360°, clockwise from North)
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final y = sin(endLng - startLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(endLng - startLng);
    final bearing = atan2(y, x);

    // Dart `%` keeps the sign of the dividend — normalize to [0, 360)
    return (bearing * 180 / pi + 360) % 360;
  }

  // Handle socket disconnect
  void _handleSocketDisconnect() {
    if (_mapController.liveTrackingVehicle.value == null ||
        isReconnecting.value) {
      return;
    }

    // Keep loading state visible during reconnection
    // This ensures user knows we're reconnecting
    isLoading.value = true; // Show loading during reconnection
    // error.value = null; // DON'T clear error yet - will clear on success
    isReconnecting.value = true;

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(_reconnectionDelay, () {
      _attemptReconnection();
    });
  }

  // Attempt reconnection
  void _attemptReconnection() {
    final selectedVehicle = _mapController.liveTrackingVehicle.value;
    if (selectedVehicle == null) return;

    if (isReconnecting.value && reconnectionAttempts.value > 0) {
      return;
    }

    if (_socket != null && _socket!.connected) {
      isLoading.value = false;
      isReconnecting.value = false;
      error.value = null; // Clear error on successful connection
      reconnectionAttempts.value = 0;
      return;
    }

    if (reconnectionAttempts.value >= _maxReconnectionAttempts) {
      // After max attempts, set error but keep last known data visible
      error.value = 'Connection lost - retrying...'; // Minimal error message
      reconnectionAttempts.value = 0;
      _reconnectionTimer?.cancel();
      _reconnectionTimer = Timer(const Duration(seconds: 30), () {
        error.value = null; // Clear error before new attempt
        _attemptReconnection();
      });
      return;
    }

    reconnectionAttempts.value++;

    _disconnectSocket();

    _initializeSocket().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_socket != null && _socket!.connected) {
          isLoading.value = false;
          isReconnecting.value = false;
          error.value = null; //  Clear error on successful reconnection
          reconnectionAttempts.value = 0;
        } else {
          // Don't set error during reconnection attempts
          _reconnectionTimer?.cancel();
          _reconnectionTimer = Timer(_reconnectionDelay, () {
            _attemptReconnection();
          });
        }
      });
    }).catchError((err) {
      // Don't set error during reconnection attempts - only after max attempts
      _reconnectionTimer?.cancel();
      _reconnectionTimer = Timer(_reconnectionDelay, () {
        _attemptReconnection();
      });
    });
  }

  // Connection health check
  void _startConnectionHealthCheck() {
    _connectionHealthTimer?.cancel();
    _connectionHealthTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_mapController.liveTrackingVehicle.value == null) {
        timer.cancel();
        return;
      }

      if (_socket == null || !_socket!.connected) {
        timer.cancel();
        if (!isReconnecting.value) {
          _handleSocketDisconnect();
        }
      }
    });
  }

  // Disconnect socket
  void _disconnectSocket() {
    _connectionHealthTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // User interaction handlers
  void onMapInteraction() {
    isUserInteracting.value = true;
    shouldFollowCar.value = false;
    shouldFollowUser.value = false;

    _userInteractionTimer?.cancel();
    _userInteractionTimer = Timer(const Duration(seconds: 3), () {
      isUserInteracting.value = false;
    });
  }

  void centerOnCar() {
    if (carPosition.value == null || flutterMapController == null) return;

    // Toggle follow mode on/off when button is clicked
    if (shouldFollowCar.value) {
      // Currently following, disable it
      shouldFollowCar.value = false;
      isUserInteracting.value = false;
    } else {
      // Currently not following, enable it
      shouldFollowUser.value = false;
      shouldFollowCar.value = true;
      isUserInteracting.value = false;

      // Get the current position - prioritize carPosition as the source of truth
      // Use interpolatedPosition only if actively animating (both are same during animation)
      final currentPos = carPosition.value;
      if (currentPos != null) {
        // Set optimal zoom level for tracking
        final targetZoom = currentZoom.value < 15.0 ? 17.0 : currentZoom.value;

        // Jump instantly — avoids loading tiles along the pan path
        _jumpToCenter(currentPos, targetZoom, rotation: 0.0);
      }
    }
  }

  /// Locate the phone user's GPS position and center the map on it.
  /// Starts continuous tracking so the marker and route update as the user moves.
  /// Returns a localization key on failure, or null on success.
  Future<String?> locateUser() async {
    if (isLocatingUser.value) return null;

    // Re-center / re-enable heading-up follow if already tracking
    if (isTrackingUser.value && userPosition.value != null) {
      shouldFollowUser.value = true;
      shouldFollowCar.value = false;
      isUserInteracting.value = false;
      if (_userRouteDismissed || userToCarRoute.length < 2) {
        _userRouteDismissed = false;
        _updateUserToCarRoute();
      }
      final target = userMarkerPosition.value ?? userPosition.value!;
      final targetZoom = currentZoom.value < 15.0 ? 17.0 : currentZoom.value;
      _jumpToCenter(target, targetZoom, rotation: _headingUpRotation());
      return null;
    }

    isLocatingUser.value = true;
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[locateUser] serviceEnabled=$serviceEnabled');
      if (!serviceEnabled) {
        return 'locationServiceDisabled';
      }

      var permission = await Geolocator.checkPermission();
      debugPrint('[locateUser] checkPermission=$permission');
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[locateUser] requestPermission=$permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[locateUser] permission actually denied');
        return 'locationPermissionDenied';
      }

      Position? position = await Geolocator.getLastKnownPosition();
      debugPrint(
        '[locateUser] lastKnown='
        '${position == null ? 'null' : '${position.latitude},${position.longitude} acc=${position.accuracy}'}',
      );

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        debugPrint(
          '[locateUser] current='
          '${position.latitude},${position.longitude} acc=${position.accuracy}',
        );
      } on TimeoutException catch (e) {
        debugPrint('[locateUser] getCurrentPosition timeout: $e');
      } catch (e) {
        debugPrint('[locateUser] getCurrentPosition error: $e');
      }

      if (position == null) {
        debugPrint('[locateUser] no GPS fix — not a permission issue');
        return 'locationFixFailed';
      }

      final userPos = LatLng(position.latitude, position.longitude);
      userPosition.value = userPos;
      userMarkerPosition.value = userPos;
      _userAnimTarget = userPos;
      _mapHeading.reset();
      _mapHeading.ingestPosition(position, previous: null, current: userPos);
      userHeading.value =
          _mapHeading.hasHeading ? _mapHeading.displayedHeading : 0.0;
      _userHeadingTarget = userHeading.value;
      shouldFollowCar.value = false;
      shouldFollowUser.value = true;
      isUserInteracting.value = false;

      final targetZoom = currentZoom.value < 15.0 ? 17.0 : currentZoom.value;
      _jumpToCenter(userPos, targetZoom, rotation: _headingUpRotation());

      _resetUserRerouteState();
      _userRouteDismissed = false;
      _startUserTracking();
      _ensureUserSmoothLoop();

      if (position.accuracy <= _maxRouteGpsAccuracyMeters) {
        _routingService.clearCache();
        _userRouteRefreshQueued = true;
        unawaited(_updateUserToCarRoute());
      }

      return null;
    } on PermissionDeniedException catch (e) {
      debugPrint('[locateUser] PermissionDeniedException: $e');
      return 'locationPermissionDenied';
    } on LocationServiceDisabledException catch (e) {
      debugPrint('[locateUser] LocationServiceDisabledException: $e');
      return 'locationServiceDisabled';
    } catch (e, st) {
      debugPrint('[locateUser] unexpected error: $e');
      debugPrint('$st');
      return 'locationFixFailed';
    } finally {
      isLocatingUser.value = false;
    }
  }

  /// Start listening to phone GPS so the blue-dot and route stay up to date.
  void _startUserTracking() {
    _userPositionSubscription?.cancel();
    isTrackingUser.value = true;

    final locationSettings = _userLocationSettings();

    _userPositionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      _onUserPositionUpdate,
      onError: (_) {
        // Keep last known position; stream may recover
      },
    );

    _startPhoneCompass();
  }

  /// Compass rotates the nav icon when follow is off. Map rotation always uses
  /// GPS course via [_mapHeading], never the magnetometer (noisy inside a car).
  void _startPhoneCompass() {
    _compassSubscription?.cancel();
    _usingPhoneCompass = false;

    final events = FlutterCompass.events;
    if (events == null) return;

    _compassSubscription = events.listen(
      (event) {
        final heading = event.heading;
        if (heading == null || heading.isNaN) return;

        _usingPhoneCompass = true;
        _compassHeading = (heading + 360) % 360;

        // Do not let compass drive heading-up follow (GPS course owns that).
        if (shouldFollowUser.value && _mapHeading.hasHeading) return;

        _userHeadingTarget = _compassHeading!;
        final delta =
            _normalizeHeadingDelta(_userHeadingTarget - userHeading.value);
        if (delta.abs() < 1.5) {
          userHeading.value = _userHeadingTarget;
        }
        _ensureUserSmoothLoop();
      },
      onError: (_) {
        _usingPhoneCompass = false;
      },
    );
  }

  LocationSettings _userLocationSettings() {
    // High-frequency stream for smooth realtime movement (Google Maps style)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(milliseconds: 250),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
    );
  }

  void _onUserPositionUpdate(Position position) {
    // Ignore very noisy GPS samples for the marker
    if (position.accuracy > 80) return;

    final newPos = LatLng(position.latitude, position.longitude);
    final previousUserPos = userPosition.value;
    userPosition.value = newPos;
    userGpsAccuracyMeters.value = position.accuracy;

    // Feed the existing GPS stream into heading-up rotation (no extra stream).
    _mapHeading.ingestPosition(
      position,
      previous: previousUserPos,
      current: newPos,
    );

    LatLng targetMarker = newPos;
    if (userToCarRoute.length >= 2) {
      final route = userToCarRoute.toList();
      final snap = _closestPointOnRoute(newPos, route);
      final distanceFromRoute = _calculateDistance(newPos, snap.point);
      final offRouteThreshold = max(
        _minOffRouteDistanceMeters,
        min(
          _maxOffRouteDistanceMeters,
          position.accuracy * 1.5,
        ),
      );
      final isAccurateForDeviation =
          position.accuracy <= _maxRouteGpsAccuracyMeters;

      if (isAccurateForDeviation && distanceFromRoute > offRouteThreshold) {
        _offRouteSampleCount++;
      } else {
        _offRouteSampleCount = 0;
      }

      // Wrong street wins over reverse direction.
      if (!_isUserOffRoute &&
          _offRouteSampleCount >= _offRouteConfirmationSamples) {
        _isUserOffRoute = true;
        _clearReverseDirectionState();
        unawaited(_remarkableVibration());
        _requestImmediateUserRouteRefresh();
      }

      if (_isUserOffRoute) {
        // Do not pin the user to a route they have left. Keep the last valid
        // polyline visible while OSRM calculates its replacement.
        targetMarker = newPos;
        _userRouteSegmentIndex = 0;
        if (!_headingUpOwnsIcon()) {
          _applyUserHeadingFromPosition(position, newPos);
        }
        final lastRequest = _lastOffRouteRouteRequestAt;
        if (!_isUpdatingUserToCarRoute &&
            (lastRequest == null ||
                DateTime.now().difference(lastRequest) >=
                    _offRouteRetryInterval)) {
          _requestImmediateUserRouteRefresh();
        }
      } else {
        targetMarker = snap.point;
        _userRouteSegmentIndex = snap.segmentIndex;

        if (isAccurateForDeviation) {
          _updateReverseDirectionState(
            position: position,
            previousUserPos: previousUserPos,
            route: route,
            segmentIndex: snap.segmentIndex,
            snappedPoint: snap.point,
          );
        }

        // Icon heading: GPS heading-up when following, else polyline / GPS / compass
        if (!_headingUpOwnsIcon()) {
          if (!_usingPhoneCompass) {
            final routeHeading =
                _headingAlongRoute(snap.segmentIndex, userToCarRoute);
            if (routeHeading != null && !_isUserGoingReverse) {
              _userHeadingTarget = (routeHeading + 360) % 360;
            } else {
              _applyUserHeadingFromPosition(position, newPos);
            }
          }
        }
      }
    } else {
      _userRouteSegmentIndex = 0;
      _offRouteSampleCount = 0;
      _clearReverseDirectionState(keepData: false);
      if (!_headingUpOwnsIcon() && !_usingPhoneCompass) {
        _applyUserHeadingFromPosition(position, newPos);
      }
    }

    _userAnimTarget = targetMarker;
    if (userMarkerPosition.value == null) {
      userMarkerPosition.value = targetMarker;
      userHeading.value = _userHeadingTarget;
      _dropPassedRouteSegments();
      _maybeUpdatePolylineVisualStart(targetMarker, force: true);
    }
    _ensureUserSmoothLoop();

    if (userToCarRoute.length >= 2 && !_userRouteDismissed) {
      _updateRemainingProgress(targetMarker);
    }

    // Only rebuild the road polyline when GPS is accurate enough
    if (position.accuracy > _maxRouteGpsAccuracyMeters) return;

    _maybeRefreshUserToCarRoute();
  }

  /// Keep a continuous smooth loop running while tracking.
  void _ensureUserSmoothLoop() {
    if (_userSmoothMoveTimer != null) return;

    _userSmoothMoveTimer =
        Timer.periodic(const Duration(milliseconds: 16), (_) {
      final target = _userAnimTarget;
      var current = userMarkerPosition.value;
      if (target == null) return;
      current ??= target;

      // --- Smooth position ---
      final dist = _calculateDistance(current, target);
      LatLng nextPos;
      if (dist < _userPositionSnapMeters) {
        nextPos = target;
      } else {
        nextPos = LatLng(
          current.latitude +
              (target.latitude - current.latitude) * _userPositionLerp,
          current.longitude +
              (target.longitude - current.longitude) * _userPositionLerp,
        );
      }
      userMarkerPosition.value = nextPos;

      _dropPassedRouteSegments();
      _maybeUpdatePolylineVisualStart(nextPos);

      // Heading-up: interpolate GPS course along the shortest path.
      _mapHeading.tick();
      if (_headingUpOwnsIcon()) {
        userHeading.value = _mapHeading.displayedHeading;
      } else {
        final headingDelta =
            _normalizeHeadingDelta(_userHeadingTarget - userHeading.value);
        if (headingDelta.abs() < 0.4) {
          userHeading.value = _userHeadingTarget;
        } else {
          userHeading.value =
              (userHeading.value + headingDelta * _userHeadingLerp + 360) % 360;
        }
      }

      _updateFollowCamera(nextPos);
    });
  }

  /// Drop vertices already behind the marker. Does not rewrite route[0] or
  /// refresh the list every frame.
  void _dropPassedRouteSegments() {
    if (_userRouteDismissed ||
        _isUserOffRoute ||
        _isUserGoingReverse ||
        userToCarRoute.length < 2) {
      return;
    }

    final seg = _userRouteSegmentIndex.clamp(0, userToCarRoute.length - 2);
    if (seg > 0) {
      userToCarRoute.removeRange(0, seg);
      _userRouteSegmentIndex = 0;
    }
  }

  /// Publish a polyline start point at most every 50 ms or 0.4 m.
  void _maybeUpdatePolylineVisualStart(LatLng marker, {bool force = false}) {
    if (_userRouteDismissed ||
        _isUserOffRoute ||
        _isUserGoingReverse ||
        userToCarRoute.length < 2) {
      if (polylineVisualStart.value != null) {
        polylineVisualStart.value = null;
      }
      return;
    }

    final last = polylineVisualStart.value;
    final lastAt = _lastPolylineVisualAt;
    final moved =
        last == null ? double.infinity : _calculateDistance(last, marker);
    final elapsed = lastAt == null
        ? _polylineVisualInterval
        : DateTime.now().difference(lastAt);
    if (!force &&
        last != null &&
        moved < _polylineVisualMoveMeters &&
        elapsed < _polylineVisualInterval) {
      return;
    }

    _lastPolylineVisualAt = DateTime.now();
    polylineVisualStart.value = marker;
  }

  void _updateFollowCamera(LatLng target) {
    if (!shouldFollowUser.value || flutterMapController == null) return;
    final zoom = currentZoom.value < 15.0 ? 17.0 : currentZoom.value;
    final rotation = _headingUpRotation();
    final camera = flutterMapController!.camera;
    final sameCenter =
        (camera.center.latitude - target.latitude).abs() < 1e-7 &&
            (camera.center.longitude - target.longitude).abs() < 1e-7;
    final sameRotation =
        MapHeadingMath.shortestDelta(camera.rotation, rotation).abs() < 0.15;
    final sameZoom = (camera.zoom - zoom).abs() < 0.01;
    if (sameCenter && sameRotation && sameZoom) return;

    flutterMapController!.moveAndRotate(target, zoom, rotation);
    currentZoom.value = zoom;
  }

  /// Camera rotation for heading-up follow. North-up until GPS course locks.
  double _headingUpRotation() {
    if (_mapHeading.hasHeading) return _mapHeading.mapRotationDegrees;
    return 0.0;
  }

  bool _headingUpOwnsIcon() =>
      shouldFollowUser.value && _mapHeading.hasHeading;

  /// Place the navigation arrow on the route and aim its tip along the street.
  void _syncUserMarkerWithPolyline(LatLng gpsPos, [Position? position]) {
    if (userToCarRoute.length < 2) {
      _userAnimTarget = gpsPos;
      if (position != null && !_headingUpOwnsIcon()) {
        _applyUserHeadingFromPosition(position, gpsPos);
      }
      _ensureUserSmoothLoop();
      return;
    }

    final snap = _closestPointOnRoute(gpsPos, userToCarRoute.toList());
    _userAnimTarget = snap.point;
    _userRouteSegmentIndex = snap.segmentIndex;

    final routeHeading = _headingAlongRoute(snap.segmentIndex, userToCarRoute);
    if (!_headingUpOwnsIcon() && !_usingPhoneCompass) {
      if (routeHeading != null) {
        _userHeadingTarget = (routeHeading + 360) % 360;
      } else if (position != null) {
        _applyUserHeadingFromPosition(position, gpsPos);
      }
    }
    _ensureUserSmoothLoop();
  }

  /// Bearing of the polyline toward the taxi from [segmentIndex].
  /// Looks ahead along the route so the icon tip aims down the street.
  double? _headingAlongRoute(int segmentIndex, List<LatLng> route) {
    if (route.length < 2) return null;

    var i = segmentIndex.clamp(0, route.length - 2);
    // Prefer a segment that is long enough for a stable street direction
    while (i < route.length - 2 &&
        _calculateDistance(route[i], route[i + 1]) < 4) {
      i++;
    }

    // Look further ahead (~25m) so the tip tracks the road curve ahead
    var j = i + 1;
    var travelled = _calculateDistance(route[i], route[j]);
    while (j < route.length - 1 && travelled < 25) {
      j++;
      travelled += _calculateDistance(route[j - 1], route[j]);
    }
    return _calculateBearing(route[i], route[j]);
  }

  /// Direction of the visible user→taxi polyline from the marker toward the taxi.
  double? get userToCarRouteHeading => (_isUserOffRoute || _isUserGoingReverse)
      ? null
      : _headingAlongRoute(0, userToCarRoute.toList());

  /// Remaining distance along [route] from the snapped point to the taxi end.
  double _remainingDistanceAlongRoute(
    List<LatLng> route,
    int segmentIndex,
    LatLng pointOnSegment,
  ) {
    if (route.length < 2) return 0.0;
    final seg = segmentIndex.clamp(0, route.length - 2);
    var dist = _calculateDistance(pointOnSegment, route[seg + 1]);
    for (var i = seg + 1; i < route.length - 1; i++) {
      dist += _calculateDistance(route[i], route[i + 1]);
    }
    return dist;
  }

  double? _movementHeading(
    Position position,
    LatLng? previousUserPos,
    LatLng newPos,
  ) {
    final gpsHeading = position.heading;
    final headingAccuracy = position.headingAccuracy;
    if (gpsHeading >= 0 && (headingAccuracy < 0 || headingAccuracy <= 45)) {
      return gpsHeading;
    }
    if (previousUserPos != null && position.speed >= _headingUpdateMinSpeedMs) {
      return _calculateBearing(previousUserPos, newPos);
    }
    return null;
  }

  /// Detect reverse travel on the correct street (Google-like progress + course).
  void _updateReverseDirectionState({
    required Position position,
    required LatLng? previousUserPos,
    required List<LatLng> route,
    required int segmentIndex,
    required LatLng snappedPoint,
  }) {
    final remaining = _remainingDistanceAlongRoute(
      route,
      segmentIndex,
      snappedPoint,
    );

    if (remaining < _minRemainingRouteMeters) {
      _minRemainingRouteMeters = remaining;
    }

    final remainingIncrease = remaining - _minRemainingRouteMeters;
    final routeHeading = _headingAlongRoute(segmentIndex, route);
    final moveHeading = position.speed >= _headingUpdateMinSpeedMs
        ? _movementHeading(
            position,
            previousUserPos,
            LatLng(position.latitude, position.longitude),
          )
        : null;
    // Phone top direction (compass) — used with reverse to bias the new route.
    final phoneHeading = _usingPhoneCompass ? _compassHeading : null;

    var courseOpposite = false;
    if (routeHeading != null && moveHeading != null) {
      final delta = _normalizeHeadingDelta(moveHeading - routeHeading).abs();
      courseOpposite = delta >= _reverseHeadingDeltaDegrees;
    }

    var phoneOpposite = false;
    if (routeHeading != null && phoneHeading != null) {
      final delta = _normalizeHeadingDelta(phoneHeading - routeHeading).abs();
      phoneOpposite = delta >= _reverseHeadingDeltaDegrees;
    }

    final strongProgressReverse =
        remainingIncrease >= _minReverseRemainingIncreaseMeters;
    final mildProgressReverse = remainingIncrease >= _reverseJitterMeters &&
        (courseOpposite || phoneOpposite);

    if (strongProgressReverse || mildProgressReverse) {
      _reverseSampleCount++;
    } else if (remainingIncrease < _reverseJitterMeters &&
        !phoneOpposite &&
        !courseOpposite) {
      _reverseSampleCount = 0;
      if (_isUserGoingReverse) {
        // Recovered toward the taxi on the same line.
        _isUserGoingReverse = false;
        _preferredRouteStartBearing = null;
      }
    }

    // Prefer phone facing, then GPS course, for the departure bearing.
    final reverseFacingBearing =
        phoneOpposite ? phoneHeading : (courseOpposite ? moveHeading : null);

    if (!_isUserGoingReverse &&
        _reverseSampleCount >= _reverseConfirmationSamples) {
      _isUserGoingReverse = true;
      if (reverseFacingBearing != null) {
        _preferredRouteStartBearing = (reverseFacingBearing + 360) % 360;
      }
      // Noticeable feedback when reverse (and phone facing) triggers a new route.
      unawaited(_remarkableVibration());
      _requestImmediateUserRouteRefresh();
      return;
    }

    if (_isUserGoingReverse) {
      if (reverseFacingBearing != null) {
        final nextBearing = (reverseFacingBearing + 360) % 360;
        final bearingChanged = _preferredRouteStartBearing == null ||
            _normalizeHeadingDelta(
                  nextBearing - _preferredRouteStartBearing!,
                ).abs() >=
                25;
        _preferredRouteStartBearing = nextBearing;
        if (bearingChanged) {
          _requestImmediateUserRouteRefresh();
          return;
        }
      }

      final lastRequest = _lastReverseRouteRequestAt;
      if (!_isUpdatingUserToCarRoute &&
          (lastRequest == null ||
              DateTime.now().difference(lastRequest) >=
                  _reverseRetryInterval)) {
        _requestImmediateUserRouteRefresh();
      }
    }
  }

  void _clearReverseDirectionState({bool keepData = false}) {
    _isUserGoingReverse = false;
    _reverseSampleCount = 0;
    _lastReverseRouteRequestAt = null;
    _preferredRouteStartBearing = null;
    if (!keepData) {
      _minRemainingRouteMeters = double.infinity;
    }
  }

  /// Stronger feedback than lightImpact alone — works on more Android devices.
  Future<void> _remarkableVibration() async {
    await HapticFeedback.heavyImpact();
    await HapticFeedback.vibrate();
  }

  /// Closest point on a polyline to [point], with the segment index used.
  ({LatLng point, int segmentIndex}) _closestPointOnRoute(
    LatLng point,
    List<LatLng> route,
  ) {
    var bestDist = double.infinity;
    var bestPoint = route.first;
    var bestSegment = 0;

    for (var i = 0; i < route.length - 1; i++) {
      final projected = _projectOnSegment(point, route[i], route[i + 1]);
      final dist = _calculateDistance(point, projected);
      if (dist < bestDist) {
        bestDist = dist;
        bestPoint = projected;
        bestSegment = i;
      }
    }

    return (point: bestPoint, segmentIndex: bestSegment);
  }

  LatLng _projectOnSegment(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final dx = bx - ax;
    final dy = by - ay;
    if (dx == 0 && dy == 0) return a;

    final t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
    final clamped = t.clamp(0.0, 1.0);
    return LatLng(ay + clamped * dy, ax + clamped * dx);
  }

  /// Update heading from GPS course, or from movement bearing as fallback.
  void _applyUserHeadingFromPosition(Position position, LatLng newPos) {
    double? nextHeading;

    final gpsHeading = position.heading;
    final headingAccuracy = position.headingAccuracy;
    if (gpsHeading >= 0 && (headingAccuracy < 0 || headingAccuracy <= 45)) {
      nextHeading = gpsHeading;
    } else if (position.speed >= _headingUpdateMinSpeedMs &&
        userPosition.value != null) {
      nextHeading = _calculateBearing(userPosition.value!, newPos);
    }

    if (nextHeading == null) return;
    _setUserHeading(nextHeading);
  }

  void _setUserHeading(double nextHeading) {
    _userHeadingTarget = (nextHeading + 360) % 360;
  }

  double _normalizeHeadingDelta(double degrees) {
    var d = degrees % 360;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d;
  }

  void _stopUserTracking() {
    _userPositionSubscription?.cancel();
    _userPositionSubscription = null;
    _compassSubscription?.cancel();
    _compassSubscription = null;
    _usingPhoneCompass = false;
    _compassHeading = null;
    _mapHeading.reset();
    _userSmoothMoveTimer?.cancel();
    _userSmoothMoveTimer = null;
    _userAnimTarget = null;
    polylineVisualStart.value = null;
    _lastPolylineVisualAt = null;
    isTrackingUser.value = false;
    shouldFollowUser.value = false;
    _resetUserRerouteState();
  }

  void _resetUserRerouteState() {
    _offRouteSampleCount = 0;
    _isUserOffRoute = false;
    _userRouteRefreshQueued = false;
    _lastOffRouteRouteRequestAt = null;
    _clearReverseDirectionState(keepData: false);
    // Any HTTP response started for the previous tracking state is stale.
    _userRouteRequestGeneration++;
  }

  /// Remove only the user→taxi polyline. Keeps GPS tracking, taxi, and info card.
  void cancelUserRoute() {
    _userToCarRouteDebounceTimer?.cancel();
    _userRouteDismissed = true;
    _isUpdatingUserToCarRoute = false;
    _userRouteRefreshQueued = false;
    isUserToCarRouteLoading.value = false;
    _lastRoutedCarPosition = null;
    _lastRoutedUserPosition = null;
    _userRouteSegmentIndex = 0;
    _clearReverseDirectionState(keepData: false);
    _isUserOffRoute = false;
    _offRouteSampleCount = 0;
    _userRouteRequestGeneration++;
    if (userToCarRoute.isNotEmpty) {
      userToCarRoute.clear();
    }
    polylineVisualStart.value = null;
    _lastPolylineVisualAt = null;
    _clearUserRouteMetrics();
  }

  void _applyUserToCarRouteResult(
    OsrmRouteResult snapped,
    LatLng user,
    LatLng car,
    LatLng latestUser,
  ) {
    userToCarRoute.assignAll(snapped.points);
    _lastRoutedCarPosition = car;
    _lastRoutedUserPosition = user;
    _offRouteSampleCount = 0;
    _isUserOffRoute = false;
    _lastOffRouteRouteRequestAt = null;
    _clearReverseDirectionState(keepData: false);
    userToCarDistanceMeters.value = snapped.distanceMeters;
    userToCarDurationSeconds.value = snapped.durationSeconds;
    userToCarRemainingMeters.value = snapped.distanceMeters;
    nextManeuverStreet.value = snapped.firstStepName ?? '';
    nextManeuverType.value = snapped.firstManeuver ?? '';
    hasArrivedAtTaxi.value = snapped.distanceMeters <= _arrivalDistanceMeters;
    _haptic100Fired = false;
    _haptic30Fired = false;
    _arrivalHapticFired = hasArrivedAtTaxi.value;
    _syncUserMarkerWithPolyline(latestUser);
    final marker = userMarkerPosition.value ?? latestUser;
    _dropPassedRouteSegments();
    _maybeUpdatePolylineVisualStart(marker, force: true);
    _updateRemainingProgress(marker);
  }

  void _clearUserRouteMetrics() {
    userToCarDistanceMeters.value = 0.0;
    userToCarDurationSeconds.value = 0.0;
    userToCarRemainingMeters.value = 0.0;
    nextManeuverStreet.value = '';
    nextManeuverType.value = '';
    hasArrivedAtTaxi.value = false;
    _haptic100Fired = false;
    _haptic30Fired = false;
    _arrivalHapticFired = false;
  }

  void _updateRemainingProgress(LatLng marker) {
    if (userToCarRoute.length < 2) return;
    final remaining = _remainingDistanceAlongRoute(
      userToCarRoute.toList(),
      _userRouteSegmentIndex,
      marker,
    );
    userToCarRemainingMeters.value = remaining;

    final arrived = remaining <= _arrivalDistanceMeters;
    if (arrived && !hasArrivedAtTaxi.value) {
      hasArrivedAtTaxi.value = true;
      if (!_arrivalHapticFired) {
        _arrivalHapticFired = true;
        unawaited(_remarkableVibration());
      }
    } else if (!arrived && remaining > _arrivalDistanceMeters + 15) {
      hasArrivedAtTaxi.value = false;
      _arrivalHapticFired = false;
    }

    if (!_haptic100Fired && remaining <= 100 && remaining > 30) {
      _haptic100Fired = true;
      unawaited(_remarkableVibration());
    }
    if (!_haptic30Fired && remaining <= 30 && remaining > 0) {
      _haptic30Fired = true;
      if (!_arrivalHapticFired) {
        unawaited(_remarkableVibration());
      }
    }
  }

  /// Switch walking / driving profile and rebuild the user→taxi route.
  Future<void> setUserRouteProfile(String profile) async {
    final next = profile == 'driving' ? 'driving' : 'foot';
    if (userRouteProfile.value == next) return;
    userRouteProfile.value = next;
    if (_userRouteDismissed || userPosition.value == null) return;
    _routingService.clearCache();
    _requestImmediateUserRouteRefresh();
  }

  /// Stop GPS tracking, hide the nav marker, and clear the polyline.
  void stopUserLocationTracking() {
    _userToCarRouteDebounceTimer?.cancel();
    _userRouteDismissed = true;
    _isUpdatingUserToCarRoute = false;
    _userRouteRefreshQueued = false;
    isUserToCarRouteLoading.value = false;
    userToCarRoute.clear();
    _clearUserRouteMetrics();
    userPosition.value = null;
    userMarkerPosition.value = null;
    polylineVisualStart.value = null;
    _lastPolylineVisualAt = null;
    userGpsAccuracyMeters.value = 0.0;
    userHeading.value = 0.0;
    _userRouteRequestGeneration++;
    _stopUserTracking();
  }

  /// Open Google Maps, then Waze, then a web maps fallback (always driving).
  Future<void> openExternalNavigationToTaxi() async {
    final user = userPosition.value ?? userMarkerPosition.value;
    final car = carPosition.value;
    if (user == null || car == null) return;
    final googleApp = Uri.parse(
      'google.navigation:q=${car.latitude},${car.longitude}&mode=d',
    );
    final waze = Uri.parse(
      'waze://?ll=${car.latitude},${car.longitude}&navigate=yes',
    );
    final web = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${user.latitude},${user.longitude}'
      '&destination=${car.latitude},${car.longitude}'
      '&travelmode=driving',
    );
    try {
      if (await canLaunchUrl(googleApp)) {
        await launchUrl(googleApp, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(waze)) {
        await launchUrl(waze, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }

  void _requestImmediateUserRouteRefresh() {
    _userToCarRouteDebounceTimer?.cancel();
    _userRouteRefreshQueued = true;
    _lastOffRouteRouteRequestAt = DateTime.now();
    if (_isUserGoingReverse) {
      _lastReverseRouteRequestAt = DateTime.now();
    }
    // Invalidate an older in-flight response. Its finally block will start
    // the queued request from the newest GPS and taxi positions.
    _userRouteRequestGeneration++;
    if (!_isUpdatingUserToCarRoute) {
      unawaited(_updateUserToCarRoute());
    }
  }

  /// Fetch a road-following route from the user GPS to the taxi.
  /// Only replaces the polyline when a real road geometry is returned.
  Future<void> _updateUserToCarRoute() async {
    if (_userRouteDismissed) return;
    if (_isUpdatingUserToCarRoute) {
      return;
    }

    final user = userPosition.value;
    final car = carPosition.value;
    if (user == null || car == null) return;

    final requestGeneration = _userRouteRequestGeneration;
    final startBearing =
        _isUserGoingReverse ? _preferredRouteStartBearing : null;
    _userRouteRefreshQueued = false;
    _isUpdatingUserToCarRoute = true;
    isUserToCarRouteLoading.value = userToCarRoute.isEmpty;
    try {
      final snapped = await _routingService.getRoute(
        user,
        car,
        profile: userRouteProfile.value,
        startBearing: startBearing,
      );
      final latestUser = userPosition.value;
      final latestCar = carPosition.value;
      if (_userRouteDismissed || latestUser == null || latestCar == null) {
        return;
      }

      final requestWasInvalidated =
          requestGeneration != _userRouteRequestGeneration;
      final userMovedTooFar = _calculateDistance(user, latestUser) >
          _staleRouteRequestDistanceMeters;
      final carMovedTooFar =
          _calculateDistance(car, latestCar) > _staleRouteRequestDistanceMeters;
      if (requestWasInvalidated) {
        // A newer explicit request (or a tracking reset) owns the next action.
        // Preserve its queued state instead of allowing this response to alter it.
        return;
      }
      if (userMovedTooFar || carMovedTooFar) {
        _userRouteRefreshQueued = true;
        return;
      }

      // Require a real road path (more than a 2-point straight segment)
      final isRoadRoute = snapped.points.length > 2;
      final isValidCloseRoute =
          snapped.points.length >= 2 && _calculateDistance(user, car) < 50;
      if (isRoadRoute || isValidCloseRoute) {
        _applyUserToCarRouteResult(snapped, user, car, latestUser);
      } else if (userToCarRoute.isEmpty && snapped.points.length >= 2) {
        _applyUserToCarRouteResult(snapped, user, car, latestUser);
      }
      // If routing failed/returned a straight line and we already have a route,
      // keep the previous correct road polyline — do not flash a false line.
    } catch (_) {
      // Keep existing correct route on failure
    } finally {
      _isUpdatingUserToCarRoute = false;
      isUserToCarRouteLoading.value = false;
      if (_userRouteRefreshQueued &&
          !_userRouteDismissed &&
          userPosition.value != null &&
          carPosition.value != null) {
        unawaited(_updateUserToCarRoute());
      }
    }
  }

  /// Refresh the user→taxi route when the user or car has moved enough.
  void _maybeRefreshUserToCarRoute() {
    if (_userRouteDismissed) return;
    if (_isUserOffRoute || _isUserGoingReverse) return;
    if (userPosition.value == null || carPosition.value == null) return;

    final user = userPosition.value!;
    final car = carPosition.value!;

    var needsRefresh =
        _lastRoutedCarPosition == null || _lastRoutedUserPosition == null;
    if (!needsRefresh) {
      final carMoved = _calculateDistance(_lastRoutedCarPosition!, car) >=
          _userToCarRouteRefreshDistance;
      final userMoved = _calculateDistance(_lastRoutedUserPosition!, user) >=
          _userToCarRouteRefreshDistance;
      needsRefresh = carMoved || userMoved;
    }
    if (!needsRefresh) return;

    _userToCarRouteDebounceTimer?.cancel();
    _userToCarRouteDebounceTimer =
        Timer(const Duration(milliseconds: 1200), () {
      _updateUserToCarRoute();
    });
  }

  /// Instant camera jump — no intermediate tile loading while panning.
  void _jumpToCenter(
    LatLng targetPosition,
    double targetZoom, {
    double rotation = 0.0,
  }) {
    if (flutterMapController == null) return;
    _centerAnimationTimer?.cancel();
    _centerAnimationTimer = null;
    flutterMapController!.moveAndRotate(targetPosition, targetZoom, rotation);
    currentZoom.value = targetZoom;
  }

  void centerOnCarInitial() {
    if (carPosition.value == null || flutterMapController == null) return;

    shouldFollowCar.value = true;
    isUserInteracting.value = false;

    flutterMapController!.move(carPosition.value!, 17.0);
  }

  /// Keep PiP centered on the active follow target (taxi or me). Never fit
  /// bounds to the whole A→B route — that jumps to an unrelated viewport.
  void onEnteredPictureInPicture() {
    if (flutterMapController == null) return;
    isUserInteracting.value = false;

    final zoom = currentZoom.value < 15.0 ? 17.0 : currentZoom.value;

    if (shouldFollowUser.value && userMarkerPosition.value != null) {
      _jumpToCenter(
        userMarkerPosition.value!,
        zoom,
        rotation: _headingUpRotation(),
      );
      return;
    }

    final car = carPosition.value;
    if (car != null) {
      // Following taxi, or no follow mode: stay on the vehicle.
      if (!shouldFollowUser.value) {
        shouldFollowCar.value = true;
      }
      _jumpToCenter(car, zoom, rotation: 0.0);
    }
  }

  Future<void> reconnectAfterTabSwitch() async {
    if (_socket != null && _socket!.connected) {
      return;
    }

    error.value = null;
    isReconnecting.value = false;
    reconnectionAttempts.value = 0;

    await _initializeSocket();
  }

  void handleZoomChange(double newZoom) {
    _zoomDebounceTimer?.cancel();
    _zoomDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if ((currentZoom.value - newZoom).abs() > 0.1) {
        currentZoom.value = newZoom;
      }
    });
  }

  double getCarRotationAngle() {
    double bearing = currentBearing.value;
    while (bearing < 0) bearing += 360.0;
    while (bearing >= 360) bearing -= 360.0;
    return bearing;
  }

  String getCarMarkerPath() {
    final vehicle = _mapController.liveTrackingVehicle.value;
    if (vehicle == null) return 'assets/images/car_marker.png';

    final carType = vehicle['car_type'] as String?;
    switch (carType) {
      case 'taxi':
        return 'assets/images/car_marker.png';
      case 'louage':
        return 'assets/images/louage_marker.png';
      default:
        return 'assets/images/car_marker.png';
    }
  }

  // Change selected vehicle
  void changeVehicle(Map<String, dynamic> vehicle) {
    _mapController.setLiveTrackingVehicle(vehicle);

    // Reset state
    carPosition.value = null;
    previousPosition.value = null;
    userPosition.value = null;
    userMarkerPosition.value = null;
    polylineVisualStart.value = null;
    _lastPolylineVisualAt = null;
    userToCarRoute.clear();
    _clearUserRouteMetrics();
    _lastRoutedCarPosition = null;
    _lastRoutedUserPosition = null;
    userHeading.value = 0.0;
    shouldFollowUser.value = false;
    isUserToCarRouteLoading.value = false;
    _userRouteDismissed = false;
    _userToCarRouteDebounceTimer?.cancel();
    _stopUserTracking();
    routePoints.clear();
    significantRoutePoints.clear();
    currentSpeed.value = 0.0;
    taxiMeterStatus.value = TaxiMeterStatus.libre;
    _lastSocketTaxiMeterStatus = null;
    taximeterPrice.value = null;
    isDoorOpen.value = false;
    rotationAngle.value = 0.0;
    isLoading.value = true;
    error.value = null;
    positionQueue.clear();
    dataQueue.clear();
    recentPositions.clear();
    isMoving.value = false;
    isCarStationary.value = false;
    stationaryCount.value = 0;
    _movementTimer?.cancel();
    _predictionTimer?.cancel();

    // Reconnect
    _reconnectionTimer?.cancel();
    isReconnecting.value = false;
    reconnectionAttempts.value = 0;

    _initializeSocket();
  }

  double? _parseTaxiPrice(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
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

  // Getter for clean route display in UI
  List<LatLng> get displayRoutePoints => significantRoutePoints.toList();

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
    } else if (carPosition.value != null) {
      fetchAddressFromCoordinates(carPosition.value!);
    }
  }

  /// Hide address bubble
  void hideAddressBubble() {
    showAddressBubble.value = false;
  }

  /// Debounced address update when car moves
  void _debouncedAddressUpdate(LatLng position) {
    _addressUpdateTimer?.cancel();
    _addressUpdateTimer = Timer(_addressUpdateDebounce, () {
      if (showAddressBubble.value) {
        fetchAddressFromCoordinates(position);
      }
    });
  }
}
