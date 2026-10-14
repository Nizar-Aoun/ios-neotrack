import 'package:get/get.dart';
import 'package:taxi_driver_app/features/profile/application/profile_controller.dart';
import 'package:taxi_driver_app/features/profile/data/user_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserRepository>()) {
      Get.putAsync<UserRepository>(() async => await UserRepository.create(),
          permanent: true);
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.lazyPut<ProfileController>(
          () => ProfileController(repository: Get.find<UserRepository>()));
    }
  }
}
