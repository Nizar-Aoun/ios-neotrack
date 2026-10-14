import 'package:get/get.dart';
import 'package:taxi_driver_app/features/shifts/application/shift_controller.dart';
import 'package:taxi_driver_app/features/shifts/data/shift_repository.dart';

class ShiftBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ShiftRepository>()) {
      Get.put<ShiftRepository>(ShiftRepository(), permanent: true);
    }
    if (!Get.isRegistered<ShiftController>()) {
      Get.put<ShiftController>(
        ShiftController(repository: Get.find<ShiftRepository>()),
        permanent: true,
      );
    }
  }
}
