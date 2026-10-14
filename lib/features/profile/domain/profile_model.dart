import 'package:taxi_driver_app/models/user.dart';

/// Profile state model
class ProfileState {
  final User? user;
  final List<Map<String, dynamic>> cars;
  final Map<String, UserPreferences> carPreferences;
  final bool isLoadingCars;
  final bool isUploadingPhoto;
  final bool isRemovingPhoto;
  final bool isUpdatingPreferences;
  final bool isUpdatingProfile;
  final bool isUpdatingContact;
  final bool isUpdatingPassword;
  final String? errorMessage;

  const ProfileState({
    this.user,
    this.cars = const [],
    this.carPreferences = const {},
    this.isLoadingCars = false,
    this.isUploadingPhoto = false,
    this.isRemovingPhoto = false,
    this.isUpdatingPreferences = false,
    this.isUpdatingProfile = false,
    this.isUpdatingContact = false,
    this.isUpdatingPassword = false,
    this.errorMessage,
  });

  bool get hasError => errorMessage != null;
  bool get isLoading =>
      isLoadingCars ||
      isUploadingPhoto ||
      isRemovingPhoto ||
      isUpdatingPreferences ||
      isUpdatingProfile ||
      isUpdatingContact ||
      isUpdatingPassword;

  ProfileState copyWith({
    User? user,
    List<Map<String, dynamic>>? cars,
    Map<String, UserPreferences>? carPreferences,
    bool? isLoadingCars,
    bool? isUploadingPhoto,
    bool? isRemovingPhoto,
    bool? isUpdatingPreferences,
    bool? isUpdatingProfile,
    bool? isUpdatingContact,
    bool? isUpdatingPassword,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      cars: cars ?? this.cars,
      carPreferences: carPreferences ?? this.carPreferences,
      isLoadingCars: isLoadingCars ?? this.isLoadingCars,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      isRemovingPhoto: isRemovingPhoto ?? this.isRemovingPhoto,
      isUpdatingPreferences:
          isUpdatingPreferences ?? this.isUpdatingPreferences,
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      isUpdatingContact: isUpdatingContact ?? this.isUpdatingContact,
      isUpdatingPassword: isUpdatingPassword ?? this.isUpdatingPassword,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Alert preference update data
class AlertPreferenceUpdate {
  final String type;
  final dynamic value;

  AlertPreferenceUpdate({
    required this.type,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      type: value,
    };
  }
}

/// Speed alert data
class SpeedAlertData {
  final double speedLimit;

  SpeedAlertData({required this.speedLimit});

  Map<String, dynamic> toJson() {
    return {
      'speed_alert': speedLimit,
    };
  }
}

/// Free status alert data
class FreeStatusAlertData {
  final double? distance;
  final int? duration;

  FreeStatusAlertData({
    this.distance,
    this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'free_status_alert': {
        if (distance != null) 'distance': distance,
        if (duration != null) 'duration': duration,
      },
    };
  }
}

/// Stop alert data
class StopAlertData {
  final int stopDuration;

  StopAlertData({required this.stopDuration});

  Map<String, dynamic> toJson() {
    return {
      'stop_alert': stopDuration,
    };
  }
}

/// Geo forcing alert data
class GeoForcingAlertData {
  final double latitude;
  final double longitude;
  final double radius;

  GeoForcingAlertData({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  Map<String, dynamic> toJson() {
    return {
      'geo_forcing_alert': {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      },
    };
  }
}

/// Password update data
class PasswordUpdateData {
  final String oldPassword;
  final String newPassword;

  PasswordUpdateData({
    required this.oldPassword,
    required this.newPassword,
  });
}
