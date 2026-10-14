import 'package:get/get.dart';
import 'package:taxi_driver_app/features/auth/controller/auth_controller_getx.dart';

/// GetX Binding for Auth feature
/// This ensures proper dependency injection for the Auth Controller
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Register AuthController as a singleton
    Get.lazyPut<AuthControllerGetX>(
      () => AuthControllerGetX(),
      fenix: true,
    );
  }
}
