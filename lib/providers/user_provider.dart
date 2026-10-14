import 'package:flutter/foundation.dart';
import 'package:taxi_driver_app/models/user.dart';

class UserProvider with ChangeNotifier {
  User? _user;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  UserPermissions? get permissions => _user?.permissions;
  String? get carId => _user?.cars.isNotEmpty == true ? _user!.cars.first : null;
  bool get passwordUpdated => _user?.passwordUpdated ?? false;

  void setUser(User? user) {
    _user = user;
    notifyListeners();
  }

  Future<void> updateUser(Map<String, dynamic> userData) async {
    _user = User.fromJson(userData);
    notifyListeners();
  }

  void updatePasswordStatus(bool updated) {
    if (_user != null) {
      // Create a new user with updated password status
      _user = User(
        id: _user!.id,
        fname: _user!.fname,
        lname: _user!.lname,
        email: _user!.email,
        cin: _user!.cin,
        dob: _user!.dob,
        countryCode: _user!.countryCode,
        phone: _user!.phone,
        cars: _user!.cars,
        isActive: _user!.isActive,
        createdAt: _user!.createdAt,
        lastTimeOnline: _user!.lastTimeOnline,
        permissions: _user!.permissions,
        profilePhoto: _user!.profilePhoto,
        preferences: _user!.preferences,
        passwordUpdated: updated, isOnline: _user!.isOnline,
      );
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  // Helper getters for commonly accessed user data
  String? get fullName => _user?.fullName;
  String? get profilePhoto => _user?.profilePhoto;
  String? get phoneNumber => _user?.fullPhone;
  List<String>? get cars => _user?.cars;
} 