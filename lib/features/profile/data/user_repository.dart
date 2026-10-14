import 'dart:typed_data';
import 'package:taxi_driver_app/models/user.dart';
import 'package:taxi_driver_app/services/auth_service.dart';
import 'package:taxi_driver_app/services/user_service.dart';
import 'package:taxi_driver_app/services/car_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User repository for profile feature
class UserRepository {
  final UserService _userService;
  final CarService _carService;

  UserRepository({
    required UserService userService,
    required CarService carService,
  })  : _userService = userService,
        _carService = carService;

  /// Factory constructor with async initialization
  static Future<UserRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    final authService = AuthService(prefs);
    final userService = UserService(authService);
    final carService = CarService(authService);

    return UserRepository(
      userService: userService,
      carService: carService,
    );
  }

  /// Get current user
  Future<User> getCurrentUser(String token, String userId) async {
    return await _userService.getCurrentUser(token, userId);
  }

  /// Update profile name fields
  Future<Map<String, dynamic>> updateProfile({
    String? fname,
    String? lname,
  }) async {
    return await _userService.updateProfile(fname: fname, lname: lname);
  }

  /// Request OTP for phone or email change
  Future<Map<String, dynamic>> requestProfileChangeOtp({
    String? phone,
    String? email,
  }) async {
    return await _userService.requestProfileChangeOtp(
      phone: phone,
      email: email,
    );
  }

  /// Verify OTP and persist the new phone or email
  Future<Map<String, dynamic>> verifyProfileChangeOtp({
    String? phone,
    String? email,
    required String otp,
  }) async {
    return await _userService.verifyProfileChangeOtp(
      phone: phone,
      email: email,
      otp: otp,
    );
  }

  /// Load cars for user
  Future<List<Map<String, dynamic>>> loadCars() async {
    try {
      final response = await _carService.getUserCars();
      final cars =
          (response['cars'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return cars;
    } catch (e) {
      throw Exception('Failed to load cars: $e');
    }
  }

  /// Upload profile photo
  Future<Map<String, dynamic>> uploadProfilePhoto(
    Uint8List bytes,
    String filename,
  ) async {
    return await _userService.updateProfilePhoto(bytes, filename);
  }

  /// Remove profile photo
  Future<Map<String, dynamic>> removeProfilePhoto() async {
    return await _userService.removeProfilePhoto();
  }

  /// Update user preferences (legacy - kept for backward compatibility)
  Future<Map<String, dynamic>> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    return await _userService.updatePreferences(preferences);
  }

  /// Get car preferences for all user cars
  Future<List<Map<String, dynamic>>> getCarPreferences() async {
    try {
      final response = await _carService.getCarPreferences();
      final cars =
          (response['cars'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      return cars;
    } catch (e) {
      throw Exception('Failed to load car preferences: $e');
    }
  }

  /// Update preferences for a specific car
  Future<Map<String, dynamic>> updateCarPreferences(
    String carId,
    Map<String, dynamic> preferences,
  ) async {
    return await _carService.updateCarPreferences(carId, preferences);
  }

  /// Update password
  Future<Map<String, dynamic>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await _userService.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  /// Remote stop car
  Future<Map<String, dynamic>> remoteStopCar(String carId) async {
    return await _carService.remoteStop(carId);
  }

  /// Remote start car
  Future<Map<String, dynamic>> remoteStartCar(String carId) async {
    return await _carService.remoteStart(carId);
  }
}
