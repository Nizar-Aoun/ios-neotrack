import 'package:get/get.dart';
import 'package:taxi_driver_app/features/home/controller/home_controller.dart';
import 'package:taxi_driver_app/services/car_service.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // HomeController is already initialized globally in main.dart
    // Just ensure it exists, but don't create a new instance
    if (!Get.isRegistered<HomeController>()) {
      final carService = Get.find<CarService>();
      Get.put<HomeController>(HomeController(carService: carService));
    }
  }
}
