import 'package:get/get.dart';
import 'package:taxi_driver_app/features/help/provider/help_controller.dart';
import 'package:taxi_driver_app/features/help/data/help_repository.dart';
import 'package:taxi_driver_app/services/auth_service.dart';

/// Help Feature Binding - Registers dependencies for help feature
class HelpBinding extends Bindings {
  @override
  void dependencies() {
    final authService = Get.find<AuthService>();
    Get.lazyPut<HelpRepository>(() => HelpRepository(authService));
    Get.lazyPut<HelpController>(
        () => HelpController(Get.find<HelpRepository>()));
  }
}
