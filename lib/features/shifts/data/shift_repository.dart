import 'package:flutter/foundation.dart';
import 'package:taxi_driver_app/features/shifts/data/shift_api_service.dart';
import 'package:taxi_driver_app/features/shifts/domain/shift_model.dart';

/// Structured API response wrapper
class ShiftApiResult<T> {
  final bool success;
  final T? data;
  final String? error;

  const ShiftApiResult.ok(this.data)
      : success = true,
        error = null;

  const ShiftApiResult.fail(this.error)
      : success = false,
        data = null;
}

/// Repository that wraps ShiftApiService with error handling
class ShiftRepository {
  final ShiftApiService _api;

  ShiftRepository({ShiftApiService? api}) : _api = api ?? ShiftApiService();

  Future<ShiftApiResult<ShiftModel>> createShift(ShiftModel shift) async {
    try {
      final result = await _api.createShift(shift);
      return ShiftApiResult.ok(result);
    } catch (e) {
      return ShiftApiResult.fail(e.toString());
    }
  }

  Future<ShiftApiResult<ShiftModel>> updateShift(
      String id, ShiftModel shift) async {
    try {
      final result = await _api.updateShift(id, shift);
      return ShiftApiResult.ok(result);
    } catch (e) {
      return ShiftApiResult.fail(e.toString());
    }
  }

  Future<ShiftApiResult<List<ShiftModel>>> getShiftsByCar(String carId) async {
    try {
      final result = await _api.getShiftsByCar(carId);
      return ShiftApiResult.ok(result);
    } catch (e) {
      return ShiftApiResult.fail(e.toString());
    }
  }

  Future<ShiftApiResult<void>> closeShift(String id) async {
    try {
      await _api.patchShiftStatus(id);
      return const ShiftApiResult.ok(null);
    } catch (e) {
      return ShiftApiResult.fail(e.toString());
    }
  }

  Future<ShiftApiResult<void>> deleteShift(String id) async {
    try {
      await _api.deleteShift(id);
      return const ShiftApiResult.ok(null);
    } catch (e) {
      return ShiftApiResult.fail(e.toString());
    }
  }
}
