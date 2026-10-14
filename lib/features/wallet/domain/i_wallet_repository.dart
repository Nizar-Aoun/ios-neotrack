import 'package:taxi_driver_app/models/ride.dart';
import 'package:taxi_driver_app/models/expense.dart';
import 'package:taxi_driver_app/models/category.dart';

/// Repository interface for wallet-related operations
abstract class IWalletRepository {
  /// Fetch rides for a given car and date range
  Future<List<Ride>> getRides({
    required String carId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Fetch expenses for a given car and date range
  Future<List<Expense>> getExpenses({
    required String carId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Fetch all expense categories
  Future<List<Category>> getCategories();

  /// Add a new expense
  Future<Expense> addExpense({
    required String carId,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? description,
  });

  /// Update an existing expense
  Future<Expense> updateExpense({
    required String expenseId,
    required String carId,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? description,
  });

  /// Delete an expense
  Future<void> deleteExpense({
    required String expenseId,
    required String carId,
  });

  /// Delete a ride
  Future<void> deleteRide({
    required String rideId,
  });
}
