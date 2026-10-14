import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'car.dart';
import 'location.dart';

class Ride {
  final String id;
  final Car car;
  final List<Location> locations;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? rideAmount;
  final String? driverName;
  final bool dateRangeAlert;
  final String? status;
  final double? distance;
  final double? maxSpeed;
  final bool? isDeleted;
  final int? state;
  final String? tripId;
  final int? version;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Ride({
    required this.id,
    required this.car,
    required this.locations,
    this.startDate,
    this.endDate,
    this.rideAmount,
    this.driverName,
    this.dateRangeAlert = false,
    this.status,
    this.distance,
    this.maxSpeed,
    this.isDeleted,
    this.state,
    this.tripId,
    this.version,
    this.createdAt,
    this.updatedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    try {
      String parseId(dynamic id) {
        if (id is String) return id;
        if (id is Map && id.containsKey('_id')) return id['_id'];
        return id.toString();
      }

      DateTime? parseDate(dynamic date) {
        if (date == null) return null;
        if (date is String) {
          try {
            return DateTime.parse(date);
          } catch (e) {
            // Handle different date formats
            if (date.contains('T')) {
              return DateTime.parse(date);
            } else {
              return DateTime.parse('${date}Z');
            }
          }
        }
        if (date is Map && date.containsKey('\$date')) {
          return DateTime.parse(date['\$date']);
        }
        try {
          return DateTime.parse(date.toString());
        } catch (e) {
          return null;
        }
      }

      bool parseBool(dynamic value) {
        if (value is bool) return value;
        if (value is num) return value != 0;
        if (value is String) {
          final normalized = value.trim().toLowerCase();
          return normalized == 'true' || normalized == '1';
        }
        return false;
      }

      // Parse car with fallback for missing/malformed data
      Car parseCar(dynamic carData) {
        try {
          if (carData is Map && carData.isNotEmpty) {
            return Car.fromJson(carData as Map<String, dynamic>);
          }
        } catch (e) {
        }
        // Fallback car if parsing fails
        return Car(
          id: 'unknown',
          plateNumber: 'N/A',
          brand: 'Unknown',
          model: 'Unknown',
          carType: 'unknown',
        );
      }

      // Parse locations with null safety
      List<Location> parseLocations(dynamic locData) {
        try {
          if (locData is List && locData.isNotEmpty) {
            return locData
                .map((loc) => Location.fromJson(loc as Map<String, dynamic>))
                .toList();
          }
        } catch (e) {
        }
        return [];
      }

      final id = parseId(json['_id'] ?? json['id'] ?? 'unknown');
      return Ride(
        id: id,
        car: parseCar(json['car_id']),
        locations: parseLocations(json['locations']),
        startDate: parseDate(json['start_date']),
        endDate: parseDate(json['end_date']),
        rideAmount: json['ride_amount'] != null
            ? (json['ride_amount'] as num).toDouble()
            : null,
        driverName: json['driver_name']?.toString(),
        dateRangeAlert: parseBool(json['date_range_alert']),
        status: json['status']?.toString(),
        distance: json['distance'] != null
            ? (json['distance'] as num).toDouble()
            : null,
        maxSpeed: (json['maxSpeed'] ?? json['max_speed']) is num
            ? ((json['maxSpeed'] ?? json['max_speed']) as num).toDouble()
            : null,
        isDeleted:
            json['isDeleted'] == null ? null : parseBool(json['isDeleted']),
        state: json['state'] is num ? (json['state'] as num).toInt() : null,
        tripId: json['trip_id']?.toString(),
        version: json['__v'] is num ? (json['__v'] as num).toInt() : null,
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'car_id': car.toJson(),
      'locations': locations.map((loc) => loc.toJson()).toList(),
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'ride_amount': rideAmount,
      'driver_name': driverName,
      'date_range_alert': dateRangeAlert,
      'status': status,
      'distance': distance,
      'maxSpeed': maxSpeed,
      'isDeleted': isDeleted,
      'state': state,
      'trip_id': tripId,
      '__v': version,
      'id': id,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper getter for duration
  Duration? get duration {
    if (startDate != null && endDate != null) {
      return endDate!.difference(startDate!);
    }
    return null;
  }

  // Helper getter for formatted duration
  String formattedDuration(BuildContext context) {
    final duration = this.duration;
    if (duration == null) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final l10n = AppLocalizations.of(context);
    return '${hours}${l10n.translate('hourUnit')} ${minutes}${l10n.translate('minuteUnit')}';
  }

  // Helper getter for car plate number
  String get carPlateNumber => car.plateNumber;

  // Helper getter for car brand and model
  String get carInfo => '${car.brand} ${car.model}';
}
