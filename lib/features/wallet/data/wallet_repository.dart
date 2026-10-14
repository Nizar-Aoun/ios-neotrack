import 'package:taxi_driver_app/models/ride.dart';
import 'package:taxi_driver_app/models/expense.dart';
import 'package:taxi_driver_app/models/category.dart';
import 'package:taxi_driver_app/features/wallet/domain/i_wallet_repository.dart';
import 'package:taxi_driver_app/services/ride_service.dart';
import 'package:taxi_driver_app/services/expense_service.dart';
import 'package:taxi_driver_app/services/category_service.dart';

/// Implementation of the wallet repository using existing services
class WalletRepository implements IWalletRepository {
  final String baseUrl;

  WalletRepository({required this.baseUrl});

  @override
  Future<List<Ride>> getRides({
    required String carId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final rideService = RideService(
      baseUrl: baseUrl,
      carId: carId,
    );
  
    return await rideService.getRides(
      startDate: startDate,
      endDate: endDate,
    );
    
  }

  @override
  Future<List<Expense>> getExpenses({
    required String carId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final expenseService = ExpenseService(
      baseUrl: baseUrl,
      carId: carId,
    );
    return await expenseService.getExpenses(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    final categoryService = CategoryService(
      baseUrl: baseUrl,
    );
    return await categoryService.getCategories();
  }

  @override
  Future<Expense> addExpense({
    required String carId,
    required double amount,
    required String categoryId,
    required DateTime date,
    String? description,
  }) async {
    final expenseService = ExpenseService(
      baseUrl: baseUrl,
      carId: carId,
    );
    return await expenseService.createExpense(
      amount: amount,
      categoryId: categoryId,
      date: date,
      title: 'Expense', // Default title
      description: description ?? '',
    );
  }

  @override
  Future<Expense> updateExpense({
    required String expenseId,
    required String carId,
    double? amount,
    String? categoryId,
    DateTime? date,
    String? description,
  }) async {
    final expenseService = ExpenseService(
      baseUrl: baseUrl,
      carId: carId,
    );

    // For update, we need to provide all required fields
    // If any are null, we should fetch the current expense first
    // For now, we'll require all fields to be provided
    if (amount == null || categoryId == null || date == null) {
      throw Exception('All fields are required for expense update');
    }

    return await expenseService.updateExpense(
      expenseId,
      amount: amount,
      categoryId: categoryId,
      date: date,
      title: 'Expense', // Default title
      description: description ?? '',
    );
  }

  @override
  Future<void> deleteExpense({
    required String expenseId,
    required String carId,
  }) async {
    final expenseService = ExpenseService(
      baseUrl: baseUrl,
      carId: carId,
    );
    return await expenseService.deleteExpense(expenseId);
  }

  @override
  Future<void> deleteRide({
    required String rideId,
  }) async {
    // For delete, we don't need carId since rideId is unique
    // Use a placeholder carId just to instantiate the service
    final rideService = RideService(
      baseUrl: baseUrl,
      carId: 'placeholder',
    );
    return await rideService.deleteRide(rideId);
  }
}
