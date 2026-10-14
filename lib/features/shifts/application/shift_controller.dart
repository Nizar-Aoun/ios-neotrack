import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:taxi_driver_app/core/controllers/user_controller.dart';
import 'package:taxi_driver_app/features/shifts/data/shift_repository.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';
import 'package:taxi_driver_app/models/ride.dart';

/// GetX controller for shift management
class ShiftController extends GetxController {
  final ShiftRepository _repository;

  ShiftController({required ShiftRepository repository})
      : _repository = repository;

  // ── State ────────────────────────────────────────────────────────────────────

  final Rx<ShiftState> state = const ShiftState().obs;

  /// Currently active car id
  final RxnString currentCarId = RxnString();

  // ── Public API ───────────────────────────────────────────────────────────────

  List<ShiftModel> get shifts => state.value.shifts;

  bool get canAddMore => state.value.canAddMore;

  /// The shift currently selected for filtering (null = all shifts)
  ShiftModel? get selectedShift {
    final id = state.value.selectedShiftId;
    if (id == null) return null;
    try {
      return shifts.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void selectShiftForFilter(String? shiftId) {
    state.value = state.value.copyWith(
      selectedShiftId: shiftId,
      clearSelectedShift: shiftId == null,
    );
  }

  /// Find the shift that matches a given ride by its start time.
  /// Returns null if no shift contains the ride's start time.
  ShiftModel? shiftForRide(Ride ride) {
    final dt = ride.startDate;
    if (dt == null || shifts.isEmpty) return null;
    try {
      return shifts.firstWhere((s) => s.containsTime(dt));
    } catch (_) {
      return null;
    }
  }

  /// Load all shifts for [carId] and create the default shift if none exist.
  Future<void> loadShiftsForCar(String carId) async {
    if (state.value.isLoading) return;
    currentCarId.value = carId;
    state.value = state.value.copyWith(isLoading: true, clearError: true);

    final result = await _repository.getShiftsByCar(carId);

    if (result.success) {
      final loaded = result.data ?? [];
      if (loaded.isEmpty) {
        // No shifts yet → create the default one
        state.value = state.value.copyWith(
          shifts: [],
          isLoading: false,
        );
        await _createDefaultShift(carId);
      } else {
        state.value = state.value.copyWith(
          shifts: loaded,
          isLoading: false,
        );
      }
    } else {
      state.value = state.value.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }
  }

  /// Add a new shift (max 4).
  /// Returns null on success, or an error message string on failure.
  Future<String?> addShift({
    required String carId,
    required String driverName,
    required String phoneNumber,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    if (!state.value.canAddMore) return null;

    state.value = state.value.copyWith(isSaving: true, clearError: true);

    final shift = ShiftModel(
      carId: carId,
      driverName: driverName,
      phoneNumber: phoneNumber,
      startTime: startTime,
      endTime: endTime,
    );

    final result = await _repository.createShift(shift);

    if (result.success && result.data != null) {
      final updated = [...state.value.shifts, result.data!];
      state.value = state.value.copyWith(shifts: updated, isSaving: false);
      return null;
    } else {
      state.value = state.value.copyWith(
        isSaving: false,
        errorMessage: result.error,
      );
      return result.error;
    }
  }

  /// Update an existing shift.
  /// Returns null on success, or an error message string on failure.
  Future<String?> updateShift({
    required ShiftModel shift,
    required String driverName,
    required String phoneNumber,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    if (shift.id == null) return null;
    state.value = state.value.copyWith(isSaving: true, clearError: true);

    final updated = shift.copyWith(
      driverName: driverName,
      phoneNumber: phoneNumber,
      startTime: startTime,
      endTime: endTime,
    );

    final result = await _repository.updateShift(shift.id!, updated);

    if (result.success && result.data != null) {
      final list = state.value.shifts.map((s) {
        return s.id == shift.id ? result.data! : s;
      }).toList();
      state.value = state.value.copyWith(shifts: list, isSaving: false);
      return null;
    } else {
      state.value = state.value.copyWith(
        isSaving: false,
        errorMessage: result.error,
      );
      return result.error;
    }
  }

  /// Close/archive a shift via PATCH.
  Future<bool> closeShift(String shiftId) async {
    final result = await _repository.closeShift(shiftId);
    if (result.success) {
      // Reload to get updated status
      if (currentCarId.value != null) {
        await loadShiftsForCar(currentCarId.value!);
      }
      return true;
    }
    state.value = state.value.copyWith(errorMessage: result.error);
    return false;
  }

  /// Permanently delete a shift.
  Future<bool> deleteShift(String shiftId) async {
    state.value = state.value.copyWith(isSaving: true, clearError: true);
    final result = await _repository.deleteShift(shiftId);
    if (result.success) {
      final updated = state.value.shifts.where((s) => s.id != shiftId).toList();
      state.value = state.value.copyWith(shifts: updated, isSaving: false);
      return true;
    }
    state.value = state.value.copyWith(
      isSaving: false,
      errorMessage: result.error,
    );
    return false;
  }

  void clearError() {
    state.value = state.value.copyWith(clearError: true);
  }

  // ── Private ──────────────────────────────────────────────────────────────────

  /// Creates the default "24-hour" shift using the logged-in user's name.
  Future<void> _createDefaultShift(String carId) async {
    String driverName = 'Driver';
    try {
      final userController = Get.find<UserController>();
      final user = userController.user.value;
      if (user != null) {
        driverName = user.fullName;
      }
    } catch (_) {}

    await addShift(
      carId: carId,
      driverName: driverName,
      phoneNumber: '',
      startTime: const TimeOfDay(hour: 3, minute: 0),
      endTime: const TimeOfDay(hour: 2, minute: 59),
    );
  }
}
