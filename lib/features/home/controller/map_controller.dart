import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MapController extends GetxController {
  // Services
  late final HomeController _homeController;

  // Get current tab index from HomeController
  int get currentTabIndex => _homeController.tabIndex.value;

  // Observable state variables
  final RxList<Map<String, dynamic>> allVehicles = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> onlineVehicles =
      <Map<String, dynamic>>[].obs;
  // Separate vehicle selections for each tab
  final Rx<Map<String, dynamic>?> liveTrackingVehicle =
      Rx<Map<String, dynamic>?>(null);
  final Rx<Map<String, dynamic>?> selectedVehicle =
      Rx<Map<String, dynamic>?>(null); // For backward compatibility
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool noCarsAvailable = false.obs;
  final RxBool noOnlineCars = false.obs;
  final RxInt historyTabKey = 0.obs;

  // History tab state preservation
  final Rx<DateTime?> preservedStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> preservedEndDate = Rx<DateTime?>(null);
  final Rx<Map<String, dynamic>?> preservedHistoryVehicle =
      Rx<Map<String, dynamic>?>(null);
  final RxList<Map<String, dynamic>> preservedLocationHistory =
      <Map<String, dynamic>>[].obs;
  final RxList<LatLng> preservedRoutePoints = <LatLng>[].obs;
  final RxDouble preservedPlaybackPosition = 0.0.obs;
  final RxBool preservedIsPlaying = false.obs;
  final RxDouble preservedPlaybackSpeed = 1.0.obs;

  // Cache for online vehicles
  List<Map<String, dynamic>>? _onlineVehiclesCache;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    WakelockPlus.enable();
  }

  @override
  void onClose() {
    // Disable wakelock when controller is disposed
    WakelockPlus.disable();
    super.onClose();
  }

  Future<void> _initializeServices() async {
    await Future.microtask(() async {
      _homeController = Get.find<HomeController>();
      // Reuse cars from HomeController instead of fetching again
      await _loadCarsFromHomeController();
    });
  }

  Future<void> _loadCarsFromHomeController() async {
    try {
      // Wait for HomeController to finish loading if still in progress
      while (_homeController.isLoadingCars.value) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Use cars from HomeController
      allVehicles.value = List<Map<String, dynamic>>.from(_homeController.cars);
      clearOnlineVehiclesCache();
      onlineVehicles.value = getOnlineVehicles();
      isLoading.value = false;
      noCarsAvailable.value = allVehicles.isEmpty;
      noOnlineCars.value = onlineVehicles.isEmpty;

      updateVehicleSelection();
    } catch (e) {
      isLoading.value = false;
      hasError.value = true;
      errorMessage.value = 'Failed to load vehicles.';
    }
  }

  List<Map<String, dynamic>> getOnlineVehicles() {
    if (_onlineVehiclesCache != null) {
      return _onlineVehiclesCache!;
    }
    _onlineVehiclesCache =
        allVehicles.where((car) => car['isOnline'] == true).toList();
    return _onlineVehiclesCache!;
  }

  void clearOnlineVehiclesCache() {
    _onlineVehiclesCache = null;
  }

  void updateVehicleSelection() {
    final online = getOnlineVehicles();
    // Initialize live tracking vehicle if not set
    if (online.isNotEmpty && liveTrackingVehicle.value == null) {
      liveTrackingVehicle.value = online.first;
    }
    // Keep selectedVehicle for backward compatibility
    if (online.isNotEmpty && selectedVehicle.value == null) {
      selectedVehicle.value = online.first;
    }
  }

  Future<void> refreshVehicles() async {
    isLoading.value = true;
    hasError.value = false;
    errorMessage.value = '';

    // Refresh from HomeController to keep data in sync
    await _homeController.fetchUserCars();
    await _loadCarsFromHomeController();
  }

  void setSelectedVehicle(Map<String, dynamic>? vehicle) {
    selectedVehicle.value = vehicle;
  }

  // Set live tracking vehicle separately
  void setLiveTrackingVehicle(Map<String, dynamic>? vehicle) {
    liveTrackingVehicle.value = vehicle;
  }

  void switchTab(int index) {
    _homeController.switchInnerTab(index);

    // Only reset vehicle selection if explicitly requested
    if (index == 1) {
      // History tab - increment key to force recreation
      historyTabKey.value++;
    } else {
      // Live tab - reset history state
      preservedStartDate.value = null;
      preservedEndDate.value = null;
      preservedHistoryVehicle.value = null;
      preservedLocationHistory.clear();
      preservedRoutePoints.clear();
      preservedPlaybackPosition.value = 0.0;
      preservedIsPlaying.value = false;
      preservedPlaybackSpeed.value = 1.0;
    }
  }

  // Preserve history tab state
  void preserveHistoryState({
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic>? selectedVehicle,
    required List<Map<String, dynamic>> locationHistory,
    required List<LatLng> routePoints,
    required double playbackPosition,
    required bool isPlaying,
    required double playbackSpeed,
  }) {
    preservedStartDate.value = startDate;
    preservedEndDate.value = endDate;
    preservedHistoryVehicle.value = selectedVehicle;
    preservedLocationHistory.value = List.from(locationHistory);
    preservedRoutePoints.value = List.from(routePoints);
    preservedPlaybackPosition.value = playbackPosition;
    preservedIsPlaying.value = isPlaying;
    preservedPlaybackSpeed.value = playbackSpeed;
  }

  // Get preserved history state
  Map<String, dynamic> getPreservedHistoryState() {
    return {
      'startDate': preservedStartDate.value,
      'endDate': preservedEndDate.value,
      'selectedVehicle': preservedHistoryVehicle.value,
      'locationHistory': preservedLocationHistory,
      'routePoints': preservedRoutePoints,
      'playbackPosition': preservedPlaybackPosition.value,
      'isPlaying': preservedIsPlaying.value,
      'playbackSpeed': preservedPlaybackSpeed.value,
    };
  }
}
