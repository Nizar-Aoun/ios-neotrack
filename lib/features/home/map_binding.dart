import 'package:get/get.dart';
import 'package:taxi_driver_app/features/home/application/live_tracking_pip_coordinator.dart';
import 'package:taxi_driver_app/features/home/controller/map_controller.dart';

class MapBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(MapController());
    if (!Get.isRegistered<LiveTrackingPipCoordinator>()) {
      Get.put(LiveTrackingPipCoordinator());
    }
  }
}
