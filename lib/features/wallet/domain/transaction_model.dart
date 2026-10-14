import 'package:taxi_driver_app/models/ride.dart';
import 'package:taxi_driver_app/models/expense.dart';

/// Represents a financial transaction (either a ride or an expense)
class TransactionModel {
  final String id;
  final DateTime date;
  final bool isExpense;
  final double amount;
  final String? description;
  final dynamic data; // Either Ride or Expense object

  TransactionModel({
    required this.id,
    required this.date,
    required this.isExpense,
    required this.amount,
    this.description,
    required this.data,
  });

  factory TransactionModel.fromRide(Ride ride) {
    // Get first and last location coordinates if available
    String getLocationDesc() {
      if (ride.locations.isEmpty) return 'Ride';
      if (ride.locations.length == 1) {
        return 'Single location ride';
      }
      return 'Ride (${ride.locations.length} locations)';
    }

    return TransactionModel(
      id: ride.id,
      date: ride.startDate ?? DateTime.now(),
      isExpense: false,
      amount: ride.rideAmount ?? 0.0,
      description: getLocationDesc(),
      data: ride,
    );
  }

  factory TransactionModel.fromExpense(Expense expense) {
    return TransactionModel(
      id: expense.id,
      date: expense.date,
      isExpense: true,
      amount: expense.amount,
      description: expense.description,
      data: expense,
    );
  }

  Ride? get asRide => isExpense ? null : data as Ride;
  Expense? get asExpense => isExpense ? data as Expense : null;
}

