import 'package:get/get.dart';
import 'package:taxi_driver_app/models/user.dart';

/// User Controller - Manages user state and authentication
class UserController extends GetxController {
  final Rxn<User> user = Rxn<User>();

  bool get isLoggedIn => user.value != null;
  UserPermissions? get permissions => user.value?.permissions;
  String? get carId =>
      user.value?.cars.isNotEmpty == true ? user.value!.cars.first : null;
  bool get passwordUpdated => user.value?.passwordUpdated ?? false;

  void setUser(User? newUser) {
    user.value = newUser;
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    user.value = User.fromJson(userData);
  }

  void updatePasswordStatus(bool updated) {
    if (user.value != null) {
      final currentUser = user.value!;
      user.value = User(
        id: currentUser.id,
        fname: currentUser.fname,
        lname: currentUser.lname,
        email: currentUser.email,
        cin: currentUser.cin,
        dob: currentUser.dob,
        countryCode: currentUser.countryCode,
        phone: currentUser.phone,
        cars: currentUser.cars,
        isActive: currentUser.isActive,
        createdAt: currentUser.createdAt,
        lastTimeOnline: currentUser.lastTimeOnline,
        permissions: currentUser.permissions,
        profilePhoto: currentUser.profilePhoto,
        preferences: currentUser.preferences,
        passwordUpdated: updated,
        isOnline: currentUser.isOnline,
      );
    }
  }

  void clearUser() {
    user.value = null;
  }
}
