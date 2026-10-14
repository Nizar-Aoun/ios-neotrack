import 'package:flutter/material.dart';

/// Represents a driver shift for a specific car
class ShiftModel {
  final String? id;
  final String carId;
  final String driverName;
  final String phoneNumber;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? status; // 'open', 'closed', etc.
  final bool isDefault;

  const ShiftModel({
    this.id,
    required this.carId,
    required this.driverName,
    required this.phoneNumber,
    required this.startTime,
    required this.endTime,
    this.status,
    this.isDefault = false,
  });

  /// Whether this shift spans midnight (e.g., 22:00 → 03:00)
  bool get isOvernight {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes < startMinutes;
  }

  /// Duration of this shift in minutes
  int get durationMinutes {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    if (isOvernight) {
      return (24 * 60 - startMinutes) + endMinutes;
    }
    return endMinutes - startMinutes;
  }

  /// Check if a given DateTime falls within this shift,
  /// relative to a reference calendar date (the "shift day").
  ///
  /// For an overnight shift (e.g. 23:00–03:00), [referenceDate] is the
  /// calendar day on which the shift *starts*.
  bool containsTime(DateTime dt) {
    final dtMinutes = dt.hour * 60 + dt.minute;
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (isOvernight) {
      // Overnight: matches if time >= startTime OR time <= endTime
      return dtMinutes >= startMinutes || dtMinutes <= endMinutes;
    } else {
      return dtMinutes >= startMinutes && dtMinutes <= endMinutes;
    }
  }

  /// Human-readable time range label, e.g. "23:30 – 03:30"
  String get timeLabel {
    String fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      carId: json['car_id']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      startTime: _parseTimeString(json['start_time']?.toString() ?? '00:00'),
      endTime: _parseTimeString(json['end_time']?.toString() ?? '23:59'),
      status: json['status']?.toString(),
      isDefault: json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'car_id': carId,
      'driver_name': driverName,
      'phone_number': phoneNumber,
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'start_time': _formatTime(startTime),
      'end_time': _formatTime(endTime),
      'driver_name': driverName,
      'phone_number': phoneNumber,
    };
  }

  ShiftModel copyWith({
    String? id,
    String? carId,
    String? driverName,
    String? phoneNumber,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? status,
    bool? isDefault,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      carId: carId ?? this.carId,
      driverName: driverName ?? this.driverName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  static TimeOfDay _parseTimeString(String timeStr) {
    // Handle formats: "HH:mm", "HH:mm:ss", "HH:mm:ss.SSSZ"
    try {
      final parts = timeStr.replaceAll(RegExp(r'[Z+\-].*'), '').split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return const TimeOfDay(hour: 0, minute: 0);
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00.000Z';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// State object for the ShiftController
class ShiftState {
  final List<ShiftModel> shifts;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? selectedShiftId; // For filtering

  const ShiftState({
    this.shifts = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.selectedShiftId,
  });

  bool get hasError => errorMessage != null;
  static const int maxShifts = 4;
  bool get canAddMore => shifts.length < maxShifts;

  ShiftState copyWith({
    List<ShiftModel>? shifts,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
    String? selectedShiftId,
    bool clearSelectedShift = false,
  }) {
    return ShiftState(
      shifts: shifts ?? this.shifts,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedShiftId:
          clearSelectedShift ? null : (selectedShiftId ?? this.selectedShiftId),
    );
  }
}
