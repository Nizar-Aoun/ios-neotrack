import 'package:taxi_driver_app/config/env.dart';

class User {
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
  final DateTime createdAt;
  final DateTime? lastTimeOnline;
  final UserPermissions permissions;
  final String? profilePhoto;
  final UserPreferences preferences;
  final bool passwordUpdated;
  final bool isOnline;

  // Cache for computed URL to avoid recomputation on every access
  String? _cachedFullProfilePhotoUrl;

  User({
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
    required this.createdAt,
    this.lastTimeOnline,
    required this.permissions,
    this.profilePhoto,
    required this.preferences,
    required this.passwordUpdated,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
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
    String? _preserveLeadingZeros(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is num) {
        // IMPORTANT: If the CIN comes as a number from the server, leading zeros are already lost
        // due to JSON parsing. This is a server-side issue that should be fixed by ensuring
        // CIN values are always sent as strings, not numbers.
        //
        // For now, we just convert to string. The proper fix is to ensure the server
        // sends CIN values as strings (e.g., "0123456789" instead of 123456789)
        return value.toString();
      }
      return value.toString();
    }

    final cleanedProfilePhoto =
        cleanProfilePhotoUrl(json['profile_photo']?.toString());
    return User(
      id: parseId(json['_id'] ?? json['id']),
      fname: json['fname']?.toString() ?? '',
      lname: json['lname']?.toString() ?? '',
      email: json['email']?.toString(),
      cin: _preserveLeadingZeros(json['cin']),
      dob: json['dob'] != null
          ? DateTime.tryParse(json['dob'].toString()) ?? DateTime(1970)
          : DateTime(1970),
      countryCode: json['country_code']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      cars: (json['cars'] as List?)?.map((car) => parseId(car)).toList() ?? [],
      isActive: json['isActive'] == true || json['isActive'] == 'true',
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
      isOnline: json['isOnline'] == true || json['isOnline'] == 'true',
    );
  }

  String get fullName => '$fname $lname';
  String get fullPhone => '$countryCode$phone';

  String? get fullProfilePhotoUrl {
    // Return cached value if already computed
    if (_cachedFullProfilePhotoUrl != null || profilePhoto == null) {
      return _cachedFullProfilePhotoUrl;
    }

    // Compute and cache the URL
    if (profilePhoto!.startsWith('http')) {
      _cachedFullProfilePhotoUrl = profilePhoto;
    } else {
      // Remove any leading slashes from the profile photo path
      final cleanPath = profilePhoto!.replaceFirst(RegExp(r'^/+'), '');
      // Remove any leading /api/ from the path to avoid duplication
      final pathWithoutApi = cleanPath.replaceFirst(RegExp(r'^api/'), '');
      _cachedFullProfilePhotoUrl = '${Env.apiUrl}/$pathWithoutApi';
    }

    return _cachedFullProfilePhotoUrl;
  }
}

class UserPermissions {
  final bool gps;
  final bool wallet;
  final bool booking;
  final bool cam;
  final bool ads;

  UserPermissions({
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
}

class UserPreferences {
  final double? speedAlert;
  final FreeStatusAlert? freeStatusAlert;
  final int? stopAlert;
  final bool? openDoor;

  /// Object-based geo forcing (user-level preferences: contains lat/lng/radius).
  final GeoForcingAlert? geoForcingAlert;

  /// Boolean-based geo forcing (car-level preferences from /api/cars/preferences).
  final bool? geoForcingEnabled;

  UserPreferences({
    this.speedAlert,
    this.freeStatusAlert,
    this.stopAlert,
    this.openDoor,
    this.geoForcingAlert,
    this.geoForcingEnabled,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final freeStatus = json['free_status_alert'] != null
        ? FreeStatusAlert.fromJson(json['free_status_alert'])
        : null;

    GeoForcingAlert? geoForcing;
    bool? geoEnabled;
    final geoJson = json['geo_forcing_alert'];
    if (geoJson is bool) {
      // Car preferences: geo_forcing_alert is a boolean switch
      geoEnabled = geoJson;
    } else if (geoJson is Map<String, dynamic>) {
      // User preferences: geo_forcing_alert is an object with lat/lng/radius
      geoForcing = GeoForcingAlert.fromJson(geoJson);
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
      geoForcingEnabled: geoEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speed_alert': speedAlert,
      'free_status_alert': freeStatusAlert?.toJson(),
      'stop_alert': stopAlert,
      'open_door': openDoor,
      if (geoForcingEnabled != null)
        'geo_forcing_alert': geoForcingEnabled
      else
        'geo_forcing_alert': geoForcingAlert?.toJson(),
    };
  }

  /// True when geo forcing is active, regardless of whether it comes from a
  /// boolean flag (car prefs) or a full object (user prefs).
  bool get isGeoForcingEnabled =>
      geoForcingEnabled ?? (geoForcingAlert != null);

  UserPreferences toUserPreferences() => this;
}

class FreeStatusAlert {
  final double? distance;
  final int? duration;

  FreeStatusAlert({
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
}

class GeoForcingAlert {
  final double latitude;
  final double longitude;
  final double radius; // in meters

  GeoForcingAlert({
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
}
