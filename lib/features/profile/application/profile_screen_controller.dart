import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taxi_driver_app/features/profile/application/profile_controller.dart';
import 'package:taxi_driver_app/features/profile/domain/profile_model.dart';
// No longer depends on UserProvider for profile feature

/// Controller that exposes UI-friendly methods for ProfileScreenNew.
/// It delegates to the Riverpod ProfileController and hides implementation details
/// like repositories and legacy provider bridges.
class ProfileScreenController {
  final ProfileController controller = Get.find<ProfileController>();

  /// Ensure initial data is loaded and user is synced into state.
  Future<void> initialize(BuildContext context) async {
    await controller.initialize();
  }

  /// Logout user and clear local state.
  Future<void> handleLogout() async {
    await controller.logout();
  }

  /// Pick an image from gallery and upload as profile photo.
  Future<void> pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final filename =
          pickedFile.name.isNotEmpty ? pickedFile.name : 'profile_photo.jpg';
      await controller.uploadProfilePhoto(bytes, filename);
    }
  }

  /// Remove current profile photo.
  Future<void> removeProfilePhoto(BuildContext context) async {
    await controller.removeProfilePhoto();
  }

  /// Update any user preferences (legacy).
  Future<void> updatePreferences(
    Map<String, dynamic> preferences,
    BuildContext context,
  ) async {
    await controller.updatePreferences(preferences);
  }

  /// Update car-specific preferences via new API.
  Future<void> updateCarPreferences(
    String carId,
    Map<String, dynamic> preferences,
    BuildContext context,
  ) async {
    await controller.updateCarPreferences(carId, preferences);
  }

  /// Update password.
  Future<void> updatePassword(
    String oldPassword,
    String newPassword,
    BuildContext context,
  ) async {
    await controller.updatePassword(
      PasswordUpdateData(oldPassword: oldPassword, newPassword: newPassword),
    );
  }

  Future<void> updateProfileInfo(
    String? fname,
    String? lname,
    BuildContext context,
  ) async {
    await controller.updateProfileInfo(fname: fname, lname: lname);
  }

  Future<void> requestProfileChangeOtp(
    String? phone,
    String? email,
    BuildContext context,
  ) async {
    await controller.requestProfileChangeOtp(phone: phone, email: email);
  }

  Future<void> verifyProfileChangeOtp(
    String? phone,
    String? email,
    String otp,
    BuildContext context,
  ) async {
    await controller.verifyProfileChangeOtp(
      phone: phone,
      email: email,
      otp: otp,
    );
  }

  /// Remote stop/start
  Future<void> remoteStop(String carId) async {
    await controller.remoteStopCar(carId);
  }

  Future<void> remoteStart(String carId) async {
    await controller.remoteStartCar(carId);
  }
}
