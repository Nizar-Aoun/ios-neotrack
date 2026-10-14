import 'package:flutter/foundation.dart';
import 'package:taxi_driver_app/config/env.dart';

/// User domain model for the auth feature
class UserModel {
  final String id;
  final String fname;
  final String lname;
  final String? email;
  final String? cin;
  final DateTime dob;
  final String countryCode;
  final String phone;
  final List<String> cars;
  final bool isActive;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime? lastTimeOnline;
  final UserPermissions permissions;
  final String? profilePhoto;
  final UserPreferences preferences;
  final bool passwordUpdated;

  const UserModel({
    required this.id,
    required this.fname,
    required this.lname,
    this.email,
    this.cin,
    required this.dob,
    required this.countryCode,
    required this.phone,
    required this.cars,
    required this.isActive,
    required this.isOnline,
    required this.createdAt,
    this.lastTimeOnline,
    required this.permissions,
    this.profilePhoto,
    required this.preferences,
    required this.passwordUpdated,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct string ID and MongoDB ObjectId format
    String parseId(dynamic id) {
      if (id is String) return id;
      if (id is Map && id.containsKey('\$oid')) return id['\$oid'];
      return id?.toString() ?? '';
    }

    // Safely parse DateTime with MongoDB format support
    DateTime? parseDateTime(dynamic date) {
      if (date == null) return null;
      if (date is String) return DateTime.tryParse(date);
      if (date is Map && date.containsKey('\$date')) {
        return DateTime.tryParse(date['\$date']);
      }
      return null;
    }

    // Clean up profile photo URL to remove duplicate /api/ paths
    String? cleanProfilePhotoUrl(String? url) {
      if (url == null) {
        return null;
      }
      if (!url.startsWith('http')) {
        return url;
      }

      // Replace localhost with the actual API URL host
      if (url.contains('localhost')) {
        final baseUrl = Env.apiUrl.split('/api')[0];
        url = url.replaceFirst('http://localhost:5000', baseUrl);
      }

      // Remove any duplicate /api/ paths
      url = url.replaceAll(RegExp(r'/api/api/'), '/api/');
      // If the URL starts with the API URL, return just the path part
      if (url.startsWith(Env.apiUrl)) {
        final path = url.substring(Env.apiUrl.length);
        return path;
      }
      return url;
    }

    // Preserve leading zeros in CIN numbers
    String? preserveLeadingZeros(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is num) {
        return value.toString();
      }
      return value.toString();
    }

    final cleanedProfilePhoto =
        cleanProfilePhotoUrl(json['profile_photo']?.toString());
    return UserModel(
      id: parseId(json['_id'] ?? json['id']),
      fname: json['fname']?.toString() ?? '',
      lname: json['lname']?.toString() ?? '',
      email: json['email']?.toString(),
      cin: preserveLeadingZeros(json['cin']),
      dob: json['dob'] != null
          ? DateTime.tryParse(json['dob'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      countryCode: json['country_code']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      cars: (json['cars'] as List?)?.map((car) => parseId(car)).toList() ?? [],
      isActive: json['isActive'] == true || json['isActive'] == 'true',
      isOnline: json['isOnline'] == true || json['isOnline'] == 'true',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      lastTimeOnline: parseDateTime(json['last_time_online']),
      permissions: UserPermissions.fromJson(json['permissions'] ?? {}),
      profilePhoto: cleanedProfilePhoto,
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      passwordUpdated: json['passwordUpdated'] == true ||
          json['password_updated'] == true ||
          json['passwordUpdated'] == 'true' ||
          json['password_updated'] == 'true',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fname': fname,
      'lname': lname,
      'email': email,
      'cin': cin,
      'dob': dob.toIso8601String(),
      'country_code': countryCode,
      'phone': phone,
      'cars': cars,
      'isActive': isActive,
      'isOnline': isOnline,
      'created_at': createdAt.toIso8601String(),
      'last_time_online': lastTimeOnline?.toIso8601String(),
      'permissions': permissions.toJson(),
      'profile_photo': profilePhoto,
      'preferences': preferences.toJson(),
      'password_updated': passwordUpdated,
    };
  }

  UserModel copyWith({
    String? id,
    String? fname,
    String? lname,
    String? email,
    String? cin,
    DateTime? dob,
    String? countryCode,
    String? phone,
    List<String>? cars,
    bool? isActive,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? lastTimeOnline,
    UserPermissions? permissions,
    String? profilePhoto,
    UserPreferences? preferences,
    bool? passwordUpdated,
  }) {
    return UserModel(
      id: id ?? this.id,
      fname: fname ?? this.fname,
      lname: lname ?? this.lname,
      email: email ?? this.email,
      cin: cin ?? this.cin,
      dob: dob ?? this.dob,
      countryCode: countryCode ?? this.countryCode,
      phone: phone ?? this.phone,
      cars: cars ?? this.cars,
      isActive: isActive ?? this.isActive,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      lastTimeOnline: lastTimeOnline ?? this.lastTimeOnline,
      permissions: permissions ?? this.permissions,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      preferences: preferences ?? this.preferences,
      passwordUpdated: passwordUpdated ?? this.passwordUpdated,
    );
  }

  String get fullName => '$fname $lname';
  String get fullPhone => '$countryCode$phone';

  String? get fullProfilePhotoUrl {
    if (profilePhoto == null) {
      return null;
    }
    if (profilePhoto!.startsWith('http')) {
      return profilePhoto;
    }
    // Remove any leading slashes from the profile photo path
    final cleanPath = profilePhoto!.replaceFirst(RegExp(r'^/+'), '');
    // Remove any leading /api/ from the path to avoid duplication
    final pathWithoutApi = cleanPath.replaceFirst(RegExp(r'^api/'), '');
    final fullUrl = '${Env.apiUrl}/$pathWithoutApi';
    return fullUrl;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class UserPermissions {
  final bool gps;
  final bool wallet;
  final bool booking;
  final bool cam;
  final bool ads;

  const UserPermissions({
    required this.gps,
    required this.wallet,
    required this.booking,
    required this.cam,
    required this.ads,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      gps: json['gps'] ?? false,
      wallet: json['wallet'] ?? false,
      booking: json['booking'] ?? false,
      cam: json['cam'] ?? false,
      ads: json['ads'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gps': gps,
      'wallet': wallet,
      'booking': booking,
      'cam': cam,
      'ads': ads,
    };
  }

  UserPermissions copyWith({
    bool? gps,
    bool? wallet,
    bool? booking,
    bool? cam,
    bool? ads,
  }) {
    return UserPermissions(
      gps: gps ?? this.gps,
      wallet: wallet ?? this.wallet,
      booking: booking ?? this.booking,
      cam: cam ?? this.cam,
      ads: ads ?? this.ads,
    );
  }
}

class UserPreferences {
  final double? speedAlert;
  final FreeStatusAlert? freeStatusAlert;
  final int? stopAlert;
  final bool? openDoor;
  final dynamic geoForcingAlert; // Can be bool or GeoForcingAlert object

  const UserPreferences({
    this.speedAlert,
    this.freeStatusAlert,
    this.stopAlert,
    this.openDoor,
    this.geoForcingAlert,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final freeStatus = json['free_status_alert'] != null
        ? FreeStatusAlert.fromJson(json['free_status_alert'])
        : null;

    // Handle geo_forcing_alert as either bool or object
    dynamic geoForcing;
    if (json['geo_forcing_alert'] != null) {
      if (json['geo_forcing_alert'] is bool) {
        geoForcing = json['geo_forcing_alert'];
      } else if (json['geo_forcing_alert'] is Map) {
        geoForcing = GeoForcingAlert.fromJson(json['geo_forcing_alert']);
      }
    }

    return UserPreferences(
      speedAlert: json['speed_alert']?.toDouble(),
      freeStatusAlert: (freeStatus != null &&
              (freeStatus.distance != null || freeStatus.duration != null))
          ? freeStatus
          : null,
      stopAlert: json['stop_alert'],
      openDoor: json['open_door'],
      geoForcingAlert: geoForcing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speed_alert': speedAlert,
      'free_status_alert': freeStatusAlert?.toJson(),
      'stop_alert': stopAlert,
      'open_door': openDoor,
      'geo_forcing_alert': geoForcingAlert is GeoForcingAlert
          ? (geoForcingAlert as GeoForcingAlert).toJson()
          : geoForcingAlert,
    };
  }

  UserPreferences copyWith({
    double? speedAlert,
    FreeStatusAlert? freeStatusAlert,
    int? stopAlert,
    bool? openDoor,
    dynamic geoForcingAlert,
  }) {
    return UserPreferences(
      speedAlert: speedAlert ?? this.speedAlert,
      freeStatusAlert: freeStatusAlert ?? this.freeStatusAlert,
      stopAlert: stopAlert ?? this.stopAlert,
      openDoor: openDoor ?? this.openDoor,
      geoForcingAlert: geoForcingAlert ?? this.geoForcingAlert,
    );
  }

  /// Helper to check if geo forcing is enabled
  bool get isGeoForcingEnabled {
    if (geoForcingAlert == null) return false;
    if (geoForcingAlert is bool) return geoForcingAlert as bool;
    if (geoForcingAlert is GeoForcingAlert) return true;
    return false;
  }
}

class FreeStatusAlert {
  final double? distance;
  final int? duration;

  const FreeStatusAlert({
    this.distance,
    this.duration,
  });

  factory FreeStatusAlert.fromJson(Map<String, dynamic> json) {
    return FreeStatusAlert(
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration,
    };
  }

  FreeStatusAlert copyWith({
    double? distance,
    int? duration,
  }) {
    return FreeStatusAlert(
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
    );
  }
}

class GeoForcingAlert {
  final double latitude;
  final double longitude;
  final double radius;

  const GeoForcingAlert({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory GeoForcingAlert.fromJson(Map<String, dynamic> json) {
    return GeoForcingAlert(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      radius: json['radius']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  GeoForcingAlert copyWith({
    double? latitude,
    double? longitude,
    double? radius,
  }) {
    return GeoForcingAlert(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
    );
  }
}
